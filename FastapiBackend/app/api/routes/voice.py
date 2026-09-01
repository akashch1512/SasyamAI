from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile

from app.core.dependencies import CurrentUserDep
from app.schemas.voice import (
    TextToSpeechRequest,
    TextToSpeechResponse,
    TranscriptionResponse,
)
from app.services.sarvam_service import (
    synthesize_speech_sarvam,
    transcribe_audio_sarvam,
)

router = APIRouter(prefix="/voice", tags=["Voice (Sarvam AI)"])


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


@router.post("/tts", response_model=TextToSpeechResponse)
async def text_to_speech(
    payload: TextToSpeechRequest,
    current_user: CurrentUserDep,
) -> TextToSpeechResponse:
    """Speak assistant replies using Sarvam Bulbul text-to-speech."""
    result = await synthesize_speech_sarvam(
        text=payload.text,
        language_code=payload.language_code,
        speaker=payload.speaker,
    )
    return TextToSpeechResponse(
        audio_base64=result.get("audio_base64", ""),
        content_type=result.get("content_type", "audio/wav"),
        language_code=result.get("language_code", payload.language_code),
        speaker=result.get("speaker", payload.speaker),
        is_fallback=result.get("is_fallback", False),
    )
