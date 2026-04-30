---
name: stock-trading
description: "实时A股/港股/美股行情，龙虎榜，北向资金，技术分析。Trigger on: A股, 港股, 美股, 股票, 行情, 涨停, 跌停, 龙虎榜, 北向资金, 基金, stock, 上证, 深证, 创业板, 科创板, 恒生, 纳斯达克, 标普500, 成交量, K线, 均线, RSI, MACD."
version: 1.0.0
license: MIT
---

# Stock Trading 📈

Real-time Chinese A-share, HK, and US stock market data for OpenClaw agents.

## What it does

- **A-share real-time**: 沪深两市实时行情，板块涨跌
- **龙虎榜数据**: 当日龙虎榜席位分析
- **北向资金**: 沪股通/深股通资金流向
- **港股行情**: 恒生指数及热门港股
- **美股行情**: 纳斯达克/标普500成分股
- **技术指标**: 均线、RSI、MACD、布林带
- **涨停板扫描**: 涨停原因分析，连板统计
- **自选股追踪**: 自定义股票池监控

## Trigger Conditions

Activate when user asks about:
- 股票行情、涨跌幅、成交量
- 龙虎榜、机构席位、游资动向
- 北向资金、外资流向
- 板块热点、概念股
- 涨停板、跌停板
- 技术分析指标
- 基金、ETF行情

## Prerequisites

- `curl`, `jq` (auto-installed if missing)
- Internet access

## Installation

```
clawhub install clawto/stock-trading
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/quote.sh` | 实时股票行情 |
| `scripts/lhb.sh` | 龙虎榜数据 |
| `scripts/northbound.sh` | 北向资金流向 |
| `scripts/board.sh` | 板块/概念行情 |
| `scripts/technical.sh` | 技术指标计算 |
| `scripts/limitup.sh` | 涨停板扫描 |

## Usage

```
# 查询个股
> 贵州茅台行情如何？

📊 贵州茅台 (600519) | ¥1,850.00 | +2.3%
量比: 1.35 | 换手: 0.8% | 市值: ¥23.2万亿

# 龙虎榜
> 今天龙虎榜有什么看点？

🏦 龙虎榜净买入 TOP5:
1. 科大讯飞 (002230) | 净买入 ¥3.2亿 | 机构买入 ¥2.1亿
2. 中际旭创 (300308) | 净买入 ¥2.8亿 | 深股通 ¥1.5亿

# 北向资金
> 北向资金今天流向？

🔴 北向资金今日净流出 ¥48.3亿
沪股通: -23.1亿 | 深股通: -25.2亿
```

## 🫶 Support

If this skill helps you profit, consider donating:

| Coin | Address |
|------|---------|
| BTC | `bc1qxy2kgdygjrsqtzq2n0yrf2493p3q5k3v7dw9lx` |
| ETH | `0x71C7656EC7ab88b098defB751B7401B5f6d8976F` |

## License

MIT
