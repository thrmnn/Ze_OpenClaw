# Project — Personal Website

> Extracted from MEMORY.md on 2026-04-02

## Deployment
- Live at: https://thrmnn.github.io
- Repo: `~/projects/website/` → GitHub: `git@github-thrmnn:thrmnn/thrmnn.github.io.git`
- Stack: Hugo Blox (academic CV theme), 168 pages
- CI/CD: GitHub Actions auto-deploy on push to main
- GitHub Pages source must be set to "GitHub Actions" in repo settings

## Hugo Config
- Hugo pinned to 0.136.5
- blox-tailwind pinned to v0.3.1 (v0.10.0 incompatible — needs preact + TailwindCSS CLI)
- `public/` excluded from git (952 artifacts removed)
- Vercel deploy deferred (Hugo not pre-installed in Vercel build env)

## Content
- Source of truth: `PERSONAL_INFO.md` + `PROJECTS.md`
- After edits: run `python3 sync_personal_info.py`
- Projects written: Roboat, Loomo, Urban Digital Twin/Brisa+, LAI
- 2 publications added

## Commands
```bash
cd ~/projects/website && hugo server        # preview locally
git push origin main                         # deploy (Actions build automatically)
```
