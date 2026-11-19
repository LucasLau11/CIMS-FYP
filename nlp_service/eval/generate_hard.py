"""
A HARDER set of fake resumes with known answers, for measuring the app's regex parser.

    python eval/generate_hard.py [count] [seed]      -> eval/hard_resumes.json

The first set (generate_synthetic.py) uses clean layouts and the parsers score 100% on it, so it can
no longer show an improvement. This one mixes in what real student resumes do:

  * a title line ("CURRICULUM VITAE", "RESUME") before the name, or a "Name:" label
  * phones written with many labels and shapes, landline decoys, student-id decoys
  * CGPA written as "CGPA of 3.45", "3.45 CGPA", "GPA 3.45/4.0", with decoy numbers ("Version 3.5")
  * dates of birth like "12th March 2002", "Born: 12 Mar 2002", "March 12, 2002"
  * "Sem 3", "Semester 3 of 6", "Year 2 Semester 1" style semesters
  * skills under "Soft Skills", "IT Skills", "Skills & Tools", separated by pipes, with levels in
    brackets, and names that contain a slash ("CI/CD", "UI/UX", "TCP/IP")
  * "Industrial Training" / "Internships" headings, month ranges inside one year ("Jun - Aug 2024"),
    "Position | Company | dates" lines and the company on its own line
  * a label and its value on separate lines, tabs, page footers
  * (v2, from a real resume that failed) postcodes that start with 0 (Kedah, Perlis), the name on one line with
    a job title ("NAME | Software Developer"), the whole contact on one line ("address | phone | email"), an IC
    number, and sections after the skills with odd headings (REFEREES, AWARDS & CO-CURRICULAR, VOLUNTEER WORK)
    whose lines must not be read as skills or as the candidate's own details

Each resume records which variant it used for every field, so a failure can be traced to the exact
habit that caused it. The answers are generated, never labelled by hand.
Like the first set: generated resumes show how a parser copes with these habits, not how it does on
every real resume.
"""

from __future__ import annotations

import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_synthetic import KNOWN_SKILLS, MONTHS, UNSEEN_SKILLS, make_truth  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))

MONTH_FULL = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November",
              "December"]
JOBS = ["Software Developer", "Final Year IT Student", "Computer Science Undergraduate", "Aspiring Data Analyst", "Web Designer",
        "Business Administration Student", "Junior Network Engineer"]
# postcodes as printed on Malaysian addresses; Kedah (05xxx, 08xxx) and Perlis (01xxx) start with 0
PLACES = [("Alor Setar", "05050"), ("Kangar", "01000"), ("Bayan Lepas", "11900"), ("Butterworth", "13700"), ("Kuala Lumpur", "50450"),
          ("Johor Bahru", "81100"), ("Kuching", "93000"), ("Kota Kinabalu", "88000"), ("Ipoh", "30250"), ("Seremban", "70200"),
          ("Sungai Petani", "08000"), ("Melaka", "75000"), ("Cheras", "56000"), ("Kajang", "43000"), ("Shah Alam", "40150")]
STREET_NAMES = ["Jalan Ampang", "Taman Desa", "Lorong Maarof", "Jalan Universiti", "Persiaran Sultan Ibrahim", "Jalan Genting Klang"]
REFEREE_HEADINGS = ["REFERENCES", "REFEREES", "Referees", "CHARACTER REFERENCES", "REFEREE", "References:"]
AWARD_HEADINGS = ["AWARDS & ACHIEVEMENTS", "AWARDS, HONOURS & CO-CURRICULAR", "CO-CURRICULAR ACTIVITIES", "VOLUNTEER WORK",
                  "ADDITIONAL INFORMATION", "PERSONAL PARTICULARS", "Honours & Awards", "Extracurricular Activities"]
SLASH_SKILLS = ["CI/CD", "UI/UX", "TCP/IP", "REST API", "C++", "C#", ".NET", "Node.js", "ASP.NET", "Adobe Illustrator"]


def ordinal(n: int) -> str:
    suffix = "th" if 10 <= n % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


# ---------------------------------------------------------------- field writers (return text, variant)

