"""
Tests for the skill labelling and the layouts the extractor used to get wrong.

    python -m unittest discover -s tests          (run from the nlp_service folder)

They do not need the trained model: the extractor falls back to the Skills-heading rules when it
is absent, and these tests are about those rules and the labelling code.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ["CIMS_SKILL_MODEL"] = "0"  # test the rules, whether or not a model has been trained

import extractor  # noqa: E402
from skill_labels import build_vocabulary, chunk_text, looks_like_skill, section_items, silver_skill_spans  # noqa: E402


class LooksLikeSkill(unittest.TestCase):
    def test_accepts_real_skills(self):
        for item in ["Python", "C++", "Node.js", "Project Management", "Microsoft Office", "TCP/IP"]:
            self.assertTrue(looks_like_skill(item), item)

    def test_rejects_fragments_and_sentences(self):
        for item in ["and", "web site development and", "Experience in planning the whole budget for 2021",
                     "2019 - 2021", "name@mail.com", "Languages: English", "microsoft office (powerpoint", "Skills"]:
            self.assertFalse(looks_like_skill(item), item)


class SectionItems(unittest.TestCase):
    def test_items_under_a_heading_have_exact_offsets(self):
        text = "Ali\nSkills\n- Python\n- SQL, Git\nEducation\nDiploma\n"
        items = [s.text(text) for s in section_items(text)]
        self.assertEqual(items, ["Python", "SQL", "Git"])

    def test_inline_skills_line(self):
        text = "Ali\nSkills: Python, Java\nEducation\n"
        self.assertEqual([s.text(text) for s in section_items(text)], ["Python", "Java"])


class Vocabulary(unittest.TestCase):
    def test_a_phrase_needs_several_resumes_to_count(self):
        common = "Skills\nPython\n"
        texts = [common + "x"] * 3 + ["Skills\nOddOneOut\n"]
        vocab = build_vocabulary(texts, min_docs=3)
        self.assertIn("python", vocab)
        self.assertNotIn("oddoneout", vocab)

    def test_spans_are_found_outside_the_list_for_distinctive_phrases(self):
        vocab = {"machine learning", "python"}
        text = "Skills\nMachine Learning\nPython\n\nI built models with machine learning and python."
        words = [s.text(text).lower() for s in silver_skill_spans(text, vocab)]
        self.assertEqual(words.count("machine learning"), 2)  # listed + in the sentence
        self.assertEqual(words.count("python"), 1)  # a plain one-word term is NOT propagated into prose


class Chunking(unittest.TestCase):
    def test_chunks_cover_the_text_in_order(self):
        text = "\n".join(f"line number {i}" for i in range(200))
        chunks = chunk_text(text, max_chars=300)
        self.assertGreater(len(chunks), 3)
        for offset, chunk in chunks:
            self.assertEqual(text[offset:offset + len(chunk)], chunk)


class ExtractorLayouts(unittest.TestCase):
    def test_inline_skills(self):
        self.assertEqual(extractor.parse("Ali bin Abu\nSkills: Python, Java, SQL\n").skills, ["Python", "Java", "SQL"])

    def test_category_labels_are_dropped(self):
        skills = extractor.parse("Ali bin Abu\n\nTechnical Skills\nProgramming: Python, Java\nTools: Git, Docker\n\nEducation\n").skills
        self.assertEqual(set(skills), {"Python", "Java", "Git", "Docker"})

    def test_titles_and_a_l_names(self):
        self.assertEqual(extractor.parse("Ms. Siti Aminah\nPhone: 012-345 6789\n").fullName, "Siti Aminah")
        self.assertEqual(extractor.parse("Priya a/p Rajan\nPhone: 012-345 6789\n").fullName, "Priya a/p Rajan")

    def test_faculty_line(self):
        r = extractor.parse("Ali\nDiploma in IT\nFaculty of Computing and Information Technology\n")
        self.assertEqual(r.faculty, "Faculty of Computing and Information Technology")

    def test_position_comma_company(self):
        r = extractor.parse("Ali\n\nWork Experience\nGraphic Designer, Maybank Technology  2022 - 2024\n")
        self.assertEqual((r.workExperience[0].position, r.workExperience[0].companyName), ("Graphic Designer", "Maybank Technology"))


if __name__ == "__main__":
    unittest.main()
