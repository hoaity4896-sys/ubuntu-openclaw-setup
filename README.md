# Ubuntu OpenClaw Setup (All-in-One)

One script to fully set up an Ubuntu machine with **SSH remote access**, **NVM**, **Node.js 24**, and **OpenClaw**.

## What it does

| Step | Description |
|------|-------------|
| 1/6 | Update & upgrade system packages |
| 2/6 | Install dependencies (`curl`, `git`, `build-essential`, `python3`) |
| 3/6 | SSH remote access (openssh-server, disable sleep, terminal info display) |
| 4/6 | Install NVM + Node.js 24 |
| 5/6 | Install OpenClaw globally |
| 6/6 | Show final summary with connection info |

## One-Liner Install

```bash
wget -qO- https://raw.githubusercontent.com/hoaity4896-sys/ubuntu-openclaw-setup/main/setup-openclaw.sh | sudo bash
```

## Manual Install

```bash
git clone https://github.com/hoaity4896-sys/ubuntu-openclaw-setup.git
cd ubuntu-openclaw-setup
sudo bash setup-openclaw.sh
```

## After Setup

Open a new terminal — SSH info is displayed automatically:

```
  ┌──────────────────────────────────────────────┐
  │  SSH REMOTE ACCESS                           │
  │  ────────────────────────────────────────     │
  │  Connect: ssh user@192.168.x.x               │
  │  Status : ● Running                          │
  └──────────────────────────────────────────────┘
```

## License

MIT
