import 'package:flutter/material.dart';

import '../widgets/legal_document_page.dart';

class AiDisclosureTemplatePage extends StatelessWidget {
  const AiDisclosureTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'AI 解讀模板與揭露',
      lastUpdated: '2026-04-27',
      intro: '本頁提供 AI 解讀內容的標準揭露模板，協助你在閱讀月報與提醒建議時理解模型限制與使用邊界。',
      sections: [
        LegalSection(
          title: '1. 模板用途',
          paragraphs: [
            'AI 解讀內容僅供你快速摘要財務趨勢與風險提示，不能取代專業投資、法律或稅務建議。',
            '你可將下列模板用於匯出報告、團隊審查或內部稽核附註。',
          ],
        ),
        LegalSection(
          title: '2. 建議揭露模板',
          paragraphs: [
            '「本段內容由 AI 依據使用者提供資料自動生成，可能受資料完整性、模型偏誤與情境限制影響，僅供參考，不構成投資建議。」',
            '「重要決策前，請自行驗證關鍵數據並諮詢合格專業人士。」',
          ],
        ),
        LegalSection(
          title: '3. 品質與風險說明',
          paragraphs: [
            'AI 可能產生過度簡化、延遲或不完整結論。若資料缺漏，輸出結果可能失真。',
            '你可透過關閉 AI 功能、調整資料來源、或加入人工覆核流程降低風險。',
          ],
        ),
        LegalSection(
          title: '4. 使用建議',
          paragraphs: [
            '請將 AI 解讀視為初步草稿，搭配原始交易與資產資料一起檢視。',
            '若輸出內容與實際情況不符，請以人工判讀為準並回報系統以利後續優化。',
          ],
        ),
      ],
    );
  }
}
