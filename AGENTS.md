# AGENTS.md

READ ~/Projects/agent-scripts/{AGENTS.MD,TOOLS.MD} BEFORE ANYTHING (skip if files missing).

Repo-local notes
- Changelog: keep entries Trimmy-only—no other repos/products.
- Run Trimmy via `Scripts/compile_and_run.sh` (handles kill/build/test/package/launch) after code changes and before handoff.
- To guarantee the right bundle is running after a rebuild, use: `pkill -x CodexBar || pkill -f CodexBar.app || true; cd /Users/steipete/Projects/codexbar && open -n /Users/steipete/Projects/codexbar/CodexBar.app`.
- After any code change that affects the app, always rebuild with `Scripts/package_app.sh` and restart the app using the command above before validating behavior.
- Settings tabs once animated per tab (spring + `contentHeight`/`preferredHeight`); restore from pre-2025-11-19 ~18:40 commit if needed.
