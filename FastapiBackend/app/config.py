from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_NAME: str = "SasyamAI"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # PostgreSQL Database URL
    DATABASE_URL: str = (
        "postgresql+asyncpg://sasyamai_user:YOUR_PASSWORD@localhost:5432/sasyamai"
    )

    # JWT Authentication
    JWT_SECRET_KEY: str = Field(
        default="sasyamai-super-secret-jwt-key-change-in-production-2026",
        min_length=32,
    )
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # OpenAI API
    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str = "gpt-4o"
    MAX_OUTPUT_TOKEN: int = 800

    # Sarvam AI Saaras v3 STT + Bulbul TTS
    SARVAM_API_KEY: str | None = None
    SARVAM_STT_URL: str = "https://api.sarvam.ai/speech-to-text"
    SARVAM_TTS_URL: str = "https://api.sarvam.ai/text-to-speech"

    # ImgBB API
    IMGBB_API_KEY: str | None = None
    IMGBB_UPLOAD_URL: str = "https://api.imgbb.com/1/upload"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
