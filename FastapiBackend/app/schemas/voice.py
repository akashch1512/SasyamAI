from pydantic import BaseModel, Field


class TranscriptionResponse(BaseModel):
    transcript: str
    language_code: str = "hi-IN"
    detected_language: str = "Hindi"
    confidence: float = 1.0


class TextToSpeechRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    language_code: str = "hi-IN"
    speaker: str = "anushka"


class TextToSpeechResponse(BaseModel):
    audio_base64: str = ""
    content_type: str = "audio/wav"
    language_code: str = "hi-IN"
    speaker: str = "anushka"
    is_fallback: bool = False
