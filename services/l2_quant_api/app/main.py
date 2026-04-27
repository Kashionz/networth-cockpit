from __future__ import annotations

import os
import logging
from datetime import datetime, timezone
from typing import Literal

import httpx
from fastapi import FastAPI
from pydantic import BaseModel, Field

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


class MonthlyAnalysisRequest(BaseModel):
    month: str = Field(pattern=r"^\d{4}-\d{2}$")
    income: float = Field(ge=0)
    expense: float = Field(ge=0)
    top_categories: list[CategorySpend] = Field(default_factory=list)
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


def _generate_llm_insight(
    request: MonthlyAnalysisRequest,
    net_saving: float,
    savings_rate_pct: float,
    top_category: str | None,
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
        f"top_category={top_category or 'N/A'}, notes={request.notes or 'N/A'}."
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
    )

    return MonthlyAnalysisResponse(
        month=payload.month,
        net_saving=round(net_saving, 2),
        savings_rate_pct=round(savings_rate_pct, 2),
        top_category=top_category,
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
