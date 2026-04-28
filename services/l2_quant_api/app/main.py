from __future__ import annotations

import os
import logging
from datetime import datetime, timezone
from typing import Literal

import httpx
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field

from .quant import (
    annualized_return,
    annualized_volatility,
    benchmark_diff,
    calc_returns,
    max_drawdown,
    sharpe_ratio,
    stress_test,
)

app = FastAPI(
    title="NetWorth Cockpit L2 Quant API",
    version="0.1.0",
    description="L2 quant analysis skeleton with safe LLM fallback.",
)
logger = logging.getLogger(__name__)


class HealthResponse(BaseModel):
    status: Literal["ok"]
    service: str
    now_utc: str


class CategorySpend(BaseModel):
    category: str = Field(min_length=1, max_length=80)
    amount: float = Field(ge=0)


class PriceHistoryPoint(BaseModel):
    date: str = Field(min_length=1, max_length=40)
    close: float


class MonthlyAnalysisRequest(BaseModel):
    month: str = Field(pattern=r"^\d{4}-\d{2}$")
    income: float = Field(ge=0)
    expense: float = Field(ge=0)
    top_categories: list[CategorySpend] = Field(default_factory=list)
    price_history: list[PriceHistoryPoint] = Field(default_factory=list)
    benchmark_history: list[PriceHistoryPoint] | None = None
    notes: str | None = Field(default=None, max_length=500)


class LlmInsight(BaseModel):
    mode: Literal["template_fallback", "openai", "openai_fallback"]
    text: str
    reason: str | None = None


class MonthlyAnalysisResponse(BaseModel):
    month: str
    net_saving: float
    savings_rate_pct: float
    top_category: str | None
    sharpe_ratio: float | None = None
    annualized_volatility: float | None = None
    max_drawdown_pct: float | None = None
    benchmark_diff_pct: float | None = None
    stress_test_result: dict | None = None
    recommendations: list[str]
    llm_insight: LlmInsight


class MerchantClassifyRequest(BaseModel):
    merchant_name: str = Field(min_length=1, max_length=120)
    amount: float | None = Field(default=None, ge=0)
    memo: str | None = Field(default=None, max_length=250)


class MerchantClassifyResponse(BaseModel):
    merchant_name: str
    category: str
    confidence: float = Field(ge=0, le=1)
    matched_keyword: str | None = None
    rationale: str


def _template_guidance(
    month: str,
    net_saving: float,
    savings_rate_pct: float,
    top_category: str | None,
) -> str:
    category_text = top_category or "一般支出"
    return (
        f"{month} 的淨結餘為 {net_saving:.0f}，儲蓄率約 {savings_rate_pct:.1f}%。"
        f" 建議先檢視 {category_text} 的固定支出，"
        "每週微調一項項目以維持穩定改善節奏。"
    )


def _extract_openai_text(payload: dict) -> str:
    output = payload.get("output", [])
    if not isinstance(output, list):
        return ""

    parts: list[str] = []
    for item in output:
        if not isinstance(item, dict):
            continue
        content = item.get("content", [])
        if not isinstance(content, list):
            continue
        for chunk in content:
            if not isinstance(chunk, dict):
                continue
            text = chunk.get("text")
            if isinstance(text, str) and text.strip():
                parts.append(text.strip())

    return "\n".join(parts).strip()


def _history_to_price_series(history: list[PriceHistoryPoint] | None) -> pd.Series:
    if not history:
        return pd.Series(dtype=float)

    frame = pd.DataFrame([{"date": item.date, "close": item.close} for item in history])
    if frame.empty:
        return pd.Series(dtype=float)

    frame["date"] = pd.to_datetime(frame["date"], errors="coerce", utc=True)
    frame["close"] = pd.to_numeric(frame["close"], errors="coerce")
    frame = frame.dropna(subset=["date", "close"]).sort_values("date")
    if frame.empty:
        return pd.Series(dtype=float)

    return pd.Series(frame["close"].values, index=frame["date"], dtype=float)


