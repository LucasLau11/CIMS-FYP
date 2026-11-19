"""
Runs the resume parser on ONE real resume, on your own computer, and prints what it found.

    python eval/try_resume.py path\\to\\resume.pdf            (also .docx or .txt)
    python eval/try_resume.py resume.pdf --text               (also print the text read from the file)

Nothing is uploaded: the file is read and parsed locally. Use --text to see exactly what the parser sees; the
order of the lines in a PDF is often not the order on the page, which explains most odd results.
"""

import dataclasses
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from extractor import parse  # noqa: E402


def read_text(path: str) -> str:
    ext = os.path.splitext(path)[1].lower()
    if ext == ".pdf":
        from pypdf import PdfReader

        return "\n".join((page.extract_text() or "") for page in PdfReader(path).pages)
    if ext == ".docx":
        import zipfile
        import re

        xml = zipfile.ZipFile(path).read("word/document.xml").decode("utf-8")
        xml = re.sub(r"</w:p>", "\n", xml)
        return re.sub(r"<[^>]+>", "", xml)
    return open(path, encoding="utf-8", errors="replace").read()


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    text = read_text(sys.argv[1])
    if "--text" in sys.argv:
        print("----- text read from the file -----")
        print(text)
        print("-----------------------------------")
    result = parse(text)
    print(json.dumps(dataclasses.asdict(result), indent=2, ensure_ascii=False, default=str))


if __name__ == "__main__":
    main()
