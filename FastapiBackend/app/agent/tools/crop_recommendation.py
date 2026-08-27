import logging
from typing import Any

logger = logging.getLogger(__name__)


def predict_crops_ml(
    soil_type: str | None,
    state: str | None,
    district: str | None = None,
    irrigation_source: str | None = None,
    land_size_acres: float | None = None,
    nitrogen: float | None = None,
    phosphorus: float | None = None,
    potassium: float | None = None,
    ph: float | None = None,
    rainfall: float | None = None,
) -> dict[str, Any]:
    """ML Model Inference Interface for Crop Recommendation.

    This function acts as a clean, decoupled placeholder interface.
    When a trained scikit-learn / XGBoost / PyTorch crop prediction model
    is integrated in the future, it will be executed inside this function.
    """
    logger.info(
        f"[ML_PLACEHOLDER] Running predict_crops_ml with soil={soil_type}, state={state}, irrigation={irrigation_source}"
    )

    # Modular heuristic baseline placeholder mapping for Indian agro-climatic zones
    soil = (soil_type or "").lower()
    st = (state or "").lower()

    recommended_crops = []
    if "black" in soil:
        recommended_crops = [
            "Cotton (Bt Cotton)",
            "Soybean",
            "Wheat (Rabi)",
            "Onion",
            "Gram (Chickpea)",
        ]
    elif "alluvial" in soil:
        recommended_crops = ["Wheat", "Paddy (Rice)", "Sugarcane", "Mustard", "Maize"]
    elif "red" in soil:
        recommended_crops = [
            "Groundnut",
            "Ragi (Finger Millet)",
            "Pigeon Pea (Arhar)",
            "Potato",
            "Tomato",
        ]
    elif "sandy" in soil or "arid" in soil:
        recommended_crops = [
            "Bajra (Pearl Millet)",
            "Guar (Cluster Bean)",
            "Mustard",
            "Cumin",
            "Moth Bean",
        ]
    elif "laterite" in soil:
        recommended_crops = ["Cashew", "Coconut", "Arecanut", "Black Pepper", "Tea"]
    else:
        if "punjab" in st or "haryana" in st or "uttar pradesh" in st:
            recommended_crops = ["Wheat", "Paddy", "Sugarcane", "Mustard"]
        elif "maharashtra" in st or "madhya pradesh" in st or "gujarat" in st:
            recommended_crops = ["Cotton", "Soybean", "Gram", "Groundnut", "Onion"]
        elif "andhra" in st or "telangana" in st or "karnataka" in st or "tamil" in st:
            recommended_crops = ["Paddy", "Chilli", "Groundnut", "Ragi", "Maize"]
        else:
            recommended_crops = [
                "Wheat",
                "Pulses (Chickpea/Moong)",
                "Mustard",
                "Seasonal Vegetables",
            ]

    return {
        "model_version": "ml_heuristic_v1_placeholder",
        "is_ml_inferred": False,  # Will be True when actual ML weights are loaded
        "top_crops": recommended_crops,
        "soil_suitability_score": 0.88,
        "recommended_rotation": "Legume intercropping recommended for nitrogen fixation",
    }


def check_missing_crop_recommendation_fields(profile: dict[str, Any]) -> list[str]:
    """Check what essential fields are missing from the farmer's profile for an accurate crop recommendation."""
    missing = []
    if not profile.get("soil_type"):
        missing.append("soil_type")
    if not profile.get("state"):
        missing.append("state or location")
    if not profile.get("irrigation_source"):
        missing.append("irrigation source")
    return missing
