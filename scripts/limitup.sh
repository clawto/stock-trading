#!/bin/bash
# 涨停板扫描 via 东方财富
set -euo pipefail

command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq 2>/dev/null || true

echo "=== 🔥 涨停板扫描 ==="
echo ""

# Modified approach: use the list API filtered by change_pct >= 9.9
data=$(curl -sf --connect-timeout 10 \
    "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=20&po=1&np=1&fields=f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f14&fid=f3&fs=m:0+t:6,m:0+t:80,m:0+t:81,m:0+t:82&fltt=2" \
    2>/dev/null) || {
    echo "❌ 数据获取失败（非交易时间数据不更新）"
    exit 0
}

echo "$data" | jq -r '
    .data.diff[]? |
    select((.f3 | tonumber) >= 9.5) |
    "🔥 \(.f14) (\(.f12)) | +\(.f3)% | 现价: ¥\(.f2) | 成交额: \(.f7 // "N/A") | 换手: \(.f8)%"
' 2>/dev/null || echo "当前无涨停个股或非交易时间"

echo ""
echo "💡 仅显示涨幅≥9.5%个股 | 数据来源: 东方财富"
echo "💡 ST/*ST/科创/创业板涨跌幅限制不同"
