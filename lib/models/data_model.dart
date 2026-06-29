/// 体重记录数据模型
class WeightRecord {
  final String date; // 日期 (yyyy-MM-dd)
  final double weight; // 体重 (kg)
  final double bmi; // BMI值
  final String level; // 段位名称
  final DateTime timestamp; // 记录时间

  WeightRecord({
    required this.date,
    required this.weight,
    required this.bmi,
    required this.level,
    required this.timestamp,
  });

  /// 从JSON创建对象
  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      date: json['date'] as String,
      weight: (json['weight'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      level: json['level'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weight': weight,
      'bmi': bmi,
      'level': level,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  WeightRecord copyWith({
    String? date,
    double? weight,
    double? bmi,
    String? level,
    DateTime? timestamp,
  }) {
    return WeightRecord(
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'WeightRecord(date: $date, weight: $weight, bmi: $bmi, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightRecord &&
        other.date == date &&
        other.weight == weight &&
        other.bmi == bmi &&
        other.level == level;
  }

  @override
  int get hashCode {
    return date.hashCode ^ weight.hashCode ^ bmi.hashCode ^ level.hashCode;
  }
}

/// 用户基础信息模型
class UserProfile {
  final double height; // 身高 (cm)
  final String gender; // 性别: 'male' | 'female'
  final DateTime? lastUpdate; // 最后更新时间

  UserProfile({
    required this.height,
    required this.gender,
    this.lastUpdate,
  });

  /// 从JSON创建对象
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      height: (json['height'] as num).toDouble(),
      gender: json['gender'] as String,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'gender': gender,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  UserProfile copyWith({
    double? height,
    String? gender,
    DateTime? lastUpdate,
  }) {
    return UserProfile(
      height: height ?? this.height,
      gender: gender ?? this.gender,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() {
    return 'UserProfile(height: $height, gender: $gender)';
  }
}

/// BMI段位信息
class BMILevel {
  static const List<String> levelNames = [
    "轻盈闪电", // < 18.5
    "体重赢家", // 18.5 - 23.9
    "燃脂预备役", // 24.0 - 27.9
    "不动如山", // >= 28.0
  ];

  static const List<double> levelRanges = [
    18.5, // 轻盈闪电上限
    24.0, // 体重赢家上限
    28.0, // 燃脂预备役上限
  ];

  /// 根据BMI值获取段位
  static String getBMILevel(double bmi) {
    if (bmi < levelRanges[0]) {
      return levelNames[0]; // 轻盈闪电
    } else if (bmi < levelRanges[1]) {
      return levelNames[1]; // 体重赢家
    } else if (bmi < levelRanges[2]) {
      return levelNames[2]; // 燃脂预备役
    } else {
      return levelNames[3]; // 不动如山
    }
  }

  /// 根据段位获取建议
  static List<String> getSuggestions(String level) {
    switch (level) {
      case "轻盈闪电":
        return [
          "增加鸡蛋、牛奶等优质蛋白摄入",
          "每周3次简单力量训练",
          "避免过度节食，规律三餐",
        ];
      case "体重赢家":
        return [
          "保持规律三餐，均衡饮食",
          "每周2-3次有氧运动",
          "体重±0.5kg波动属正常，无需焦虑",
        ];
      case "燃脂预备役":
        return [
          "减少高油高糖食物，多吃蔬菜粗粮",
          "每天30分钟快走/慢跑，循序渐进",
          "控制晚餐热量，避免睡前加餐",
        ];
      case "不动如山":
        return [
          "建议咨询专业营养师制定饮食计划",
          "从低强度运动开始，避免运动损伤",
          "每日记录饮食，控制总热量摄入",
        ];
      default:
        return [];
    }
  }
}

/// 体重波动类型
enum WeightChangeType {
  lost, // 瘦了
  gained, // 胖了
  stable, // 正常波动
  none, // 首次记录
}

/// 体重变化分析结果
class WeightAnalysis {
  final WeightChangeType changeType;
  final double weightDiff; // 体重差值 (kg)
  final double currentBMI; // 当前BMI
  final String currentLevel; // 当前段位
  final String? feedbackMessage; // 反馈消息

  WeightAnalysis({
    required this.changeType,
    required this.weightDiff,
    required this.currentBMI,
    required this.currentLevel,
    this.feedbackMessage,
  });

  /// 分析体重变化
  static WeightAnalysis analyzeWeightChange({
    required double currentWeight,
    required double previousWeight,
    required double height,
  }) {
    final double currentBMI = currentWeight / ((height / 100) * (height / 100));
    final String currentLevel = BMILevel.getBMILevel(currentBMI);

    // 首次记录
    if (previousWeight == 0) {
      return WeightAnalysis(
        changeType: WeightChangeType.none,
        weightDiff: 0,
        currentBMI: currentBMI,
        currentLevel: currentLevel,
      );
    }

    final double weightDiff = currentWeight - previousWeight;
    WeightChangeType changeType;

    if (weightDiff < -0.5) {
      changeType = WeightChangeType.lost;
    } else if (weightDiff > 0.5) {
      changeType = WeightChangeType.gained;
    } else {
      changeType = WeightChangeType.stable;
    }

    return WeightAnalysis(
      changeType: changeType,
      weightDiff: weightDiff,
      currentBMI: currentBMI,
      currentLevel: currentLevel,
    );
  }
}

/// 自定义语句库模型
class CustomPhrases {
  List<String> lostPhrases = []; // 瘦了语句库
  List<String> gainedPhrases = []; // 胖了语句库
  List<String> stablePhrases = []; // 正常波动语句库

  CustomPhrases({
    required this.lostPhrases,
    required this.gainedPhrases,
    required this.stablePhrases,
  });

  /// 从JSON创建对象
  factory CustomPhrases.fromJson(Map<String, dynamic> json) {
    return CustomPhrases(
      lostPhrases: (json['lostPhrases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      gainedPhrases: (json['gainedPhrases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stablePhrases: (json['stablePhrases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'lostPhrases': lostPhrases,
      'gainedPhrases': gainedPhrases,
      'stablePhrases': stablePhrases,
    };
  }

  /// 获取随机反馈语句
  String getRandomPhrase(WeightChangeType type, bool isPurchased,
      [double currentBMI = 0.0, String currentLevel = '']) {
    List<String> phrases;

    if (isPurchased) {
      switch (type) {
        case WeightChangeType.lost:
          phrases = lostPhrases.isNotEmpty ? lostPhrases : defaultLostPhrases;
          break;
        case WeightChangeType.gained:
          phrases =
              gainedPhrases.isNotEmpty ? gainedPhrases : defaultGainedPhrases;
          break;
        case WeightChangeType.stable:
          phrases =
              stablePhrases.isNotEmpty ? stablePhrases : defaultStablePhrases;
          break;
        case WeightChangeType.none:
          return '首次记录：BMI${currentBMI.toStringAsFixed(2)}，段位：$currentLevel';
      }
    } else {
      switch (type) {
        case WeightChangeType.lost:
          phrases = defaultLostPhrases;
          break;
        case WeightChangeType.gained:
          phrases = defaultGainedPhrases;
          break;
        case WeightChangeType.stable:
          phrases = defaultStablePhrases;
          break;
        case WeightChangeType.none:
          return '首次记录：BMI${currentBMI.toStringAsFixed(2)}，段位：$currentLevel';
      }
    }

    return phrases[(DateTime.now().millisecondsSinceEpoch) % phrases.length];
  }

  /// 免费版预设文案 - 瘦了（鼓励型）
  static final List<String> defaultLostPhrases = [
    "优秀！体重悄悄下降，自律没白费～",
    "哇！瘦了哦，离理想身材又近一步～",
    "太棒了！继续保持，脂肪在偷偷溜走～",
    "给力！今天的克制，换来了体重的惊喜～",
    "超赞！体重下降，心情是不是也变好了？",
    "厉害啦！坚持下去，冲击体重赢家宝座～",
    "可喜可贺！体重掉了，值得小小庆祝～",
    "超棒的！自律在线，体重也很给面子～",
    "太牛了！慢慢瘦，这样才更易坚持哦～",
    "完美！体重下降，继续保持这个势头～",
  ];

  /// 免费版预设文案 - 胖了（调侃型）
  static final List<String> defaultGainedPhrases = [
    "哈哈，昨天的美食是不是太香了？",
    "哦豁，体重上涨了，奶茶该停一停啦～",
    "哎呀，脂肪又来报道了，今天要管住嘴～",
    "噗～体重涨了，看来快乐超标了～",
    "哦莫，体重上去了，明天可得动一动～",
    "哈哈，美食的诱惑，你还是没扛住呀～",
    "哎呀呀，体重上涨，该给脂肪减减负了～",
    "笑死，昨天的火锅/烧烤，体重记下来了～",
    "哦豁，体重超标一点点，今天清淡点哦～",
    "哈哈，脂肪在囤货，你可得拦着点～",
  ];

  /// 免费版预设文案 - 正常波动（佛系型）
  static final List<String> defaultStablePhrases = [
    "体重稳如老狗，这波动很健康～",
    "不错哦，体重无明显变化，继续保持～",
    "完美！体重波动在正常范围，超安心～",
    "挺好的，体重没起伏，状态很稳定～",
    "优秀！脂肪和自律达成了平衡～",
    "不错不错，体重稳当当，无需焦虑～",
    "佛系打卡成功，体重无明显变化～",
    "挺好的，这波动很正常，继续保持就好～",
    "体重稳如泰山，这份定力值得夸～",
    "完美！正常波动，不用为体重操心啦～",
  ];

  /// 免费版预设文案 - 胖了（调侃型）
  const List<String> _defaultGainedPhrases = [
    "哈哈，昨天的美食是不是太香了？",
    "哦豁，体重上涨了，奶茶该停一停啦～",
    "哎呀，脂肪又来报道了，今天要管住嘴～",
    "噗～体重涨了，看来快乐超标了～",
    "哦莫，体重上去了，明天可得动一动～",
    "哈哈，美食的诱惑，你还是没扛住呀～",
    "哎呀呀，体重上涨，该给脂肪减减负了～",
    "笑死，昨天的火锅/烧烤，体重记下来了～",
    "哦豁，体重超标一点点，今天清淡点哦～",
    "哈哈，脂肪在囤货，你可得拦着点～",
  ];

  /// 免费版预设文案 - 正常波动（佛系型）
  const List<String> _defaultStablePhrases = [
    "体重稳如老狗，这波动很健康～",
    "不错哦，体重无明显变化，继续保持～",
    "完美！体重波动在正常范围，超安心～",
    "挺好的，体重没起伏，状态很稳定～",
    "优秀！脂肪和自律达成了平衡～",
    "不错不错，体重稳当当，无需焦虑～",
    "佛系打卡成功，体重无明显变化～",
    "挺好的，这波动很正常，继续保持就好～",
    "体重稳如泰山，这份定力值得夸～",
    "完美！正常波动，不用为体重操心啦～",
  ];
}

/// 个性化设置模型
class PersonalSettings {
  String page1WallpaperPath = ''; // 页面1壁纸路径
  String page2WallpaperPath = ''; // 页面2壁纸路径
  String avatarPath = ''; // 头像路径
  double wallpaperOpacity = 1.0; // 壁纸透明度
  bool reminderEnabled = false; // 提醒开关
  String reminderTime = '09:00'; // 提醒时间
  String customReminderText = ''; // 自定义提醒文案

  PersonalSettings({
    this.page1WallpaperPath = '',
    this.page2WallpaperPath = '',
    this.avatarPath = '',
    this.wallpaperOpacity = 1.0,
    this.reminderEnabled = false,
    this.reminderTime = '09:00',
    this.customReminderText = '',
  });

  /// 从JSON创建对象
  factory PersonalSettings.fromJson(Map<String, dynamic> json) {
    return PersonalSettings(
      page1WallpaperPath: json['page1WallpaperPath'] as String? ?? '',
      page2WallpaperPath: json['page2WallpaperPath'] as String? ?? '',
      avatarPath: json['avatarPath'] as String? ?? '',
      wallpaperOpacity: (json['wallpaperOpacity'] as num?)?.toDouble() ?? 1.0,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String? ?? '09:00',
      customReminderText: json['customReminderText'] as String? ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'page1WallpaperPath': page1WallpaperPath,
      'page2WallpaperPath': page2WallpaperPath,
      'avatarPath': avatarPath,
      'wallpaperOpacity': wallpaperOpacity,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'customReminderText': customReminderText,
    };
  }

  /// 复制并修改部分属性
  PersonalSettings copyWith({
    String? page1WallpaperPath,
    String? page2WallpaperPath,
    String? avatarPath,
    double? wallpaperOpacity,
    bool? reminderEnabled,
    String? reminderTime,
    String? customReminderText,
  }) {
    return PersonalSettings(
      page1WallpaperPath: page1WallpaperPath ?? this.page1WallpaperPath,
      page2WallpaperPath: page2WallpaperPath ?? this.page2WallpaperPath,
      avatarPath: avatarPath ?? this.avatarPath,
      wallpaperOpacity: wallpaperOpacity ?? this.wallpaperOpacity,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      customReminderText: customReminderText ?? this.customReminderText,
    );
  }
}
