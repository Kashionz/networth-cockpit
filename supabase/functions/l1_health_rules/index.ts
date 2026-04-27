type DashboardMetrics = {
  netWorthChangePct: number;
  savingsRatePct: number;
  debtToIncomePct: number;
  liquidityMonths: number;
};

type HealthHint = {
  id: string;
  title: string;
  detail: string;
  level: "info" | "watch";
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const asNumber = (value: unknown, fallback = 0): number => {
  const num = Number(value);
  return Number.isFinite(num) ? num : fallback;
};

const normalizeMetrics = (raw: Record<string, unknown>): DashboardMetrics => {
  return {
    netWorthChangePct: asNumber(raw.netWorthChangePct),
    savingsRatePct: asNumber(raw.savingsRatePct),
    debtToIncomePct: asNumber(raw.debtToIncomePct),
    liquidityMonths: asNumber(raw.liquidityMonths),
  };
};

const buildHints = (metrics: DashboardMetrics): HealthHint[] => {
  const hints: HealthHint[] = [];

  if (metrics.savingsRatePct < 10) {
    hints.push({
      id: "savings-rate",
      title: "儲蓄率可再微幅調整",
      detail: "可從固定提升 1% 開始，逐步接近每月 10% 以上。",
      level: "watch",
    });
  }

  if (metrics.liquidityMonths < 3) {
    hints.push({
      id: "liquidity",
      title: "預備金月數可逐步補強",
      detail: "建議分期補到 3 至 6 個月生活費，保留現金流彈性。",
      level: "watch",
    });
  }

  if (metrics.debtToIncomePct > 40) {
    hints.push({
      id: "debt-ratio",
      title: "負債占比可持續優化",
      detail: "可優先整理高利率帳戶，循序降低固定支出負擔。",
      level: "watch",
    });
  }

  if (metrics.netWorthChangePct < 0) {
    hints.push({
      id: "net-worth-volatility",
      title: "本月淨值有正常波動",
      detail: "可搭配收支與配置一併檢視，維持長期節奏即可。",
      level: "info",
    });
  }

  if (hints.length === 0) {
    hints.push({
      id: "stable",
      title: "整體指標維持穩定",
      detail: "目前可沿用既有計畫，持續觀察每月微幅變化。",
      level: "info",
    });
  }

  return hints;
};

const jsonResponse = (body: unknown, status = 200) => {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      {
        status: "error",
        message: "method_not_allowed",
      },
      405,
    );
  }

  try {
    const payload = await req.json();
    const rawMetrics =
      payload && typeof payload === "object" && "metrics" in payload
        ? (payload.metrics as Record<string, unknown>)
        : {};

    const metrics = normalizeMetrics(rawMetrics);
    const hints = buildHints(metrics);

    return jsonResponse({
      status: "ok",
      source: "l1_health_rules",
      summary: "L1 規則層已完成本月健康檢視。",
      hints,
      metrics,
    });
  } catch (_error) {
    return jsonResponse(
      {
        status: "error",
        message: "invalid_payload",
      },
      400,
    );
  }
});
