from rest_framework.test import APITestCase
from core.models import Property


class DistrictFilterTests(APITestCase):
    def setUp(self):
        for district in ['Хан-Уул', 'Баянзүрх', 'Сүхбаатар']:
            for listing_type in ['sale', 'rent']:
                Property.objects.create(title='Test', district=district, listing_type=listing_type, price=100, latitude=47.918, longitude=106.917)

    def test_multiple_districts_are_or_and_other_filters_still_apply(self):
        response = self.client.get('/api/properties/', {'district': 'Хан-Уул,Баянзүрх', 'listing_type': 'sale', 'located': 'true'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['count'], 2)
        self.assertEqual({p['district'] for p in response.data['results']}, {'Хан-Уул', 'Баянзүрх'})

    def test_single_district_and_no_selection_are_compatible(self):
        self.assertEqual(self.client.get('/api/properties/', {'district': 'Хан-Уул'}).data['count'], 2)
        self.assertEqual(self.client.get('/api/properties/', {'district': ''}).data['count'], 6)
        self.assertEqual(self.client.get('/api/properties/', {'district': ' , '}).data['count'], 6)

    def test_repeated_and_duplicate_values_do_not_duplicate_results(self):
        response = self.client.get('/api/properties/', {'district': ['Хан-Уул,Хан-Уул', ' Баянзүрх ']})
        self.assertEqual(response.data['count'], 4)
