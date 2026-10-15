# Pika Debloater

**Pika Debloater** is a rebranded fork-build of [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil), using the original MIT-licensed source. It is **not affiliated with or endorsed by Chris Titus Tech**. The original copyright and MIT license must stay with the software.

This ZIP is a **GitHub build kit**, not the compiled full utility. GitHub Actions fetches the WinUtil source, changes the visible Pika Debloater window and banner names, and compiles its full Install / Tweaks / Config / Updates functionality into `PikaDebloater.ps1`. Internal WinUtil identifiers and some upstream references remain to avoid breaking features; third-party links may still point upstream. Review those before distributing your fork.

## Setup: create your GitHub repo

1. On GitHub, create a **public** repository named `pika-debloater` with branch `main`.
2. Extract this ZIP locally. Upload `Build-PikaDebloater.ps1`, `README.md`, `LICENSE-WINUTIL`, and the full `.github/workflows/build.yml` folder into your GitHub repository. To preserve the `.github` directory, drag in the extracted folder with its contents, or use `git` locally.
3. In the GitHub repository, open **Actions** > **Build Pika Debloater** > **Run workflow**. The workflow also starts on first push to `main` if Actions is allowed.
4. Wait for the workflow to succeed. You should then see `PikaDebloater.ps1` and `run.ps1` in the root of your repo. If the workflow fails, check its log; upstream project changes can require updating the build kit.
5. Open **Windows PowerShell as administrator** and run this command, replacing `YOUR_GITHUB_USERNAME` with your username:

```powershell
irm https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/pika-debloater/main/run.ps1 | iex
```

To run the compiled tool without remotely executing a loader, download `PikaDebloater.ps1` from your own GitHub repo, review it, then in PowerShell run:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\PikaDebloater.ps1
```

## Included features

Most WinUtil functions are preserved: application installation and upgrades, Windows tweaks and debloat options, Config tools, and Windows Update settings. As with original WinUtil, some actions can affect system behavior and need administrator permissions. Create a restore point first and understand each tweak before enabling it. This fork does not automatically guarantee all operations are reversible.

## Origin and license

Based on open-source [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil), copyright (c) 2022 CT Tech Group LLC, MIT License. Keep `LICENSE-WINUTIL` and author notice with your redistributed copies. The resulting compiled script also includes the license notice. Pika Debloater changes are primarily branding and packaging, not a claim of original authorship of WinUtil functionality.

## Limitations

This kit is intended to build on a GitHub-hosted **Windows** runner. Because the upstream repository can change, a future upstream update can require modifying the rebranding script. The full Windows GUI was not executed or validated in the environment where this kit was prepared.
