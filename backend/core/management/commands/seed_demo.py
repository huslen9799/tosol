"""Add explicitly fictional examples without overwriting existing application data."""
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from core.comfort import DEFAULT_WEIGHTS
from core.models import (Complex, ComplexComment, ComplexRating, ComfortWeights,
                         District, Favorite, Property)

AREAS = (
    ('Хан-Уул', 47.8865, 106.9120), ('Сүхбаатар', 47.9280, 106.9250),
    ('Баянзүрх', 47.9180, 106.9700), ('Баянгол', 47.9160, 106.8700),
    ('Сонгинохайрхан', 47.9320, 106.8100), ('Чингэлтэй', 47.9500, 106.9000),
    ('Налайх', 47.7720, 107.2530), ('Багануур', 47.7850, 108.3650),
    ('Багахангай', 47.3630, 107.4910),
)
TYPES = ('apartment', 'house', 'office', 'land')
LABELS = ('орон сууц', 'хаус', 'оффис', 'газар')
PHOTO_IDS = ('1609766857326-18a204c2cf31', '1701092868263-2ed67ac8dfa0', '1612419299101-6c294dc2901d')
PHOTO_SLUGS = ('jt2I98bh53A', '_BBps6MAJ2w', 'QGxBeUDkeWk')
PREFIX = '[bair-demo-v2:'


class Command(BaseCommand):
    help = 'Add 72 marked demo listings, map coordinates, 9 demo complexes, ratings, comments and saved examples. Safe to rerun.'

    @transaction.atomic
    def handle(self, *args, **options):
        User = get_user_model()
        users = []
        for number in range(4):
            username = f'__bair_demo_v2_{number}__'
            email = f'demo-v2-{number}@example.invalid'
            user, _ = User.objects.get_or_create(username=username, defaults={
                'email': email, 'first_name': 'Жишээ', 'last_name': f'Хэрэглэгч {number + 1}',
                'is_active': False, 'password': '!',
            })
            user = User.objects.select_for_update().get(pk=user.pk)
            if user.email != email or user.is_active or user.has_usable_password():
                raise CommandError('Reserved demo account already belongs to another user. No changes applied.')
            users.append(user)
            ComfortWeights.objects.get_or_create(user=user, defaults={'weights': dict(DEFAULT_WEIGHTS)})

        added = skipped = 0
        for district_index, (name, lat, lon) in enumerate(AREAS):
            district, _ = District.objects.get_or_create(name=name)
            complex_obj, _ = Complex.objects.get_or_create(
                district=district, name=f'Жишээ — {name} өргөө',
                defaults={'address': f'{name}, туршилтын байршил',
                          'description': 'Зөвхөн аппын загвар, хайлт, газрын зургийг турших зохиомол хотхон. Бодит төсөл биш.'},
            )
            for reviewer_index, user in enumerate(users[1:]):
                marker = f'[bair-demo-v2-comment:{district_index}:{reviewer_index}]'
                comment, _ = ComplexComment.objects.get_or_create(
                    complex=complex_obj, user=user, text=(
                        f'Жишээ сэтгэгдэл. {("Нийтийн тээвэр болон үйлчилгээ ойр байх хувилбарыг туршиж байна.", "Ногоон орчин, зогсоолын үнэлгээний жишээ.", "Байршил болон ашиглалтын зардлыг харьцуулах жишээ.")[reviewer_index]} {marker}'
                    ),
                )
                ComplexRating.objects.get_or_create(complex=complex_obj, user=user, defaults={
                    'scores': {key: 55 + (district_index * 7 + reviewer_index * 11 + i * 3) % 41 for i, key in enumerate(DEFAULT_WEIGHTS)},
                    'explanation_comment': comment,
                })

            for type_index, kind in enumerate(TYPES):
                for rent in (False, True):
                    index = district_index * 8 + type_index * 2 + int(rent)
                    marker = f'{PREFIX}{index:02d}]'
                    if Property.objects.filter(description__contains=marker).exists():
                        skipped += 1
                        continue
                    area = Decimal((64, 160, 92, 700)[type_index] + district_index * (2 if kind != 'land' else 10))
                    rooms = (2 + district_index % 3, 4 + district_index % 2, 2, 1)[type_index]
                    total_floors = (12 + district_index % 3 * 2, 2, 8, 1)[type_index]
                    floor = (1 + district_index % total_floors) if kind in ('apartment', 'office') else 1
                    price = (Decimal((1800000, 4500000, 3200000, 800000)[type_index]) + district_index * 150000) if rent else area * Decimal((4500000, 4200000, 5200000, 180000)[type_index] + district_index * 50000)
                    photo_index = index % len(PHOTO_IDS)
                    listing = Property(
                        owner=users[0], complex=complex_obj, district=name,
                        title=f'Жишээ • {name} — {rooms} өрөө {LABELS[type_index]}' if kind != 'land' else f'Жишээ • {name} — {area} м² газар',
                        description=(f'Жишээ зар. Бодит худалдах, түрээслэх санал биш. {marker}\n'
                                     f'{name} дүүрэгт байрлах {LABELS[type_index]}-ын зохиомол мэдээлэл. '
                                     f'{area} м² талбайтай. Хайлт, шүүлтүүр, харьцуулалт болон газрын зургийн туршилтад зориулав.\n'
                                     'Газрын зургийн цэг нь зөвхөн жишээ, бодит объектын байршил биш.\n'
                                     + (f'Жишээ интерьер зураг; бодит объектын зураг биш. Эх сурвалж: https://unsplash.com/photos/{PHOTO_SLUGS[photo_index]}' if kind in ('apartment', 'house', 'office') else 'Газрын зургийн жишээ зар.')),
                        location=f'{name}, Жишээ өргөө — туршилтын байршил',
                        property_type=kind, listing_type='rent' if rent else 'sale',
                        area=area, rooms=rooms, total_floors=total_floors, floor=floor,
                        price=price, contact_phone='', is_featured=index % 5 == 0,
                        latitude=lat + type_index * .002 + int(rent) * .0007,
                        longitude=lon + type_index * .003 + int(rent) * .0009,
                        remote_image_url=(f'https://images.unsplash.com/photo-{PHOTO_IDS[photo_index]}?auto=format&fit=crop&w=1200&q=85' if kind != 'land' else ''),
                    )
                    listing.full_clean()
                    listing.save()
                    Favorite.objects.get_or_create(user=users[1], property=listing)
                    added += 1
        self.stdout.write(self.style.SUCCESS(f'Demo: {added} listings added, {skipped} skipped; 9 demo complexes, 27 ratings/comments, 4 demo users. Existing data preserved.'))
