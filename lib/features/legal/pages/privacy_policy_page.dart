import 'package:flutter/material.dart';

import '../widgets/legal_document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: '隱私政策',
      lastUpdated: '2026-04-27',
      intro: '本隱私政策說明 NetWorth Cockpit 如何蒐集、使用、保存與保護你的資料。使用本服務即代表你理解並同意本政策內容。',
      sections: [
        LegalSection(
          title: '1. 蒐集資料範圍',
          paragraphs: [
            '我們蒐集你主動提供的帳號資訊、資產配置、預算分類與交易紀錄，以及你在 App 內設定的提醒偏好。',
            '為了維持服務品質，我們可能記錄裝置型態、瀏覽器資訊、操作事件與錯誤日誌，但不會主動蒐集你未提交的金融帳戶憑證。',
          ],
        ),
        LegalSection(
          title: '2. 使用目的',
          paragraphs: [
            '蒐集資料僅用於提供個人財務儀表板、提醒通知、月度回顧與功能優化。',
            '除非經你授權或法律要求，我們不會將可識別個人資料出售或揭露給第三方行銷用途。',
          ],
        ),
        LegalSection(
          title: '3. 儲存與保護',
          paragraphs: [
            '我們採取合理安全措施保護資料，包括存取控管、傳輸加密與權限分級。',
            '你可隨時申請資料匯出或刪除。依法律義務需保存者，將於法定期間內保存後刪除或匿名化。',
          ],
        ),
        LegalSection(
          title: '4. 你的權利',
          paragraphs: [
            '你可查詢、修正、下載或刪除個人資料，並可關閉通知與 AI 分析功能。',
            '如對隱私政策有疑問，可透過客服管道聯繫我們，我們將於合理時間內回覆。',
          ],
        ),
      ],
    );
  }
}
