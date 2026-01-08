# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Routing scripts to maintain AI agent internet connectivity while developing on isolated networks (captive portals, test WiFi, IoT networks).

## Setup

    cp config.env.example config.env
    # Edit config.env with your interface names (find with: ip link show)

## Commands

### Routing Control (requires sudo)

    ./scripts/ai-routing.sh enable   # Split traffic: AI to internet, default to test network
    ./scripts/ai-routing.sh disable  # Restore normal routing
    ./scripts/ai-routing.sh status   # Show current routing state

### Testing

    ./scripts/ai-routing.sh enable && cd tests && ./test-routing.sh enable
    ./scripts/ai-routing.sh disable && cd tests && ./test-routing.sh disable

## Architecture

Uses Linux policy-based routing (iproute2):
- `ip route add` pins specific IP ranges (AI services) to the internet interface
- `ip route replace default` switches default route to the test interface
- config.env defines CLAUDE_ROUTES for AI service IP ranges

## Git Workflow

- Create feature branches: `git checkout -b feature/description`
- Never commit directly to main
- Open PR for review before merging
