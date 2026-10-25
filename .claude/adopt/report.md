# Adoption Pending Items

Target: `.`

4 item(s) require human judgment before this adoption is complete.

## Source-of-Truth Missing

- **`specs/SOURCE-OF-TRUTH.md`**
  SOURCE-OF-TRUTH.md absent — needs seeding with project decisions and architecture ground-truth before the first change is tracked.
  Resolves: C3/human

## [SPECIFY] Placeholders

- **`.claude/skills/task-verify/SKILL.md`**
  File contains [SPECIFY] placeholder(s) — must be filled in by a human to adapt this skill to the project's conventions.
  Resolves: C3/human

## Tier-3 Extension Set Still Default

- **`.claude/hooks/require-approved-spec.sh`**
  Tier-3 extension set is still the kit default ('*.rs|*/Cargo.toml|*.sql|*.proto|*.ts|*.tsx|*.py'). Retarget to this project's app-code extensions (e.g. *.go, *.java) so the gate polices the right files.
  Resolves: C3/human

## Project Name Missing in CLAUDE.md

- **`CLAUDE.md`**
  CLAUDE.md contains only the seam block with no project-specific header. Add a project name/title above the seam so Claude and team members know which project this is.
  Resolves: C3/human
