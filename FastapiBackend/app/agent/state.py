from typing import Any, TypedDict


class FarmerProfileContext(TypedDict, total=False):
    user_id: int
    full_name: str
    phone_number: str | None
    state: str | None
    district: str | None
    latitude: float | None
    longitude: float | None
    soil_type: str | None
    land_size_acres: float | None
    irrigation_source: str | None
    primary_crops: str | None
    preferred_language: str
    is_onboarded: bool


class AgentState(TypedDict, total=False):
    # Core Chat Context
    messages: list[dict[str, Any]]
    current_user_message: str
    image_url: str | None
    user_profile: FarmerProfileContext

    # Intent & Routing
    intent: (
        str | None
    )  # crop_recommendation | crop_price | government_schemes | disease_detection | farm_advisory | general
    missing_fields: list[str]
    clarification_question: str | None

    # Domain Tool Outputs
    ml_prediction_result: dict[str, Any] | None
    disease_analysis_result: dict[str, Any] | None
    crop_price_result: str | None
    government_schemes_result: str | None
    advisory_context: str | None

    # Detected Entities for Analytics
    detected_crop: str | None
    detected_disease: str | None

    # Final Output
    final_response: str
    suggested_actions: list[str]
