# NetWorth Cockpit Flutter MVP TODO

> **For agentic workers:** 建議使用 `superpowers:subagent-driven-development` 逐項執行。每個任務應先補測試，再實作，完成後跑 `flutter analyze` 與相關 `flutter test`。

**依據文件:** `PRD_v0.1.md`、`Flutter_Architecture_v0.1.md`、`Design_Handoff_v0.1.md`

**目前基準:** Flutter Web 專案已建立；已完成初版 `AppShell`、routing、theme tokens、privacy mode、`MoneyDisplay`、`ProgressBar`、`AllocationBar`、`DisclaimerBanner`、Dashboard mock、信用卡匯入 review flow 雛形。

**全域硬約束:**

- [x] Dashboard 第一視覺焦點維持「本月儲蓄率」
- [x] 所有金額顯示一律透過 `MoneyDisplay`
- [x] 隱私模式只遮金額，不遮百分比、趨勢與配置結構
- [x] 不使用紅字、驚嘆號、羞辱式文案或焦慮式警示
- [x] Portfolio、Insights、Dashboard footer 顯示「本資訊僅供參考,不構成投資建議」
- [x] 補倉方向只能給類別比例，不指定個股、ETF 或買賣指令
- [x] 每個新增 feature 至少有 widget test 或 controller/unit test

---

## P0 - Architecture Hardening

### 1. Mock Repository 與 Provider 分層

**目標:** 讓頁面不直接持有 mock raw data，改由 repository/provider 聚合。

**建議檔案:**

- [x] Create `lib/data/repositories/dashboard_repository.dart`
- [x] Create `lib/data/repositories/budget_repository.dart`
- [x] Create `lib/data/repositories/portfolio_repository.dart`
- [x] Create `lib/data/repositories/transaction_repository.dart`
- [x] Create `lib/data/mock/mock_dashboard_data.dart`
- [x] Create `lib/data/mock/mock_budget_data.dart`
- [x] Create `lib/data/mock/mock_portfolio_data.dart`
- [x] Create `lib/data/mock/mock_transactions.dart`
- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`

**驗收:**

- [x] Dashboard 透過 `dashboardRepositoryProvider` 取得 `DashboardSnapshot`
- [x] mock repository 可未來替換 API，不需要重寫 UI
- [x] `flutter test test/features/dashboard/dashboard_page_test.dart` pass

### 2. 共用 Value Objects

**目標:** 建立 Flutter 架構文件中的 shared models，避免各頁自造資料形狀。

**建議檔案:**

- [x] Create `lib/shared/models/money.dart`
- [x] Create `lib/shared/models/percentage.dart`
- [x] Create `lib/shared/models/month_key.dart`
- [x] Modify `lib/core/formatters/money_formatter.dart`

**驗收:**

- [x] `MoneyDisplay` 可接受 `Money` 或保留 `num amount` 但 formatter 集中處理
- [x] 月份顯示一致使用 `MonthKey`
- [x] 金額 formatter 覆蓋正負值、隱私模式與千分位

### 3. Routing 完整化

**目標:** 補齊 Flutter 架構文件路由表的主要路由與 placeholder page。

**建議檔案:**

- [x] Modify `lib/core/routing/route_paths.dart`
- [x] Modify `lib/core/routing/app_router.dart`
- [x] Create missing page skeletons under `lib/features/**/pages/`

**必補路由:**

- [x] `/auth/login`
- [x] `/auth/signup`
- [x] `/onboarding/welcome`
- [x] `/onboarding/risk-questionnaire`
- [x] `/onboarding/target-allocation`
- [x] `/onboarding/budget-setup`
- [x] `/onboarding/first-asset`
- [x] `/assets`
- [x] `/assets/add`
- [x] `/transactions`
- [x] `/transactions/manual`
- [x] `/cards`
- [x] `/cards/add`
- [x] `/budget/history`
- [x] `/portfolio/performance`
- [x] `/insights`
- [x] `/settings/profile`
- [x] `/settings/export`
- [x] `/settings/account`

**驗收:**

- [x] 所有主要路由可進入
- [x] Desktop sidebar 與 mobile bottom nav 不產生錯誤選取狀態
- [x] 低頻頁面可由頁內 CTA 或次級入口進入

---

## P1 - Shared Widgets

### 4. `TrendSparkline`

**目標:** Dashboard 淨資產與 Insights 月報可顯示簡潔趨勢。

**建議檔案:**

- [x] Create `lib/shared/widgets/data_display/trend_sparkline.dart`
- [x] Create `test/shared/trend_sparkline_test.dart`
- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`

