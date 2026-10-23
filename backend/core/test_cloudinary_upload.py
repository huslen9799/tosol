"""Exercise the real Cloudinary storage backend with mocked provider requests."""
from io import BytesIO
from unittest.mock import patch

from cloudinary.exceptions import Error as CloudinaryError
from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from PIL import Image
from requests.exceptions import ConnectionError
from rest_framework.test import APITestCase

from .models import Property


@override_settings(STORAGES={
    "default": {"BACKEND": "cloudinary_storage.storage.MediaCloudinaryStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
})
class CloudinaryUploadTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='upload-owner', password='test-password')
        self.client.force_authenticate(self.user)
        self.property = Property.objects.create(owner=self.user, title='Upload test', price='100000.00')
        self.url = f'/api/properties/{self.property.pk}/photos/'

    def photo(self):
        stream = BytesIO()
        Image.new('RGB', (8, 8), 'green').save(stream, format='PNG')
        return SimpleUploadedFile('room.png', stream.getvalue(), content_type='image/png')

    @patch('cloudinary.uploader.upload', return_value={'public_id': 'media/properties/gallery/room'})
    def test_valid_photo_uses_cloudinary_and_returns_https_url(self, upload):
        response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(self.property.images.count(), 1)
        self.assertTrue(response.data[0]['image'].startswith('https://res.cloudinary.com/'))
        upload.assert_called_once()

    @patch('cloudinary.uploader.upload', side_effect=CloudinaryError('Invalid Signature private-secret'))
    def test_credentials_failure_is_json_and_does_not_leak_provider_response(self, upload):
        with self.assertLogs('core.marketplace', level='ERROR') as logs:
            response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertIn('CLOUDINARY_URL', str(response.data['detail']))
        self.assertIn('category=credentials', ' '.join(logs.output))
        self.assertNotIn('private-secret', str(response.data) + ' '.join(logs.output))
        self.assertEqual(self.property.images.count(), 0)

    @patch('cloudinary.uploader.upload', side_effect=ConnectionError('sensitive-url'))
    def test_connection_error_is_retryable(self, upload):
        response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('sensitive-url', str(response.data))
        self.assertEqual(self.property.images.count(), 0)

    @patch('cloudinary.uploader.upload', side_effect=CloudinaryError('Quota exceeded'))
    def test_provider_quota_error_is_identified(self, upload):
        response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertIn('лимит', str(response.data['detail']))

    @patch('cloudinary.uploader.upload')
    def test_failed_second_photo_rolls_back_rows_and_same_listing_can_retry(self, upload):
        upload.side_effect = [{'public_id': 'media/properties/gallery/first'}, CloudinaryError('Invalid API key')]
        response = self.client.post(self.url, {'images': [self.photo(), self.photo()]}, format='multipart')
        self.assertEqual(response.status_code, 503)
        self.assertEqual(self.property.images.count(), 0)
        upload.side_effect = None
        upload.return_value = {'public_id': 'media/properties/gallery/retry'}
        response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Property.objects.count(), 1)
        self.assertEqual(self.property.images.count(), 1)

    @patch('cloudinary.uploader.upload')
    def test_invalid_file_and_foreign_owner_are_rejected_before_upload(self, upload):
        response = self.client.post(self.url, {'images': SimpleUploadedFile('bad.png', b'not an image')}, format='multipart')
        self.assertEqual(response.status_code, 400)
        other = User.objects.create_user(username='not-owner')
        self.client.force_authenticate(other)
        response = self.client.post(self.url, {'images': self.photo()}, format='multipart')
        self.assertEqual(response.status_code, 403)
        upload.assert_not_called()
