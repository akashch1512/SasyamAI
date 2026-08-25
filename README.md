# SasyamAI

SasyamAI is an AI-powered agriculture project built with a FastAPI backend and a Flutter frontend.

## Project Structure

```text
SasyamAI/
├── FastapiBackend/      # FastAPI backend and AI agent
└── FlutterFrontend/     # Flutter application
```

## Backend

The backend is built using:

* FastAPI
* Python 3.12
* LangGraph
* Alembic
* Ruff
* uv

## Getting Started

### Backend Setup

Navigate to the backend directory:

```bash
cd FastapiBackend
```

Install dependencies:

```bash
uv sync
```

Run the development server:

```bash
uv run uvicorn app.main:app --reload
```

The API will be available at:

`http://127.0.0.1:8000`

API documentation:

`http://127.0.0.1:8000/docs`

## Development Tools

Run Ruff checks:

```bash
uv run ruff check .
```

Format the code:

```bash
uv run ruff format .
```

## Database Migrations

Alembic is configured for database migrations.

Create a migration:

```bash
uv run alembic revision --autogenerate -m "migration message"
```

Apply migrations:

```bash
uv run alembic upgrade head
```

## Status

The project is currently under active development.
