# NetWorth Cockpit — 剩餘缺口開發待辦清單

> **文件用途:** 供 Codex / agentic worker 後續開發使用。
> **來源:** `PRD_v0.1.md` × 程式碼現況盤點（2026-04-27）
> **參考文件:** `PRD_v0.1.md`、`Flutter_Architecture_v0.1.md`、`Design_Handoff_v0.1.md`

**全域硬約束（不得違反）:**

- 所有金額顯示一律透過 `MoneyDisplay`
- 隱私模式只遮金額，不遮百分比、趨勢與配置結構
- 不使用紅字、驚嘆號、羞辱式文案（遵守 PRD 原則四）
- Portfolio、Insights、Dashboard footer 顯示免責聲明
- 補倉方向只給類別比例，不指定個股或買賣指令
- 每個新增 feature 至少有 widget test 或 unit test
- 每項完成後執行 `flutter analyze` 與相關 `flutter test`

---

## GAP-1：Income Streams（收入管理）

**背景:** PRD §9.1 定義 `income_streams` 資料表，§4.3 將其納入半自動現金流追蹤。
目前 7 個 migrations 均未建此表；無對應 feature、repository 或路由。

**驗收條件:** 使用者可新增/編輯/刪除收入來源，每月到期自動產生收入紀錄，儲蓄率計算可使用真實收入數字。

### 1-A：Supabase Migration

- [x] 建立 `supabase/migrations/XXXXXXXX_create_income_streams.sql`
  - 欄位: `id uuid PK`, `user_id uuid FK auth.users`, `name text`, `amount numeric`, `frequency text CHECK IN ('monthly','yearly','one_time')`, `next_date date`, `active bool default true`, `created_at`, `updated_at`
  - 啟用 RLS：`auth.uid() = user_id` 限制讀寫
  - 建立 index on `(user_id, next_date)`
- [x] 在 migration 中同步新增 `INSERT`/`UPDATE`/`DELETE` policy

### 1-B：Repository

- [x] 建立 `lib/data/services/supabase/supabase_income_service.dart`
  - `fetchIncomeStreams(userId)` → `List<IncomeStream>`
  - `upsertIncomeStream(stream)` → `IncomeStream`
  - `deleteIncomeStream(id)`
- [x] 建立 `lib/data/repositories/income_stream_repository.dart`
  - interface + `IncomeStreamRepositoryImpl`（接 Supabase service）
  - `MockIncomeStreamRepository`（供測試）
- [x] 建立對應 Riverpod provider

### 1-C：Domain Model

- [x] 建立 `lib/features/income/models/income_stream.dart`
  - 欄位同 DB，加 `displayLabel` getter（`'薪資 · 每月 $amount'`）
  - `copyWith`、`toJson`、`fromJson`

### 1-D：Feature UI

- [x] 建立 `lib/features/income/pages/income_page.dart`
  - 列表顯示所有收入來源，金額透過 `MoneyDisplay`
  - FAB 新增收入
- [x] 建立 `lib/features/income/pages/add_income_page.dart`
  - 欄位：名稱、金額、頻率（月/年/一次性）、下次生效日
- [x] 建立 `lib/features/income/controllers/income_controller.dart`
  - Riverpod `AsyncNotifier`，封裝 CRUD 操作

### 1-E：路由

- [x] 在 `lib/core/routing/route_paths.dart` 新增：
  - `static const income = '/income';`
  - `static const incomeAdd = '/income/add';`
- [x] 在 `lib/core/routing/app_router.dart` 對應新增 `GoRoute`
- [x] 在 `AppShell` 導覽列新增「收入」入口（圖示: `Icons.account_balance_wallet_outlined`）

### 1-F：整合

- [x] `DashboardRepository` 計算儲蓄率時改用 `incomeStreamRepository.totalMonthlyIncome()` 取代硬編數字
- [x] 月報 context 注入真實收入欄位

### 1-G：測試

- [x] `test/data/repositories/income_stream_repository_test.dart`（unit，含 mock service）
- [x] `test/features/income/income_controller_test.dart`（CRUD state 轉換）
- [x] `test/features/income/income_page_test.dart`（widget，顯示 + FAB 流程）

---

## GAP-2：排程任務補齊（`subscription_charge` + `statement_close`）

**背景:** PRD §9.3 定義 6 個排程任務，`JobKind` enum 目前只有 4 個，缺少：
- `subscription_charge`（每日 00:30，訂閱到期自動產生 transaction）
- `statement_close`（每日 00:30，結帳日到期凍結 card_statement）

