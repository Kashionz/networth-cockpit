# NetWorth Cockpit — Flutter Architecture

> Flutter-first architecture document
> 文件版本:v0.1
> 撰寫日期:2026-04-26
> 對應文件:PRD v0.1、Design Handoff v0.1

---

## 0. 文件目的

本文件將既有 React/Vite 設計原型與 `Design_Handoff_v0.1.md` 轉換為 Flutter 開發架構。後續正式產品開發以 Flutter 為主要技術方向,現有 `src/main.jsx` 與 `src/styles.css` 視為互動與視覺原型參考,不作為正式前端架構基礎。

本文件回答:

1. Flutter 專案如何分層
2. 完整頁面與路由如何規劃
3. 共用 Widget 與 Feature module 如何拆分
4. 隱私模式、金額顯示、合規免責如何全域處理
5. MVP 開發順序與驗收標準

---

## 1. 技術方向

### 1.1 平台策略

產品後續採用 Flutter 作為主要前端技術:

- Phase 0:Flutter Web
- Phase 1:Flutter iOS
- Phase 2:Flutter Android(視產品策略決定)

此產品是登入後工具型 App,重點是互動流程、資料視覺化、跨平台一致性與隱私模式,不是公開 SEO 網站。因此 Flutter 比 Next.js 更適合作為長期主架構。

### 1.2 建議套件

| 類別 | 套件 | 用途 |
|---|---|---|
| 路由 | `go_router` | 宣告式路由、巢狀 layout、deep link |
| 狀態管理 | `flutter_riverpod` | 全域狀態、資料讀取、流程狀態 |
| Immutable model | `freezed` | 資料模型與 sealed state |
| JSON | `json_serializable` | API DTO 與本地 mock data |
| 日期/數字 | `intl` | 台灣貨幣、日期、百分比格式 |
| 圖表 | `fl_chart` | 趨勢圖、長條圖、圓餅圖雛形 |
| 本地儲存 | `shared_preferences` | 隱私模式、使用者偏好 |
| 安全儲存 | `flutter_secure_storage` | token、敏感設定 |
| 檔案挑選 | `file_picker` | 信用卡帳單匯入 |
| 拖放 Web | `desktop_drop` 或自訂 Web drop zone | Flutter Web 上傳體驗 |

### 1.3 設計原則映射

Flutter 實作必須保留設計交付文件的硬約束:

- Dashboard 第一視覺焦點是「本月儲蓄率」
- 不使用紅字、驚嘆號、羞辱式警示
- 預算視覺要有掌控感,不是監視感
- 匯入流程必須低摩擦
- 不以逐筆瑣碎消費列表作為主畫面
- 所有金額元件必須支援隱私模式
- 投資相關解讀必須帶免責聲明

---

## 2. 專案目錄架構

建議 Flutter 專案建立後採用以下結構:

```txt
lib/
  main.dart
  app.dart

  core/
    config/
      app_environment.dart
      feature_flags.dart
    routing/
      app_router.dart
      route_paths.dart
      route_guards.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radii.dart
      app_shadows.dart
    formatters/
      money_formatter.dart
      percentage_formatter.dart
      date_formatter.dart
    privacy/
      privacy_mode_controller.dart
      privacy_mode_provider.dart
    errors/
      app_error.dart
      error_presenter.dart

  shared/
    models/
      money.dart
      percentage.dart
      month_key.dart
    widgets/
      app_shell/
        app_shell.dart
        desktop_sidebar.dart
        mobile_bottom_nav.dart
        page_header.dart
      buttons/
        primary_button.dart
        secondary_button.dart
        icon_action_button.dart
      data_display/
        money_display.dart
        percentage_display.dart
        progress_bar.dart
        trend_sparkline.dart
        allocation_bar.dart
        allocation_donut.dart
      feedback/
        health_alert_card.dart
        empty_state.dart
        loading_state.dart
        error_state.dart
        disclaimer_banner.dart
      forms/
        app_text_field.dart
        app_select_field.dart
        category_tag.dart
      navigation/
        breadcrumb.dart
        month_switcher.dart

  features/
    auth/
    onboarding/
    dashboard/
    transactions/
    budget/
    portfolio/
    assets/
    cards/
    insights/
    settings/

  data/
    models/
    repositories/
    mock/
    services/
```