**驗收:**

- [x] 支援 6-12 個 mock data point
- [x] 空資料顯示中性 empty state
- [x] 不使用紅綠語義

### 5. `HealthAlertCard`

**目標:** 以結構、檢視、建議、資訊四級呈現健康提示。

**建議檔案:**

- [x] Create `lib/shared/widgets/feedback/health_alert_card.dart`
- [x] Create `test/shared/health_alert_card_test.dart`
- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`

**驗收:**

- [x] 支援 `structural`、`review`、`educational`、`info`
- [x] 不使用驚嘆號與警告 icon
- [x] CTA 使用「檢視」、「調整」、「稍後」等中性文案

### 6. Form 與 Category Components

**目標:** 支撐匯入分類、手動大額記錄、預算設定與 onboarding。

**建議檔案:**

- [x] Create `lib/shared/widgets/forms/app_text_field.dart`
- [x] Create `lib/shared/widgets/forms/app_select_field.dart`
- [x] Create `lib/shared/widgets/forms/category_tag.dart`
- [x] Create `lib/shared/widgets/buttons/primary_button.dart`
- [x] Create `lib/shared/widgets/buttons/secondary_button.dart`

**驗收:**

- [x] 文字不溢出
- [x] mobile touch target 足夠
- [x] category tag 可被匯入 review row 重用

---

## P1 - Dashboard Completion

### 7. Dashboard Repository 聚合

**目標:** Dashboard 使用 repository 聚合資料，不直接寫死 mock。

**建議檔案:**

- [x] Move `lib/features/dashboard/models/dashboard_snapshot.dart` mock data to `lib/data/mock/mock_dashboard_data.dart`
- [x] Create `lib/features/dashboard/controllers/dashboard_controller.dart`
- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`

**驗收:**

- [x] Dashboard page 只負責 rendering
- [x] `DashboardSnapshot` 包含 `month`、`savingsRate`、`netWorth`、`budgetSummary`、`allocationSummary`、`attentionItems`、`statementSummary`、`lastSyncedAt`

### 8. Mobile Fold 驗證

**目標:** 手機首屏完整看到儲蓄率 panel。

**建議檔案:**

- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`
- [x] Add responsive widget test in `test/features/dashboard/dashboard_page_test.dart`

**驗收:**

- [x] 390px width 下 `本月儲蓄率` 與 `28.4%` 不被遮擋
- [x] 無 layout overflow

### 9. 本期信用卡 CTA

**目標:** Dashboard 可引導到帳單匯入流程。

**建議檔案:**

- [x] Modify `lib/features/dashboard/pages/dashboard_page.dart`
- [x] Modify `test/features/dashboard/dashboard_page_test.dart`

**驗收:**

- [x] 「匯入本期帳單」CTA 導向 `/transactions/import`
- [x] CTA 文案低調，不製造壓力

---

## P1 - Credit Card Import Flow

### 10. 5-Step Import Flow State Machine

**目標:** 將目前 review-only 頁擴充為完整 5 步驟。

**建議檔案:**

- [x] Create `lib/features/transactions/import/models/import_step.dart`
- [x] Create `lib/features/transactions/import/models/imported_transaction.dart`
- [x] Create `lib/features/transactions/import/controllers/transaction_import_controller.dart`
- [x] Modify `lib/features/transactions/import/pages/transaction_import_flow_page.dart`
- [x] Create `test/features/transactions/transaction_import_controller_test.dart`

**流程狀態:**

- [x] `selectingCard`
- [x] `uploading`
- [x] `parsing`
- [x] `reviewing`
- [x] `confirming`
- [x] `completed`
- [x] `failed`

**驗收:**

- [x] 使用者可從選卡走到完成
- [x] failed 文案使用「這份檔案暫時無法解析」「可以換一份 CSV,或稍後再試」
- [x] 不出現「錯誤」「失敗!」等焦慮文案

### 11. Upload Drop Zone

**目標:** 支援拖拉與點擊上傳的視覺雛形。

**建議檔案:**

- [x] Create `lib/features/transactions/import/widgets/upload_drop_zone.dart`
- [x] Create `test/features/transactions/upload_drop_zone_test.dart`

**驗收:**

- [x] 顯示支援 CSV / PDF
- [x] parsing 前有進度或狀態感
- [x] 不要求真的解析檔案；MVP 可用 mock trigger

### 12. Review Row Classification

**目標:** 待確認交易可輕量改分類，不跳大型彈窗。

**建議檔案:**

- [x] Create `lib/features/transactions/import/widgets/transaction_review_row.dart`
- [x] Create `lib/features/transactions/import/widgets/category_picker_sheet.dart`
- [x] Modify `lib/features/transactions/import/pages/transaction_import_flow_page.dart`
- [x] Modify `test/features/transactions/transaction_import_flow_test.dart`

**驗收:**

- [x] 高信心度交易預設摺疊
- [x] 低信心度或新商家預設展開
- [x] 點分類 tag 可切換分類
- [x] 可一鍵接受全部建議
- [x] 可顯示「已記住規則」或等價規則記憶感

### 13. Confirm Write Step

**目標:** 完成前顯示本次寫入摘要與預算影響。

**建議檔案:**

- [x] Create `lib/features/transactions/import/widgets/import_summary_band.dart`
- [x] Modify `lib/features/transactions/import/pages/transaction_import_flow_page.dart`

**驗收:**

- [x] 顯示「將寫入 N 筆」
- [x] 顯示固定 / 生活 / 彈性預算影響
- [x] 完成後導回 Dashboard 或顯示 completed state

---

## P1 - Budget

### 14. Budget Models 與 Mock Data

**目標:** 建立三類預算資料結構。

**建議檔案:**

- [x] Create `lib/features/budget/models/budget_month.dart`
- [x] Create `lib/features/budget/models/budget_category.dart`
- [x] Create `lib/data/mock/mock_budget_data.dart`
- [x] Create `lib/features/budget/controllers/budget_controller.dart`

**驗收:**

- [x] 支援固定、生活、彈性三類
- [x] 支援 rollover flag
- [x] 支援大額支出列表

### 15. Budget Page

**目標:** 完成 `/budget` 本月預算頁。

**建議檔案:**

- [x] Modify `lib/features/budget/pages/budget_page.dart`
- [x] Create `lib/features/budget/widgets/budget_summary_panel.dart`
- [x] Create `lib/features/budget/widgets/budget_category_column.dart`
- [x] Create `lib/features/budget/widgets/large_expense_list.dart`
- [x] Create `lib/features/budget/widgets/next_month_planning_panel.dart`
- [x] Create `test/features/budget/budget_page_test.dart`

**驗收:**

- [x] 顯示本月總覽
- [x] 顯示三類預算進度
- [x] 95% 用量不使用紅字
- [x] 月底 framing 是「下月怎麼分配」

### 16. Budget History

**目標:** 補 `/budget/history` 與月份詳情。

**建議檔案:**

- [x] Create `lib/features/budget/pages/budget_history_page.dart`
- [x] Create `lib/features/budget/pages/budget_month_detail_page.dart`

**驗收:**

- [x] 可查看歷史月份摘要
- [x] 文字維持中性、向前看

---

## P1 - Portfolio Allocation

### 17. Portfolio Models 與 Controller

**目標:** 建立配置分析資料結構。

**建議檔案:**

- [x] Create `lib/features/portfolio/models/asset_allocation.dart`
- [x] Create `lib/features/portfolio/models/holding.dart`
- [x] Create `lib/features/portfolio/models/contribution_direction.dart`
- [x] Create `lib/features/portfolio/controllers/portfolio_controller.dart`
- [x] Create `lib/data/mock/mock_portfolio_data.dart`

**驗收:**

- [x] 現況配置與目標配置可並存
- [x] 支援偏離度與 Top 5 集中度資料

### 18. Allocation Page

**目標:** 完成 `/portfolio/allocation`。

**建議檔案:**

- [x] Modify `lib/features/portfolio/pages/allocation_page.dart`
- [x] Create `lib/features/portfolio/widgets/allocation_compare_panel.dart`
- [x] Create `lib/features/portfolio/widgets/allocation_drift_list.dart`
- [x] Create `lib/features/portfolio/widgets/holdings_section.dart`
- [x] Create `lib/features/portfolio/widgets/contribution_direction_panel.dart`
- [x] Create `lib/features/portfolio/widgets/concentration_note_card.dart`
- [x] Create `test/features/portfolio/allocation_page_test.dart`

**驗收:**

- [x] 顯示現況 vs 目標
- [x] 顯示股 / 債 / 現偏離度
- [x] 顯示補倉比例方向
- [x] 不指定買賣標的
- [x] 顯示免責聲明

---

## P1 - Onboarding

### 19. Onboarding Flow

**目標:** 建立 6 步驟首次設定流程。

**建議檔案:**

- [x] Create `lib/features/onboarding/models/onboarding_step.dart`
- [x] Create `lib/features/onboarding/models/risk_answer.dart`
- [x] Create `lib/features/onboarding/controllers/onboarding_controller.dart`
- [x] Create `lib/features/onboarding/pages/welcome_page.dart`
- [x] Create `lib/features/onboarding/pages/risk_questionnaire_page.dart`
- [x] Create `lib/features/onboarding/pages/target_allocation_page.dart`
- [x] Create `lib/features/onboarding/pages/budget_setup_page.dart`
- [x] Create `lib/features/onboarding/pages/first_asset_page.dart`
- [x] Create `test/features/onboarding/onboarding_flow_test.dart`

**驗收:**

- [x] 每一步都可以跳過
- [x] 完成後導向 Dashboard
- [x] 新使用者 5 分鐘內可完成
- [x] 空資料 Dashboard 不出現挫折式空白

### 20. Risk Questionnaire

**目標:** 實作 8-10 題風險屬性問卷與五級配置結果。

**建議檔案:**

- [x] Create `lib/features/onboarding/widgets/risk_question_card.dart`
- [x] Create `lib/features/onboarding/widgets/onboarding_progress.dart`
- [x] Create `lib/features/onboarding/widgets/allocation_slider_group.dart`
- [x] Create `test/features/onboarding/risk_questionnaire_test.dart`

**驗收:**

- [x] 可得到 L1-L5 等級
- [x] 預設配置符合 PRD 表格
- [x] 使用者可手動調整目標配置

---

## P2 - Assets

### 21. Assets Overview

**目標:** 完成資產總覽與新增資產雛形。

**建議檔案:**

- [x] Create `lib/features/assets/models/asset.dart`
- [x] Create `lib/features/assets/models/asset_type.dart`
- [x] Create `lib/features/assets/controllers/assets_controller.dart`
- [x] Create `lib/features/assets/pages/assets_page.dart`
- [x] Create `lib/features/assets/pages/add_asset_page.dart`
- [x] Create `lib/features/assets/widgets/asset_group_section.dart`
- [x] Create `lib/features/assets/widgets/asset_list_item.dart`
- [x] Create `test/features/assets/assets_page_test.dart`

**驗收:**

- [x] 以類別分組
- [x] 每筆顯示名稱、估值、佔比
- [x] 所有估值使用 `MoneyDisplay`
- [x] CRUD 可先用 mock repository 模擬

---

## P2 - Cards

### 22. Credit Cards

**目標:** 完成信用卡列表、單卡詳情與新增卡片雛形。

**建議檔案:**

- [x] Create `lib/features/cards/models/credit_card_account.dart`
- [x] Create `lib/features/cards/models/statement_cycle.dart`
- [x] Create `lib/features/cards/controllers/cards_controller.dart`
- [x] Create `lib/features/cards/pages/cards_page.dart`
- [x] Create `lib/features/cards/pages/card_detail_page.dart`
- [x] Create `lib/features/cards/pages/add_card_page.dart`
- [x] Create `lib/features/cards/widgets/credit_card_list_item.dart`
- [x] Create `lib/features/cards/widgets/statement_summary_panel.dart`
- [x] Create `test/features/cards/cards_page_test.dart`

**驗收:**

- [x] 顯示本期帳單金額、結帳日、繳款日
- [x] 可從單卡詳情進入 `/transactions/import`
- [x] 不追蹤循環利息或高負債情境

---

## P2 - Transactions Manual Entry

### 23. Large Manual Expense

**目標:** 完成 `/transactions/manual` 大額手動記錄。

**建議檔案:**

- [x] Create `lib/features/transactions/pages/transactions_page.dart`
- [x] Create `lib/features/transactions/pages/manual_transaction_page.dart`
- [x] Create `lib/features/transactions/models/transaction_record.dart`
- [x] Create `lib/features/transactions/controllers/transactions_controller.dart`
- [x] Create `test/features/transactions/manual_transaction_page_test.dart`

**驗收:**

- [x] 欄位包含金額、日期、類別、來源帳戶、備註
- [x] 來源帳戶預設上次使用
- [x] 目標 30 秒內完成
- [x] 低於門檻的小額現金消費不被主動要求記錄

---

## P2 - Insights

### 24. Monthly Insights

**目標:** 完成月度報告與 AI 解讀容器。

**建議檔案:**

- [x] Create `lib/features/insights/models/monthly_insight.dart`
- [x] Create `lib/features/insights/controllers/insights_controller.dart`
- [x] Create `lib/features/insights/pages/insights_page.dart`
- [x] Create `lib/features/insights/pages/monthly_insight_page.dart`
- [x] Create `lib/features/insights/widgets/monthly_summary_header.dart`
- [x] Create `lib/features/insights/widgets/savings_rate_recap.dart`
- [x] Create `lib/features/insights/widgets/budget_recap.dart`
- [x] Create `lib/features/insights/widgets/allocation_change_recap.dart`
- [x] Create `lib/features/insights/widgets/ai_interpretation_panel.dart`
- [x] Create `test/features/insights/monthly_insight_page_test.dart`

**驗收:**

- [x] 顯示淨值變化、儲蓄率、預算達成、配置變化
- [x] AI 解讀文末顯示免責聲明
- [x] 月報 footer 顯示「本資訊僅供參考,不構成投資建議」
- [x] 不論結果好壞都使用中性、向前看的文字

---

## P2 - Settings/Auth

### 25. Settings Completion

**目標:** 補齊設定子頁。

**建議檔案:**

- [x] Create `lib/features/settings/pages/profile_page.dart`
- [x] Create `lib/features/settings/pages/risk_profile_page.dart`
- [x] Create `lib/features/settings/pages/target_allocation_settings_page.dart`
- [x] Create `lib/features/settings/pages/export_page.dart`
- [x] Create `lib/features/settings/pages/account_page.dart`
- [x] Create `lib/features/settings/widgets/settings_section.dart`
- [x] Create `lib/features/settings/widgets/settings_tile.dart`
- [x] Create `lib/features/settings/widgets/export_format_picker.dart`
- [x] Create `test/features/settings/settings_page_test.dart`

**驗收:**

- [x] 隱私模式開關醒目
- [x] 資料匯出支援 CSV / JSON 選項
- [x] 帳號刪除清楚可見，但不使用誇張警告風格

### 26. Auth Pages

**目標:** 補登入與註冊頁雛形。

**建議檔案:**

- [x] Create `lib/features/auth/pages/login_page.dart`
- [x] Create `lib/features/auth/pages/signup_page.dart`
- [x] Create `lib/features/auth/widgets/auth_form_shell.dart`
- [x] Create `lib/features/auth/widgets/investment_disclaimer_checkbox.dart`
- [x] Create `test/features/auth/signup_page_test.dart`

**驗收:**

- [x] 支援 Email 登入/註冊 UI
- [x] 預留 Google OAuth button
- [x] Signup 必須勾選「我了解本服務不提供投資建議」
- [x] Auth footer 顯示隱私政策與使用者條款入口

---

## P3 - Rule Layer / Domain Logic

### 27. Health Rule Engine

**目標:** Flutter 端先建立可測的 L1 規則雛形，未來可搬至 Supabase Edge Function。

**建議檔案:**

- [x] Create `lib/domain/rules/health_rule_engine.dart`
- [x] Create `test/domain/rules/health_rule_engine_test.dart`

**規則順序:**

- [x] 本期信用卡應繳 > 可動用現金
- [x] 緊急預備金月數 < 3
- [x] 儲蓄率 < 10%
- [x] 投資配置偏離 > 10%
- [x] 全部健康

**驗收:**

- [x] 首條滿足即觸發
- [x] 每條提示都有中性標題與原因
- [x] 不輸出「警告」「危險」「錯誤」

### 28. Budget Alert Rules

**目標:** 預算用量閾值行為可測。

**建議檔案:**

- [x] Create `lib/domain/rules/budget_alert_rules.dart`
- [x] Create `test/domain/rules/budget_alert_rules_test.dart`

**驗收:**

- [x] < 80% 不主動通知
- [x] 80-99% 顯示「還剩 X 元,N 天」
- [x] >= 100% 使用中性文案
- [x] > 120% 月底提示是否調整下月分配

### 29. Allocation Drift Rules

**目標:** 配置偏離規則可測。

**建議檔案:**

- [x] Create `lib/domain/rules/allocation_drift_rules.dart`
- [x] Create `test/domain/rules/allocation_drift_rules_test.dart`

**驗收:**

- [x] 任一類別偏離 > 5% 且持續 7 天可提示
- [x] 偏離 > 10% 可高亮
- [x] 偏離 > 15% 月報專章
- [x] 輸出仍不指定投資標的

---

## P3 - Visual QA / Browser QA

### 30. Responsive Screenshot Pass

**目標:** 確認 desktop/mobile 沒有 overflow 或重疊。

**建議驗證尺寸:**

- [x] 390 x 844
- [x] 768 x 1024
- [x] 1440 x 900

**驗收:**

- [x] Dashboard mobile fold 上方完整顯示儲蓄率
- [x] Import review row 文字不溢出
- [x] Sidebar 與 bottom nav 不重疊內容
- [x] 預算與配置頁無卡片套卡片問題

### 31. Golden Tests

**目標:** 為高風險視覺狀態加 golden baseline。

**建議檔案:**

- [x] Create `test/goldens/dashboard_desktop_test.dart`
- [x] Create `test/goldens/dashboard_mobile_test.dart`
- [x] Create `test/goldens/import_review_desktop_test.dart`
- [x] Create `test/goldens/privacy_mode_test.dart`

**驗收:**

- [x] Golden 不因動態時間或隨機資料變動
- [x] 隱私模式 on/off 都有覆蓋

---

## Backlog - Post-MVP / Phase 1+

- [x] 真實 Supabase Auth / profiles / RLS 串接
- [x] 台股 TWSE / TPEx OpenAPI 行情更新
- [x] Supabase Edge Function L1 規則層
- [x] FastAPI L2 量化分析服務
- [x] LLM 月度報告解讀
- [x] LLM 商家分類 fallback
- [x] 推播提醒
- [x] PWA 支援與安裝體驗
- [x] Flutter iOS target
- [x] Coingecko 加密貨幣支援
- [x] 暗色模式
- [x] 法律審查後的正式條款、隱私政策與 AI template

---

## 每次任務完成前必跑

- [x] `cmd.exe /C "cd /d C:\Users\Kashionz\Desktop\Project\networth-cockpit && C:\Users\Kashionz\flutter\bin\dart.bat format lib test"`
- [x] `cmd.exe /C "cd /d C:\Users\Kashionz\Desktop\Project\networth-cockpit && C:\Users\Kashionz\flutter\bin\flutter.bat analyze"`
- [x] `cmd.exe /C "cd /d C:\Users\Kashionz\Desktop\Project\networth-cockpit && C:\Users\Kashionz\flutter\bin\flutter.bat test"`
- [x] `cmd.exe /C "cd /d C:\Users\Kashionz\Desktop\Project\networth-cockpit && C:\Users\Kashionz\flutter\bin\flutter.bat build web"`
