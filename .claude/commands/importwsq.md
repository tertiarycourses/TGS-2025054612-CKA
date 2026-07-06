---
description: Import all WSQ skills, hooks, agents and commands from the user level (~/.claude) into the current project (.claude) — safe merge, never overwrites course-customised files
---

# Import WSQ tooling — user level → project level

Import the full WSQ courseware toolchain from `~/.claude` into the current project's
`.claude/`, so the repo is self-contained and portable. Idempotent — safe to re-run
whenever the user-level tooling changes.

## What gets imported

| Category | Items | Rule |
|---|---|---|
| Skills | `wsq-slides`, `wsq-learner-guide`, `wsq-lesson-plan`, `wsq-assessment`, `gdrive-push`, `tertiary-course-slides`, `tertiary-learner-guide`, `tertiary-lesson-plan`, `tertiary-ppt-design` | **Safe merge**: copy the folder if missing; if present, add missing files only — NEVER overwrite an existing project file (project copies carry course-specific "THIS COURSE" blocks and the course build scripts). Report user-level files that differ so they can be ported manually. |
| Agents | ALL `~/.claude/agents/*.md` | Copy; overwrite is OK (agents are not course-customised) |
| Hooks | ALL `~/.claude/hooks/*.py` | Copy; overwrite OK. Then wire `courseware-pre-hook.py` (PreToolUse) and `courseware-post-hook.py` (PostToolUse) into `.claude/settings.json` with `$CLAUDE_PROJECT_DIR` paths (idempotent merge — skip if already wired). |
| Commands | ALL `~/.claude/commands/*.md` (including `importwsq.md` itself) | Copy if missing only — never overwrite an existing project command (it may be course-customised, e.g. `gdrive-push.md`). |

Do NOT import `courseware-build` — that is another course's build pipeline.

## Run

Execute from the project root:

```bash
python3 - <<'EOF'
import glob, json, os, shutil

U = os.path.expanduser("~/.claude")
P = ".claude"
report = []

SKILLS = ["wsq-slides", "wsq-learner-guide", "wsq-lesson-plan", "wsq-assessment",
          "gdrive-push", "tertiary-course-slides", "tertiary-learner-guide",
          "tertiary-lesson-plan", "tertiary-ppt-design"]

def merge_skill(name):
    src, dst = f"{U}/skills/{name}", f"{P}/skills/{name}"
    if not os.path.isdir(src):
        return report.append(f"SKIP (no user copy): skills/{name}")
    if not os.path.isdir(dst):
        shutil.copytree(src, dst)
        return report.append(f"imported (new): skills/{name}")
    added, differs = 0, []
    for root, dirs, files in os.walk(src):
        dirs[:] = [x for x in dirs if x != "__pycache__"]
        rel = os.path.relpath(root, src)
        for f in files:
            if f.endswith(".pyc") or f == ".DS_Store":
                continue
            s, d = os.path.join(root, f), os.path.join(dst, rel, f)
            if not os.path.exists(d):
                os.makedirs(os.path.dirname(d), exist_ok=True)
                shutil.copy2(s, d); added += 1
            elif open(s, "rb").read() != open(d, "rb").read():
                differs.append(os.path.normpath(os.path.join(rel, f)))
    msg = f"kept customised: skills/{name} (+{added} new files)"
    if differs:
        msg += f"  [differs from user level — port manually if wanted: {', '.join(differs)}]"
    report.append(msg)

for s in SKILLS:
    merge_skill(s)

os.makedirs(f"{P}/agents", exist_ok=True)
for src in glob.glob(f"{U}/agents/*.md"):
    shutil.copy2(src, f"{P}/agents/"); report.append(f"synced: agents/{os.path.basename(src)}")

os.makedirs(f"{P}/hooks", exist_ok=True)
for src in glob.glob(f"{U}/hooks/*.py"):
    shutil.copy2(src, f"{P}/hooks/"); report.append(f"synced: hooks/{os.path.basename(src)}")

os.makedirs(f"{P}/commands", exist_ok=True)
for src in glob.glob(f"{U}/commands/*.md"):
    d = f"{P}/commands/{os.path.basename(src)}"
    if os.path.exists(d):
        report.append(f"kept project command: commands/{os.path.basename(src)}")
    else:
        shutil.copy2(src, d); report.append(f"imported (new): commands/{os.path.basename(src)}")

sp = f"{P}/settings.json"
s = json.load(open(sp)) if os.path.exists(sp) else {}
hooks = s.setdefault("hooks", {})
for event, script in [("PreToolUse", "courseware-pre-hook.py"),
                      ("PostToolUse", "courseware-post-hook.py")]:
    if not os.path.exists(f"{P}/hooks/{script}"):
        continue
    arr = hooks.setdefault(event, [])
    cmd = f'python3 "$CLAUDE_PROJECT_DIR/.claude/hooks/{script}"'
    if not any(h.get("command") == cmd for m in arr for h in m.get("hooks", [])):
        arr.append({"matcher": "Bash", "hooks": [{"type": "command", "command": cmd}]})
        report.append(f"wired hook: {event} -> {script}")
json.dump(s, open(sp, "w"), indent=2)
print("\n".join(report))
EOF
```

## After the import

1. Show the report to the user: imported / synced / kept-customised (with any
   "differs from user level" files listed) / wired hooks.
2. Do NOT commit unless the user asks.
3. Remind: course-customised skill files are never overwritten — to adopt user-level
   template changes into an existing course, port them manually (the report lists
   exactly which files differ).