### 2.1 分層原則

- `core/`:跨 feature 的基礎能力,例如 routing、theme、privacy、formatters。
- `shared/`:可複用 UI 與簡單 value object,不得依賴任一 feature。
- `features/`:以產品功能切分頁面、widget、controller、repository。
- `data/`:通用資料來源、mock data、API service。MVP 可先使用 mock repository。

---

## 3. 路由架構

### 3.1 完整路由表

```txt
/

/auth/login
/auth/signup

/onboarding/welcome
/onboarding/risk-questionnaire
/onboarding/target-allocation
/onboarding/budget-setup
/onboarding/first-asset

/assets
/assets/cash
/assets/investments
/assets/add
/assets/:assetId

/transactions
/transactions/import
/transactions/manual

/cards
/cards/add
/cards/:cardId

/budget
/budget/history
/budget/history/:yearMonth

/portfolio/allocation
/portfolio/performance

/insights
/insights/:yearMonth

/settings/profile
/settings/risk-profile
/settings/target-allocation
/settings/privacy
/settings/export
/settings/account
```

### 3.2 Shell 分組

```txt
PublicShell
  /auth/login
  /auth/signup

OnboardingShell
  /onboarding/*

AppShell
  /
  /assets/*
  /transactions/*
  /cards/*
  /budget/*
  /portfolio/*
  /insights/*

SettingsShell
  /settings/*
```

### 3.3 導覽規則

Desktop 使用 `DesktopSidebar`,主要導覽:

1. Dashboard
2. Assets
3. Transactions
4. Budget
5. Portfolio
6. Cards
7. Insights
8. Settings

Mobile 使用 `MobileBottomNav`,只放高頻入口:

1. Dashboard
2. Assets
3. Budget
4. Insights
5. Settings

低頻頁面如 `transactions/import`、`cards/add`、`settings/export` 由頁內 CTA 或子導覽進入。

---

## 4. Feature 架構

每個 feature 以固定結構拆分:

```txt
features/<feature_name>/
  pages/
  widgets/
  controllers/
  models/
  repositories/
```

小型 feature 可省略不需要的資料夾,但頁面不得全部堆在單一檔案。

### 4.1 Auth

```txt
features/auth/
  pages/
    login_page.dart
    signup_page.dart
  widgets/
    auth_form_shell.dart
    oauth_button.dart
    investment_disclaimer_checkbox.dart
  controllers/
    auth_controller.dart
```

需求:

- 支援 Email 登入/註冊
- 預留 Google OAuth
- 註冊頁必須包含「本服務不提供投資建議」勾選確認
- 登入後若未完成 onboarding,導向 `/onboarding/welcome`

### 4.2 Onboarding

```txt
features/onboarding/
  pages/
    welcome_page.dart
    risk_questionnaire_page.dart
    target_allocation_page.dart
    budget_setup_page.dart
    first_asset_page.dart
  widgets/
    onboarding_progress.dart
    risk_question_card.dart
    allocation_slider_group.dart
    budget_template_editor.dart
  controllers/
    onboarding_controller.dart
  models/
    onboarding_step.dart
    risk_answer.dart
```

流程:

1. Welcome
2. 風險屬性問卷
3. 目標配置設定
4. 月薪輸入
5. 預算設定
6. 新增第一筆資產

要求:

- 每步都可以跳過
- 總體感受像簡單表單,不是多關卡任務
- 完成後導向 Dashboard
- 空資料 Dashboard 必須有中性、期待感的 empty state

### 4.3 Dashboard

```txt
features/dashboard/
  pages/
    dashboard_page.dart
  widgets/
    savings_rate_panel.dart
    net_worth_panel.dart
    budget_snapshot_panel.dart
    allocation_snapshot_panel.dart
    health_attention_panel.dart
    statement_due_panel.dart
  controllers/
    dashboard_controller.dart
  models/
    dashboard_snapshot.dart
```

資訊區塊順序:

