import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_model.dart';

/// 本地存储工具类
class StorageUtils {
  static const String _keyHeight = 'user_height';
  static const String _keyGender = 'user_gender';
  static const String _keyWeightRecords = 'weight_records';
  static const String _keyCustomPhrases = 'custom_phrases';
  static const String _keyPersonalSettings = 'personal_settings';
  static const String _keyIsPurchased = 'is_purchased';
  static const String _keyLastPurchaseId = 'last_purchase_id';
  static const String _keyLastWeight = 'last_weight';
  static const String _keyHasShownPrivacy = 'has_shown_privacy';

  /// 保存用户基础信息
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyHeight, profile.height);
      await prefs.setString(_keyGender, profile.gender);
      await prefs.setString(
          'last_profile_update', DateTime.now().toIso8601String());
      print('用户基础信息保存成功');
    } catch (e) {
      print('保存用户基础信息失败: $e');
      rethrow;
    }
  }

  /// 获取用户基础信息
  static Future<UserProfile?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? height = prefs.getDouble(_keyHeight);
      final String? gender = prefs.getString(_keyGender);

      if (height == null || gender == null) {
        return null;
      }

      final String? lastUpdateStr = prefs.getString('last_profile_update');
      final DateTime? lastUpdate =
          lastUpdateStr != null ? DateTime.parse(lastUpdateStr) : null;

      return UserProfile(
        height: height,
        gender: gender,
        lastUpdate: lastUpdate,
      );
    } catch (e) {
      print('获取用户基础信息失败: $e');
      return null;
    }
  }

  /// 保存体重记录（近30天数据）
  static Future<void> saveWeightRecord(WeightRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<WeightRecord> records = await getWeightRecords();

      // 检查是否已存在相同日期的记录，如果存在则替换，否则添加
      final int existingIndex =
          records.indexWhere((r) => r.date == record.date);
      if (existingIndex != -1) {
        records[existingIndex] = record;
      } else {
        records.add(record);
      }

      // 按日期排序
      records.sort((a, b) => a.date.compareTo(b.date));

      // 只保留最近30天数据
      if (records.length > 30) {
        records.removeRange(0, records.length - 30);
      }

      // 转换为JSON并保存
      final List<String> jsonList =
          records.map((record) => jsonEncode(record.toJson())).toList();
      await prefs.setStringList(_keyWeightRecords, jsonList);

      // 保存最新体重（用于波动分析）
      await prefs.setDouble(_keyLastWeight, record.weight);

      print('体重记录保存成功，当前共${records.length}条记录');
    } catch (e) {
      print('保存体重记录失败: $e');
      rethrow;
    }
  }

  /// 获取体重记录列表
  static Future<List<WeightRecord>> getWeightRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_keyWeightRecords);

      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }

      final List<WeightRecord> records = jsonList
          .map((jsonStr) {
            try {
              final Map<String, dynamic> json = jsonDecode(jsonStr);
              return WeightRecord.fromJson(json);
            } catch (e) {
              print('解析体重记录失败: $e');
              return null;
            }
          })
          .where((record) => record != null)
          .cast<WeightRecord>()
          .toList();

      // 按日期排序
      records.sort((a, b) => a.date.compareTo(b.date));

      return records;
    } catch (e) {
      print('获取体重记录失败: $e');
      return [];
    }
  }

  /// 获取最新体重
  static Future<double> getLastWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyLastWeight) ?? 0.0;
    } catch (e) {
      print('获取最新体重失败: $e');
      return 0.0;
    }
  }

  /// 获取昨天的体重记录
  static Future<WeightRecord?> getYesterdayRecord() async {
    try {
      final List<WeightRecord> records = await getWeightRecords();
      if (records.isEmpty) return null;

      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final String yesterdayStr =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      return records.where((r) => r.date == yesterdayStr).firstOrNull;
    } catch (e) {
      print('获取昨天体重记录失败: $e');
      return null;
    }
  }

  /// 保存自定义语句库
  static Future<void> saveCustomPhrases(CustomPhrases phrases) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(phrases.toJson());
      await prefs.setString(_keyCustomPhrases, jsonStr);
      print('自定义语句库保存成功');
    } catch (e) {
      print('保存自定义语句库失败: $e');
      rethrow;
    }
  }

  /// 获取自定义语句库
  static Future<CustomPhrases> getCustomPhrases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyCustomPhrases);

      if (jsonStr == null || jsonStr.isEmpty) {
        return CustomPhrases(
          lostPhrases: [],
          gainedPhrases: [],
          stablePhrases: [],
        );
      }

      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return CustomPhrases.fromJson(json);
    } catch (e) {
      print('获取自定义语句库失败: $e');
      return CustomPhrases(
        lostPhrases: [],
        gainedPhrases: [],
        stablePhrases: [],
      );
    }
  }

  /// 保存个性化设置
  static Future<void> savePersonalSettings(PersonalSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(settings.toJson());
      await prefs.setString(_keyPersonalSettings, jsonStr);
      print('个性化设置保存成功');
    } catch (e) {
      print('保存个性化设置失败: $e');
      rethrow;
    }
  }

  /// 获取个性化设置
  static Future<PersonalSettings> getPersonalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyPersonalSettings);

      if (jsonStr == null || jsonStr.isEmpty) {
        return PersonalSettings();
      }

      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return PersonalSettings.fromJson(json);
    } catch (e) {
      print('获取个性化设置失败: $e');
      return PersonalSettings();
    }
  }

  /// 获取付费状态
  static Future<bool> getIsPurchased() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsPurchased) ?? false;
    } catch (e) {
      print('获取付费状态失败: $e');
      return false;
    }
  }

  /// 保存付费状态
  static Future<void> saveIsPurchased(bool isPurchased) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsPurchased, isPurchased);
      print('付费状态保存成功: $isPurchased');
    } catch (e) {
      print('保存付费状态失败: $e');
      rethrow;
    }
  }

  /// 保存订单ID
  static Future<void> saveLastPurchaseId(String purchaseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastPurchaseId, purchaseId);
      print('订单ID保存成功: $purchaseId');
    } catch (e) {
      print('保存订单ID失败: $e');
    }
  }

  /// 获取订单ID
  static Future<String> getLastPurchaseId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastPurchaseId) ?? '';
    } catch (e) {
      print('获取订单ID失败: $e');
      return '';
    }
  }

  /// 检查是否已显示隐私政策
  static Future<bool> getHasShownPrivacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasShownPrivacy) ?? false;
    } catch (e) {
      print('获取隐私政策显示状态失败: $e');
      return false;
    }
  }

  /// 设置隐私政策显示状态
  static Future<void> setHasShownPrivacy(bool hasShown) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasShownPrivacy, hasShown);
      print('隐私政策显示状态设置成功: $hasShown');
    } catch (e) {
      print('设置隐私政策显示状态失败: $e');
    }
  }

  /// 删除3个月前的数据
  static Future<void> deleteOldRecords() async {
    try {
      final List<WeightRecord> records = await getWeightRecords();
      final DateTime threeMonthsAgo =
          DateTime.now().subtract(const Duration(days: 90));

      final List<WeightRecord> filteredRecords = records
          .where((record) => record.timestamp.isAfter(threeMonthsAgo))
          .toList();

      if (filteredRecords.length != records.length) {
        final List<String> jsonList = filteredRecords
            .map((record) => jsonEncode(record.toJson()))
            .toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_keyWeightRecords, jsonList);

        print('删除${records.length - filteredRecords.length}条旧记录');
      }
    } catch (e) {
      print('删除旧记录失败: $e');
      rethrow;
    }
  }

  /// 清空所有数据（用于重置应用）
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('所有数据已清空');
    } catch (e) {
      print('清空数据失败: $e');
      rethrow;
    }
  }

  /// 导出体重记录为CSV格式
  static Future<String> exportWeightRecordsToCSV() async {
    try {
      final List<WeightRecord> records = await getWeightRecords();
      if (records.isEmpty) {
        return '';
      }

      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('日期,体重(kg),BMI,段位');

      for (final record in records) {
        csvBuffer.writeln(
            '${record.date},${record.weight.toStringAsFixed(1)},${record.bmi.toStringAsFixed(2)},${record.level}');
      }

      return csvBuffer.toString();
    } catch (e) {
      print('导出CSV失败: $e');
      rethrow;
    }
  }

  /// 批量导入语句（从文本）
  static Future<void> importPhrasesFromText(String text, String type) async {
    try {
      final CustomPhrases currentPhrases = await getCustomPhrases();
      final List<String> lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      CustomPhrases updatedPhrases;
      switch (type) {
        case 'lost':
          updatedPhrases = CustomPhrases(
            lostPhrases: [...currentPhrases.lostPhrases, ...lines],
            gainedPhrases: currentPhrases.gainedPhrases,
            stablePhrases: currentPhrases.stablePhrases,
          );
          break;
        case 'gained':
          updatedPhrases = CustomPhrases(
            lostPhrases: currentPhrases.lostPhrases,
            gainedPhrases: [...currentPhrases.gainedPhrases, ...lines],
            stablePhrases: currentPhrases.stablePhrases,
          );
          break;
        case 'stable':
          updatedPhrases = CustomPhrases(
            lostPhrases: currentPhrases.lostPhrases,
            gainedPhrases: currentPhrases.gainedPhrases,
            stablePhrases: [...currentPhrases.stablePhrases, ...lines],
          );
          break;
        default:
          throw ArgumentError('无效的语句类型: $type');
      }

      await saveCustomPhrases(updatedPhrases);
      print('成功导入${lines.length}条$type语句');
    } catch (e) {
      print('导入语句失败: $e');
      rethrow;
    }
  }
}
