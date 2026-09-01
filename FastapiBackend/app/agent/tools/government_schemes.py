import logging
from typing import Any

logger = logging.getLogger(__name__)

_SCHEMES: list[dict[str, str]] = [
    {
        "name": "PM-KISAN",
        "benefit": "₹6,000 per year in three instalments of ₹2,000 for landholding farmer families.",
        "how_to_apply": "Register or check status on pmkisan.gov.in with Aadhaar-linked land records.",
        "keywords": "kisan income support pmkisan",
    },
    {
        "name": "PMFBY (Pradhan Mantri Fasal Bima Yojana)",
        "benefit": "Crop insurance against drought, flood, pest, and other non-preventable risks at low premium.",
        "how_to_apply": "Enrol through the bank, CSC, or pmfby.gov.in before the notified cut-off date.",
        "keywords": "insurance crop pmfby fasal bima",
    },
    {
        "name": "Kisan Credit Card (KCC)",
        "benefit": "Short-term crop credit at concessional interest, often with 3% prompt-repayment rebate.",
        "how_to_apply": "Apply at your nearest cooperative, rural, or commercial bank with land and ID proof.",
        "keywords": "kcc credit loan interest",
    },
    {
        "name": "PM-KUSUM",
        "benefit": "Subsidy on solar pumps and grid-connected solar for irrigation, reducing diesel cost.",
        "how_to_apply": "Apply via the state renewable-energy / agriculture portal under PM-KUSUM Component B/C.",
        "keywords": "solar pump kusum irrigation electricity",
    },
    {
        "name": "Micro Irrigation (PDMC / drip-sprinkler subsidy)",
        "benefit": "Typically 45–55% subsidy on drip and sprinkler systems, higher for small/marginal farmers.",
        "how_to_apply": "Apply through the district horticulture / agriculture office or pmksy.gov.in.",
        "keywords": "drip sprinkler irrigation subsidy water",
    },
    {
        "name": "Soil Health Card",
        "benefit": "Free soil testing with nutrient recommendations for your plot.",
        "how_to_apply": "Request a sample test at the local Krishi Vigyan Kendra or agriculture department.",
        "keywords": "soil health test fertilizer",
    },
]


def fetch_government_schemes(
    scheme_name: str | None = None,
    state: str | None = None,
    land_size_acres: float | None = None,
    crop_name: str | None = None,
    farmer_category: str | None = None,
) -> dict[str, Any]:
    """Return relevant central agricultural schemes for the farmer query."""
    logger.info(
        f"[SCHEMES] scheme={scheme_name}, state={state}, land_size={land_size_acres}"
    )
    query = " ".join(
        filter(None, [scheme_name, crop_name, farmer_category])
    ).lower()
    matched = [
        s
        for s in _SCHEMES
        if not query or any(word in query for word in s["keywords"].split())
    ]
    if not matched:
        matched = _SCHEMES[:4]
    return {
        "status": "ok",
        "scheme_name": scheme_name,
        "state": state,
        "land_size_acres": land_size_acres,
        "schemes": [
            {
                "name": s["name"],
                "benefit": s["benefit"],
                "how_to_apply": s["how_to_apply"],
            }
            for s in matched
        ],
    }