def _build_quant_summary(
    annual_ret: float | None,
    volatility: float | None,
    sharpe: float | None,
    drawdown_pct: float | None,
    benchmark_delta_pct: float | None,
    stress_results: dict | None,
) -> str:
    stress_brief = "N/A"
    if isinstance(stress_results, dict) and stress_results:
        chunks: list[str] = []
        for scenario_name, scenario_result in stress_results.items():
            if isinstance(scenario_result, dict) and scenario_result.get("ok"):
                chunks.append(
                    f"{scenario_name}(shock_pct={scenario_result.get('shock_pct')},"
                    f" stressed_max_drawdown_pct={scenario_result.get('stressed_max_drawdown_pct')})"
                )
        if chunks:
            stress_brief = "; ".join(chunks)

    annual_ret_pct = None if annual_ret is None else annual_ret * 100.0
    parts = [
        f"annualized_return_pct={annual_ret_pct:.2f}" if annual_ret_pct is not None else "annualized_return_pct=N/A",
        f"annualized_volatility={volatility:.4f}" if volatility is not None else "annualized_volatility=N/A",
        f"sharpe_ratio={sharpe:.4f}" if sharpe is not None else "sharpe_ratio=N/A",
        f"max_drawdown_pct={drawdown_pct:.2f}" if drawdown_pct is not None else "max_drawdown_pct=N/A",
        f"benchmark_diff_pct={benchmark_delta_pct:.2f}" if benchmark_delta_pct is not None else "benchmark_diff_pct=N/A",
        f"stress_test={stress_brief}",
    ]
    return "; ".join(parts)


def _generate_llm_insight(
    request: MonthlyAnalysisRequest,
    net_saving: float,
    savings_rate_pct: float,
    top_category: str | None,
    quant_summary: str,
) -> LlmInsight:
    template = _template_guidance(
        month=request.month,
        net_saving=net_saving,
        savings_rate_pct=savings_rate_pct,
        top_category=top_category,
    )

    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    model = os.getenv("OPENAI_MODEL", "gpt-4.1-mini").strip() or "gpt-4.1-mini"

    if not api_key:
        return LlmInsight(
            mode="template_fallback",
            text=template,
            reason="OPENAI_API_KEY is missing.",
        )

    prompt = (
        "You are a calm finance assistant. Give 3 concise, neutral monthly suggestions "
        "for budgeting and cashflow. Avoid alarming wording. "
        f"Month={request.month}, income={request.income}, expense={request.expense}, "
        f"net_saving={net_saving}, savings_rate_pct={savings_rate_pct:.2f}, "
        f"top_category={top_category or 'N/A'}, notes={request.notes or 'N/A'}, "
        f"quant_summary={quant_summary}."
    )

    try:
        response = httpx.post(
            "https://api.openai.com/v1/responses",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "input": prompt,
                "max_output_tokens": 180,
            },
            timeout=8.0,
        )
        response.raise_for_status()
        payload = response.json()
        text = _extract_openai_text(payload)
        if text:
            return LlmInsight(mode="openai", text=text)

        return LlmInsight(
            mode="openai_fallback",
            text=template,
            reason="OpenAI response did not include text output.",
        )
    except Exception:  # noqa: BLE001
        logger.exception("OpenAI call failed while generating monthly insight.")
        return LlmInsight(
            mode="openai_fallback",
            text=template,
            reason="AI 服務暫時無法使用，已改用模板建議。",
        )


def _derive_recommendations(
    net_saving: float,
    savings_rate_pct: float,
    top_category: str | None,
) -> list[str]:
    recommendations: list[str] = []

    if savings_rate_pct < 10:
        recommendations.append("先將儲蓄率每月提高 1%，逐步接近 10% 以上。")
    else:
        recommendations.append("維持目前儲蓄節奏，並定期檢視自動轉帳金額。")

    if net_saving < 0:
        recommendations.append("本月支出高於收入，可先盤點可延後的非必要支出。")
    else:
        recommendations.append("本月有正向淨結餘，可優先補強預備金或降息負債。")

    if top_category:
        recommendations.append(f"追蹤 {top_category} 類別的單筆大額交易，優化預算上限。")
    else:
        recommendations.append("補齊交易分類資料，有助於下月比較趨勢。")

    return recommendations


_KEYWORD_CATEGORY = [
    ("uber", "交通"),
    ("taxi", "交通"),
    ("shell", "交通"),
    ("mrt", "交通"),
    ("starbucks", "餐飲"),
    ("mcdonald", "餐飲"),
    ("foodpanda", "餐飲"),
    ("ubereats", "餐飲"),
    ("7-11", "生活"),
    ("familymart", "生活"),
    ("netflix", "娛樂"),
    ("spotify", "娛樂"),
    ("amazon", "購物"),
    ("costco", "購物"),
    ("ikea", "居家"),
    ("hospital", "醫療"),
    ("clinic", "醫療"),
]


