# Regex parser on the HARD fake resumes

600 generated resumes that use the habits of real student resumes (see `generate_hard.py`).
Scored automatically; nobody labelled anything by hand. Generated resumes show how the parser copes with these habits, not how it does on every real resume.

| Field | Correct |
|---|---|
| fullName | 100.0% (600/600) |
| phone | 100.0% (600/600) |
| address | 100.0% (600/600) |
| dateOfBirth | 100.0% (600/600) |
| programme | 100.0% (600/600) |
| faculty | 100.0% (600/600) |
| semester | 100.0% (600/600) |
| cgpa | 100.0% (600/600) |
| skills (exact set) | 100.0% (600/600) |
| work history (exact set) | 100.0% (600/600) |

Skills F1 1.000 · work history F1 1.000

## Habits that still fail

| Field | Habit | Correct | Example |
|---|---|---|---|
