"""Provider contract tests: no real email is sent and no database is needed."""
import io
import json
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.core.mail import EmailMessage, EmailMultiAlternatives, send_mail
from django.test import SimpleTestCase, override_settings

from core.email_backends import ResendDeliveryError, ResendEmailBackend


MAILERS = {"default": {
    "BACKEND": "core.email_backends.ResendEmailBackend",
    "OPTIONS": {"api_key": "re_test_only_not_a_real_key", "timeout": 10},
}}


@override_settings(MAILERS=MAILERS, DEFAULT_FROM_EMAIL="Өргөө <onboarding@resend.dev>")
class ResendEmailTests(SimpleTestCase):
    def accepted(self, mock_open):
        response = MagicMock()
        response.read.return_value = b'{"id":"test-message-id"}'
        mock_open.return_value.__enter__.return_value = response

    @patch("core.email_backends.urlopen")
    def test_send_mail_uses_https_and_preserves_mongolian_otp(self, mock_open):
        self.accepted(mock_open)
        self.assertEqual(send_mail("Баталгаажуулах код", "Таны код: 123456", None, ["owner@example.com"]), 1)
        request = mock_open.call_args.args[0]
        self.assertEqual(request.full_url, "https://api.resend.com/emails")
        self.assertEqual(request.get_method(), "POST")
        self.assertEqual(request.get_header("Authorization"), "Bearer re_test_only_not_a_real_key")
        self.assertEqual(mock_open.call_args.kwargs["timeout"], 10)
        self.assertEqual(json.loads(request.data), {
            "from": "Өргөө <onboarding@resend.dev>", "to": ["owner@example.com"],
            "subject": "Баталгаажуулах код", "text": "Таны код: 123456",
        })

    @patch("core.email_backends.urlopen")
    def test_html_alternative_keeps_text_and_recipient_fields(self, mock_open):
        self.accepted(mock_open)
        message = EmailMultiAlternatives("Subject", "Text", "from@example.com", ["to@example.com"],
                                        cc=["copy@example.com"], reply_to=["reply@example.com"])
        message.attach_alternative("<p>HTML</p>", "text/html")
        self.assertEqual(message.send(), 1)
        payload = json.loads(mock_open.call_args.args[0].data)
        self.assertEqual(payload["text"], "Text")
        self.assertEqual(payload["html"], "<p>HTML</p>")
        self.assertEqual(payload["cc"], ["copy@example.com"])
        self.assertEqual(payload["reply_to"], ["reply@example.com"])

    @patch("core.email_backends.urlopen")
    def test_provider_rejections_are_actionable_without_leaking_response(self, mock_open):
        for status in (401, 403, 422, 429, 500):
            with self.subTest(status=status):
                mock_open.side_effect = HTTPError("https://api.resend.com/emails", status,
                    "provider error", {}, io.BytesIO(b'{"message":"private-otp-and-api-key"}'))
                with self.assertLogs("core.email_backends", level="WARNING") as logs:
                    with self.assertRaisesRegex(ResendDeliveryError, f"Resend HTTP {status}") as error:
                        send_mail("Subject", "123456", None, ["owner@example.com"])
                self.assertNotIn("private-otp", str(error.exception))
                self.assertNotIn("123456", " ".join(logs.output))
                self.assertNotIn("re_test", " ".join(logs.output))

    @patch("core.email_backends.urlopen", side_effect=URLError("private-network-details"))
    def test_connection_failure_is_reported_or_silenced_as_requested(self, mock_open):
        with self.assertRaisesRegex(ResendDeliveryError, "HTTPS connection failed"):
            send_mail("Subject", "Body", None, ["owner@example.com"])
        self.assertEqual(send_mail("Subject", "Body", None, ["owner@example.com"], fail_silently=True), 0)

    @patch("core.email_backends.urlopen")
    def test_missing_acceptance_id_is_not_reported_as_success(self, mock_open):
        for body in (b'{}', b'[]', b'not-json'):
            with self.subTest(body=body):
                mock_open.return_value.__enter__.return_value.read.return_value = body
                with self.assertRaises(ResendDeliveryError):
                    send_mail("Subject", "Body", None, ["owner@example.com"])

    @patch("core.email_backends.urlopen")
    def test_empty_recipient_list_does_not_send(self, mock_open):
        self.assertEqual(send_mail("Subject", "Body", None, []), 0)
        mock_open.assert_not_called()

    @patch("core.email_backends.urlopen")
    def test_attachment_is_not_silently_discarded(self, mock_open):
        message = EmailMessage("Subject", "Body", to=["owner@example.com"])
        message.attach("file.txt", "content", "text/plain")
        with self.assertRaisesRegex(ResendDeliveryError, "Attachments"):
            message.send()
        mock_open.assert_not_called()

    def test_missing_api_key_is_rejected(self):
        with self.assertRaises(ImproperlyConfigured):
            ResendEmailBackend(api_key="  ")


if __name__ == "__main__":
    if not settings.configured:
        settings.configure(SECRET_KEY="test-only", MAILERS=MAILERS, DEFAULT_FROM_EMAIL="test@example.com")
    import django
    django.setup()
    unittest.main()
