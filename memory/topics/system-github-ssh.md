# System — GitHub SSH Setup

> Extracted from MEMORY.md on 2026-04-02

## Two GitHub Accounts

| Account | Key | Host Alias | Used for |
|---------|-----|------------|---------|
| `theoh-io` | `id_ed25519` | `github-theoh-io` | Personal projects |
| `thrmnn` | `id_rsa` | `github-thrmnn` | Papers, website |

**Critical:** Default `github.com` host maps to `theoh-io` key — WRONG for thrmnn repos.

## SSH Config (laptop, NOT yet on VPS)
```
Host github-theoh-io
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

Host github-thrmnn
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa
```

## Repo Remotes
- LAI paper: `git@github-thrmnn:thrmnn/lai_paper.git`
- Website: `git@github-thrmnn:thrmnn/thrmnn.github.io.git`
- Fix command: `git remote set-url origin git@github-thrmnn:thrmnn/<repo>.git`

## VPS Status
- ⚠️ SSH keys NOT configured on VPS yet
- Only `authorized_keys` exists at `~/.ssh/`
- No `~/.ssh/config` on VPS
- Git pushes from VPS blocked until SSH keys are added