def write_name(t, rng):
    name = t["fullName"]
    style = rng.choice(["plain", "title_line", "resume_word", "name_label", "caps_after_title", "personal_details",
                        "name_pipe_job", "name_dash_job", "name_caps_job_below", "job_pipe_name"])
    job = rng.choice(JOBS)
    if style == "plain":
        return [name], style
    if style == "name_pipe_job":
        return [f"{name.upper()} | {job}"], style
    if style == "name_dash_job":
        return [f"{name} - {job}"], style
    if style == "name_caps_job_below":
        return [name.upper(), job], style
    if style == "job_pipe_name":
        return [f"{job} | {name}"], style
    if style == "title_line":
        return ["CURRICULUM VITAE", "", name], style
    if style == "resume_word":
        return ["RESUME", name.upper()], style
    if style == "name_label":
        return [f"Name: {name}"], style
    if style == "caps_after_title":
        return ["Curriculum Vitae", name.upper()], style
    return ["PERSONAL DETAILS", f"Name : {name}"], style


def write_phone(t, rng):
    digits = t["phone"]
    local = "0" + digits[2:] if digits.startswith("60") else digits  # 0AAxxxxxxx
    a, rest = local[1:3], local[3:]
    shapes = {
        "dash": f"0{a}-{rest[:3]} {rest[3:]}",
        "compact": f"0{a}{rest}",
        "plus": f"+60{a}-{rest}",
        "plus_space": f"+60 {a} {rest[:3]} {rest[3:]}",
        "paren": f"(+60) {a}-{rest[:3]} {rest[3:]}",
        "spaces": f"0{a} {rest[:3]} {rest[3:]}",
    }
    shape = rng.choice(list(shapes))
    label = rng.choice(["Phone", "Tel", "H/P", "Mobile No.", "Contact No.", "Phone Number", "HP", "Mobile", "Contact"])
    sep = rng.choice([": ", " : ", ":\t", " - "])
    layout = rng.choice(["labelled", "labelled", "header", "next_line"])
    if layout == "labelled":
        return f"{label}{sep}{shapes[shape]}", f"{layout}/{label}/{shape}"
    if layout == "next_line":
        return f"{label}\n{shapes[shape]}", f"{layout}/{label}/{shape}"
    return f"{shapes[shape]}", f"{layout}/{shape}"


def write_cgpa(t, rng):
    c = f"{t['cgpa']:.2f}"
    style = rng.choice(["label_colon", "slash4", "cumulative", "of", "after", "gpa_slash", "current_dash", "paren"])
    text = {
        "label_colon": f"CGPA: {c}",
        "slash4": f"CGPA : {c} / 4.00",
        "cumulative": f"Cumulative GPA: {c}",
        "of": f"Currently holding a CGPA of {c}",
        "after": f"{c} CGPA",
        "gpa_slash": f"GPA {c}/4.0",
        "current_dash": f"Current CGPA - {c}",
        "paren": f"CGPA ({c})",
    }[style]
    return text, style


def write_dob(t, rng):
    y, m, d = (int(x) for x in t["dateOfBirth"].split("-"))
    style = rng.choice(["slash", "dash", "long", "ordinal", "born", "us", "iso", "dob_dots"])
    text = {
        "slash": f"Date of Birth: {d:02d}/{m:02d}/{y}",
        "dash": f"DOB: {d:02d}-{m:02d}-{y}",
        "long": f"Date of Birth: {d} {MONTH_FULL[m - 1]} {y}",
        "ordinal": f"D.O.B : {ordinal(d)} {MONTH_FULL[m - 1]} {y}",
        "born": f"Born: {d} {MONTHS[m - 1]} {y}",
        "us": f"Date of Birth: {MONTH_FULL[m - 1]} {d}, {y}",
        "iso": f"Date of Birth: {y}-{m:02d}-{d:02d}",
        "dob_dots": f"DOB: {d:02d}.{m:02d}.{y}",
    }[style]
    return text, style


def write_semester(t, rng):
    s = t["semester"]
    style = rng.choice(["colon", "plain", "sem", "of_six", "year_sem", "currently"])
    text = {
        "colon": f"Semester: {s}",
        "plain": f"Semester {s}",
        "sem": f"Sem {s}",
        "of_six": f"Semester {s} of 6",
        "year_sem": f"Year {(s + 1) // 2}, Semester {s}",
        "currently": f"Currently in Semester {s}",
    }[style]
    return text, style


def write_programme(t, rng):
    p, f = t["programme"], t["faculty"]
    style = rng.choice(["label", "education_plain", "with_school_years", "pursuing", "course_label"])
    inst = rng.choice(["TAR UMT", "Tunku Abdul Rahman University of Management and Technology"])
    if style == "label":
        return [f"Programme: {p}", f"Faculty: {f}"], style
    if style == "education_plain":
        return [p, f, inst], style
    if style == "with_school_years":
        return [f"{p}, {inst}, 2023 - 2026", f], style
    if style == "pursuing":
        return [f"Currently pursuing {p} at {inst}.", f"({f})"], style
    return [f"Course: {p}", f"{f}"], style


