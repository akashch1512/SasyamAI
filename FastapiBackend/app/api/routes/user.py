from typing import Annotated

from fastapi import APIRouter, File, UploadFile

from app.core.dependencies import CurrentUserDep, DatabaseDep
from app.schemas.user import UserOnboardingRequest, UserProfileUpdate, UserResponse
from app.services.imgbb_service import upload_image_to_imgbb

router = APIRouter(prefix="/user", tags=["User Profile & Onboarding"])


@router.get("/profile", response_model=UserResponse)
async def get_profile(current_user: CurrentUserDep) -> UserResponse:
    """Retrieve farmer profile details."""
    return UserResponse.model_validate(current_user)


@router.put("/profile", response_model=UserResponse)
async def update_profile(
    update_data: UserProfileUpdate,
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> UserResponse:
    """Update personal and farm details."""
    update_dict = update_data.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        setattr(current_user, field, val)

    await db.commit()
    await db.refresh(current_user)
    return UserResponse.model_validate(current_user)


@router.post("/onboarding", response_model=UserResponse)
async def complete_onboarding(
    onboarding_data: UserOnboardingRequest,
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> UserResponse:
    """Save onboarding info (location, phone, soil, land size, crops) and mark user as onboarded."""
    data = onboarding_data.model_dump(exclude_unset=True)
    for field, val in data.items():
        setattr(current_user, field, val)

    current_user.is_onboarded = True
    await db.commit()
    await db.refresh(current_user)
    return UserResponse.model_validate(current_user)


@router.post("/upload-image")
async def upload_user_image(
    file: Annotated[UploadFile, File()],
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> dict:
    """Upload an image (profile picture or farm picture) via ImgBB."""
    content = await file.read()
    result = await upload_image_to_imgbb(
        content, filename=file.filename or "upload.jpg"
    )

    if result.get("success") and current_user and db:
        # Optionally update user's profile image
        image_url = result.get("image_url")
        if image_url:
            current_user.profile_image_url = image_url
            await db.commit()

    return result
