from __future__ import annotations

import math

import numpy as np
import pandas as pd
from scipy import stats

_ANNUAL_PERIODS = 252
_EPSILON = 1e-12


def _to_numeric_series(values: pd.Series) -> pd.Series:
    if not isinstance(values, pd.Series):
        return pd.Series(dtype=float)

    numeric = pd.to_numeric(values, errors="coerce")
    if not isinstance(numeric, pd.Series):
        return pd.Series(dtype=float)

    cleaned = numeric.replace([np.inf, -np.inf], np.nan).dropna()
    if cleaned.empty:
        return pd.Series(dtype=float)

    return cleaned.astype(float)


def calc_returns(prices: pd.Series) -> pd.Series:
    clean_prices = _to_numeric_series(prices)
    if clean_prices.size < 2:
        return pd.Series(dtype=float)

    returns = clean_prices.pct_change().replace([np.inf, -np.inf], np.nan).dropna()
    if returns.empty:
        return pd.Series(dtype=float)

    return returns.astype(float)


def annualized_return(returns: pd.Series) -> float:
    clean_returns = _to_numeric_series(returns)
    if clean_returns.empty:
        return 0.0

    growth = float((1.0 + clean_returns).prod())
    if not math.isfinite(growth):
        return 0.0
    if growth <= 0:
        return -1.0

    periods = clean_returns.size
    return float((growth ** (_ANNUAL_PERIODS / periods)) - 1.0)


def annualized_volatility(returns: pd.Series) -> float:
    clean_returns = _to_numeric_series(returns)
    if clean_returns.size < 2:
        return 0.0

    # Use scipy to keep L2 stack aligned with PRD dependency expectations.
    daily_std = float(stats.tstd(clean_returns.to_numpy(), ddof=1))
    if not math.isfinite(daily_std):
        return 0.0

    volatility = daily_std * math.sqrt(_ANNUAL_PERIODS)
    if not math.isfinite(volatility):
        return 0.0

    return float(volatility)


def sharpe_ratio(returns: pd.Series, risk_free: float = 0.02) -> float:
    clean_returns = _to_numeric_series(returns)
    if clean_returns.empty:
        return 0.0

    risk_free_rate = float(risk_free) if math.isfinite(risk_free) else 0.0
    ann_return = annualized_return(clean_returns)
    ann_vol = annualized_volatility(clean_returns)
    if ann_vol <= _EPSILON:
        return 0.0

    ratio = (ann_return - risk_free_rate) / ann_vol
    if not math.isfinite(ratio):
        return 0.0

    return float(ratio)


def max_drawdown(prices: pd.Series) -> float:
    clean_prices = _to_numeric_series(prices)
    if clean_prices.empty:
        return 0.0

    rolling_peak = clean_prices.cummax()
    drawdowns = (clean_prices / rolling_peak) - 1.0
    drawdowns = drawdowns.replace([np.inf, -np.inf], np.nan).dropna()
    if drawdowns.empty:
        return 0.0

    result = float(drawdowns.min())
    if not math.isfinite(result):
        return 0.0

    return result


def benchmark_diff(portfolio_ret: float, benchmark_ret: float) -> float:
    portfolio = float(portfolio_ret) if math.isfinite(portfolio_ret) else 0.0
    benchmark = float(benchmark_ret) if math.isfinite(benchmark_ret) else 0.0
    return float(portfolio - benchmark)


def stress_test(prices: pd.Series, shock_pct: float) -> dict:
    clean_prices = _to_numeric_series(prices)
    if clean_prices.empty:
        return {"ok": False, "reason": "empty_price_series"}

    shock = float(shock_pct) if math.isfinite(shock_pct) else float("nan")
    shock_factor = 1.0 + shock
    if not math.isfinite(shock_factor) or shock_factor <= 0:
        return {"ok": False, "reason": "invalid_shock_pct"}

    stressed_prices = clean_prices.copy()
    stressed_prices.iloc[-1] = stressed_prices.iloc[-1] * shock_factor

    base_returns = calc_returns(clean_prices)
    stressed_returns = calc_returns(stressed_prices)

    base_drawdown = max_drawdown(clean_prices)
    stressed_drawdown = max_drawdown(stressed_prices)

    return {
        "ok": True,
        "shock_pct": round(shock * 100.0, 2),
        "base_last_price": round(float(clean_prices.iloc[-1]), 4),
        "stressed_last_price": round(float(stressed_prices.iloc[-1]), 4),
        "base_annualized_return_pct": round(annualized_return(base_returns) * 100.0, 4),
        "stressed_annualized_return_pct": round(annualized_return(stressed_returns) * 100.0, 4),
        "base_max_drawdown_pct": round(base_drawdown * 100.0, 4),
        "stressed_max_drawdown_pct": round(stressed_drawdown * 100.0, 4),
        "drawdown_delta_pct": round((stressed_drawdown - base_drawdown) * 100.0, 4),
    }
