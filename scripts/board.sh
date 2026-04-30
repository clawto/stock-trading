#!/bin/bash
# 板块/概念行情 via 东方财富
set -euo pipefail

command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq 2>/dev/null || true

usage() {
    cat << EOF
Usage: board.sh [options]

Options:
  -t, --type TYPE   sector (行业板块) | concept (概念板块) | region (地域板块)
  -l, --limit N     Results limit (default: 10)
  -h, --help        Show this help
EOF
}

TYPE="sector"
LIMIT=10

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--type) TYPE="$2"; shift 2 ;;
        -l|--limit) LIMIT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) shift ;;
    esac
done

# Map type to East Money fs code
case "$TYPE" in
    sector)  FS="m:90+t2"; TNAME="行业板块" ;;
    concept) FS="m:90+t3"; TNAME="概念板块" ;;
    region)  FS="m:90+t1"; TNAME="地域板块" ;;
    *)       FS="m:90+t2"; TNAME="行业板块" ;;
esac

echo "=== 📊 ${TNAME} 涨幅 TOP${LIMIT} ==="
echo ""

data=$(curl -sf --connect-timeout 10 \
    "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=${LIMIT}&po=1&np=1&fields=f2,f3,f4,f12,f14,f15,f16,f17&fid=f3&fs=${FS}" \
    2>/dev/null) || {
    echo "❌ 数据获取失败（非交易时间可能无数据）"
    exit 0
}

echo "$data" | jq -r --argjson limit "$LIMIT" '
    .data.diff[:$limit][]? |
    "\((if (.f3 | tonumber) > 0 then "📈" elif (.f3 | tonumber) < 0 then "📉" else "➡️" end)) \(.f14) | \(.f3)% | 领涨股: \(.f15 // "N/A") | 涨家:\(.f16 // "-") 跌家:\(.f17 // "-")"
' 2>/dev/null

echo ""
echo "💡 数据来源: 东方财富"