1. 本月儲蓄率
2. 淨資產
3. 本月預算進度
4. 投資配置
5. 值得檢視
6. 本期信用卡帳單

要求:

- 儲蓄率必須是第一視覺焦點
- 手機上儲蓄率區塊必須完整出現在 fold 上方
- 所有金額使用 `MoneyDisplay`
- 隱私模式只遮金額,比例與結構仍可見

### 4.4 Transactions

```txt
features/transactions/
  pages/
    transactions_page.dart
    manual_transaction_page.dart
  import/
    pages/
      transaction_import_flow_page.dart
    steps/
      select_card_step.dart
      upload_file_step.dart
      parsing_step.dart
      review_classification_step.dart
      confirm_write_step.dart
    widgets/
      import_stepper.dart
      upload_drop_zone.dart
      transaction_review_row.dart
      category_picker_sheet.dart
      import_summary_band.dart
    controllers/
      transaction_import_controller.dart
    models/
      import_step.dart
      imported_transaction.dart
      classification_confidence.dart
```

信用卡帳單匯入 5 步驟:

1. 選擇卡片
2. 上傳檔案
3. 解析中
4. 審核分類結果
5. 確認寫入

Step 4 是 MVP 核心:

- 高信心度交易預設摺疊為「已自動分類」
- 低信心度或新商家展開為「待確認」
- 點分類 tag 即可改分類,不要跳大型彈窗
- 支援全部接受建議
- 顯示「越用越快」的規則記憶感

大額手動記錄:

- 路由 `/transactions/manual`
- 欄位:金額、日期、類別、來源帳戶、備註
- 來源帳戶預設上次使用
- 目標 30 秒內完成

### 4.5 Budget

```txt
features/budget/
  pages/
    budget_page.dart
    budget_history_page.dart
    budget_month_detail_page.dart
  widgets/
    budget_summary_panel.dart
    budget_category_column.dart
    budget_progress_bar.dart
    large_expense_list.dart
    next_month_planning_panel.dart
  controllers/
    budget_controller.dart
  models/
    budget_month.dart
    budget_category.dart
```

區塊:

1. 本月總覽
2. 三類預算進度:固定、生活、彈性
3. 大額支出
4. 下月預算規劃

要求:

- 95% 用量也不使用紅字
- 以剩餘可用日均、字重、色階深淺傳達優先級
- 月底 framing 是「下月怎麼分配」而非「本月哪裡失敗」

### 4.6 Portfolio

```txt
features/portfolio/
  pages/
    allocation_page.dart
    performance_page.dart
  widgets/
    allocation_compare_panel.dart
    allocation_drift_list.dart
    holdings_section.dart
    contribution_direction_panel.dart
    concentration_note_card.dart
  controllers/
    portfolio_controller.dart
  models/
    asset_allocation.dart
    holding.dart
    contribution_direction.dart
```

MVP 頁面為 `/portfolio/allocation`。

區塊:

1. 配置概覽:現況 vs 目標
2. 偏離度
3. 持股明細
4. 補倉方向

要求:

- 補倉方向只能給比例方向,不得指定買賣標的
- 頁面需顯示「本資訊僅供參考,不構成投資建議」
- 偏離度清楚但不情緒化

### 4.7 Assets

```txt
features/assets/
  pages/
    assets_page.dart
    cash_accounts_page.dart
    investments_page.dart
    add_asset_page.dart
    asset_detail_page.dart
  widgets/
    asset_group_section.dart
    asset_list_item.dart
    asset_value_distribution.dart
  controllers/
    assets_controller.dart
  models/
    asset.dart
    asset_type.dart
```

要求:

- 以類別分組
- 每筆顯示名稱、估值、佔比
- CRUD 操作可先用 mock repository 模擬
- 所有估值使用 `MoneyDisplay`

### 4.8 Cards

```txt
features/cards/
  pages/
    cards_page.dart
    card_detail_page.dart
    add_card_page.dart
  widgets/
    credit_card_list_item.dart
    statement_summary_panel.dart
    statement_history_list.dart
  controllers/
    cards_controller.dart
  models/
    credit_card_account.dart
    statement_cycle.dart
```

