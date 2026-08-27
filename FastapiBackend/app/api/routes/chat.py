import datetime

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import selectinload

from app.agent.orchestrator import run_sasyamai_agent
from app.core.dependencies import CurrentUserDep, DatabaseDep
from app.models.chat import ChatMessage, ChatSession
from app.schemas.chat import (
    ChatMessageResponse,
    ChatSessionCreate,
    ChatSessionResponse,
    ChatSessionSummary,
    SendMessageRequest,
    SendMessageResponse,
)
from app.services.analytics_service import log_user_query

router = APIRouter(prefix="/chat", tags=["Chat & AI Agent"])


@router.get("/sessions", response_model=list[ChatSessionSummary])
async def list_chat_sessions(
    current_user: CurrentUserDep, db: DatabaseDep
) -> list[ChatSessionSummary]:
    """List all conversation sessions for the current user."""
    query = (
        select(
            ChatSession.id,
            ChatSession.user_id,
            ChatSession.title,
            ChatSession.created_at,
            ChatSession.updated_at,
            func.count(ChatMessage.id).label("message_count"),
        )
        .outerjoin(ChatMessage, ChatSession.id == ChatMessage.session_id)
        .where(ChatSession.user_id == current_user.id)
        .group_by(ChatSession.id)
        .order_by(desc(ChatSession.updated_at))
    )
    result = await db.execute(query)
    rows = result.all()

    return [
        ChatSessionSummary(
            id=row[0],
            user_id=row[1],
            title=row[2],
            created_at=row[3],
            updated_at=row[4],
            message_count=row[5],
        )
        for row in rows
    ]


@router.post(
    "/sessions", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED
)
async def create_chat_session(
    session_in: ChatSessionCreate,
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> ChatSessionResponse:
    """Create a new chat conversation session."""
    session = ChatSession(
        user_id=current_user.id,
        title=session_in.title or "New Conversation",
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return ChatSessionResponse(
        id=session.id,
        user_id=session.user_id,
        title=session.title,
        created_at=session.created_at,
        updated_at=session.updated_at,
        messages=[],
    )


@router.get("/sessions/{session_id}", response_model=ChatSessionResponse)
async def get_chat_session(
    session_id: str,
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> ChatSessionResponse:
    """Get conversation history for a specific session."""
    query = (
        select(ChatSession)
        .options(selectinload(ChatSession.messages))
        .where(ChatSession.id == session_id, ChatSession.user_id == current_user.id)
    )
    result = await db.execute(query)
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat session not found",
        )

    return ChatSessionResponse.model_validate(session)


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_chat_session(
    session_id: str,
    current_user: CurrentUserDep,
    db: DatabaseDep,
):
    """Delete a chat session and all its messages."""
    query = select(ChatSession).where(
        ChatSession.id == session_id, ChatSession.user_id == current_user.id
    )
    result = await db.execute(query)
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chat session not found",
        )

    await db.delete(session)
    await db.commit()


@router.post("/message", response_model=SendMessageResponse)
async def send_chat_message(
    message_req: SendMessageRequest,
    current_user: CurrentUserDep,
    db: DatabaseDep,
) -> SendMessageResponse:
    """Send a message (text or image) to the SasyamAI LangGraph agent."""
    session_id = message_req.session_id

    # Find or create session
    if session_id:
        sess_query = select(ChatSession).where(
            ChatSession.id == session_id, ChatSession.user_id == current_user.id
        )
        res = await db.execute(sess_query)
        session = res.scalar_one_or_none()
        if not session:
            session = ChatSession(
                id=session_id,
                user_id=current_user.id,
                title="Agricultural Inquiry",
            )
            db.add(session)
            await db.flush()
    else:
        # Generate initial title from prompt
        title_summary = (
            message_req.content[:30]
            if message_req.content
            else "Crop Disease Diagnosis"
        )
        session = ChatSession(
            user_id=current_user.id,
            title=title_summary,
        )
        db.add(session)
        await db.flush()
        session_id = session.id

    # Retrieve prior conversation messages
    history_query = (
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.asc())
        .limit(10)
    )
    history_res = await db.execute(history_query)
    history_rows = history_res.scalars().all()
    chat_history = [{"role": m.role, "content": m.content} for m in history_rows]

    # Save User Message
    user_msg_record = ChatMessage(
        session_id=session_id,
        role="user",
        content=message_req.content,
        image_url=message_req.image_url,
        metadata_json={"audio_transcription": message_req.audio_transcription}
        if message_req.audio_transcription
        else None,
    )
    db.add(user_msg_record)
    await db.flush()

    # Prepare Farmer Profile Context
    farmer_profile = {
        "user_id": current_user.id,
        "full_name": current_user.full_name,
        "phone_number": current_user.phone_number,
        "state": current_user.state,
        "district": current_user.district,
        "soil_type": current_user.soil_type,
        "land_size_acres": current_user.land_size_acres,
        "irrigation_source": current_user.irrigation_source,
        "primary_crops": current_user.primary_crops,
        "preferred_language": current_user.preferred_language,
        "is_onboarded": current_user.is_onboarded,
    }

    # Run LangGraph Orchestrator
    agent_output = await run_sasyamai_agent(
        user_message=message_req.content,
        user_profile=farmer_profile,
        image_url=message_req.image_url,
        chat_history=chat_history,
    )

    assistant_content = agent_output.get(
        "final_response", "Thank you for reaching out to SasyamAI."
    )
    detected_intent = agent_output.get("intent", "general")
    detected_crop = agent_output.get("detected_crop")
    detected_disease = agent_output.get("detected_disease")
    suggested_actions = agent_output.get("suggested_actions", [])

    # Save Assistant Message
    assistant_msg_record = ChatMessage(
        session_id=session_id,
        role="assistant",
        content=assistant_content,
        metadata_json={
            "intent": detected_intent,
            "detected_crop": detected_crop,
            "detected_disease": detected_disease,
            "suggested_actions": suggested_actions,
        },
    )
    db.add(assistant_msg_record)

    # Update session title if default
    if (
        session.title in ["New Conversation", "Agricultural Inquiry"]
        and message_req.content
    ):
        words = message_req.content.strip().split()
        session.title = " ".join(words[:5]) if words else "Agricultural Chat"
    session.updated_at = datetime.datetime.now(datetime.UTC)

    # Log analytics asynchronously
    await log_user_query(
        db=db,
        query_text=message_req.content or "Image Scan",
        category=detected_intent,
        user_id=current_user.id,
        session_id=session_id,
        detected_crop=detected_crop,
        detected_disease=detected_disease,
        state=current_user.state,
    )

    await db.commit()
    await db.refresh(user_msg_record)
    await db.refresh(assistant_msg_record)

    return SendMessageResponse(
        session_id=session_id,
        user_message=ChatMessageResponse.model_validate(user_msg_record),
        assistant_message=ChatMessageResponse.model_validate(assistant_msg_record),
        suggested_actions=suggested_actions,
    )