def _classify_merchant(name: str) -> tuple[str, float, str | None, str]:
    normalized = name.strip().lower()
    for keyword, category in _KEYWORD_CATEGORY:
        if keyword in normalized:
            return (
                category,
                0.88,
                keyword,
                f"Matched keyword '{keyword}' in merchant name.",
            )

    return (
        "其他",
        0.52,
        None,
        "No direct keyword match, assigned neutral fallback category.",
    )


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        service="l2_quant_api",
        now_utc=datetime.now(timezone.utc).isoformat(),
    )


@app.post("/analysis/monthly", response_model=MonthlyAnalysisResponse)
def analysis_monthly(payload: MonthlyAnalysisRequest) -> MonthlyAnalysisResponse:
    net_saving = payload.income - payload.expense
    savings_rate_pct = 0.0 if payload.income <= 0 else (net_saving / payload.income) * 100

    top_category = None
    if payload.top_categories:
        top = max(payload.top_categories, key=lambda item: item.amount)
        top_category = top.category

    portfolio_prices = _history_to_price_series(payload.price_history)
    benchmark_prices = _history_to_price_series(payload.benchmark_history)
    portfolio_returns = calc_returns(portfolio_prices)
    benchmark_returns = calc_returns(benchmark_prices)

    ann_return = None if portfolio_returns.empty else annualized_return(portfolio_returns)
    ann_volatility = None if portfolio_returns.empty else annualized_volatility(portfolio_returns)
    portfolio_sharpe = None if portfolio_returns.empty else sharpe_ratio(portfolio_returns)
    drawdown_pct = None if portfolio_prices.empty else max_drawdown(portfolio_prices) * 100.0

    benchmark_delta_pct = None
    if ann_return is not None and not benchmark_returns.empty:
        benchmark_ann_return = annualized_return(benchmark_returns)
        benchmark_delta_pct = benchmark_diff(ann_return, benchmark_ann_return) * 100.0

    stress_result = None
    if not portfolio_prices.empty:
        # Scenario 1: broad market shock -20%
        market_drop = stress_test(portfolio_prices, shock_pct=-0.2)
        # Scenario 2: +100bps rate-hike proxy shock (modeled as valuation pressure)
        rate_hike = stress_test(portfolio_prices, shock_pct=-0.06)
        stress_result = {
            "market_down_20pct": market_drop,
            "rate_hike_100bps": rate_hike,
        }

    quant_summary = _build_quant_summary(
        annual_ret=ann_return,
        volatility=ann_volatility,
        sharpe=portfolio_sharpe,
        drawdown_pct=drawdown_pct,
        benchmark_delta_pct=benchmark_delta_pct,
        stress_results=stress_result,
    )

    recommendations = _derive_recommendations(
        net_saving=net_saving,
        savings_rate_pct=savings_rate_pct,
        top_category=top_category,
    )
    llm_insight = _generate_llm_insight(
        request=payload,
        net_saving=net_saving,
        savings_rate_pct=savings_rate_pct,
        top_category=top_category,
        quant_summary=quant_summary,
    )

    return MonthlyAnalysisResponse(
        month=payload.month,
        net_saving=round(net_saving, 2),
        savings_rate_pct=round(savings_rate_pct, 2),
        top_category=top_category,
        sharpe_ratio=None if portfolio_sharpe is None else round(portfolio_sharpe, 4),
        annualized_volatility=None if ann_volatility is None else round(ann_volatility, 6),
        max_drawdown_pct=None if drawdown_pct is None else round(drawdown_pct, 2),
        benchmark_diff_pct=None if benchmark_delta_pct is None else round(benchmark_delta_pct, 2),
        stress_test_result=stress_result,
        recommendations=recommendations,
        llm_insight=llm_insight,
    )


@app.post("/classify/merchant", response_model=MerchantClassifyResponse)
def classify_merchant(payload: MerchantClassifyRequest) -> MerchantClassifyResponse:
    category, confidence, keyword, rationale = _classify_merchant(payload.merchant_name)

    return MerchantClassifyResponse(
        merchant_name=payload.merchant_name,
        category=category,
        confidence=confidence,
        matched_keyword=keyword,
        rationale=rationale,
    )