要求:

- 顯示本期帳單金額、結帳日、繳款日
- 可從單卡詳情進入 `/transactions/import`
- 不追蹤循環利息或高負債情境

### 4.9 Insights

```txt
features/insights/
  pages/
    insights_page.dart
    monthly_insight_page.dart
  widgets/
    monthly_summary_header.dart
    savings_rate_recap.dart
    budget_recap.dart
    allocation_change_recap.dart
    ai_interpretation_panel.dart
    milestone_note.dart
  controllers/
    insights_controller.dart
  models/
    monthly_insight.dart
```

要求:

- 不論結果好壞都使用中性、向前看的文字
- AI 解讀文末必須顯示免責聲明
- 月報 footer 必須顯示「本資訊僅供參考,不構成投資建議」

### 4.10 Settings

```txt
features/settings/
  pages/
    profile_page.dart
    risk_profile_page.dart
    target_allocation_settings_page.dart
    privacy_page.dart
    export_page.dart
    account_page.dart
  widgets/
    settings_section.dart
    settings_tile.dart
    privacy_mode_toggle.dart
    export_format_picker.dart
  controllers/
    settings_controller.dart
```

要求:

- 隱私模式開關要醒目
- 資料匯出與帳號刪除清楚可見
- 危險操作文案保持清楚,但不使用誇張警告風格

---

## 5. 共用 Widget 規格

### 5.1 MoneyDisplay

用途:

- 顯示所有金額
- 統一處理貨幣、等寬數字、正負值、隱私模式

Props 建議:

```dart
class MoneyDisplay extends ConsumerWidget {
  const MoneyDisplay({
    required this.amount,
    this.currency = 'NT\$',
    this.size,
    this.weight,
    this.showSign = false,
    this.muted = false,
    super.key,
  });

  final num amount;
  final String currency;
  final double? size;
  final FontWeight? weight;
  final bool showSign;
  final bool muted;
}
```

隱私模式啟用時:

- `NT$ 2,450,000` 顯示為 `NT$ ¥¥¥¥¥`
- 版面寬度盡量保持穩定
- 不隱藏百分比、趨勢方向與配置比例

### 5.2 ProgressBar

用途:

- 儲蓄率達成度
- 預算使用量
- 配置偏離程度

規則:

- 三段式 tone:`calm`、`near`、`review`
- 不使用 red/green 語義
- 不只靠顏色,可搭配文字、位置、形狀

### 5.3 HealthAlertCard

等級:

| Level | Label | 視覺語言 |
|---|---|---|
| structural | 結構 | 菱形 + 較深色階 |
| review | 檢視 | 三角形 + 中等色階 |
| educational | 建議 | 方形 + 柔和色階 |
| info | 資訊 | 圓點 + 低對比 |

要求:

- 不使用驚嘆號
- 標題用中性語氣,例如「可考慮回看配置」
- CTA 不得製造壓力

### 5.4 AppShell

職責:

- Desktop sidebar
- Mobile bottom navigation
- 全域頁面背景
- 隱私模式入口
- 合規 footer

響應式規則:

- `< 640px`:Mobile layout
- `640px–1024px`:Tablet layout
- `> 1024px`:Desktop layout

---

## 6. 狀態管理

### 6.1 Riverpod Provider 分層

```txt
core providers
  privacyModeProvider
  appThemeProvider
  currentUserProvider

repository providers
  dashboardRepositoryProvider
  transactionRepositoryProvider
  budgetRepositoryProvider
  portfolioRepositoryProvider

controller providers
  dashboardControllerProvider
  importFlowControllerProvider
  budgetControllerProvider
  onboardingControllerProvider
```

### 6.2 匯入流程狀態

```txt
idle
selectingCard
uploading
parsing
reviewing
confirming
completed
failed
```

`failed` 狀態文案要中性,例如:

- 「這份檔案暫時無法解析」
- 「可以換一份 CSV,或稍後再試」

避免:

- 「錯誤!」
- 「解析失敗!」
- 紅色警告 icon

### 6.3 Dashboard Snapshot

