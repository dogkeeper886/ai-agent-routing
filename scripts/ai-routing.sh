#!/bin/bash
# AI Agent Routing Script
# Enables split routing: AI agents use internet, other traffic uses secondary interface
# Uses NetworkManager (nmcli) for persistent route configuration
#
# Usage: ./ai-routing.sh {enable|disable|status}

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load configuration
if [ ! -f "$PROJECT_DIR/config.env" ]; then
    echo "Error: config.env not found"
    echo "Copy config.env.example to config.env and edit for your machine:"
    echo "  cp $PROJECT_DIR/config.env.example $PROJECT_DIR/config.env"
    exit 1
fi
source "$PROJECT_DIR/config.env"

# Get gateway IP for a connection (from DHCP or manual config)
get_gateway() {
    if [ "$INET_GW" = "dhcp" ]; then
        # Get gateway from current route table for this interface
        local gw=$(ip route show dev "$INET_IF" 2>/dev/null | grep -oP 'default via \K[\d.]+' || true)
        if [ -z "$gw" ]; then
            # Try getting from nmcli connection details
            gw=$(nmcli -g IP4.GATEWAY connection show "$INET_CONN" 2>/dev/null | head -1)
        fi
        if [ -z "$gw" ]; then
            echo "Error: Could not detect gateway for $INET_CONN" >&2
            echo "Set INET_GW manually in config.env or ensure connection is active" >&2
            exit 1
        fi
        echo "$gw"
    else
        echo "$INET_GW"
    fi
}

# Verify connection exists
verify_connection() {
    local conn=$1
    if ! nmcli connection show "$conn" &>/dev/null; then
        echo "Error: NetworkManager connection '$conn' not found"
        echo "List available connections with: nmcli connection show"
        exit 1
    fi
}

enable() {
    echo "Enabling AI agent routing..."
    echo "  AI traffic -> $INET_CONN ($INET_IF)"
    echo "  Default traffic -> $DEV_IF"
    echo ""

    verify_connection "$INET_CONN"

    # Get gateway (auto-detect if dhcp)
    local gateway=$(get_gateway)
    echo "Gateway: $gateway"
    echo ""

    # Build route string for nmcli (format: "ip/prefix gateway")
    local route_str=""
    for route in $AI_ROUTES; do
        if [ -n "$route_str" ]; then
            route_str="$route_str, $route $gateway"
        else
            route_str="$route $gateway"
        fi
    done

    echo "Configuring NetworkManager connection '$INET_CONN'..."

    # Add static routes for AI services
    echo "  Adding AI service routes..."
    sudo nmcli connection modify "$INET_CONN" ipv4.routes "$route_str"

    # Prevent this connection from being the default route
    echo "  Setting never-default=yes..."
    sudo nmcli connection modify "$INET_CONN" ipv4.never-default yes

    # Reapply connection to activate changes
    echo "  Reapplying connection..."
    sudo nmcli connection up "$INET_CONN" 2>/dev/null || true

    # Check dev interface default route
    local dev_gw=$(ip route show dev "$DEV_IF" 2>/dev/null | grep -oP 'default via \K[\d.]+' || true)
    echo ""
    if [ -n "$dev_gw" ]; then
        echo "Default route: $DEV_IF via $dev_gw"
    else
        echo "Warning: No default route on $DEV_IF yet (connect to activate)"
    fi

    echo ""
    echo "Done. Routes are managed by NetworkManager and will persist."
}

disable() {
    echo "Disabling AI agent routing..."
    echo ""

    verify_connection "$INET_CONN"

    echo "Restoring NetworkManager connection '$INET_CONN'..."

    # Remove static routes
    echo "  Removing AI service routes..."
    sudo nmcli connection modify "$INET_CONN" ipv4.routes ""

    # Allow connection to be default route again
    echo "  Setting never-default=no..."
    sudo nmcli connection modify "$INET_CONN" ipv4.never-default no

    # Reapply connection
    echo "  Reapplying connection..."
    sudo nmcli connection up "$INET_CONN" 2>/dev/null || true

    echo ""
    echo "Done. All traffic -> $INET_CONN ($INET_IF)"
}

status() {
    echo "=== NetworkManager Connections ==="
    echo "Internet: $INET_CONN ($INET_IF)"
    echo "Dev:      ${DEV_CONN:-auto} ($DEV_IF)"
    echo ""

    echo "=== Connection Settings ==="
    local never_default=$(nmcli -g ipv4.never-default connection show "$INET_CONN" 2>/dev/null)
    local routes=$(nmcli -g ipv4.routes connection show "$INET_CONN" 2>/dev/null)
    echo "never-default: $never_default"
    echo "ipv4.routes:   ${routes:-none}"
    echo ""

    echo "=== Network Interfaces ==="
    ip -br addr show "$INET_IF" "$DEV_IF" 2>/dev/null || true
    echo ""

    echo "=== Active Routes ==="
    echo "Default route:"
    ip route show default | head -1
    echo ""
    echo "AI routes:"
    for route in $AI_ROUTES; do
        local r=$(ip route show "$route" 2>/dev/null)
        if [ -n "$r" ]; then
            echo "  $r"
        else
            echo "  $route: not active"
        fi
    done
    echo ""

    echo "=== Route Tests ==="
    echo -n "AI (160.79.104.10):  "
    ip route get 160.79.104.10 2>/dev/null | grep -oP 'dev \K\S+' || echo "unreachable"
    echo -n "Default (8.8.8.8):   "
    ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\S+' || echo "unreachable"
}

case "${1:-}" in
    enable)  enable ;;
    disable) disable ;;
    status)  status ;;
    *)
        echo "AI Agent Routing Script"
        echo ""
        echo "Split network traffic so AI coding agents maintain internet access"
        echo "while other applications use a secondary network (e.g., captive portal)."
        echo ""
        echo "Uses NetworkManager (nmcli) for persistent route configuration."
        echo ""
        echo "Usage: $0 {enable|disable|status}"
        echo ""
        echo "  enable   - Route AI traffic to internet, default to dev interface"
        echo "  disable  - Restore normal routing (all traffic to internet connection)"
        echo "  status   - Show current routing state and NM configuration"
        echo ""
        echo "Configuration: edit config.env (copy from config.env.example)"
        exit 1
        ;;
esac
