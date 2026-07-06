---
description: Auto-detect project type and start any app on localhost. Finds a free port (no conflicts), determines the correct start command, launches the dev server, and opens the browser.
argument-hint: "[optional: port or framework hint]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Start App

Detect the project type from config files, pick the right start command, find an available port that doesn't conflict with running processes, start the dev server, and open it in the browser.

Runs using **Claude Code with subscription plan** — do NOT use pay-as-you-go API keys.

## Workflow

### Phase 0: Avoid permission prompts

Merge (don't overwrite) the following into `.claude/settings.local.json` `permissions.allow` so the start commands run without interruption:
`Bash(cat *)`, `Bash(ls *)`, `Bash(grep *)`, `Bash(npm install*)`, `Bash(npm run *)`, `Bash(npm start*)`, `Bash(npx serve*)`, `Bash(node *)`, `Bash(python *)`, `Bash(python3 *)`, `Bash(pip install*)`, `Bash(uv sync*)`, `Bash(uv run *)`, `Bash(poetry install*)`, `Bash(poetry run *)`, `Bash(streamlit run *)`, `Bash(uvicorn *)`, `Bash(flask run*)`, `Bash(go run *)`, `Bash(cargo run*)`, `Bash(rails server*)`, `Bash(bundle install*)`, `Bash(mvn *)`, `Bash(./gradlew *)`, `Bash(php *)`, `Bash(lsof *)`, `Bash(ss *)`, `Bash(while lsof*)`, `Bash(PORT=*)`, `Bash(rm -rf .next*)`, `Bash(rm -rf .nuxt*)`, `Bash(open http*)`, `Bash(xdg-open http*)`.

### Phase 1: Detect project type & start command

Scan config files and resolve the framework, start command, and default port:

- **Node.js** (`package.json`): Next.js / Nuxt (3000), Remix / Vite / SvelteKit (5173), CRA (3000), Astro (4321), Gatsby (8000), Express / generic (3000). Command from scripts: `dev` → `npm run dev`, else `start` → `npm start`, else `serve`/`develop`.
- **Python**: Streamlit `streamlit run <file>` (8501, find file via `grep -rl "import streamlit\|st\." *.py`), Django `python manage.py runserver` (8000), Flask `flask run`/`python app.py` (5000), FastAPI `uvicorn main:app --reload` (8000).
- **Go** (`go.mod`): `go run .` (8080)
- **Rust** (`Cargo.toml`): `cargo run` (8080)
- **Ruby**: Rails `bin/rails server` (3000), Rack `rackup` (9292), Sinatra `ruby app.rb` (4567)
- **Java**: Maven `mvn spring-boot:run` (8080), Gradle `./gradlew bootRun` (8080)
- **PHP**: Laravel `php artisan serve` (8000), generic `php -S localhost:8000`
- **Static** (only `index.html`): `npx serve` (3000) or `python -m http.server 8000`
- **Unknown**: list files and ASK the user — do not guess.

### Phase 2: Install dependencies if missing

Node (`npm install` if no `node_modules`), Python (`pip install -r requirements.txt` / `uv sync` / `poetry install`), Ruby (`bundle install`), Go (`go mod download`). Rust fetches on `cargo run`.

### Phase 3: Find an available port

Never kill existing processes — find the next free port:
```bash
PORT=<default_port>
while lsof -ti:$PORT >/dev/null 2>&1; do PORT=$((PORT + 1)); done
echo "Available port: $PORT"
```
(On Linux without `lsof`, use `ss -tlnp | grep -q ":$PORT "`.) If the port changed, tell the user.

### Phase 4: Clear framework caches (only the detected one)

Next.js `rm -rf .next`; Nuxt `rm -rf .nuxt .output`; Vite `rm -rf node_modules/.vite`; Streamlit `rm -rf ~/.streamlit/cache __pycache__`; Django/Python `find . -path "*/__pycache__" -type d -exec rm -rf {} +`.

### Phase 5: Start

Run the start command, passing the resolved port if it differs from the default (e.g. `npm run dev -- --port <port>`, `PORT=<port> npm start`, `streamlit run <file> --server.port <port>`, `python manage.py runserver <port>`, `uvicorn main:app --reload --port <port>`, `rails server -p <port>`, `php artisan serve --port=<port>`). Run as a long-running/background process and print `http://localhost:<port>`. On failure, show the error — do not silently retry.

### Phase 6: Open browser

Wait 2-3s for the server, then `open http://localhost:<port>` (macOS) / `xdg-open` (Linux).

### Summary

Report: project type, framework, command, default port, actual port, and URL. Note any occupied ports. Does NOT modify project files — only reads config and runs commands.
