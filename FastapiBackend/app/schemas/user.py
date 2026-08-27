import datetime

from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    phone_number: str | None = None
    profile_image_url: str | None = None
    role: str = "user"
    state: str | None = None
    district: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    soil_type: str | None = None
    land_size_acres: float | None = None
    irrigation_source: str | None = None
    primary_crops: str | None = None
    preferred_language: str = "en"
    is_onboarded: bool = False
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    full_name: str | None = None
    phone_number: str | None = None
    profile_image_url: str | None = None
    state: str | None = None
    district: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    soil_type: str | None = None
    land_size_acres: float | None = None
    irrigation_source: str | None = None
    primary_crops: str | None = None
    preferred_language: str | None = None


class UserOnboardingRequest(BaseModel):
    phone_number: str | None = None
    state: str | None = None
    district: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    soil_type: str | None = None
    land_size_acres: float | None = None
    irrigation_source: str | None = None
    primary_crops: str | None = None
    preferred_language: str = "en"