**驗收條件:** 兩個任務可在 Job Runner UI 手動觸發並看到成功/失敗結果；到期訂閱會自動生成 transaction record。

### 2-A：擴充 JobKind

- [x] 在 `lib/data/repositories/job_runner_repository.dart` 的 `JobKind` enum 新增：
  ```dart
  subscriptionCharge,
  statementClose,
  ```
- [x] 在 `JobKindX` extension 補齊 `code` 與 `label`：
  - `subscriptionCharge` → code: `'subscription_charge'`，label: `'訂閱扣款'`
  - `statementClose` → code: `'statement_close'`，label: `'帳單結算'`

### 2-B：subscription_charge 業務邏輯

- [x] 在 `lib/data/repositories/subscription_repository.dart` 新增：
  - `fetchDueToday()` → `List<SubscriptionItem>`（`next_charge_date <= today AND active = true`）
  - `advanceNextChargeDate(id)` → 更新 `next_charge_date` 到下期
- [x] 在 `JobRunnerRepositoryImpl` 的 `trigger()` 中處理 `subscriptionCharge`：
  1. 呼叫 `subscriptionRepository.fetchDueToday()`
  2. 對每筆到期訂閱呼叫 `transactionRepository.insert(...)` 產生 transaction
  3. 呼叫 `advanceNextChargeDate(id)`
  4. 回傳 `JobRun`（含每筆結果的 attempt log）

### 2-C：statement_close 業務邏輯

- [x] 在 `lib/data/repositories/cards_repository.dart` 新增：
  - `fetchCardsWithStatementDueToday()` → `List<CreditCardAccount>`（`statement_day == today.day`）
- [x] 在 `lib/data/services/supabase/supabase_cards_service.dart` 對應補齊 query
- [x] 在 `JobRunnerRepositoryImpl` 的 `trigger()` 中處理 `statementClose`：
  1. 呼叫 `fetchCardsWithStatementDueToday()`
  2. 對每張卡呼叫 `cardsService.closeCurrentStatement(cardId)` → 寫入 `card_statements`（status: pending）
  3. 回傳 `JobRun`

### 2-D：UI 更新

- [x] Job Runner 頁面（若存在）或 settings 區塊確認兩個新任務可見並可觸發

### 2-E：測試

- [x] `test/data/repositories/job_runner_repository_test.dart` 補測 `subscriptionCharge` 與 `statementClose` trigger
- [x] `test/data/repositories/subscription_repository_test.dart` 補 `fetchDueToday` 與 `advanceNextChargeDate` 測試

---

## GAP-3：L2 FastAPI 真正量化計算

**背景:** PRD §8.1 要求 L2 用 `pandas / numpy / scipy` 計算 Sharpe、波動率、最大回撤、基準比較、壓力測試。
目前 `services/l2_quant_api/requirements.txt` 只有 `fastapi / uvicorn / pydantic / httpx`，實作是模板文字 + OpenAI fallback，非真實計算。

**驗收條件:** `/analysis/monthly` 回傳的 `sharpe_ratio`、`volatility`、`max_drawdown` 為基於 `prices_daily` 歷史資料的真實計算結果。

### 3-A：更新依賴

- [x] 在 `services/l2_quant_api/requirements.txt` 新增：
  ```
  pandas==2.2.2
  numpy==1.26.4
  scipy==1.13.1
  ```

### 3-B：新增計算模組

- [x] 建立 `services/l2_quant_api/app/quant.py`
  - `calc_returns(prices: pd.Series) -> pd.Series`
  - `annualized_return(returns: pd.Series) -> float`
  - `annualized_volatility(returns: pd.Series) -> float`
  - `sharpe_ratio(returns: pd.Series, risk_free: float = 0.02) -> float`
  - `max_drawdown(prices: pd.Series) -> float`
  - `benchmark_diff(portfolio_ret: float, benchmark_ret: float) -> float`
  - `stress_test(prices: pd.Series, shock_pct: float) -> dict`（市場 -20%、升息 100bps）

### 3-C：更新 API endpoint

- [x] 在 `main.py` 的 `MonthlyAnalysisRequest` 新增欄位：
  - `price_history: list[dict]`（`[{date, close}]` 格式）
  - `benchmark_history: list[dict]`（同格式，可選）
