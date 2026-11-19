"""
Fake resumes with KNOWN answers, for an automatic accuracy test (no hand labeling).

    python eval/generate_synthetic.py [count] [seed]      -> eval/synthetic_resumes.json

Each resume is written in one of several layouts (list under a heading, one-line "Skills:", no
skills heading at all, upper-case headings, messy contact lines ...), using Malaysian student
names, programmes, phone formats and addresses, because that is who uses CIMS. The file keeps the
true answer next to the text, so any parser can be scored on it without a person checking.

Some skills are deliberately NOT in the word list the older tagger used ("unseen" skills), so the
test also measures whether a model generalises instead of just remembering a list.

Limitation, stated plainly: these are generated resumes, so the scores show how a parser copes with
these layouts, not how it does on every real resume. Real resumes are messier.
"""

from __future__ import annotations

import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

FIRST = ["Muhammad", "Nur", "Ahmad", "Siti", "Lim", "Tan", "Wong", "Chong", "Priya", "Arjun", "Aisyah", "Haziq", "Mei Ling",
         "Jia Wei", "Kavitha", "Farid", "Nurul", "Daniel", "Sarah", "Irfan", "Hui Ying", "Zul", "Amirah", "Raj"]
LAST = ["bin Abdullah", "binti Ismail", "Wei Jie", "Mei Xin", "a/l Krishnan", "a/p Rajan", "Chen", "Lee", "Ong", "Hassan",
        "Rahman", "Yusof", "Abdul Aziz", "Teo", "Ng", "Kumar", "Singh", "Ibrahim", "Hamid", "Goh"]

PROGRAMMES = [
    ("Bachelor of Information Technology (Honours) in Software Systems Development", "Faculty of Computing and Information Technology"),
    ("Diploma in Information Technology", "Faculty of Computing and Information Technology"),
    ("Bachelor of Computer Science (Honours)", "Faculty of Computing and Information Technology"),
    ("Bachelor of Business Administration", "Faculty of Accountancy, Finance and Business"),
    ("Diploma in Accounting", "Faculty of Accountancy, Finance and Business"),
    ("Bachelor of Mechanical Engineering (Honours)", "Faculty of Engineering and Technology"),
    ("Bachelor of Mass Communication (Honours)", "Faculty of Communication and Creative Industries"),
    ("Diploma in Graphic Design", "Faculty of Communication and Creative Industries"),
]

COMPANIES = ["Southern Steel Berhad", "TechNova Sdn Bhd", "Petronas Digital", "Maybank Technology", "Grab Malaysia",
             "Shopee Malaysia", "MIMOS Berhad", "Axiata Digital", "Fusionex International", "Boustead Holdings",
             "Intel Malaysia", "Dell Technologies", "Sunway Group", "AirAsia Digital", "Telekom Malaysia"]

POSITIONS = ["Software Engineering Intern", "Data Analyst Intern", "Web Developer", "IT Support Assistant", "Marketing Executive",
             "Accounts Assistant", "Graphic Designer", "Research Assistant", "Quality Assurance Tester", "Network Technician",
             "Mobile App Developer", "Business Analyst", "Customer Service Representative", "Project Coordinator"]

# in the older tagger's word list
KNOWN_SKILLS = ["Python", "Java", "SQL", "Flutter", "Dart", "HTML", "JavaScript", "React", "Node.js", "Docker", "Git", "Linux",
                "Excel", "Microsoft Office", "PowerPoint", "Figma", "Firebase", "MySQL", "MongoDB", "AWS", "Kubernetes",
                "Project Management", "Data Analysis", "Machine Learning", "Tableau", "Power BI", "Photoshop", "Agile", "Scrum",
                "Communication", "Teamwork", "Problem Solving", "Leadership", "Customer Service", "TensorFlow", "Django", "PHP"]
# NOT in that word list: tests whether a model generalises
UNSEEN_SKILLS = ["Svelte", "Supabase", "Solidity", "Prisma", "LangChain", "Pinecone", "ONNX", "dbt", "Vite", "Elixir",
                 "Astro", "Deno", "FlutterFlow", "Hugging Face Transformers", "tRPC", "Zig"]

STREETS = ["Jalan Ampang", "Jalan Bukit Bintang", "Taman Desa", "Lorong Maarof", "Jalan Genting Klang", "Persiaran Sultan Ibrahim",
           "Jalan Universiti", "Taman Tun Dr Ismail"]
CITIES = [("Kuala Lumpur", "50450"), ("Petaling Jaya", "46000"), ("Johor Bahru", "80100"), ("Penang", "10200"), ("Shah Alam", "40000"),
          ("Ipoh", "30000"), ("Setapak", "53300")]