Dashboard 不直接讀多個 feature 的 raw data。建議由 repository 聚合成 `DashboardSnapshot`,降低頁面複雜度。

```txt
DashboardSnapshot
  month
  savingsRate
  netWorth
  budgetSummary
  allocationSummary
  attentionItems
  statementSummary
  lastSyncedAt
```

---

## 7. Theme 與 Design Tokens

### 7.1 Token 類別

```txt
AppColors
  background
  surface
  surfaceMuted
  line
  textPrimary
  textSecondary
  textTertiary
  accent
  accentMuted
  budgetFixed
  budgetLiving
  budgetFlex
  assetEquity
  assetBond
  assetCash
  assetCrypto

AppTypography
  titleLarge
  titleMedium
  body
  label
  numericLarge
  numericMedium
  numericSmall

AppSpacing
  xxs = 4
  xs = 8
  sm = 12
  md = 16
  lg = 24
  xl = 32
```

### 7.2 字型

正式字型待設計端確認。Flutter 實作需確保:

- 金額與百分比支援 tabular figures 或使用等寬數字字型
- 中英文混排不破壞行高
- Mobile 上大數字不溢出

### 7.3 深淺模式

MVP 可先完成 light mode,但 token 命名必須可支援 dark mode。不要在 widget 內直接寫死顏色。

---

## 8. 資料模型草案

### 8.1 Money

```txt
Money
  amount:num
  currency:String
```

### 8.2 BudgetCategory

```txt
BudgetCategory
  id:String
  name:String
  type:fixed | living | flex
  budgetAmount:Money
  usedAmount:Money
  items:List<BudgetItem>
```

### 8.3 ImportedTransaction

```txt
ImportedTransaction
  id:String
  date:DateTime
  merchantName:String
  amount:Money
  suggestedCategoryId:String?
  selectedCategoryId:String?
  confidence:double
  isAutoClassified:bool
  ruleHint:String?
```

### 8.4 AssetAllocation

```txt
AssetAllocation
  equity:double
  bond:double
  cash:double
  crypto:double
```

### 8.5 HealthAttentionItem

```txt
HealthAttentionItem
  id:String
  level:structural | review | educational | info
  title:String
  body:String
  actionLabel:String?
  actionRoute:String?
```

---

## 9. MVP 開發順序

### Milestone 1:Flutter 專案基礎

- 建立 Flutter app
- 加入 `go_router`、`flutter_riverpod`、`intl`
- 建立 theme tokens
- 建立 `AppShell`
- 建立 mock repositories
- 完成 desktop/mobile responsive shell

驗收:

- `/` 可載入 Dashboard 空殼
- Desktop 顯示 sidebar
- Mobile 顯示 bottom nav
- 隱私模式 provider 可切換

### Milestone 2:共用資料展示元件

- `MoneyDisplay`
- `ProgressBar`
- `TrendSparkline`
- `AllocationBar`
- `HealthAlertCard`
- `DisclaimerBanner`

驗收:

- 隱私模式切換後所有 `MoneyDisplay` 即時遮罩
- 所有狀態不使用紅字與驚嘆號

### Milestone 3:Dashboard

- 儲蓄率 panel
- 淨資產 panel
- 預算 snapshot
- 投資配置 snapshot
- 值得檢視
- 本期信用卡帳單

驗收:

- 儲蓄率是第一視覺焦點
- Mobile fold 上方完整顯示儲蓄率
- Dashboard footer 有合規文字

### Milestone 4:信用卡帳單匯入

- 5-step import flow
- 上傳區
- 解析中狀態
- 審核分類頁
- 確認寫入頁

驗收:

- 50 筆 mock transactions 可在審核頁掃過
- 高信心度預設摺疊
- 低信心度預設展開
- 可一鍵接受全部建議
- 改分類不用跳大型彈窗

### Milestone 5:Budget 與 Portfolio

- `/budget`
- `/budget/history`
- `/portfolio/allocation`

驗收:

- 預算 95% 狀態仍不使用焦慮式紅色
- Portfolio 補倉方向不指定標的
- 投資頁顯示免責聲明

### Milestone 6:Onboarding

- 6 步驟 onboarding
- 每步可跳過
- 風險問卷
- 目標配置
- 預算模板

