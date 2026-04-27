import 'package:flutter/material.dart';

import '../widgets/legal_document_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: '使用者條款',
      lastUpdated: '2026-04-27',
      intro: '本條款規範你使用 NetWorth Cockpit 之權利與義務。若你不同意本條款，請停止使用本服務。',
      sections: [
        LegalSection(
          title: '1. 服務定位',
          paragraphs: [
            '本服務提供財務資料整理、提醒與視覺化分析工具，屬資訊整理與決策輔助，不構成投資建議、法律意見或稅務意見。',
            '你應自行判斷任何投資、借貸、保險與財務決策風險，必要時尋求專業顧問。',
          ],
        ),
        LegalSection(
          title: '2. 帳號責任',
          paragraphs: [
            '你應提供真實且完整資料，並妥善保管登入憑證。因帳號保管不當造成之風險，由你自行承擔。',
            '若發現未經授權使用情形，請立即通知我們以便啟動保護流程。',
          ],
        ),
        LegalSection(
          title: '3. 可接受使用',
          paragraphs: [
            '你不得利用本服務從事違法、侵權、干擾系統或濫用自動化請求等行為。',
            '若有重大違規，我們得依情節限制功能、暫停或終止帳號並保留法律追訴權。',
          ],
        ),
        LegalSection(
          title: '4. 責任限制與條款調整',
          paragraphs: [
            '在法律允許範圍內，本服務對間接、附帶或衍生性損害不負賠償責任。',
            '我們得因法規或產品調整更新條款，並以 App 內公告或你留存的聯絡方式通知。',
          ],
        ),
      ],
    );
  }
}