def phone(rng: random.Random) -> tuple[str, str]:
    """(text as written, digits only)"""
    a = rng.choice(["11", "12", "13", "14", "16", "17", "18", "19"])
    n = "".join(rng.choice("0123456789") for _ in range(7))
    style = rng.choice(["dash", "plus", "plain"])
    if style == "dash":
        return f"0{a}-{n[:3]} {n[3:]}", f"0{a}{n}"
    if style == "plus":
        return f"+60 {a}-{n[:3]} {n[3:]}", f"60{a}{n}"
    return f"0{a}{n}", f"0{a}{n}"


def make_truth(rng: random.Random) -> dict:
    name = f"{rng.choice(FIRST)} {rng.choice(LAST)}"
    programme, faculty = rng.choice(PROGRAMMES)
    n_known = rng.randint(3, 7)
    n_unseen = rng.choice([0, 0, 1, 2, 3])
    skills = rng.sample(KNOWN_SKILLS, n_known) + rng.sample(UNSEEN_SKILLS, n_unseen)
    rng.shuffle(skills)
    exp = []
    year = 2025
    for _ in range(rng.choice([0, 1, 1, 2, 3])):
        length = rng.choice([1, 1, 2])
        current = not exp and rng.random() < 0.25
        end = None if current else year
        start = (year if current else year) - length
        exp.append({
            "position": rng.choice(POSITIONS),
            "companyName": rng.choice(COMPANIES),
            "startYear": start,
            "endYear": end,
            "isCurrent": current,
        })
        year = start
    city, post = rng.choice(CITIES)
    written, digits = phone(rng)
    return {
        "fullName": name,
        "phone": digits,
        "phoneWritten": written,
        "email": name.split()[0].lower() + str(rng.randint(10, 99)) + "@student.tarc.edu.my",
        "address": f"No. {rng.randint(1, 99)}, {rng.choice(STREETS)}, {post} {city}",
        "dateOfBirth": f"{rng.randint(1999, 2004)}-{rng.randint(1, 12):02d}-{rng.randint(1, 28):02d}",
        "programme": programme,
        "faculty": faculty,
        "semester": rng.randint(1, 4),
        "cgpa": round(rng.uniform(2.6, 3.95), 2),
        "skills": skills,
        "unseenSkills": [s for s in skills if s in UNSEEN_SKILLS],
        "workExperience": exp,
    }


def years(e: dict) -> str:
    return f"{e['startYear']} - {'Present' if e['isCurrent'] else e['endYear']}"


def dob_text(iso: str) -> str:
    y, m, d = iso.split("-")
    return f"{d}/{m}/{y}"


SENTENCES = [
    "Built internal dashboards using {a} and {b} that cut report preparation time by half.",
    "Worked closely with the team on {a}, and automated routine checks with {b}.",
    "Developed and maintained features with {a}; deployed releases using {b}.",
    "Responsible for {a} tasks and improved the process with {b}.",
]


def layout_classic(t: dict, rng: random.Random) -> str:
    lines = [t["fullName"].upper(), f"Phone: {t['phoneWritten']}", f"Email: {t['email']}", f"Address: {t['address']}",
             f"Date of Birth: {dob_text(t['dateOfBirth'])}", "", "EDUCATION", t["programme"], t["faculty"],
             f"Semester: {t['semester']}", f"CGPA: {t['cgpa']}", "", "TECHNICAL SKILLS"]
    lines += [f"• {s}" for s in t["skills"]]
    lines += ["", "WORK EXPERIENCE"]
    for e in t["workExperience"]:
        lines += [f"{e['position']} at {e['companyName']}   {years(e)}", f"• Contributed to {rng.choice(['testing', 'reporting', 'client support', 'documentation'])} for the team."]
    return "\n".join(lines)


def layout_inline(t: dict, rng: random.Random) -> str:
    lines = [t["fullName"], f"{t['phoneWritten']} | {t['email']}", t["address"], "", "Education", t["programme"], t["faculty"],
             f"CGPA: {t['cgpa']}  Semester: {t['semester']}", "", f"Skills: {', '.join(t['skills'])}", "", "Experience"]
    for e in t["workExperience"]:
        lines += [f"{e['position']}, {e['companyName']}  ({years(e)})"]
    return "\n".join(lines)


def layout_plain_lines(t: dict, rng: random.Random) -> str:
    lines = [t["fullName"], "Contact", f"Mobile: {t['phoneWritten']}", f"Email: {t['email']}", "", "Education",
             t["programme"], f"{t['faculty']}", f"Semester {t['semester']}", f"CGPA {t['cgpa']}", "", "Skills"]
    lines += list(t["skills"])
    lines += ["", "Work Experience"]
    for e in t["workExperience"]:
        lines += [f"{e['position']} - {e['companyName']}  {years(e)}"]
    return "\n".join(lines)


