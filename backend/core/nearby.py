"""Байрны ойр байрлах нийтийн газруудыг OpenStreetMap-оос хайх.

Байрны latitude/longitude-гоор сургууль, цэцэрлэг, эмийн сан, автобусны
буудал, дэлгүүр/худалдааны төвийг Overpass API-аас хайж, зайг туулайгаар
тооцно. Үр дүнг Django cache-д түр хадгалж давтан хүсэлтээс сэргийлнэ.
"""
import logging
import math

import requests
from django.core.cache import cache

logger = logging.getLogger(__name__)

# Нийтийн Overpass mirror-үүд. Нэг нь унасан/хязгаарлагдсан ч бусдаар
# оролдох боломжтой. Дараалал: хамгийн найдвартай нь эхэнд.
OVERPASS_URLS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
]
CACHE_TTL = 60 * 60 * 24  # 24 цаг ( давтамжтай харагдах газрууд шуурхай)
DEFAULT_RADIUS = 1500  # метр
PER_CATEGORY = 3
OVERPASS_TIMEOUT = 15  # Overpass query-ийн timeout (секунд)
REQUESTS_TIMEOUT = 15  # mirror тус бүрийн HTTP timeout (секунд)


class NearbyUnavailable(Exception):
    """Overpass API болон сүлжээний алдааг илэрхийлэх."""


# Ангилал: key -> (харуулах нэр, Overpass-ийн node шүүлтүүр).
# node-only (way/relation-г оруулдаггүй) -> Overpass хурдан хариулна.
# OSM-д сургууль/цэцэрлэг/эмийн сан/буудал/дэлгүүр ихэнх нь node хэлбэртэй.
CATEGORIES = {
    "school": ("Сургууль", 'node["amenity"="school"]'),
    "kindergarten": ("Цэцэрлэг", 'node["amenity"="kindergarten"]'),
    "pharmacy": ("Эмийн сан", 'node["amenity"="pharmacy"]'),
    "bus_stop": ("Автобусны буудал", 'node["highway"="bus_stop"]'),
    "shop": (
        "Дэлгүүр / худалдааны төв",
        'node["shop"~"^(supermarket|mall|convenience|department_store)$"]',
    ),
}

_SHOP_TYPES = {"supermarket", "mall", "convenience", "department_store"}


def haversine(lat1, lon1, lat2, lon2):
    """Хоёр координатын хоорондох зай метрээр."""
    radius = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    return 2 * radius * math.asin(math.sqrt(a))


def _classify(tags):
    amenity = tags.get("amenity")
    if amenity == "school":
        return "school"
    if amenity == "kindergarten":
        return "kindergarten"
    if amenity == "pharmacy":
        return "pharmacy"
    if tags.get("highway") == "bus_stop":
        return "bus_stop"
    if tags.get("shop") in _SHOP_TYPES:
        return "shop"
    return None


def _place_name(tags, category):
    for key in ("name:mn", "name", "name:en"):
        value = tags.get(key)
        if value:
            return value
    return CATEGORIES[category][0]


def _element_point(element):
    if "lat" in element and "lon" in element:
        return element["lat"], element["lon"]
    center = element.get("center") or {}
    if "lat" in center and "lon" in center:
        return center["lat"], center["lon"]
    return None


def _build_query(latitude, longitude, radius):
    parts = []
    for _label, node_filter in CATEGORIES.values():
        parts.append(f"{node_filter}(around:{radius},{latitude},{longitude});")
    return "[out:json][timeout:%d];(" % OVERPASS_TIMEOUT + "".join(parts) + ");out qt;"


def _fetch(latitude, longitude, radius):
    query = _build_query(latitude, longitude, radius)
    errors = []
    for url in OVERPASS_URLS:
        try:
            response = requests.get(
                url,
                params={"data": query},
                timeout=REQUESTS_TIMEOUT,
                headers={"User-Agent": "UgeuBairApp/1.0 (nearby lookup)"},
            )
            response.raise_for_status()
            payload = response.json()
            elements = payload.get("elements", [])
            logger.info("Nearby Overpass ok via %s (%d elements)", url, len(elements))
            return elements
        except Exception as error:  # сүлжээ, timeout, буруу JSON
            errors.append(f"{url}: {error}")
            logger.warning("Nearby Overpass failed via %s: %s", url, error)
    raise NearbyUnavailable("; ".join(errors))


def nearby_amenities(latitude, longitude, radius=DEFAULT_RADIUS, per_category=PER_CATEGORY):
    """Ангилал бүрийн хамгийн ойр газруудыг буцаана.

    Үр дүн: {latitude, longitude, radius, categories: [
        {key, label, places: [{name, distance, latitude, longitude}]}
    ]}
    """
    cache_key = f"nearby:{round(latitude, 3)}:{round(longitude, 3)}:{radius}:{per_category}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    elements = _fetch(latitude, longitude, radius)

    grouped = {key: [] for key in CATEGORIES}
    for element in elements:
        tags = element.get("tags") or {}
        category = _classify(tags)
        if category is None:
            continue
        point = _element_point(element)
        if point is None:
            continue
        lat, lon = point
        distance = haversine(latitude, longitude, lat, lon)
        grouped[category].append(
            {
                "name": _place_name(tags, category),
                "distance": int(round(distance)),
                "latitude": lat,
                "longitude": lon,
            }
        )

    categories = []
    for key, (label, _node_filter) in CATEGORIES.items():
        places = sorted(grouped[key], key=lambda item: item["distance"])[:per_category]
        categories.append({"key": key, "label": label, "places": places})

    result = {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "categories": categories,
    }
    cache.set(cache_key, result, CACHE_TTL)
    return result