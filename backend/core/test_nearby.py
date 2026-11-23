from unittest.mock import patch

from django.core.cache import cache
from django.contrib.auth.models import User
from rest_framework.test import APITestCase

from .models import Property
from .nearby import NearbyUnavailable, haversine, nearby_amenities


def _element(name, lat, lon, amenity=None, **extra):
    tags = {"name": name}
    tags.update(extra)
    if amenity is not None:
        tags["amenity"] = amenity
    return {"type": "node", "lat": lat, "lon": lon, "tags": tags}


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self._payload


OVERPASS_ELEMENTS = [
    _element("Эхний сургууль", 47.9200, 106.9200, amenity="school"),
    _element("Хоёр сургууль", 47.9230, 106.9230, amenity="school"),
    _element("Цэцэрлэг", 47.9190, 106.9190, amenity="kindergarten"),
    _element("Эмийн сан", 47.9195, 106.9195, amenity="pharmacy"),
    _element("Буудал", 47.9210, 106.9210, highway="bus_stop"),
    _element("Дэлгүүр", 47.9215, 106.9215, shop="supermarket"),
    _element("Хамааралгүй", 47.9300, 106.9300),
]


class NearbyFunctionTests(APITestCase):
    def setUp(self):
        cache.clear()

    def test_haversine_is_symmetric_and_zero_for_same_point(self):
        self.assertEqual(haversine(47.9, 106.9, 47.9, 106.9), 0)
        a = haversine(47.9, 106.9, 47.92, 106.92)
        b = haversine(47.92, 106.92, 47.9, 106.9)
        self.assertAlmostEqual(a, b, places=6)

    def test_groups_by_category_sorted_by_distance(self):
        with patch("core.nearby.requests.get", return_value=FakeResponse({"elements": OVERPASS_ELEMENTS})):
            result = nearby_amenities(47.9185, 106.9177)
        by_key = {c["key"]: c for c in result["categories"]}
        # Шилдэг сургууль хамгийн ойр нь байх ёстой.
        self.assertEqual(by_key["school"]["places"][0]["name"], "Эхний сургууль")
        distances = [p["distance"] for p in by_key["school"]["places"]]
        self.assertEqual(distances, sorted(distances))
        self.assertTrue(by_key["kindergarten"]["places"])
        self.assertTrue(by_key["pharmacy"]["places"])
        self.assertTrue(by_key["bus_stop"]["places"])
        self.assertTrue(by_key["shop"]["places"])

    def test_unavailable_raises(self):
        with patch("core.nearby.requests.get", side_effect=OSError("boom")):
            with self.assertRaises(NearbyUnavailable):
                nearby_amenities(47.9185, 106.9177)

    def test_cache_prevents_second_fetch(self):
        with patch("core.nearby.requests.get", return_value=FakeResponse({"elements": OVERPASS_ELEMENTS})) as mocked:
            nearby_amenities(47.9185, 106.9177)
            nearby_amenities(47.9185, 106.9177)
        self.assertEqual(mocked.call_count, 1)


class NearbyEndpointTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.owner = User.objects.create_user("nearby_owner", password="password123")
        self.values = dict(owner=self.owner, title="Байр", location="Байр 1", district="Хан-Уул",
                           price=100000000, area=60, contact_phone="99112233")
        self.located = Property.objects.create(**self.values, latitude=47.9185, longitude=106.9177)
        self.unlocated = Property.objects.create(**self.values)

    def test_no_coordinates_returns_unavailable(self):
        result = self.client.get(f"/api/properties/{self.unlocated.pk}/nearby/")
        self.assertEqual(result.status_code, 200)
        self.assertFalse(result.data["available"])
        self.assertEqual(result.data["reason"], "no_coordinates")
        self.assertEqual(result.data["categories"], [])

    def test_located_returns_nearby_categories(self):
        with patch("core.nearby.requests.get", return_value=FakeResponse({"elements": OVERPASS_ELEMENTS})):
            result = self.client.get(f"/api/properties/{self.located.pk}/nearby/")
        self.assertEqual(result.status_code, 200)
        self.assertTrue(result.data["available"])
        keys = {c["key"] for c in result.data["categories"]}
        self.assertEqual(keys, {"school", "kindergarten", "pharmacy", "bus_stop", "shop"})

    def test_overpass_failure_is_graceful(self):
        with patch("core.nearby.requests.get", side_effect=OSError("boom")):
            result = self.client.get(f"/api/properties/{self.located.pk}/nearby/")
        self.assertEqual(result.status_code, 200)
        self.assertFalse(result.data["available"])
        self.assertEqual(result.data["reason"], "unavailable")

    def test_missing_property_returns_404(self):
        self.assertEqual(self.client.get("/api/properties/99999/nearby/").status_code, 404)