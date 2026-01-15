#!/bin/bash
# Test cases for AI agent routing (nmcli-based)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/config.env"

PASS=0
FAIL=0

pass() {
    echo "  [PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  [FAIL] $1"
    FAIL=$((FAIL + 1))
}

check() {
    if eval "$2"; then
        pass "$1"
    else
        fail "$1"
    fi
}

test_enable() {
    echo ""
    echo "=== Tests after 'enable' ==="

    # NetworkManager configuration tests
    echo ""
    echo "--- NM Connection Settings ---"

    check "never-default is enabled on $INET_CONN" \
        "nmcli -g ipv4.never-default connection show \"$INET_CONN\" | grep -q 'yes'"

    check "ipv4.routes configured on $INET_CONN" \
        "nmcli -g ipv4.routes connection show \"$INET_CONN\" | grep -q '160.79.104.0/24'"

    # Route tests
    echo ""
    echo "--- Active Routes ---"

    check "Anthropic API (160.79.104.0/24) routes via $INET_IF" \
        "ip route get 160.79.104.10 | grep -q 'dev $INET_IF'"

    check "Google Cloud (34.36.0.0/16) routes via $INET_IF" \
        "ip route get 34.36.1.1 | grep -q 'dev $INET_IF'"

    check "Google Cloud (34.149.0.0/16) routes via $INET_IF" \
        "ip route get 34.149.1.1 | grep -q 'dev $INET_IF'"

    check "Google (142.250.0.0/16) routes via $INET_IF" \
        "ip route get 142.250.1.1 | grep -q 'dev $INET_IF'"

    check "Default route via $DEV_IF" \
        "ip route show default | head -1 | grep -q 'dev $DEV_IF'"

    check "Regular traffic (8.8.8.8) routes via $DEV_IF" \
        "ip route get 8.8.8.8 | grep -q 'dev $DEV_IF'"
}

test_disable() {
    echo ""
    echo "=== Tests after 'disable' ==="

    # NetworkManager configuration tests
    echo ""
    echo "--- NM Connection Settings ---"

    check "never-default is disabled on $INET_CONN" \
        "nmcli -g ipv4.never-default connection show \"$INET_CONN\" | grep -q 'no'"

    check "ipv4.routes cleared on $INET_CONN" \
        "[ -z \"\$(nmcli -g ipv4.routes connection show \"$INET_CONN\")\" ]"

    # Route tests
    echo ""
    echo "--- Active Routes ---"

    check "Default route via $INET_IF" \
        "ip route show default | head -1 | grep -q 'dev $INET_IF'"

    check "No pinned route for 160.79.104.0/24" \
        "! ip route show 160.79.104.0/24 2>/dev/null | grep -q 'via'"

    check "Regular traffic (8.8.8.8) routes via $INET_IF" \
        "ip route get 8.8.8.8 | grep -q 'dev $INET_IF'"
}

test_status() {
    echo ""
    echo "=== Tests for 'status' ==="

    check "'ai-routing.sh status' runs successfully" \
        "$PROJECT_DIR/scripts/ai-routing.sh status > /dev/null 2>&1"
}

case "${1:-}" in
    enable)
        test_enable
        ;;
    disable)
        test_disable
        ;;
    status)
        test_status
        ;;
    *)
        echo "Usage: $0 {enable|disable|status}"
        echo ""
        echo "Run tests after executing the corresponding command:"
        echo "  ../scripts/ai-routing.sh enable  && ./test-routing.sh enable"
        echo "  ../scripts/ai-routing.sh disable && ./test-routing.sh disable"
        exit 1
        ;;
esac

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] || exit 1
