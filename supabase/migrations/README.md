# Migrations

Every schema change for this project is a numbered SQL file here, applied
via the Supabase MCP `apply_migration` tool and committed to git in the
same commit as the file itself. This is the durability practice from
`docs/superpowers/plans/2026-08-04-normalized-schema-migration.md` —
future schema changes (e.g. tutor-requested ERD revisions) should follow
the same pattern: new numbered file, applied, committed. Never apply
untracked ad-hoc SQL directly against the project.

Project: Lucas FYP - CIMS Project (lgosyvuwtkzrjvsbxyed), org "Lucas FYP Org".
