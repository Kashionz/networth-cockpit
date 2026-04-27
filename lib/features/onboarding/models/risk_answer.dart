enum RiskLevel { l1, l2, l3, l4, l5 }

extension RiskLevelX on RiskLevel {
  String get code {
    return switch (this) {
      RiskLevel.l1 => 'L1',
      RiskLevel.l2 => 'L2',
      RiskLevel.l3 => 'L3',
      RiskLevel.l4 => 'L4',
      RiskLevel.l5 => 'L5',
    };
  }

  String get label {
    return switch (this) {
      RiskLevel.l1 => '保守',
      RiskLevel.l2 => '穩健保守',
      RiskLevel.l3 => '平衡',
      RiskLevel.l4 => '穩健成長',
      RiskLevel.l5 => '積極',
    };
  }
}

enum AllocationBucket { equity, bond, cash }

extension AllocationBucketX on AllocationBucket {
  String get label {
    return switch (this) {
      AllocationBucket.equity => '股票',
      AllocationBucket.bond => '債券',
      AllocationBucket.cash => '現金',
    };
  }
}

class AssetAllocation {
  const AssetAllocation({
    required this.equity,
    required this.bond,
    required this.cash,
  });

  factory AssetAllocation.fromRiskLevel(RiskLevel level) {
    return switch (level) {
      RiskLevel.l1 => const AssetAllocation(equity: 20, bond: 50, cash: 30),
      RiskLevel.l2 => const AssetAllocation(equity: 40, bond: 40, cash: 20),
      RiskLevel.l3 => const AssetAllocation(equity: 60, bond: 30, cash: 10),
      RiskLevel.l4 => const AssetAllocation(equity: 75, bond: 20, cash: 5),
      RiskLevel.l5 => const AssetAllocation(equity: 90, bond: 5, cash: 5),
    };
  }

  final int equity;
  final int bond;
  final int cash;

  int get total => equity + bond + cash;

  int valueFor(AllocationBucket bucket) {
    return switch (bucket) {
      AllocationBucket.equity => equity,
      AllocationBucket.bond => bond,
      AllocationBucket.cash => cash,
    };
  }

  AssetAllocation rebalanced(AllocationBucket bucket, double nextValue) {
    final target = nextValue.round().clamp(0, 100);
    final remainder = 100 - target;

    final otherOne = switch (bucket) {
      AllocationBucket.equity => bond,
      AllocationBucket.bond => equity,
      AllocationBucket.cash => equity,
    };
    final otherTwo = switch (bucket) {
      AllocationBucket.equity => cash,
      AllocationBucket.bond => cash,
      AllocationBucket.cash => bond,
    };

    final otherTotal = otherOne + otherTwo;
    final updatedOne = otherTotal == 0
        ? remainder ~/ 2
        : (otherOne / otherTotal * remainder).round();
    final updatedTwo = remainder - updatedOne;

    return switch (bucket) {
      AllocationBucket.equity => AssetAllocation(
        equity: target,
        bond: updatedOne,
        cash: updatedTwo,
      ),
      AllocationBucket.bond => AssetAllocation(
        equity: updatedOne,
        bond: target,
        cash: updatedTwo,
      ),
      AllocationBucket.cash => AssetAllocation(
        equity: updatedOne,
        bond: updatedTwo,
        cash: target,
      ),
    };
  }
}

class RiskAnswer {
  const RiskAnswer({
    required this.questionId,
    required this.choiceId,
    required this.score,
  });

  final String questionId;
  final String choiceId;
  final int score;
}

class RiskChoice {
  const RiskChoice({
    required this.id,
    required this.label,
    required this.score,
  });

  final String id;
  final String label;
  final int score;
}

class RiskQuestion {
  const RiskQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String prompt;
  final List<RiskChoice> choices;
}

RiskLevel classifyRiskLevelFromAnswers(
  Map<String, RiskAnswer> answers, {
  List<RiskQuestion> questions = kRiskQuestions,
}) {
  if (questions.isEmpty) {
    return RiskLevel.l3;
  }

  var sum = 0;
  for (final question in questions) {
    sum += answers[question.id]?.score ?? 3;
  }

  final average = sum / questions.length;
  return classifyRiskLevelFromAverage(average);
}

RiskLevel classifyRiskLevelFromAverage(double averageScore) {
  if (averageScore <= 1.8) {
    return RiskLevel.l1;
  }
  if (averageScore <= 2.6) {
    return RiskLevel.l2;
  }
  if (averageScore <= 3.4) {
    return RiskLevel.l3;
  }
  if (averageScore <= 4.2) {
    return RiskLevel.l4;
  }
  return RiskLevel.l5;
}

