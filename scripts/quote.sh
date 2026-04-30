#!/bin/bash
# Stock quote fetcher using free Sina/EastMoney APIs
set -euo pipefail

command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq 2>/dev/null || true

usage() {
    cat << EOF
Usage: quote.sh [options] <stock_code...>

Stock code format:
  A-share:   sh600519 (贵州茅台), sz000001 (平安银行)
  HK stock:  hk00700  (腾讯), hk09988 (阿里)
  US stock:  usAAPL   (Apple), usTSLA (Tesla)

Options:
  -m, --market MARKET  Market filter: a|hk|us (default: all)
  -f, --format FMT     Output: text|json|csv (default: text)
  -h, --help           Show this help

Examples:
  quote.sh sh600519 sz000001
  quote.sh hk00700 hk09988 usAAPL
  quote.sh --market a sh600519 sh601318
EOF
}

MARKET=""
FORMAT="text"
CODES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--market) MARKET="$2"; shift 2 ;;
        -f|--format) FORMAT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) CODES+=("$1"); shift ;;
    esac
done

if [[ ${#CODES[@]} -eq 0 ]]; then
    usage; exit 1
fi

# Sina API fetch
fetch_sina() {
    local codes_str
    codes_str=$(IFS=,; echo "${CODES[*]}")
    local url="https://hq.sinajs.cn/list=${codes_str}"
    
    curl -sf --connect-timeout 10 \
        -H "Referer: https://finance.sina.com.cn" \
        "$url" 2>/dev/null || {
        echo "❌ Sina API unavailable"
        return 1
    }
}

# Parse Sina A-share data: var hq_str_sh600519="name,open,close,price,high,low,..."
parse_ashare() {
    local raw="$1" code="$2"
    
    # Extract the quoted string
    local data
    data=$(echo "$raw" | grep "hq_str_${code}" | sed 's/.*="//' | sed 's/";$//')
    
    if [[ -z "$data" ]]; then
        echo "  ❌ $code: 无数据"
        return
    fi
    
    IFS=',' read -ra F <<< "$data"
    local name="${F[0]}"
    local open="${F[1]}"
    local yest_close="${F[2]}"
    local price="${F[3]}"
    local high="${F[4]}"
    local low="${F[5]}"
    local volume="${F[8]}"
    local amount="${F[9]}"
    
    local change_pct=0
    if [[ "$yest_close" != "0" && -n "$yest_close" ]]; then
        change_pct=$(echo "scale=2; ($price - $yest_close) / $yest_close * 100" | bc 2>/dev/null || echo "0")
    fi
    
    local arrow="➡️"
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📈"
    (( $(echo "$change_pct < 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📉"
    
    local sign=""
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && sign="+"
    
    printf "%s %s (%s) | ¥%s (%s%s%%) | O:%s H:%s L:%s | 成交额:%s\n" \
        "$arrow" "$name" "${code^^}" "$price" "$sign" "$change_pct" "$open" "$high" "$low" "$amount"
}

# Parse Sina HK data
parse_hk() {
    local raw="$1" code="$2"
    local data
    data=$(echo "$raw" | grep "hq_str_${code}" | sed 's/.*="//' | sed 's/";$//')
    
    if [[ -z "$data" ]]; then
        echo "  ❌ $code: 无数据"
        return
    fi
    
    IFS=',' read -ra F <<< "$data"
    local name="${F[1]}"
    local open="${F[2]}"
    local yest_close="${F[3]}"
    local price="${F[6]}"
    local high="${F[4]}"
    local low="${F[5]}"
    
    local change_pct=0
    if [[ "$yest_close" != "0" && -n "$yest_close" ]]; then
        change_pct=$(echo "scale=2; ($price - $yest_close) / $yest_close * 100" | bc 2>/dev/null || echo "0")
    fi
    
    local arrow="➡️"
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📈"
    (( $(echo "$change_pct < 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📉"
    
    local sign=""
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && sign="+"
    
    printf "%s %s (%s) | HK\$%s (%s%s%%) | O:HK\$%s H:HK\$%s L:HK\$%s\n" \
        "$arrow" "$name" "${code^^}" "$price" "$sign" "$change_pct" "$open" "$high" "$low"
}

# Parse Sina US data
parse_us() {
    local raw="$1" code="$2"
    local data
    data=$(echo "$raw" | grep "hq_str_${code}" | sed 's/.*="//' | sed 's/";$//')
    
    if [[ -z "$data" ]]; then
        echo "  ❌ $code: 无数据"
        return
    fi
    
    IFS=',' read -ra F <<< "$data"
    local name="${F[0]}"
    local price="${F[1]}"
    local change_pct="${F[2]}"
    local open="${F[5]}"
    local high="${F[6]}"
    local low="${F[7]}"
    
    local arrow="➡️"
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📈"
    (( $(echo "$change_pct < 0" | bc -l 2>/dev/null || echo 0) )) && arrow="📉"
    
    local sign=""
    (( $(echo "$change_pct > 0" | bc -l 2>/dev/null || echo 0) )) && sign="+"
    
    printf "%s %s (%s) | \$%s (%s%s%%) | O:\$%s H:\$%s L:\$%s\n" \
        "$arrow" "$name" "${code^^}" "$price" "$sign" "$change_pct" "$open" "$high" "$low"
}

main() {
    local raw_data
    raw_data=$(fetch_sina)
    
    for code in "${CODES[@]}"; do
        case "$code" in
            sh*|sz*) parse_ashare "$raw_data" "$code" ;;
            hk*)     parse_hk "$raw_data" "$code" ;;
            us*|gb_*) parse_us "$raw_data" "$code" ;;
            *)       echo "  ❌ Unknown code format: $code (use sh600519/sz000001/hk00700/usAAPL)" ;;
        esac
    done
    
    echo ""
    echo "💡 数据来源: 新浪财经 | 延时15分钟左右"
    echo "💡 如需实时行情，建议使用东方财富或同花顺付费API"
}

main
