import '../mock/mock_transactions.dart';

class TransactionRepository {
  const TransactionRepository();

  List<String> getReviewMerchantNames() => MockTransactions.reviewMerchantNames;
}