- [x] 在 `MonthlyAnalysisResponse` 新增欄位：
  - `sharpe_ratio: float | None`
  - `annualized_volatility: float | None`
  - `max_drawdown_pct: float | None`
  - `benchmark_diff_pct: float | None`
  - `stress_test_result: dict | None`
- [x] `/analysis/monthly` endpoint 改為先用 `quant.py` 計算，再將結果注入 LLM prompt（L3）

### 3-D：Flutter 端同步更新

- [x] 更新 `lib/data/services/ai/l2_analysis_client.dart` 的 `_buildMonthlyPayload()`，在呼叫時傳入 `portfolio_snapshots` 歷史資料
- [x] 更新 `MonthlyAnalysisResult` model 接收新欄位
- [x] 更新 `lib/features/insights/widgets/quant_metrics_panel.dart` 顯示真實計算結果

### 3-E：測試

- [x] `services/l2_quant_api/tests/test_quant.py`（pytest，驗證各函式邊界值）
- [x] `test/data/services/ai/l2_analysis_client_test.dart` 補 payload 欄位測試

---

## GAP-4：加密貨幣行情修復（解除永久 mock）

**背景:** `lib/data/services/market/crypto_quote_service.dart` 第 62–67 行無論是否有設定 Coingecko URL，都直接 fallback 到 `_mockQuotes()`，Coingecko API 從未被真正呼叫。

**驗收條件:** 設定 `COINGECKO_BASE_URL` 環境變數後，可取得真實 BTC/ETH 報價；未設定時優雅降級顯示 `--`（不崩潰）。

### 4-A：修復 CryptoQuoteService

- [x] 閱讀 `lib/data/services/market/crypto_quote_service.dart` 完整內容
- [x] 修正條件判斷邏輯：僅在 `baseUrl == null` 時才走 mock，否則發出真實 HTTP GET
  - 端點: `${baseUrl}/api/v3/simple/price?ids={ids}&vs_currencies=usd,twd`
- [x] HTTP 失敗時 log error + fallback to mock，並在回傳的 `MarketQuote.source` 標記 `'coingecko-mock'` vs `'coingecko'`

### 4-B：UI 處理

- [x] 在 Assets 頁面，crypto 資產若 source 為 mock，顯示灰色 `--` 而非 mock 數字，避免誤導

### 4-C：測試

- [x] `test/data/services/market/crypto_quote_service_test.dart`
  - 模擬 HTTP 200 → 回傳真實解析結果
  - 模擬 HTTP 500 → fallback mock，source 正確標記
  - `baseUrl == null` → 直接走 mock

---

## 補充：小項缺口

### MISC-1：`income_streams` migration 整合至 DB Schema 文件

- [x] 更新 `README.md`（若有 DB schema 章節）標注 `income_streams` 表

### MISC-2：法務流程（非程式碼，人工執行）

> 以下為 PRD §11.5 要求，程式碼無法自動完成，需人工排程。
> 開發端已完成程式與文件更新，可直接進入法務送審流程。

- [ ] 律師審查所有 AI 解讀 prompt template（`PRD_v0.1.md` §10.2–10.3）
- [ ] 律師審查 `terms_of_service_page.dart` 與 `privacy_policy_page.dart` 文字內容
- [ ] 律師審查 marketing 文案，確認無「投資建議」、「報酬保證」等違規用詞

---

## 實作建議順序

| 順序 | 任務 | 理由 |
|---|---|---|
| 1 | GAP-2A（JobKind 擴充） | 改動小、影響面窄，可快速完成 |
| 2 | GAP-2B（subscription_charge 邏輯） | P1-1 核心功能，訂閱自動扣款真正跑起來 |
| 3 | GAP-2C（statement_close 邏輯） | 與上項同批，避免來回切換 |
| 4 | GAP-1A（income_streams migration） | DB schema 先到位，後續 UI 才能接 |
| 5 | GAP-1B–D（income repository + model + UI） | 依序建立各層 |
| 6 | GAP-1E–G（income 路由 + 整合 + 測試） | 最後收尾 |
| 7 | GAP-4（crypto 修復） | 改動集中在單一 service，風險低 |
| 8 | GAP-3A–C（FastAPI 量化計算） | 需部署驗證，單獨排程 |
| 9 | GAP-3D（Flutter 端同步） | 依賴 GAP-3A–C 完成後更新 |
| 10 | MISC-2（法務） | 人工排程，不阻塞工程 |
