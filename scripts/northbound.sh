#!/bin/bash
# 北向资金流向 via 东方财富 API
set -euo pipefail

command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq 2>/dev/null || true

echo "=== 🧭 北向资金流向 ==="
echo ""

# East Money northbound fund flow
data=$(curl -sf --connect-timeout 10 \
    "https://push2.eastmoney.com/api/qt/kamt.kline/get?fields1=f1,f2,f3,f4&fields2=f51,f52,f53&klt=103&lmt=1" \
    2>/dev/null) || {
    echo "❌ 数据获取失败（非交易日无数据）"
    exit 0
}

# Parse latest northbound data
echo "$data" | jq -r '
    .data.klineInfos[]? |
    "📅 日期: \(.date_str)\n" +
    "资金余额: ¥\(.f52) 亿 | 资金占比: \(.f53)%"
' 2>/dev/null

# Daily net flow
daily=$(curl -sf --connect-timeout 10 \
    "https://push2.eastmoney.com/api/qt/kamt.kline/get?fields1=f1,f2,f3,f4&fields2=f51,f52,f53&klt=101&lmt=5" \
    2>/dev/null) || true

if [[ -n "$daily" ]]; then
    echo ""
    echo "📊 近5日净流入（亿元）:"
    echo "$daily" | jq -r '
        .data.klineInfos[]? |
        "  \(.date_str): \(.f52) 亿"
    ' 2>/dev/null
fi

echo ""
echo "💡 北向资金 = 沪股通 + 深股通"
echo "💡 净流入为正表示外资买入A股"
echo "💡 数据来源: 东方财富"
