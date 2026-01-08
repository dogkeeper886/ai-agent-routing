#!/bin/bash
# AI Agent Routing Script
# Enables split routing: AI agents use internet, other traffic uses secondary interface
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

enable() {
    echo "Enabling AI agent routing..."
    echo "  AI traffic -> $ETH_IF (internet)"
    echo "  Other traffic -> $WIFI_IF"
    echo ""

    echo "Adding pinned routes for AI services..."
    for route in $CLAUDE_ROUTES; do
        sudo ip route add $route via $ETH_GW dev $ETH_IF 2>/dev/null || echo "  $route already exists"
    done

    echo ""
    echo "Detecting $WIFI_IF gateway..."
    WIFI_GW=$(ip route show dev $WIFI_IF 2>/dev/null | grep -oP 'default via \K[\d.]+' || true)

    if [ -z "$WIFI_GW" ]; then
        echo "Error: No gateway on $WIFI_IF"
        echo "Make sure $WIFI_IF is connected to a network"
        exit 1
    fi

    echo "Switching default route to $WIFI_IF via $WIFI_GW..."
    sudo ip route replace default via $WIFI_GW dev $WIFI_IF

    echo ""
    echo "Done. AI agents -> $ETH_IF, default -> $WIFI_IF"
}

disable() {
    echo "Disabling AI agent routing..."
    echo ""

    echo "Restoring default route to $ETH_IF via $ETH_GW..."
    sudo ip route replace default via $ETH_GW dev $ETH_IF

    echo ""
    echo "Removing pinned AI routes..."
    for route in $CLAUDE_ROUTES; do
        sudo ip route del $route 2>/dev/null || echo "  $route not found"
    done

    echo ""
    echo "Done. All traffic -> $ETH_IF"
}

status() {
    echo "=== Network Interfaces ==="
    ip -br addr show $ETH_IF $WIFI_IF 2>/dev/null || true

    echo ""
    echo "=== Default Route ==="
    ip route show default | head -1

    echo ""
    echo "=== AI Agent Routes ==="
    for route in $CLAUDE_ROUTES; do
        ip route show $route 2>/dev/null || echo "  $route: not set"
    done

    echo ""
    echo "=== Route Tests ==="
    echo -n "AI (160.79.104.10):  "; ip route get 160.79.104.10 2>/dev/null | grep -oP 'dev \K\S+' || echo "unreachable"
    echo -n "Default (8.8.8.8):   "; ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\S+' || echo "unreachable"
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
        echo "Usage: $0 {enable|disable|status}"
        echo ""
        echo "  enable   - Route AI traffic to internet, default to secondary interface"
        echo "  disable  - Restore normal routing (all traffic to primary interface)"
        echo "  status   - Show current routing state"
        echo ""
        echo "Configuration: edit config.env (copy from config.env.example)"
        exit 1
        ;;
esac
