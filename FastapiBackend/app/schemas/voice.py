from pydantic import BaseModel


class TranscriptionResponse(BaseModel):
    transcript: str
    language_code: str = "hi-IN"
    detected_language: str = "Hindi"
    confidence: float = 1.0
