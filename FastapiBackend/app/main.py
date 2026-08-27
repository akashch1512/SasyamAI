import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.api.routes.admin import router as admin_router
from app.api.routes.auth import router as auth_router
from app.api.routes.chat import router as chat_router
from app.api.routes.user import router as user_router
from app.api.routes.voice import router as voice_router
from app.config import settings
from app.core.security import get_password_hash
from app.database import async_session_factory, engine
from app.models import Base, User

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("sasyamai")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: initialize database tables and seed default accounts."""
    logger.info("Initializing SasyamAI database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed default Admin and Demo Farmer accounts if not present
    async with async_session_factory() as session:
        admin_res = await session.execute(
            select(User).where(User.email == "admin@sasyamai.com")
        )
        admin = admin_res.scalar_one_or_none()
        if not admin:
            logger.info("Seeding default admin user (admin@sasyamai.com)...")
            default_admin = User(
                email="admin@sasyamai.com",
                hashed_password=get_password_hash("admin123"),
                full_name="SasyamAI Admin",
                phone_number="+919876543210",
                role="admin",
                state="Maharashtra",
                district="Pune",
                soil_type="Black Soil",
                land_size_acres=10.0,
                irrigation_source="Borewell",
                primary_crops="Cotton, Soybean, Wheat",
                is_onboarded=True,
            )
            session.add(default_admin)
            await session.commit()

        # Seed sample farmer
        farmer_res = await session.execute(
            select(User).where(User.email == "farmer@sasyamai.com")
        )
        if not farmer_res.scalar_one_or_none():
            logger.info("Seeding sample farmer user (farmer@sasyamai.com)...")
            sample_farmer = User(
                email="farmer@sasyamai.com",
                hashed_password=get_password_hash("farmer123"),
                full_name="Ramesh Kumar",
                phone_number="+919876500001",
                role="user",
                state="Maharashtra",
                district="Nashik",
                soil_type="Black Soil",
                land_size_acres=5.5,
                irrigation_source="Drip & Borewell",
                primary_crops="Tomato, Onion, Cotton",
                is_onboarded=True,
            )
            session.add(sample_farmer)
            await session.commit()

    logger.info(f"{settings.APP_NAME} backend started successfully.")
    yield
    logger.info("Shutting down SasyamAI backend...")
    await engine.dispose()


app = FastAPI(
    title=settings.APP_NAME,
    description="SasyamAI Agricultural Intelligence Platform API - FastAPI & LangGraph",
    version="1.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter Web / Android / iOS / Desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(auth_router, prefix="/api")
app.include_router(user_router, prefix="/api")
app.include_router(chat_router, prefix="/api")
app.include_router(voice_router, prefix="/api")
app.include_router(admin_router, prefix="/api")


@app.get("/")
def read_root():
    return {
        "status": "online",
        "app": settings.APP_NAME,
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": settings.APP_NAME}
