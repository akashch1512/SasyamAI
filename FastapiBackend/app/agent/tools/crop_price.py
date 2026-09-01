import logging
from typing import Any

logger = logging.getLogger(__name__)

# Indicative APMC / mandi ranges (₹/quintal) used until a live Agmarknet feed is wired.
_INDICATIVE_PRICES: dict[str, dict[str, Any]] = {
    "wheat": {"min": 2200, "max": 2650, "modal": 2420, "unit": "₹/quintal"},
    "paddy": {"min": 2180, "max": 2600, "modal": 2320, "unit": "₹/quintal"},
    "rice": {"min": 2800, "max": 3600, "modal": 3180, "unit": "₹/quintal"},
    "cotton": {"min": 6200, "max": 7800, "modal": 7050, "unit": "₹/quintal"},
    "soybean": {"min": 4100, "max": 4900, "modal": 4450, "unit": "₹/quintal"},
    "maize": {"min": 1850, "max": 2300, "modal": 2080, "unit": "₹/quintal"},
    "mustard": {"min": 5200, "max": 6200, "modal": 5680, "unit": "₹/quintal"},
    "gram": {"min": 4800, "max": 5800, "modal": 5250, "unit": "₹/quintal"},
    "chickpea": {"min": 4800, "max": 5800, "modal": 5250, "unit": "₹/quintal"},
    "onion": {"min": 1200, "max": 2800, "modal": 1850, "unit": "₹/quintal"},
    "tomato": {"min": 800, "max": 2400, "modal": 1450, "unit": "₹/quintal"},
    "sugarcane": {"min": 310, "max": 360, "modal": 340, "unit": "₹/quintal"},
    "groundnut": {"min": 5400, "max": 6800, "modal": 6050, "unit": "₹/quintal"},
    "turmeric": {"min": 7200, "max": 9800, "modal": 8450, "unit": "₹/quintal"},
    "chilli": {"min": 9000, "max": 14500, "modal": 11200, "unit": "₹/quintal"},
}


def _lookup_price(crop_name: str | None) -> tuple[str, dict[str, Any]]:
    crop = (crop_name or "wheat").strip()
    key = crop.lower()
    for name, data in _INDICATIVE_PRICES.items():
        if name in key:
            return name.title(), data
    return crop.title(), {
        "min": 2000,
        "max": 3200,
        "modal": 2500,
        "unit": "₹/quintal",
    }


def fetch_crop_market_price(
    crop_name: str | None = None,
    mandi_name: str | None = None,
    state: str | None = None,
    district: str | None = None,
) -> dict[str, Any]:
    """Return indicative mandi price guidance for a crop and location."""
    resolved_crop, price = _lookup_price(crop_name)
    market = mandi_name or district or state or "nearest APMC / e-NAM mandi"
    logger.info(
        f"[PRICE_FETCHER] crop={resolved_crop}, state={state}, mandi={market}"
    )
    return {
        "status": "ok",
        "crop_name": resolved_crop,
        "state": state,
        "district": district,
        "mandi_name": market,
        "min_price": price["min"],
        "max_price": price["max"],
        "modal_price": price["modal"],
        "unit": price["unit"],
        "note": "Indicative range based on recent Indian APMC bands. Confirm today's lot at the local mandi or e-NAM.",
    }
