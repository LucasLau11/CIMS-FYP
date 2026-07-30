"""
Seed vocabulary for weak-supervision skill tagging (Phase B, step 1).

DB_SKILLS comes straight from your own `internships.required_skills` column
(real data from the app). SUPPLEMENTARY_SKILLS is a broader curated list to
give the auto-tagger enough coverage to be useful across a varied resume
corpus — real postings only cover 18 distinct terms, far too narrow on its
own. Edit either list freely; this is meant to be a living, editable file,
not a one-time generated artifact.
"""

DB_SKILLS = [
    "Analysis", "Cisco", "Dart", "Documentation", "Excel", "Figma",
    "Firebase", "Flutter", "HTML", "Java", "Linux", "ML", "Networking",
    "Python", "Research", "REST API", "SQL", "UI Design",
]

SUPPLEMENTARY_SKILLS = [
    # Programming languages
    "JavaScript", "TypeScript", "C++", "C#", "C", "Kotlin", "Swift", "Go",
    "Rust", "PHP", "Ruby", "R", "MATLAB", "Scala", "Perl", "Objective-C",
    "Bash", "Shell Scripting", "VBA",
    # Web frameworks / libraries
    "React", "React Native", "Angular", "Vue.js", "Node.js", "Express.js",
    "Django", "Flask", "FastAPI", "Spring Boot", "Laravel", "ASP.NET",
    "Ruby on Rails", "jQuery", "Next.js", "Bootstrap", "Tailwind CSS",
    # Mobile
    "Android", "iOS", "Xcode", "Android Studio",
    # Databases
    "MySQL", "PostgreSQL", "MongoDB", "Redis", "SQLite", "Oracle Database",
    "Firebase Firestore", "DynamoDB", "Microsoft SQL Server", "NoSQL",
    # Cloud / DevOps
    "AWS", "Amazon Web Services", "Azure", "Google Cloud Platform", "GCP",
    "Docker", "Kubernetes", "Jenkins", "CI/CD", "Terraform", "Ansible",
    "Git", "GitHub", "GitLab", "Bitbucket", "Nginx", "Apache",
    # Data / ML / AI
    "Machine Learning", "Deep Learning", "Data Analysis", "Data Science",
    "TensorFlow", "PyTorch", "Keras", "scikit-learn", "Pandas", "NumPy",
    "Natural Language Processing", "NLP", "Computer Vision",
    "Data Visualization", "Tableau", "Power BI", "Big Data", "Hadoop",
    "Spark", "ETL",
    # Design / product
    "Adobe Photoshop", "Adobe Illustrator", "Adobe XD", "Sketch",
    "UX Design", "Wireframing", "Prototyping", "Canva",
    # Networking / security / systems
    "TCP/IP", "DNS", "VPN", "Firewall Configuration", "Cybersecurity",
    "Penetration Testing", "Network Security", "Windows Server",
    "Active Directory", "Virtualization", "VMware",
    # Project / office tools
    "Microsoft Office", "PowerPoint", "Word", "Jira", "Confluence", "Trello",
    "Notion", "Slack", "Agile", "Scrum", "Kanban", "Project Management",
    # APIs / architecture
    "GraphQL", "Microservices", "API Development", "Web Services", "JSON",
    "XML",
    # Soft skills (commonly listed on resumes alongside technical ones)
    "Communication", "Teamwork", "Problem Solving", "Leadership",
    "Time Management", "Critical Thinking", "Adaptability", "Collaboration",
    "Presentation Skills", "Public Speaking", "Customer Service",
]

ALL_SKILLS = sorted(set(DB_SKILLS) | set(SUPPLEMENTARY_SKILLS), key=str.lower)
