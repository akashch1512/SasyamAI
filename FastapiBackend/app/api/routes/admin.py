from fastapi import APIRouter, Query
from sqlalchemy import desc, func, select

from app.core.dependencies import AdminUserDep, DatabaseDep
from app.models.analytics import QueryAnalytics
from app.models.user import User
from app.schemas.admin import (
    AdminInsightsResponse,
    AdminStatsResponse,
    AdminUserListResponse,
    SearchLogItem,
)
from app.schemas.user import UserResponse
from app.services.analytics_service import (
    get_admin_ai_insights,
    get_admin_dashboard_stats,
)

router = APIRouter(prefix="/admin", tags=["Admin Panel & Analytics"])


@router.get("/stats", response_model=AdminStatsResponse)
async def get_stats(
    admin: AdminUserDep,
    db: DatabaseDep,
) -> AdminStatsResponse:
    """Retrieve statistical aggregations, query counts, and category distributions."""
    return await get_admin_dashboard_stats(db)


@router.get("/insights", response_model=AdminInsightsResponse)
async def get_insights(
    admin: AdminUserDep,
    db: DatabaseDep,
) -> AdminInsightsResponse:
    """Retrieve structured AI analysis of farmer queries, top diseases, and crop demands."""
    return await get_admin_ai_insights(db)


@router.get("/users", response_model=AdminUserListResponse)
async def list_users(
    admin: AdminUserDep,
    db: DatabaseDep,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> AdminUserListResponse:
    """List registered users and farmers."""
    total_res = await db.execute(select(func.count(User.id)))
    total = total_res.scalar() or 0

    query = select(User).order_by(desc(User.created_at)).offset(skip).limit(limit)
    res = await db.execute(query)
    users = res.scalars().all()

    return AdminUserListResponse(
        total=total,
        users=[UserResponse.model_validate(u) for u in users],
    )


@router.get("/queries-summary", response_model=list[SearchLogItem])
async def get_queries_summary(
    admin: AdminUserDep,
    db: DatabaseDep,
    limit: int = Query(30, ge=1, le=100),
) -> list[SearchLogItem]:
    """List recent search queries with category and detected crop/disease entities."""
    query = (
        select(QueryAnalytics, User.full_name)
        .outerjoin(User, QueryAnalytics.user_id == User.id)
        .order_by(desc(QueryAnalytics.created_at))
        .limit(limit)
    )
    result = await db.execute(query)
    rows = result.all()

    return [
        SearchLogItem(
            id=log.id,
            user_id=log.user_id,
            user_name=user_name or "Anonymous",
            query_text=log.query_text,
            category=log.category,
            detected_crop=log.detected_crop,
            detected_disease=log.detected_disease,
            state=log.state,
            created_at=log.created_at,
        )
        for log, user_name in rows
    ]
