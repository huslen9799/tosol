from io import StringIO
from django.core.management import call_command
from django.test import TestCase
from core.models import Property, Complex, ComplexRating, ComplexComment, Favorite


class DemoSeedTests(TestCase):
    def test_all_sections_and_rerun_preserve_real_data(self):
        real = Property.objects.create(title='Бодит зар', price=100000000)
        before = Property.objects.filter(pk=real.pk).values().get()
        call_command('seed_demo', stdout=StringIO())
        samples = Property.objects.exclude(pk=real.pk)
        self.assertEqual(samples.count(), 72)
        self.assertEqual(samples.filter(listing_type='rent').count(), 36)
        self.assertEqual(samples.filter(listing_type='sale').count(), 36)
        self.assertEqual(samples.values('district').distinct().count(), 9)
        self.assertEqual(samples.values('property_type').distinct().count(), 4)
        self.assertEqual(samples.filter(latitude__isnull=False, longitude__isnull=False).count(), 72)
        for sample in samples:
            sample.full_clean()
            self.assertIn('Жишээ', sample.title)
            self.assertLessEqual(sample.floor, sample.total_floors)
        snapshot = list(Property.objects.order_by('pk').values())
        call_command('seed_demo', stdout=StringIO())
        self.assertEqual(list(Property.objects.order_by('pk').values()), snapshot)
        self.assertEqual(Complex.objects.count(), 9)
        self.assertEqual(ComplexRating.objects.count(), 27)
        self.assertEqual(ComplexComment.objects.count(), 27)
        self.assertEqual(Favorite.objects.count(), 72)
        self.assertEqual(Property.objects.filter(pk=real.pk).values().get(), before)
