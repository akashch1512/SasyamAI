import base64
import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


async def upload_image_to_imgbb(
    image_bytes: bytes, filename: str = "upload.jpg"
) -> dict[str, Any]:
    """Upload an image to ImgBB and return public URL."""
    logger.info(f"[IMGBB] Uploading image {filename} ({len(image_bytes)} bytes)")

    if not settings.IMGBB_API_KEY:
        logger.warning(
            "[IMGBB] IMGBB_API_KEY not configured. Generating high-resolution placeholder URL."
        )
        # Fallback image URL for development/demo
        return {
            "success": True,
            "image_url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22513?w=800&auto=format&fit=crop&q=80",
            "display_url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22513?w=800&auto=format&fit=crop&q=80",
            "thumb_url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22513?w=200&auto=format&fit=crop&q=80",
            "delete_url": None,
        }

    try:
        base64_encoded = base64.b64encode(image_bytes).decode("utf-8")
        data = {
            "key": settings.IMGBB_API_KEY,
            "image": base64_encoded,
            "name": filename,
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(settings.IMGBB_UPLOAD_URL, data=data)

        if response.status_code == 200:
            res_json = response.json()
            data_obj = res_json.get("data", {})
            return {
                "success": True,
                "image_url": data_obj.get("url"),
                "display_url": data_obj.get("display_url"),
                "thumb_url": data_obj.get("thumb", {}).get("url"),
                "delete_url": data_obj.get("delete_url"),
            }
        else:
            logger.error(
                f"[IMGBB] API returned status {response.status_code}: {response.text}"
            )
            return {
                "success": False,
                "image_url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22513?w=800&auto=format&fit=crop&q=80",
                "error": response.text,
            }

    except Exception as e:  # noqa: BLE001
        logger.error(f"[IMGBB] Exception during upload: {e}")
        return {
            "success": False,
            "image_url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22513?w=800&auto=format&fit=crop&q=80",
            "error": str(e),
        }