const kRiskQuestions = [
  RiskQuestion(
    id: 'horizon',
    prompt: '這筆投資資金你預計多久後才會使用？',
    choices: [
      RiskChoice(id: 'horizon_1', label: '1 年內就可能動用', score: 1),
      RiskChoice(id: 'horizon_2', label: '1-3 年內可能會用到', score: 2),
      RiskChoice(id: 'horizon_3', label: '3-5 年後再評估', score: 3),
      RiskChoice(id: 'horizon_4', label: '5-10 年都可持有', score: 4),
      RiskChoice(id: 'horizon_5', label: '10 年以上都能長期持有', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'drawdown',
    prompt: '若市場短期下跌 20%-30%，你比較可能怎麼做？',
    choices: [
      RiskChoice(id: 'drawdown_1', label: '先降低部位，保留現金', score: 1),
      RiskChoice(id: 'drawdown_2', label: '先觀望，等穩定再決定', score: 2),
      RiskChoice(id: 'drawdown_3', label: '維持原計畫，不特別加減碼', score: 3),
      RiskChoice(id: 'drawdown_4', label: '分批加碼，拉低平均成本', score: 4),
      RiskChoice(id: 'drawdown_5', label: '願意在波動中積極加碼', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'income_stability',
    prompt: '你目前的收入穩定度如何？',
    choices: [
      RiskChoice(id: 'income_1', label: '短期波動較大，需要保守安排', score: 1),
      RiskChoice(id: 'income_2', label: '偶有波動，仍以穩定為主', score: 2),
      RiskChoice(id: 'income_3', label: '大致穩定，可接受一般波動', score: 3),
      RiskChoice(id: 'income_4', label: '穩定且有餘裕可做長期投資', score: 4),
      RiskChoice(id: 'income_5', label: '穩定度高，且有多元收入來源', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'knowledge',
    prompt: '你對投資商品與風險的熟悉程度？',
    choices: [
      RiskChoice(id: 'knowledge_1', label: '剛開始接觸，偏好簡單方案', score: 1),
      RiskChoice(id: 'knowledge_2', label: '了解基本概念，仍在建立習慣', score: 2),
      RiskChoice(id: 'knowledge_3', label: '能看懂常見指標與配置比例', score: 3),
      RiskChoice(id: 'knowledge_4', label: '可自行比較商品並做資產配置', score: 4),
      RiskChoice(id: 'knowledge_5', label: '有完整策略，能管理較高波動', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'goal',
    prompt: '你的主要投資目標更接近哪一種？',
    choices: [
      RiskChoice(id: 'goal_1', label: '保本與資金可用性', score: 1),
      RiskChoice(id: 'goal_2', label: '穩定增值，波動不要太大', score: 2),
      RiskChoice(id: 'goal_3', label: '平衡成長與穩定', score: 3),
      RiskChoice(id: 'goal_4', label: '追求中長期成長', score: 4),
      RiskChoice(id: 'goal_5', label: '以長期資本成長為優先', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'liquidity',
    prompt: '你需要保留可立即動用的資金比例大概是？',
    choices: [
      RiskChoice(id: 'liquidity_1', label: '很高，超過 40%', score: 1),
      RiskChoice(id: 'liquidity_2', label: '偏高，約 25%-40%', score: 2),
      RiskChoice(id: 'liquidity_3', label: '中等，約 15%-25%', score: 3),
      RiskChoice(id: 'liquidity_4', label: '偏低，約 5%-15%', score: 4),
      RiskChoice(id: 'liquidity_5', label: '很低，5% 內即可', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'volatility',
    prompt: '你能接受投資組合一年內的波動範圍約為？',
    choices: [
      RiskChoice(id: 'volatility_1', label: '5% 以內', score: 1),
      RiskChoice(id: 'volatility_2', label: '5%-10%', score: 2),
      RiskChoice(id: 'volatility_3', label: '10%-15%', score: 3),
      RiskChoice(id: 'volatility_4', label: '15%-20%', score: 4),
      RiskChoice(id: 'volatility_5', label: '20% 以上也可以', score: 5),
    ],
  ),
  RiskQuestion(
    id: 'habit',
    prompt: '面對市場消息時，你通常的投資習慣是？',
    choices: [
      RiskChoice(id: 'habit_1', label: '先暫停投入，優先保留彈性', score: 1),
      RiskChoice(id: 'habit_2', label: '減少投入，等趨勢清楚再說', score: 2),
      RiskChoice(id: 'habit_3', label: '維持固定投入節奏', score: 3),
      RiskChoice(id: 'habit_4', label: '趁回檔做分批調整', score: 4),
      RiskChoice(id: 'habit_5', label: '會主動利用波動做策略配置', score: 5),
    ],
  ),
];
