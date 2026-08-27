import datetime

from pydantic import BaseModel

from app.schemas.user import UserResponse


class CategoryStat(BaseModel):
    category: str
    count: int
    percentage: float


class CropTrend(BaseModel):
    crop_name: str
    inquiry_count: int


class StateTrend(BaseModel):
    state: str
    query_count: int


class AdminStatsResponse(BaseModel):
    total_users: int
    total_queries: int
    total_disease_scans: int
    total_crop_recommendations: int
    category_breakdown: list[CategoryStat]
    top_crops_searched: list[CropTrend]
    state_distribution: list[StateTrend]


class SearchLogItem(BaseModel):
    id: int
    user_id: int | None
    user_name: str | None
    query_text: str
    category: str
    detected_crop: str | None
    detected_disease: str | None
    state: str | None
    created_at: datetime.datetime


class AdminInsightsResponse(BaseModel):
    generated_at: datetime.datetime
    summary_headline: str
    key_findings: list[str]
    emerging_crop_demands: list[str]
    prevalent_crop_diseases: list[str]
    farmer_advisory_suggestions: list[str]


class AdminUserListResponse(BaseModel):
    total: int
    users: list[UserResponse]
