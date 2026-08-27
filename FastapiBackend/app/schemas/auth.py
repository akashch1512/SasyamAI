from pydantic import BaseModel, EmailStr


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone_number: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    email: EmailStr
    full_name: str
    google_id: str | None = None
    profile_image_url: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


# Forward reference for TokenResponse will be resolved in user schema
from app.schemas.user import UserResponse

TokenResponse.model_rebuild()
