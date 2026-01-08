# AI Agent Routing

Split network traffic so AI coding agents maintain internet connectivity while developing on isolated networks (captive portals, test networks, IoT devices, etc.).

## The Problem

When developing network-related software (captive portals, wpa_supplicant configs, network management tools), you often need to:

1. Connect to a test network without internet access
2. Keep your AI coding agent (Claude Code, Copilot, etc.) working

These requirements conflict - the AI agent needs internet, but your development target does not have it.

## The Solution

Use Linux policy-based routing to split traffic:

- AI agent traffic goes through Ethernet (internet)
- All other traffic goes through WiFi (test network)

## Use Cases

- Captive portal development - Test portal flows while coding with AI assistance
- wpa_supplicant configuration - Develop WiFi configs on isolated networks
- Network management tools - Build NetworkManager plugins or network scripts
- IoT device development - Work with devices on isolated networks
- Network security testing - Maintain agent access during security work

## Quick Start

### 1. Configure

Copy and edit the config file:

    cp config.env.example config.env

Edit config.env with your interface names:

    ETH_IF=eth0          # Interface with internet
    ETH_GW=192.168.1.1   # Gateway for internet
    WIFI_IF=wlan0        # Interface for development

Find your interface names with:

    ip link show

### 2. Enable Split Routing

    ./scripts/ai-routing.sh enable

Now:
- AI agents (Claude, etc.) route through Ethernet to internet
- Everything else routes through WiFi to your test network

### 3. Develop

Work normally. Your AI coding agent stays connected while you:
- Connect browsers to captive portals
- Test network configurations
- Debug connectivity issues

### 4. Restore Normal Routing

    ./scripts/ai-routing.sh disable

## Commands

| Command | Description |
|---------|-------------|
| ./scripts/ai-routing.sh enable | Split: AI to internet, default to test network |
| ./scripts/ai-routing.sh disable | Restore normal routing |
| ./scripts/ai-routing.sh status | Show current routing state |

## Testing

After enabling:

    cd tests && ./test-routing.sh enable

After disabling:

    cd tests && ./test-routing.sh disable

## Configuration

Edit config.env:

| Variable | Description |
|----------|-------------|
| ETH_IF | Internet-connected interface (e.g., eth0, enp3s0) |
| ETH_GW | Gateway IP for internet interface |
| WIFI_IF | Development/test interface (e.g., wlan0, wlp2s0) |
| CLAUDE_ROUTES | IP ranges to route through internet |

### Default AI Routes

The default configuration routes these ranges through the internet interface:

- 160.79.104.0/24 - Anthropic Claude API
- 34.36.0.0/16 - Google Cloud
- 34.149.0.0/16 - Google Cloud
- 142.250.0.0/16 - Google

Add custom routes in config.env if your AI tools use other IP ranges.

## Requirements

- Linux with iproute2 (ip command)
- Two network interfaces (e.g., Ethernet + WiFi)
- sudo access for route changes

## How It Works

1. Enable: Adds specific routes for AI service IPs via Ethernet, changes default route to WiFi
2. Disable: Removes specific routes, restores default route to Ethernet
3. Routes are managed with ip route add/del/replace

## License

MIT
