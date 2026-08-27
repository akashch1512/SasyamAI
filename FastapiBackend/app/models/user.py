import datetime

from sqlalchemy import Boolean, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True, nullable=False
    )
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone_number: Mapped[str | None] = mapped_column(String(30), nullable=True)
    profile_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    role: Mapped[str] = mapped_column(
        String(50), default="user", nullable=False
    )  # "user" or "admin"

    # Farmer Specific Details
    state: Mapped[str | None] = mapped_column(String(100), nullable=True)
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    soil_type: Mapped[str | None] = mapped_column(
        String(100), nullable=True
    )  # e.g., Alluvial, Black, Red, Sandy
    land_size_acres: Mapped[float | None] = mapped_column(Float, nullable=True)
    irrigation_source: Mapped[str | None] = mapped_column(
        String(100), nullable=True
    )  # e.g., Borewell, Canal, Rainfed
    primary_crops: Mapped[str | None] = mapped_column(
        Text, nullable=True
    )  # JSON or comma-separated string
    preferred_language: Mapped[str] = mapped_column(
        String(20), default="en", nullable=False
    )
    is_onboarded: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.datetime.now(datetime.UTC),
        nullable=False,
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.datetime.now(datetime.UTC),
        onupdate=lambda: datetime.datetime.now(datetime.UTC),
        nullable=False,
    )

    # Relationships
    sessions = relationship(
        "ChatSession", back_populates="user", cascade="all, delete-orphan"
    )
    analytics = relationship("QueryAnalytics", back_populates="user")
