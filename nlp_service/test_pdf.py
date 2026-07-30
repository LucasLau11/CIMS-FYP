"""
Dev-only helper: feed a real PDF/DOCX resume into the running nlp_service
and see exactly what comes out, without touching the Flutter app.

Usage:
    python test_pdf.py path/to/resume.pdf [path/to/another.docx ...]

Requires the local server running first (in another terminal):
    uvicorn app:app --reload --port 8000

And the dev extras installed:
    pip install -r requirements-dev.txt
"""

import json
import sys
from pathlib import Path

import requests

SERVER_URL = "http://localhost:8000/parse-resume"


def extract_text(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        from pypdf import PdfReader

        reader = PdfReader(str(path))
        return "\n".join(page.extract_text() or "" for page in reader.pages)
    elif suffix == ".docx":
        import docx

        doc = docx.Document(str(path))
        return "\n".join(p.text for p in doc.paragraphs)
    else:
        raise ValueError(f"Unsupported file type: {suffix} (expected .pdf or .docx)")


def main():
    if len(sys.argv) < 2:
        print("Usage: python test_pdf.py path/to/resume.pdf [more files...]")
        sys.exit(1)

    for arg in sys.argv[1:]:
        path = Path(arg)
        print(f"\n{'=' * 70}\n{path.name}\n{'=' * 70}")

        if not path.exists():
            print(f"  File not found: {path}")
            continue

        try:
            text = extract_text(path)
        except Exception as e:
            print(f"  Could not extract text: {e}")
            continue

        if not text.strip():
            print("  Extracted 0 characters of text (likely a scanned/image-only PDF — "
                  "this parser only handles text-based PDFs, same as the Flutter app).")
            continue

        try:
            resp = requests.post(SERVER_URL, json={"text": text}, timeout=30)
            resp.raise_for_status()
        except requests.exceptions.ConnectionError:
            print(f"  Could not reach {SERVER_URL} — is the server running? "
                  f"(uvicorn app:app --reload --port 8000)")
            sys.exit(1)
        except Exception as e:
            print(f"  Request failed: {e}")
            continue

        print(json.dumps(resp.json(), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