驗收:

- 新使用者 5 分鐘內可完成
- 跳過後 Dashboard 不出現挫折式空白頁

### Milestone 7:其餘頁面骨架

- Assets
- Cards
- Insights
- Settings
- Auth

驗收:

- 所有主要路由可進入
- 每個空狀態文案中性
- Settings 可切換隱私模式
- Signup 有投資建議免責確認

---

## 10. 現有原型遷移策略

### 10.1 保留作為參考

現有 React 原型提供以下參考價值:

- Dashboard 資訊排序
- 信用卡匯入審核互動
- 預算三欄視覺語言
- Portfolio 現況 vs 目標比較
- Onboarding 問卷卡片感
- 隱私模式快速切換

### 10.2 不直接移植

以下不直接沿用:

- React state router
- Chrome browser mock wrapper
- `Tweaks` 設計調整工具
- 單檔大型 component 結構
- CSS class 命名與 DOM layout

### 10.3 Flutter 重建方式

1. 先建立 Flutter design tokens
2. 把 React 原型中的元件意圖轉為 shared widgets
3. 以 mock repository 還原畫面資料
4. 先完成互動流程,再接真實 API
5. 每個 feature 獨立驗收

---

## 11. 測試策略

### 11.1 Widget tests

必測:

- `MoneyDisplay` 隱私模式
- `ProgressBar` 不同 tone
- `HealthAlertCard` level 對應
- `TransactionReviewRow` 分類切換
- `OnboardingProgress` 跳過與前進

### 11.2 Golden tests

建議覆蓋:

- Dashboard desktop
- Dashboard mobile
- Import review desktop
- Budget mobile
- Portfolio desktop
- Privacy mode on/off

### 11.3 Integration tests

核心流程:

1. 新使用者 onboarding → Dashboard
2. 信用卡帳單匯入 → 審核 → 確認 → Dashboard 更新
3. 隱私模式切換 → 多頁金額遮罩
4. Insights → Budget 下月規劃

---

## 12. 合規與文案規則

### 12.1 固定出現位置

| 文案 | 位置 |
|---|---|
| 本服務不提供投資建議 | Signup checkbox |
| 本資訊僅供參考,不構成投資建議 | Portfolio、Insights、Dashboard footer |
| AI 解讀不構成投資建議 | AI interpretation panel footer |
| 隱私政策、使用者條款 | Auth footer、Settings account |

### 12.2 禁用語氣

不得出現:

- 超支警告
- 危險
- 失敗
- 你花太多
- 連勝/連續記帳
- 排行榜

建議語氣:

- 值得檢視
- 可考慮
- 下月可以
- 目前配置
- 接近預算上限
- 剩餘可用

---

## 13. 開放決策

以下仍需後續確認:

1. Flutter 專案是否建立在同一 repository,或另開 `networth_cockpit_flutter`
2. 正式產品名稱是否沿用 NetWorth Cockpit,或採用原型中的 Northhaven
3. Flutter Web 是否需支援 PWA
4. 圖表採用 `fl_chart` 還是以 `CustomPainter` 自製
5. 是否在 MVP 即支援 dark mode
6. API 與本地 mock repository 的切換策略

---

## 14. 架構驗收清單

- [ ] Dashboard 第一視覺焦點是儲蓄率
- [ ] 所有金額都透過 `MoneyDisplay`
- [ ] 隱私模式為全域 provider,不是頁面各自處理
- [ ] 匯入流程完整支援 5 steps
- [ ] 預算與健康提示不使用紅字、驚嘆號、羞辱式文案
- [ ] Portfolio 與 Insights 顯示合規免責
- [ ] Mobile 與 desktop 有明確 layout 策略
- [ ] Feature module 不互相直接耦合
- [ ] Mock repository 可支撐 MVP 畫面開發
- [ ] 後續可替換真實 API 而不重寫 UI

---

## 15. 文件版本

| 版本 | 日期 | 變更 |
|---|---|---|
| v0.1 | 2026-04-26 | 初版,將既有設計文件與 React 原型轉為 Flutter-first 架構 |

