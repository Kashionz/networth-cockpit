from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

SERVICE_ROOT = Path(__file__).resolve().parents[1]
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from app.quant import (
    annualized_return,
    annualized_volatility,
    benchmark_diff,
    calc_returns,
    max_drawdown,
    sharpe_ratio,
    stress_test,
)


def _series(values: list[float]) -> pd.Series:
    return pd.Series(values, dtype=float)


def test_calc_returns_computes_pct_change() -> None:
    prices = _series([100, 110, 121])
    returns = calc_returns(prices)

    assert len(returns) == 2
    assert np.allclose(returns.values, [0.1, 0.1])


def test_calc_returns_empty_or_short_series_is_safe() -> None:
    assert calc_returns(pd.Series(dtype=float)).empty
    assert calc_returns(_series([100])).empty


def test_annualized_return_matches_compounding() -> None:
    returns = _series([0.01] * 252)
    result = annualized_return(returns)

    assert math.isclose(result, (1.01**252) - 1, rel_tol=1e-9)


def test_annualized_volatility_constant_returns_is_zero() -> None:
    returns = _series([0.01] * 252)

    assert annualized_volatility(returns) == 0.0


def test_annualized_metrics_handle_invalid_series() -> None:
    invalid = pd.Series(["bad", None], dtype=object)

    assert annualized_return(invalid) == 0.0
    assert annualized_volatility(invalid) == 0.0


def test_sharpe_ratio_uses_risk_free_and_volatility() -> None:
    returns = _series([0.01, -0.02, 0.015, 0.005, -0.01, 0.02, 0.0, 0.01])
    expected = (annualized_return(returns) - 0.02) / annualized_volatility(returns)

    assert math.isclose(sharpe_ratio(returns), expected, rel_tol=1e-9)


def test_sharpe_ratio_empty_or_zero_volatility_is_safe() -> None:
    assert sharpe_ratio(pd.Series(dtype=float)) == 0.0
    assert sharpe_ratio(_series([0.01] * 12)) == 0.0


def test_max_drawdown_returns_minimum_drop() -> None:
    prices = _series([100, 120, 90, 95, 130])

    assert math.isclose(max_drawdown(prices), -0.25, rel_tol=1e-9)


def test_benchmark_diff_subtracts_benchmark_return() -> None:
    assert benchmark_diff(0.15, 0.10) == 0.05
    assert benchmark_diff(float("nan"), 0.10) == -0.10


def test_stress_test_returns_scenario_metrics() -> None:
    prices = _series([100, 120, 110, 130])

    result = stress_test(prices, shock_pct=-0.1)

    assert result["ok"] is True
    assert result["shock_pct"] == -10.0
    assert result["stressed_last_price"] == 117.0
    assert result["stressed_max_drawdown_pct"] <= result["base_max_drawdown_pct"]


def test_stress_test_handles_empty_and_invalid_shock() -> None:
    assert stress_test(pd.Series(dtype=float), shock_pct=-0.1)["ok"] is False
    assert stress_test(_series([100, 110]), shock_pct=-1.0)["ok"] is False
