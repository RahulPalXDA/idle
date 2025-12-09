# Idle Master (X11 Userspace Edition)

A lightweight, userspace daemon that prevents your Linux desktop from going idle by simulating invisible mouse movements. Sends Telegram notifications when you become idle or return.

## Features

- **Invisible Mouse Jiggle** – Moves cursor ±10 pixels (barely noticeable)
- **Telegram Notifications** – Alerts when idle/returned with duration
- **No Root Required** – Runs as a systemd user service
- **X11 Native** – Uses XScreenSaver extension for accurate idle detection
- **Silent Operation** – No console output, runs in background

## Requirements

- Linux with X11 (Xorg)
- systemd
- Telegram Bot (optional, for notifications)

### Dependencies

| Library | Package (Debian/Ubuntu) | Package (Arch) |
|---------|------------------------|----------------|
| libX11 | `libx11-dev` | `libx11` |
| libXss | `libxss-dev` | `libxss` |
| libXtst | `libxtst-dev` | `libxtst` |
| libcurl | `libcurl4-openssl-dev` | `curl` |
| Clang | `clang` | `clang` |

## Configuration

Edit `idle_master.c` before building:

```c
// Telegram Bot Settings (leave empty to disable)
#define TG_BOT_TOKEN "your_bot_token_here"
#define TG_CHAT_ID   "your_chat_id_here"

// Timing Configuration
#define IDLE_THRESHOLD_MS 30000  // Time before considered idle (ms)
#define JIGGLE_INTERVAL_MS 1000  // Mouse jiggle frequency (ms)
#define JIGGLE_PIXELS 10         // Jiggle distance (pixels, 10 recommended)
```

### Getting Telegram Credentials

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow prompts to get your **Bot Token**
3. Message your new bot, then visit:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
4. Find your **Chat ID** in the response JSON

## Installation

```bash
# Clone or download the project
cd idle

# Run the setup script (installs deps, builds, creates service)
sudo ./setup.sh

# Enable and start the service (as YOUR user, not root)
systemctl --user daemon-reload
systemctl --user enable --now idle_master
```

## Usage

### Service Commands

```bash
# Check status
systemctl --user status idle_master

# View logs
journalctl --user -u idle_master -f

# Stop service
systemctl --user stop idle_master

# Start service
systemctl --user start idle_master

# Restart service
systemctl --user restart idle_master
```

### Updating After Config Changes

```bash
sudo ./update.sh
```

This will:
1. Stop the running service
2. Rebuild with new settings
3. Install the new binary
4. Restart the service

### Uninstalling

```bash
sudo ./uninstall.sh
```

This will:
1. Stop and disable the service
2. Remove the systemd unit file
3. Delete the installed binary

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                      State Machine                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   ┌──────────────┐   idle >= 30s   ┌──────────────┐     │
│   │  MONITORING  │ ───────────────►│   JIGGLING   │     │
│   │              │                 │              │     │
│   │ (Waiting for │                 │ (Moving mouse│     │
│   │  idle state) │ ◄───────────────│  every 1s)   │     │
│   └──────────────┘   user returns  └──────────────┘     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

1. **Monitoring**: Polls X11 idle time via `XScreenSaverQueryInfo()`
2. **Idle Detection**: When idle exceeds threshold, sends `User_is_Idle`
3. **Jiggling**: Simulates ±10px mouse movement via `XTestFakeRelativeMotionEvent()`
4. **Return Detection**: If real user activity detected, sends `User_Returned_(idle_Xh_Xm_Xs)`

### Smart User Detection

The program distinguishes between its own jiggle and real user input:
- After jiggling, it sleeps 1 second
- If idle time is < 900ms after sleeping, a **real human** moved during that window
- If idle time is ≥ 900ms, only our jiggle occurred (ignored)

## File Structure

```
idle/
├── idle_master.c   # Main source code
├── Makefile        # Build configuration
├── setup.sh        # Install dependencies + build + create service
├── update.sh       # Rebuild and restart after config changes
├── uninstall.sh    # Remove everything
└── README.md       # This file
```

## Telegram Messages

| Message | Meaning |
|---------|---------|
| `User_is_Idle` | You've been inactive for 30+ seconds |
| `User_Returned_(idle_0h_5m_32s)` | You're back after being idle for 5m 32s |

## Troubleshooting

### Service won't start
```bash
# Check if X11 is running
echo $DISPLAY  # Should output something like ":0"

# Check for errors
journalctl --user -u idle_master --no-pager
```

### No Telegram messages
- Verify `TG_BOT_TOKEN` and `TG_CHAT_ID` are set correctly
- Make sure you've messaged your bot at least once
- Check network connectivity

### "XScreenSaver Extension missing"
```bash
# Install the extension
sudo apt install libxss1  # Debian/Ubuntu
```

## License

MIT License – Do whatever you want with it.

## Author

Built for keeping your presence alive while you grab coffee ☕
