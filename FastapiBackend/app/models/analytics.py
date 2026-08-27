import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class QueryAnalytics(Base):
    __tablename__ = "query_analytics"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    session_id: Mapped[str | None] = mapped_column(String(36), nullable=True)

    query_text: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(
        String(50), default="general", index=True, nullable=False
    )
    # Categories: "crop_recommendation", "crop_price", "government_schemes", "disease_detection", "farm_advisory", "general"

    detected_crop: Mapped[str | None] = mapped_column(
        String(100), nullable=True, index=True
    )
    detected_disease: Mapped[str | None] = mapped_column(String(150), nullable=True)
    state: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.datetime.now(datetime.UTC),
        nullable=False,
    )

    # Relationships
    user = relationship("User", back_populates="analytics")
