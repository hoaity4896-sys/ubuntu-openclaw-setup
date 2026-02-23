# Ubuntu OpenClaw Setup

One-command script to set up a full Ubuntu environment: remote access, Node.js, and OpenClaw.

```bash
sudo bash setup-openclaw.sh
```

## What it does

| Step | Action |
|------|--------|
| 1 | Update system (apt update, upgrade, autoremove, autoclean) |
| 2 | Install curl (if missing) |
| 3 | Run Ubuntu Remote Setup (disable sleep, SSH, terminal display) |
| 4 | Install NVM + Node.js 24 |
| 5 | Install OpenClaw globally |

## Quick Install

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/hoaity4896-sys/ubuntu-openclaw-setup/main/setup-openclaw.sh)"
```

Or clone and run:

```bash
git clone https://github.com/hoaity4896-sys/ubuntu-openclaw-setup.git
cd ubuntu-openclaw-setup
sudo bash setup-openclaw.sh
```

## After running

Open a new terminal and verify:

```bash
node -v        # v24.x.x
npm -v         # 10.x.x
openclaw --version
ssh user@your-ip
```

## What gets installed

- **System**: Updated packages, cleaned cache
- **SSH**: OpenSSH Server (enabled on boot, sleep disabled)
- **NVM**: v0.40.3 (installed for current user)
- **Node.js**: v24 (set as default)
- **OpenClaw**: Latest version (global)

## License

MIT
