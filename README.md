# AI Agent Routing

**Status:** Complete
**Created:** 2025-01-08

---

## Goal

Split network traffic so AI coding agents maintain internet connectivity while developing on isolated networks (captive portals, test networks, IoT devices). This enables developers to work with AI assistance on network-related projects that require connection to networks without internet access.

---

## Design Flow

### Overview

Uses Linux policy-based routing (iproute2) to split traffic between two network interfaces.

### Flow Steps

1. **Entry** - User runs `ai-routing.sh enable` with sudo
2. **Pin AI Routes** - Add specific routes for AI service IPs via internet interface (Ethernet)
3. **Switch Default** - Change default route to test interface (WiFi)
4. **Result** - AI traffic uses Ethernet, everything else uses WiFi

### Restore Steps

1. **Entry** - User runs `ai-routing.sh disable` with sudo
2. **Restore Default** - Change default route back to internet interface
3. **Remove Pins** - Delete specific AI service routes
4. **Result** - All traffic uses Ethernet (normal routing)

---

## Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AI AGENT ROUTING FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────────┐
                              │  Application    │
                              │  (outbound)     │
                              └────────┬────────┘
                                       │
                                       ▼
                    ┌──────────────────────────────────────┐
                    │     Linux Routing Table Decision     │
                    │     (ip route get <destination>)     │
                    └──────────────────┬───────────────────┘
                                       │
         ┌─────────────────────────────┴─────────────────────────────┐
         │                                                           │
         ▼                                                           ▼
┌─────────────────────┐                                 ┌─────────────────────┐
│  Matches AI Route?  │                                 │   Default Route     │
│  (CLAUDE_ROUTES)    │                                 │   (all other IPs)   │
└──────────┬──────────┘                                 └──────────┬──────────┘
           │                                                       │
           ▼                                                       ▼
┌─────────────────────┐                                 ┌─────────────────────┐
│     ETH_IF          │                                 │     WIFI_IF         │
│  (eth0 - internet)  │                                 │  (wlan0 - test)     │
└──────────┬──────────┘                                 └──────────┬──────────┘
           │                                                       │
           ▼                                                       ▼
┌─────────────────────┐                                 ┌─────────────────────┐
│   Internet Gateway  │                                 │   Test Network      │
│   (ETH_GW)          │                                 │   (captive portal)  │
└─────────────────────┘                                 └─────────────────────┘


                    ════════════════════════════════════════
                              ROUTING MODES
                    ════════════════════════════════════════

    DISABLED (Normal)                     ENABLED (Split)
    ─────────────────                     ─────────────────

    ┌─────────┐     ┌──────────┐          ┌─────────┐     ┌──────────┐
    │ All     │────►│  eth0    │          │ AI IPs  │────►│  eth0    │
    │ Traffic │     │ internet │          │ only    │     │ internet │
    └─────────┘     └──────────┘          └─────────┘     └──────────┘

                                          ┌─────────┐     ┌──────────┐
                                          │ Other   │────►│  wlan0   │
                                          │ Traffic │     │ test net │
                                          └─────────┘     └──────────┘
```

---

## Quick Start

### 1. Configure

```bash
cp config.env.example config.env
# Edit config.env with your interface names (find with: ip link show)
```

### 2. Enable Split Routing

```bash
./scripts/ai-routing.sh enable
```

### 3. Restore Normal Routing

```bash
./scripts/ai-routing.sh disable
```

---

## Commands

| Command | Description |
|---------|-------------|
| `./scripts/ai-routing.sh enable` | Split: AI to internet, default to test network |
| `./scripts/ai-routing.sh disable` | Restore normal routing |
| `./scripts/ai-routing.sh status` | Show current routing state |

---

## Configuration

Edit `config.env`:

| Variable | Description |
|----------|-------------|
| `ETH_IF` | Internet-connected interface (e.g., eth0, enp3s0) |
| `ETH_GW` | Gateway IP for internet interface |
| `WIFI_IF` | Development/test interface (e.g., wlan0, wlp2s0) |
| `CLAUDE_ROUTES` | IP ranges to route through internet |

### Default AI Routes

- 160.79.104.0/24 - Anthropic Claude API
- 34.36.0.0/16 - Google Cloud
- 34.149.0.0/16 - Google Cloud
- 142.250.0.0/16 - Google

---

## Use Cases

- **Captive portal development** - Test portal flows while coding with AI assistance
- **wpa_supplicant configuration** - Develop WiFi configs on isolated networks
- **Network management tools** - Build NetworkManager plugins or network scripts
- **IoT device development** - Work with devices on isolated networks
- **Network security testing** - Maintain agent access during security work

---

## Requirements

- Linux with iproute2 (`ip` command)
- Two network interfaces (e.g., Ethernet + WiFi)
- sudo access for route changes

---

## Testing

```bash
./scripts/ai-routing.sh enable && cd tests && ./test-routing.sh enable
./scripts/ai-routing.sh disable && cd tests && ./test-routing.sh disable
```

---

## License

MIT
