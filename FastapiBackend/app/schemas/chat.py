import datetime
from typing import Any

from pydantic import BaseModel


class ChatMessageResponse(BaseModel):
    id: str
    session_id: str
    role: str
    content: str
    image_url: str | None = None
    metadata_json: dict[str, Any] | None = None
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class ChatSessionResponse(BaseModel):
    id: str
    user_id: int
    title: str
    created_at: datetime.datetime
    updated_at: datetime.datetime
    messages: list[ChatMessageResponse] = []

    model_config = {"from_attributes": True}


class ChatSessionSummary(BaseModel):
    id: str
    user_id: int
    title: str
    created_at: datetime.datetime
    updated_at: datetime.datetime
    message_count: int = 0

    model_config = {"from_attributes": True}


class ChatSessionCreate(BaseModel):
    title: str | None = "New Conversation"


class SendMessageRequest(BaseModel):
    session_id: str | None = None  # If None, creates a new session
    content: str
    image_url: str | None = None
    audio_transcription: str | None = None


class SendMessageResponse(BaseModel):
    session_id: str
    user_message: ChatMessageResponse
    assistant_message: ChatMessageResponse
    suggested_actions: list[str] = []
