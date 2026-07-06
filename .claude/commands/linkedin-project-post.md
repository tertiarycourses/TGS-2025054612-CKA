---
description: Generate an exciting LinkedIn post to showcase a coding project — hook, live demo + repo links, features, tech stack, CTA, hashtags. Auto-captures a screenshot and can auto-publish via LinkedIn MCP.
argument-hint: "[optional: live demo URL and/or GitHub repo URL]"
allowed-tools: Bash, Read, Grep, Glob
---

# LinkedIn Project Post

Generate an engaging LinkedIn post for a coding project, capture a screenshot for the post image, and auto-publish via LinkedIn MCP when configured (otherwise fall back to the manual browser flow).

Runs using **Claude Code with subscription plan** — do NOT use pay-as-you-go API keys.

## Screenshot / image

If a live demo URL is provided and the user has no existing image, auto-capture a 1200×630 viewport screenshot to `~/Downloads/linkedin-screenshot.png`, then open the Downloads folder. Use whichever is available:
```bash
npx puppeteer screenshot [URL] --output ~/Downloads/linkedin-screenshot.png --viewport 1200x630
# or: shot-scraper [URL] -o ~/Downloads/linkedin-screenshot.png --width 1200 --height 630
# or a screenshot API
```
Capture the hero / main feature; if login is required, capture the landing page. Always remind the user to attach the image — posts with images get ~2× engagement.

## Post structure

1. **Opening hook** — enthusiasm + emojis: `I'm thrilled to share a vibe-coding project — [Name] — [one-line]! 🚀✨`
2. **Links** — `🌐 Check it out: [Live Demo]` and `📦 GitHub repo: [GitHub URL]`
3. **What it's about** — 🧭 2-3 sentences on the problem and audience
4. **Key features** — 🚀 `✅`-prefixed bullets, end with "… and more to come!"
5. **Tech stack** — 🛠️ `💻 Tech Stack:` bullets + "Hosted on [Platform]"
6. **Call to action** — ⭐ invite fork / comment / discuss / star
7. **Hashtags** — 5-10 relevant, e.g. `#VibeCoding #OpenSource #WebDev #BuildInPublic #DevCommunity #100DaysOfCode #SideProject`

**Emoji guide:** 🚀 features · ✨ highlights · 🌐 live demo · 📦 GitHub · 🧭 about · ✅ checkmarks · 🛠️ tools · 💻 code · ⭐ CTA · 👉 pointer · 🔗 links. **Tone:** enthusiastic but authentic, professional yet approachable, celebrate the win, invite collaboration.

## Auto-publish via LinkedIn MCP (preferred)

If a LinkedIn MCP server is configured, publish the post with the screenshot instead of opening the browser:

- **lurenss/linkedin-mcp** — `create_linkedin_image_post {text, image_path}`; text-only fallback `create_linkedin_post {text}`
- **Lnxtanx/LinkedIn-MCP** — `create_post {text, media_type:"IMAGE", media_path}`; text-only fallback `media_type:"TEXT"`

First validate credentials (e.g. `get_linkedin_profile` / tool availability). If the image upload fails, fall back to text-only. On success, report status, type, and image path.

## Manual fallback (no MCP)

```bash
open "https://www.linkedin.com/feed/?shareActive=true"
```
Then: paste the generated text, click the photo icon and upload `~/Downloads/linkedin-screenshot.png`, tag relevant people/companies, and post during peak hours (Tue–Thu, 8–10am).

## After posting

Verify the post and image render correctly, engage with comments promptly, and share the link with the team.