def layout_prose(t: dict, rng: random.Random) -> str:
    """No skills heading at all: skills only appear inside sentences."""
    sk = list(t["skills"])
    rng.shuffle(sk)
    lines = [t["fullName"], f"Phone: {t['phoneWritten']}", f"Email: {t['email']}", "", "Summary",
             f"Final-year student of {t['programme']}, CGPA: {t['cgpa']}."]
    i = 0
    while i < len(sk):
        a = sk[i]
        b = sk[i + 1] if i + 1 < len(sk) else sk[0]
        lines.append(rng.choice(SENTENCES).format(a=a, b=b))
        i += 2
    lines += ["", "Experience"]
    for e in t["workExperience"]:
        lines += [f"{e['position']} at {e['companyName']}   {years(e)}"]
    return "\n".join(lines)


def layout_messy(t: dict, rng: random.Random) -> str:
    title = rng.choice(["Mr.", "Ms.", "Encik", "Puan", ""])
    name = f"{title} {t['fullName']}".strip()
    lines = [name, f"{t['address']}  /  Tel {t['phoneWritten']}  /  {t['email']}", "", "Profile",
             f"Studying {t['programme']} ({t['faculty']}). Semester: {t['semester']}. CGPA: {t['cgpa']}", "", "Core Competencies"]
    lines += ["   ".join(t["skills"][i:i + 3]) for i in range(0, len(t["skills"]), 3)]
    lines += ["", "Employment History"]
    for e in t["workExperience"]:
        lines += [f"{years(e)}   {e['position']}, {e['companyName']}"]
    return "\n".join(lines)


def layout_categorised(t: dict, rng: random.Random) -> str:
    """Skills grouped under labels ("Programming: ...", "Tools: ..."), a very common real layout."""
    sk = list(t["skills"])
    groups = [sk[i::rng.choice([2, 3])] for i in range(2)] if len(sk) > 3 else [sk]
    labels = rng.sample(["Programming", "Tools", "Frameworks", "Soft skills", "Technologies"], len(groups))
    lines = [t["fullName"], f"{t['phoneWritten']}  |  {t['email']}", "", "Education", t["programme"], t["faculty"],
             f"CGPA: {t['cgpa']}", "", "Technical Skills"]
    lines += [f"{lab}: {', '.join(g)}" for lab, g in zip(labels, groups) if g]
    lines += ["", "Work Experience"]
    for e in t["workExperience"]:
        lines += [f"{e['position']}, {e['companyName']}  {years(e)}"]
    return "\n".join(lines)


MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def layout_month_dates(t: dict, rng: random.Random) -> str:
    """Month-name dates, a bullet description under each job, and dash bullets for skills."""
    lines = [t["fullName"], f"Mobile: {t['phoneWritten']}", f"Email: {t['email']}", "", "Skills"]
    lines += [f"- {s}" for s in t["skills"]]
    lines += ["", "Professional Experience"]
    for e in t["workExperience"]:
        end = "Present" if e["isCurrent"] else f"{rng.choice(MONTHS)} {e['endYear']}"
        lines += [f"{e['position']}, {e['companyName']}   {rng.choice(MONTHS)} {e['startYear']} – {end}",
                  "- Prepared weekly progress reports and supported the team lead.",
                  "- Attended client meetings and documented the requirements."]
    return "\n".join(lines)


# which fields each layout actually prints (a parser is only scored on fields that are in the text)
PRINTS = {
    "classic_headings_bullets": {"fullName", "phone", "address", "dateOfBirth", "programme", "faculty", "semester", "cgpa"},
    "inline_skills_line": {"fullName", "phone", "address", "programme", "faculty", "semester", "cgpa"},
    "plain_lines": {"fullName", "phone", "programme", "faculty", "semester", "cgpa"},
    "prose_no_skills_heading": {"fullName", "phone", "programme", "cgpa"},
    "messy_contact_competencies": {"fullName", "phone", "address", "programme", "faculty", "semester", "cgpa"},
    "categorised_skills": {"fullName", "phone", "programme", "faculty", "cgpa"},
    "month_dates_bullets": {"fullName", "phone"},
}

LAYOUTS = {
    "categorised_skills": layout_categorised,
    "month_dates_bullets": layout_month_dates,
    "classic_headings_bullets": layout_classic,
    "inline_skills_line": layout_inline,
    "plain_lines": layout_plain_lines,
    "prose_no_skills_heading": layout_prose,
    "messy_contact_competencies": layout_messy,
}


def main() -> None:
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 2026
    rng = random.Random(seed)
    names = list(LAYOUTS)
    out = []
    for i in range(count):
        truth = make_truth(rng)
        layout = names[i % len(names)]
        text = LAYOUTS[layout](truth, rng)
        # layouts that do not print a field must not be scored on it
        printed = PRINTS[layout]
        present = {f: f in printed for f in
                   ("fullName", "phone", "address", "dateOfBirth", "programme", "faculty", "semester", "cgpa")}
        present["skills"] = True
        present["workExperience"] = True
        out.append({"id": i, "layout": layout, "text": text, "truth": truth, "scored": present})
    path = os.path.join(HERE, "synthetic_resumes.json")
    json.dump(out, open(path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(f"wrote {count} resumes in {len(LAYOUTS)} layouts -> {path}")


if __name__ == "__main__":
    main()
