# Agent Notes
- Spoken notifications use the macOS `say` command with the current system default voice (no custom voice specified). Keep this consistent for future announcements.
- Debug builds packaged via `Scripts/package_app.sh` invalidate signatures (install_name_tool). Before launching locally from the repo, re-sign ad-hoc with `codesign --deep --force --sign - Trimmy.app` and then `open -n Trimmy.app`.
