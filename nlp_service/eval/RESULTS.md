# Resume parser accuracy on fake resumes

350 generated resumes in 7 layouts, with the true answers stored beside them. Scored automatically; nobody labelled anything by hand.

These are generated resumes: the numbers show how each parser copes with these layouts, not how it does on every real resume.

## Fields that must match exactly

| Parser | fullName | phone | programme | faculty | semester | cgpa | dateOfBirth | address |
|---|---|---|---|---|---|---|---|---|
| Regex only (the app's built-in parser) | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| spaCy service, skills from the Skills heading | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| spaCy service + trained SKILL model (model only) | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| spaCy service + trained SKILL model (model + heading, always) | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| spaCy service, default: heading rules, trained model only if none found | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| TensorFlow Lite model only (runs on the phone) | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| TensorFlow Lite on the phone: heading rules, model only if none found | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% |

## Skills (set of skills per resume)

| Parser | Precision | Recall | F1 | Recall on unseen skills |
|---|---|---|---|---|
| Regex only (the app's built-in parser) | 1.00 | 0.83 | 0.90 | 81% (325/399) |
| spaCy service, skills from the Skills heading | 1.00 | 0.83 | 0.90 | 81% (325/399) |
| spaCy service + trained SKILL model (model only) | 0.79 | 0.38 | 0.52 | 7% (26/399) |
| spaCy service + trained SKILL model (model + heading, always) | 0.89 | 0.85 | 0.87 | 81% (325/399) |
| spaCy service, default: heading rules, trained model only if none found | 0.99 | 0.85 | 0.91 | 81% (325/399) |
| TensorFlow Lite model only (runs on the phone) | 0.67 | 0.33 | 0.44 | 22% (87/399) |
| TensorFlow Lite on the phone: heading rules, model only if none found | 0.98 | 0.84 | 0.91 | 81% (325/399) |

### Skills F1 by layout

| Parser | categorised_skills | classic_headings_bullets | inline_skills_line | messy_contact_competencies | month_dates_bullets | plain_lines | prose_no_skills_heading |
|---|---|---|---|---|---|---|---|
| Regex only (the app's built-in parser) | 0.90 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.00 |
| spaCy service, skills from the Skills heading | 0.90 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.00 |
| spaCy service + trained SKILL model (model only) | 0.42 | 0.67 | 0.58 | 0.23 | 0.65 | 0.69 | 0.24 |
| spaCy service + trained SKILL model (model + heading, always) | 0.85 | 0.96 | 0.96 | 0.93 | 0.92 | 0.97 | 0.24 |
| spaCy service, default: heading rules, trained model only if none found | 0.90 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.24 |
| TensorFlow Lite model only (runs on the phone) | 0.38 | 0.63 | 0.63 | 0.08 | 0.65 | 0.34 | 0.18 |
| TensorFlow Lite on the phone: heading rules, model only if none found | 0.90 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 0.18 |

## Work history (position + company both right)

| Parser | Precision | Recall | F1 |
|---|---|---|---|
| Regex only (the app's built-in parser) | 1.00 | 1.00 | 1.00 |
| spaCy service, skills from the Skills heading | 1.00 | 1.00 | 1.00 |
| spaCy service + trained SKILL model (model only) | 1.00 | 1.00 | 1.00 |
| spaCy service + trained SKILL model (model + heading, always) | 1.00 | 1.00 | 1.00 |
| spaCy service, default: heading rules, trained model only if none found | 1.00 | 1.00 | 1.00 |
| TensorFlow Lite model only (runs on the phone) | 1.00 | 1.00 | 1.00 |
| TensorFlow Lite on the phone: heading rules, model only if none found | 1.00 | 1.00 | 1.00 |

## Speed

| Parser | Seconds per resume |
|---|---|
| Regex only (the app's built-in parser) | 0.00283 |
| spaCy service, skills from the Skills heading | 0.0009 |
| spaCy service + trained SKILL model (model only) | 0.0121 |
| spaCy service + trained SKILL model (model + heading, always) | 0.0112 |
| spaCy service, default: heading rules, trained model only if none found | 0.003 |
| TensorFlow Lite model only (runs on the phone) | 0.0029 |
| TensorFlow Lite on the phone: heading rules, model only if none found | 0.0029 |
