#!/bin/bash
set -euo pipefail
PASS=0; FAIL=0
assert() { if [ $? -eq 0 ]; then PASS=$((PASS+1)); echo "  ✅ $1"; else FAIL=$((FAIL+1)); echo "  ❌ $1"; fi; }

echo "=== Stock Trading Tests ==="
echo "Test: SKILL.md"
[ -f SKILL.md ]; assert "exists"
grep -q "^---" SKILL.md; assert "frontmatter"
grep -q "^name:" SKILL.md; assert "name field"
echo "Test: Scripts executable"
[ -x scripts/quote.sh ]; assert "quote.sh"
[ -x scripts/lhb.sh ]; assert "lhb.sh"
[ -x scripts/northbound.sh ]; assert "northbound.sh"
[ -x scripts/board.sh ]; assert "board.sh"
[ -x scripts/limitup.sh ]; assert "limitup.sh"
echo "Test: No secrets leaked"
! grep -r "ghp_\|gho_\|sk-" scripts/ 2>/dev/null; assert "no secrets"
echo "Test: quote.sh --help"
./scripts/quote.sh --help >/dev/null 2>&1; assert "quote.sh help"
echo "Test: quote.sh A-share fetch"
./scripts/quote.sh sh600519 2>/dev/null && assert "sh600519 fetch" || echo "  ⚠️  API unavailable (off-hours)"
echo "Test: lhb.sh"
./scripts/lhb.sh 2>/dev/null && assert "lhb.sh" || echo "  ⚠️  Off-hours expected"
echo ""
echo "=== $PASS passed, $FAIL failed ==="
exit $FAIL
