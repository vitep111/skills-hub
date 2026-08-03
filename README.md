# Claude Skills Hub

Master source of truth for all my Claude Code skills.

- This repo is the ONLY place skills are edited or updated.
- Other project repos COPY skills from here into their own 
  `.claude/skills/` folder — they do not link back to this repo live.
- Skills are organized by **original source**: each source repo gets its own
  folder under `skills/<source-owner>/<skill-name>/`, so it's always clear
  where a skill came from.
- See INSTALLED.md for the current catalog of available skills, grouped by
  source with each skill's exact path.
- See WORKFLOW.md for the end-to-end development loop these skills compose
  into, and the stages that still lack a skill.

## How to use a skill in another project
Ask Claude Code, from within the target project repo:
"Fetch the <skill-name> folder from skills/<source-owner>/<skill-name> in 
github.com/<my-username>/claude-skills-hub, and copy it into 
.claude/skills/<skill-name>/ in this repo."
