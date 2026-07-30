"""
FastAPI wrapper around extractor.py — POST /parse-resume takes plain
resume text (already extracted client-side by the Flutter app's existing
PDF/DOCX reader) and returns fields shaped to match ParsedResumeData /
ParsedWorkExperience in lib/services/resume_parser_service.dart.
"""

import inspect
import os

from fastapi import FastAPI
from pydantic import BaseModel

from extractor import parse

app = FastAPI(title="CIMS Resume NLP Service")


@app.on_event("startup")
async def _maybe_open_ngrok_tunnel():
    # Opt-in only — set NGROK_AUTHTOKEN before starting the server to expose
    # it publicly for testing the Flutter app against it. Normal local dev
    # (no env var set) behaves exactly as before, no ngrok involved at all.
    if not os.environ.get("NGROK_AUTHTOKEN"):
        return
    import ngrok

    port = int(os.environ.get("PORT", 8000))
    listener = ngrok.forward(port, authtoken_from_env=True)
    # forward() runs synchronously when no event loop is active, but returns
    # an awaitable Task when called from inside one (as here, under uvicorn).
    if inspect.isawaitable(listener):
        listener = await listener
    print(f"\n{'=' * 60}\n  Public URL: {listener.url()}\n{'=' * 60}\n")


class ParseRequest(BaseModel):
    text: str


class WorkExperienceOut(BaseModel):
    position: str | None = None
    companyName: str | None = None
    startYear: int | None = None
    endYear: int | None = None
    isCurrent: bool = False
    description: str | None = None


class ParseResponse(BaseModel):
    fullName: str | None = None
    nameSource: str = "none"
    phone: str | None = None
    address: str | None = None
    dateOfBirth: str | None = None
    programme: str | None = None
    faculty: str | None = None
    semester: int | None = None
    cgpa: float | None = None
    skills: list[str] = []
    workExperience: list[WorkExperienceOut] = []


@app.get("/")
def health():
    return {"status": "ok", "service": "cims-resume-nlp"}


@app.post("/parse-resume", response_model=ParseResponse)
def parse_resume(req: ParseRequest):
    result = parse(req.text)
    return ParseResponse(
        fullName=result.fullName,
        nameSource=result.nameSource,
        phone=result.phone,
        address=result.address,
        dateOfBirth=result.dateOfBirth,
        programme=result.programme,
        faculty=result.faculty,
        semester=result.semester,
        cgpa=result.cgpa,
        skills=result.skills,
        workExperience=[
            WorkExperienceOut(
                position=w.position,
                companyName=w.companyName,
                startYear=w.startYear,
                endYear=w.endYear,
                isCurrent=w.isCurrent,
                description=w.description,
            )
            for w in result.workExperience
        ],
    )
