# NetWorth Cockpit PRD 缺口 ToDo List

更新日期: 2026-04-27
來源: `PRD_v0.1.md` 與目前程式碼差異盤點

## P0（阻塞型，先完成）

- [x] **P0-1 補齊 Supabase 核心資料模型與 RLS**
  - 建立資料表: `assets`, `prices_daily`, `accounts`, `holdings`, `credit_cards`, `card_statements`, `transactions`, `subscriptions`, `monthly_budgets`, `target_allocations`, `portfolio_snapshots`, `insights`
  - 補齊索引與外鍵
  - 補齊 user-scoped RLS policy
  - 驗收: 以 migration 可完整重建 DB，且各 user 只能讀寫自己的資料

- [x] **P0-2 各模組去 Mock 化，改走真實 Repository**
  - Dashboard / Assets / Budget / Portfolio / Transactions 改為 Supabase 資料來源
  - 保留 fallback（可選）但預設走正式資料流
  - 驗收: 重整後資料持久存在，新增/編輯/刪除可回查 DB

- [x] **P0-3 完成信用卡匯入可用版（先 CSV）**
  - 上傳 CSV（非 sample-only）
  - 解析與分類審核
  - 確認後寫入 `transactions` 並產生 `card_statements`
  - 驗收: 可使用真實 CSV 從上傳走到寫入完成

- [x] **P0-4 補齊資產欄位與估值流程**
  - 資產欄位新增: `symbol`, `quantity`, `cost_basis`, `currency`, `market`
  - 行情更新寫入 `prices_daily`
  - 估值回寫持倉與投組
  - 驗收: 估值可隨行情更新且可追溯日價格

- [x] **P0-5 匯出與刪帳流程正式化**
  - 匯出: 產生可下載 CSV / JSON 實體檔
  - 刪帳: 申請刪除、30 天緩衝、到期清除、可取消
  - 驗收: 流程可操作、狀態可追蹤

- [x] **P0-6 建立排程任務骨架與執行紀錄**
  - 任務: `update_prices`, `daily_snapshot`, `monthly_report`, `health_check`
  - 建立可觀測執行 log 與重試機制
  - 驗收: 任務可手動觸發、可看到成功/失敗結果

## P1（核心體驗完整化）

- [x] **P1-1 訂閱服務管理與自動扣款**
  - Subscriptions CRUD
  - 到期自動生成 `transaction`
  - 驗收: 到期日自動入帳，來源可追溯

- [x] **P1-2 月報自動生成與歷史瀏覽**
  - 每月自動產生月報資料（含快照）
  - 歷史月份可切換瀏覽
  - 驗收: 月報可回看，不依賴當下即時計算

- [x] **P1-3 淨值時間線與里程碑系統**
  - 淨值時間線圖（資產/負債/淨值）
  - 里程碑一次性觸發與記錄
  - 驗收: 里程碑不重複洗版，時間線可顯示趨勢

- [x] **P1-4 L1 規則層與產品規則一致化**
  - 規則對齊: 應繳 > 現金、預備金 < 3、儲蓄率 < 10%、偏離 > 10%
  - Dashboard / 通知 / 月報統一同一規則來源
  - 驗收: 同一輸入在不同頁面顯示一致結論

- [x] **P1-5 真正推播通知**
  - Web Push / 行動推播（依平台）
  - 通知偏好持久化
  - 驗收: 可收到推播且可依類別開關

- [x] **P1-6 PWA 安裝體驗打通**
  - Flutter 端接上 `beforeinstallprompt` 可安裝能力
  - 顯示支援狀態與安裝引導
  - 驗收: 支援瀏覽器可直接觸發安裝

## P2（進階分析與品質）

- [x] **P2-1 L2 量化分析補齊**
  - 報酬率、波動率、Sharpe、最大回撤、基準比較、壓力測試
  - 驗收: API 與 UI 可完整顯示量化結果

- [x] **P2-2 L3 AI 解讀治理**
  - 僅使用 L1/L2 注入數字
  - 快取與追溯欄位完整化
  - 失敗 fallback 不中斷核心流程
  - 驗收: 輸出可追溯且符合免責規範

- [x] **P2-3 相關性矩陣與集中度進階分析**
  - 相關性矩陣視圖與提示
  - 驗收: 可識別高同向風險

- [x] **P2-4 風險問卷重新評估機制**
  - 12 個月提醒
  - 重大事件觸發再評估入口
  - 驗收: 可建立再評估任務並追蹤完成狀態

- [x] **P2-5 品質工程補強**
  - 核心 E2E（匯入、月報、刪帳）
  - 資料一致性測試與監控告警
  - 驗收: 核心流程有自動化回歸保護

## 建議實作順序

1. P0-1 補 schema + RLS
2. P0-2 去 mock 化（核心 CRUD）
3. P0-3 信用卡 CSV 匯入真寫入
4. P0-4 資產欄位 + 估值
5. P0-6 排程骨架 + 可觀測性
6. P0-5 匯出與刪帳正式流程
7. P1-1 訂閱自動扣款
8. P1-2 月報自動生成 + 歷史
9. P1-4 L1 規則一致化
10. P1-5 真推播通知
11. P1-3 淨值時間線 + 里程碑
12. P1-6 PWA 安裝打通
13. P2-1 / P2-2 / P2-3 / P2-4 / P2-5 依資源排程