def write_address(t, rng):
    a = t["address"]
    style = rng.choice(["label", "residential", "header", "two_lines"])
    if style == "label":
        return [f"Address: {a}"], style
    if style == "residential":
        return [f"Residential Address:", a], style
    if style == "header":
        return [a], style
    parts = a.split(", ")
    return [f"Address: {', '.join(parts[:2])}", ", ".join(parts[2:])], style


def skill_lines(skills, rng):
    heading = rng.choice(["TECHNICAL SKILLS", "Skills & Tools", "IT Skills", "Skills Summary", "Computer Skills", "Key Skills", "SKILLS"])
    style = rng.choice(["bullets", "pipes", "commas", "levels", "two_columns", "categorised_slash"])
    lines = [heading]
    if style == "bullets":
        lines += [f"• {s}" for s in skills]
    elif style == "pipes":
        lines += [" | ".join(skills[i:i + 4]) for i in range(0, len(skills), 4)]
    elif style == "commas":
        lines += [", ".join(skills[i:i + 5]) + ("," if i + 5 < len(skills) else "") for i in range(0, len(skills), 5)]
    elif style == "levels":
        lines += [f"{s} ({rng.choice(['Advanced', 'Intermediate', 'Beginner'])})" for s in skills]
    elif style == "two_columns":
        lines += ["        ".join(skills[i:i + 2]) for i in range(0, len(skills), 2)]
    else:
        half = len(skills) // 2 or 1
        lines += [f"Technical: {', '.join(skills[:half])}", f"Tools: {', '.join(skills[half:])}"] if skills[half:] else [f"Technical: {', '.join(skills)}"]
    return lines, f"{heading}/{style}"


def work_lines(t, rng):
    heading = rng.choice(["WORK EXPERIENCE", "Industrial Training", "Internship Experience", "Internships", "Work Experience & Internships",
                          "Professional Experience"])
    style = rng.choice(["pipes", "two_line", "dates_first", "month_same_year", "at_company"])
    lines = [heading]
    for e in t["workExperience"]:
        end = "Present" if e["isCurrent"] else str(e["endYear"])
        start = e["startYear"]
        m1, m2 = rng.sample(MONTHS, 2) if rng.random() < 0.5 else (None, None)
        dates = f"{m1} {start} – {('Present' if e['isCurrent'] else f'{m2} {end}')}" if m1 else f"{start} – {end}"
        if style == "pipes":
            lines.append(f"{e['position']} | {e['companyName']} | {dates}")
        elif style == "two_line":
            lines += [e["position"], f"{e['companyName']}, {dates}"]
        elif style == "dates_first":
            lines.append(f"{dates}: {e['position']} at {e['companyName']}")
        elif style == "month_same_year":
            # one calendar year, months only at the start: "Jun – Aug 2024"
            if e["isCurrent"] or e["startYear"] != e["endYear"]:
                lines.append(f"{e['position']}, {e['companyName']}  {dates}")
            else:
                a, b = sorted(rng.sample(range(12), 2))
                lines.append(f"{e['position']}, {e['companyName']}  {MONTHS[a]} – {MONTHS[b]} {e['endYear']}")
        else:
            lines.append(f"{e['position']} at {e['companyName']}, {dates}")
        lines.append(f"• {rng.choice(['Assisted the team with daily tasks.', 'Prepared reports and documentation.', 'Supported testing and client requests.'])}")
    return lines, f"{heading}/{style}"


def extra_sections(rng):
    """Sections that a real resume has after the skills and that are not skills: referees (names, job titles,
    phone numbers, e-mails), awards and co-curricular activities. Returns [(kind, placement, lines)]."""
    out = []
    if rng.random() < 0.55:
        referee = rng.choice(["Dr. Ahmad bin Ismail", "Prof. Madya Dr. Lim Siew Ling", "Ms. Nur Aisyah binti Hassan", "Mr. Rajesh a/l Kumar"])
        lines = [rng.choice(REFEREE_HEADINGS), referee,
                 rng.choice(["Senior Lecturer, Faculty of Computing", "Head of Department, TAR UMT", "Industrial Training Supervisor"]),
                 f"Tel: 0{rng.choice(['3', '4', '12', '16'])}-{rng.randint(1000, 9999)} {rng.randint(1000, 9999)}",
                 f"Email: {referee.split()[-1].lower()}@tarc.edu.my"]
        out.append(("referees", rng.choice(["after_skills", "after_skills", "end"]), lines))
    if rng.random() < 0.55:
        lines = [rng.choice(AWARD_HEADINGS), "Dean's List, Semester 2 2024", "1st Place, University Hackathon 2025",
                 "Member, Computing Society (2024 - 2025)"]
        out.append(("awards", rng.choice(["after_skills", "end"]), lines))
    return out


