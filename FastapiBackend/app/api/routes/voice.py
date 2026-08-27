from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile

from app.core.dependencies import CurrentUserDep
from app.schemas.voice import TranscriptionResponse
from app.services.sarvam_service import transcribe_audio_sarvam

router = APIRouter(prefix="/voice", tags=["Speech To Text (Sarvam AI)"])


@router.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(
    file: Annotated[UploadFile, File()],
    current_user: CurrentUserDep,
    language_code: Annotated[str, Form()] = "hi-IN",
) -> TranscriptionResponse:
    """Transcribe multilingual farmer voice audio to text using Sarvam Saaras v3."""
    content = await file.read()
    result = await transcribe_audio_sarvam(
        audio_bytes=content,
        filename=file.filename or "recording.wav",
        language_code=language_code,
    )
    return TranscriptionResponse(
        transcript=result.get("transcript", ""),
        language_code=result.get("language_code", language_code),
        detected_language=result.get("detected_language", "Hindi"),
        confidence=result.get("confidence", 0.95),
    )
