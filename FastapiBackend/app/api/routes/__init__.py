from app.api.routes.admin import router as admin_router
from app.api.routes.auth import router as auth_router
from app.api.routes.chat import router as chat_router
from app.api.routes.user import router as user_router
from app.api.routes.voice import router as voice_router

__all__ = ["admin_router", "auth_router", "chat_router", "user_router", "voice_router"]