# ---------------------------------------------------------------- whole resume

def build(truth: dict, rng: random.Random) -> tuple[str, dict]:
    t = dict(truth)
    # slash / symbol skills only appear in this harder set
    extra = rng.sample(SLASH_SKILLS, rng.choice([1, 2, 3]))
    t["skills"] = list(dict.fromkeys(list(t["skills"]) + extra))
    rng.shuffle(t["skills"])

    variants: dict[str, str] = {}
    out: list[str] = []

    city, post = rng.choice(PLACES)
    t["address"] = f"No. {rng.randint(1, 99)}, {rng.choice(STREET_NAMES)}, {post} {city}"

    name_lines, variants["name"] = write_name(t, rng)
    out += name_lines
    if rng.random() < 0.25:
        # the whole contact on one line, the phone unlabelled and next to a postcode
        written = t["phoneWritten"]
        parts = [t["address"], written, t["email"]]
        rng.shuffle(parts)
        out.append(" | ".join(parts))
        variants["phone"] = "contact_line"
        variants["address"] = "contact_line"
    else:
        phone_text, variants["phone"] = write_phone(t, rng)
        out += phone_text.split("\n")
        out.append(f"{rng.choice(['Email', 'E-mail', 'Email Address'])}: {t['email']}")
        addr_lines, variants["address"] = write_address(t, rng)
        out += addr_lines
    dob_text, variants["dob"] = write_dob(t, rng)
    out.append(dob_text)
    out.append(f"Student ID: {rng.randint(10, 99)}WMR{rng.randint(10000, 99999)}")  # decoy digits
    if rng.random() < 0.4:  # an IC number: twelve digits that are not a phone
        out.append(f"{rng.choice(['IC No', 'NRIC', 'IC Number'])}: {rng.randint(0, 9)}{rng.randint(0, 9)}{rng.randint(1, 12):02d}{rng.randint(1, 28):02d}-"
                   f"{rng.randint(1, 14):02d}-{rng.randint(1000, 9999)}")
    out.append("")

    out.append(rng.choice(["EDUCATION", "Education", "Academic Background", "Qualifications"]))
    prog_lines, variants["programme"] = write_programme(t, rng)
    out += prog_lines
    cgpa_text, variants["cgpa"] = write_cgpa(t, rng)
    out.append(cgpa_text)
    sem_text, variants["semester"] = write_semester(t, rng)
    out.append(sem_text)
    out.append("")

    sk_lines, variants["skills"] = skill_lines(t["skills"], rng)
    out += sk_lines
    out.append("")
    extras = extra_sections(rng)
    variants["extras"] = "/".join(k for k, _, _ in extras) or "none"
    at_end = []
    for kind, placement, lines in extras:
        if placement == "after_skills":
            out += lines + [""]
        else:
            at_end.append(lines)
    if rng.random() < 0.5:  # a second section the skills block must not swallow
        out += ["LANGUAGES", "English (Fluent), Bahasa Malaysia (Native), Mandarin (Conversational)", ""]
    w_lines, variants["work"] = work_lines(t, rng)
    out += w_lines
    for lines in at_end:
        out += [""] + lines
    out += ["", rng.choice(["Page 1 of 2", "Page 1", "— 1 —"])]
    if rng.random() < 0.3:  # a decoy decimal before any CGPA mention is read
        out.insert(2, f"Version {rng.choice(['3.5', '2.1', '1.8'])} of this resume")

    text = "\n".join(out)
    t["skills"] = list(t["skills"])
    return text, {"truth": t, "variants": variants}


def main() -> None:
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 400
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 4242
    rng = random.Random(seed)
    rows = []
    for i in range(count):
        truth = make_truth(rng)
        # a title in front of some names, like real resumes
        text, meta = build(truth, rng)
        rows.append({"id": i, "layout": "hard", "text": text, "truth": meta["truth"], "variants": meta["variants"]})
    path = os.path.join(HERE, "hard_resumes.json")
    json.dump(rows, open(path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(f"wrote {count} hard resumes -> {path}")


if __name__ == "__main__":
    main()
