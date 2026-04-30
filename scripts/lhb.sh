#!/bin/bash
# 龙虎榜数据 via 东方财富 API
set -euo pipefail

command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq 2>/dev/null || true

usage() {
    cat << EOF
Usage: lhb.sh [options]

Options:
  -d, --date DATE   Date in YYYY-MM-DD (default: today)
  -l, --limit N     Max stocks to show (default: 10)
  -h, --help        Show this help
EOF
}

DATE=$(date +%Y-%m-%d)
LIMIT=10

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--date) DATE="$2"; shift 2 ;;
        -l|--limit) LIMIT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) shift ;;
    esac
done

echo "=== 🏦 龙虎榜 TOP${LIMIT} ($DATE) ==="
echo ""

# East Money LHB API (free, no key needed)
data=$(curl -sf --connect-timeout 10 \
    "https://push2his.eastmoney.com/api/qt/stock/fflow/daykline/get?fields1=f1,f2,f3&fields2=f51,f52,f53,f54,f55,f56,f57&secid=90.BK0707&klt=101" \
    2>/dev/null) || {
    echo "⚠️  East Money API unavailable (market hours only)"
    echo ""
    echo "💡 龙虎榜数据仅在交易日 16:00 后更新"
    exit 0
}

# Try LHB billboard API
lhb_data=$(curl -sf --connect-timeout 10 \
    "https://datacenter.eastmoney.com/securities/api/data/v1/get?reportName=RPT_DAILYBILLBOARD_DETAILSNEW&columns=ALL&sortColumns=SECURITY_CODE&sortTypes=1&pageSize=${LIMIT}&pageNumber=1&filter=(TRADE_DATE%3D%27${DATE}%27)" \
    2>/dev/null) || {
    echo "⚠️ 暂无今日龙虎榜数据（盘后更新）"
    echo ""
    echo "=== 热门板块资金流向 ==="
    
    # Show sector fund flow instead
    flow=$(curl -sf --connect-timeout 10 \
        "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=10&po=1&np=1&fields=f2,f3,f4,f12,f14&fid=f3&fs=m:90+t2" \
        2>/dev/null) || true
    
    if [[ -n "$flow" ]]; then
        echo "$flow" | jq -r '
            .data.diff[]? | 
            "📊 \(.f14) | 涨跌: \(.f3)% | 最新: \(.f2) | 代码: \(.f12)"
        ' 2>/dev/null || echo "无板块数据"
    fi
    exit 0
}

# Parse LHB data
echo "$lhb_data" | jq -r --argjson limit "$LIMIT" '
    .result.data[:$limit][]? |
    "📊 \(.SECURITY_NAME_ABBR) (\(.SECURITY_CODE)) | 涨跌: \(.CHANGE_RATE)% | 净买入: \(.NET_BUY_AMT)元 | 上榜原因: \(.BILLBOARD_NET_AMT)"
' 2>/dev/null || echo "解析异常，请查看原始数据"

echo ""
echo "💡 数据来源: 东方财富 | 龙虎榜盘后发布"
