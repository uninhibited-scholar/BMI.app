import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/data_model.dart';
import '../utils/storage_utils.dart';
import '../widgets/line_chart_widget.dart';

/// 数据可视化&提醒页面
class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<WeightRecord> _weightRecords = [];
  PersonalSettings _personalSettings = PersonalSettings();
  UserProfile? _userProfile;
  bool _isPurchased = false;
  bool _isLoading = true;
  bool _hasNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 初始化通知
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _checkNotificationPermission();
  }

  /// 检查通知权限
  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _hasNotificationPermission = status.isGranted;
    });
  }

  /// 请求通知权限
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _hasNotificationPermission = status.isGranted;
    });

    if (status.isGranted) {
      _showMessage('通知权限已开启');
    } else {
      _showMessage('需要通知权限才能使用提醒功能');
    }
  }

  /// 通知点击回调
  void _onNotificationTap(NotificationResponse response) {
    // 处理通知点击事件
    print('通知被点击: ${response.payload}');
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final List<WeightRecord> records = await StorageUtils.getWeightRecords();
      final PersonalSettings settings =
          await StorageUtils.getPersonalSettings();
      final UserProfile? profile = await StorageUtils.getUserProfile();
      final bool purchased = await StorageUtils.getIsPurchased();

      setState(() {
        _weightRecords = records;
        _personalSettings = settings;
        _userProfile = profile;
        _isPurchased = purchased;
        _isLoading = false;
      });

      // 如果启用了提醒，设置定时提醒
      if (settings.reminderEnabled && _hasNotificationPermission) {
        _scheduleDailyReminder();
      }
    } catch (e) {
      print('加载数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 设置每日提醒
  Future<void> _scheduleDailyReminder() async {
    if (!_hasNotificationPermission) return;

    try {
      final String reminderText =
          _isPurchased && _personalSettings.customReminderText.isNotEmpty
              ? _personalSettings.customReminderText
              : '该记录今日体重啦～';

      final List<String> timeParts = _personalSettings.reminderTime.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      await _notifications.zonedSchedule(
        0,
        '瘦了么提醒',
        reminderText,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
          ),
          android: AndroidNotificationDetails(
            'daily_reminder',
            '每日提醒',
            channelDescription: '每日体重记录提醒',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('每日提醒设置成功: ${_personalSettings.reminderTime}');
    } catch (e) {
      print('设置提醒失败: $e');
    }
  }

  /// 计算下次提醒时间
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 取消提醒
  Future<void> _cancelReminder() async {
    await _notifications.cancel(0);
    print('提醒已取消');
  }

  /// 切换提醒开关
  Future<void> _toggleReminder(bool enabled) async {
    if (enabled && !_hasNotificationPermission) {
      await _requestNotificationPermission();
      if (!_hasNotificationPermission) {
        _showMessage('需要通知权限才能开启提醒');
        return;
      }
    }

    final PersonalSettings updatedSettings = _personalSettings.copyWith(
      reminderEnabled: enabled,
    );

    await StorageUtils.savePersonalSettings(updatedSettings);
    setState(() {
      _personalSettings = updatedSettings;
    });

    if (enabled) {
      await _scheduleDailyReminder();
      _showMessage('提醒已开启');
    } else {
      await _cancelReminder();
      _showMessage('提醒已关闭');
    }
  }

  /// 选择提醒时间
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_personalSettings.reminderTime.split(':')[0]),
        minute: int.parse(_personalSettings.reminderTime.split(':')[1]),
      ),
    );

    if (picked != null) {
      final String timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      final PersonalSettings updatedSettings = _personalSettings.copyWith(
        reminderTime: timeStr,
      );

      await StorageUtils.savePersonalSettings(updatedSettings);
      setState(() {
        _personalSettings = updatedSettings;
      });

      // 如果提醒已开启，重新设置提醒
      if (_personalSettings.reminderEnabled) {
        await _scheduleDailyReminder();
      }

      _showMessage('提醒时间已更新');
    }
  }

  /// 更新自定义提醒文案
  Future<void> _updateCustomReminderText(String text) async {
    if (text.length > 30) {
      _showMessage('提醒文案不能超过30字');
      return;
    }

    final PersonalSettings updatedSettings = _personalSettings.copyWith(
      customReminderText: text,
    );

    await StorageUtils.savePersonalSettings(updatedSettings);
    setState(() {
      _personalSettings = updatedSettings;
    });

    // 如果提醒已开启，重新设置提醒
    if (_personalSettings.reminderEnabled) {
      await _scheduleDailyReminder();
    }

    _showMessage('自定义提醒文案已保存');
  }

  /// 导出CSV
  Future<void> _exportCSV() async {
    if (_weightRecords.isEmpty) {
      _showMessage('暂无数据可导出');
      return;
    }

    try {
      final String csvData = await StorageUtils.exportWeightRecordsToCSV();
      if (csvData.isEmpty) {
        _showMessage('导出失败');
        return;
      }

      final Directory? directory = await getApplicationDocumentsDirectory();
      final String path = '${directory?.path}/瘦了么/体重记录.csv';

      final File file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(csvData);

      _showMessage('CSV文件已导出到：$path');
    } catch (e) {
      print('导出CSV失败: $e');
      _showMessage('导出失败，请重试');
    }
  }

  /// 删除旧数据
  Future<void> _deleteOldRecords() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定删除3个月前的历史数据吗？删除后不可恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageUtils.deleteOldRecords();
        await _loadData(); // 重新加载数据
        _showMessage('旧数据删除成功');
      } catch (e) {
        _showMessage('删除失败，请重试');
      }
    }
  }

  /// 显示消息
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String currentLevel =
        _userProfile != null && _weightRecords.isNotEmpty
            ? _weightRecords.last.level
            : '';
    final List<String> suggestions =
        currentLevel.isNotEmpty ? BMILevel.getSuggestions(currentLevel) : [];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: _personalSettings.page2WallpaperPath.isNotEmpty
              ? DecorationImage(
                  image: AssetImage(_personalSettings.page2WallpaperPath),
                  fit: BoxFit.cover,
                  opacity: _personalSettings.wallpaperOpacity,
                )
              : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                const Text(
                  '数据统计',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // 折线图（占60%空间）
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _weightRecords.isNotEmpty
                      ? LineChartWidget(records: _weightRecords)
                      : const Center(
                          child: Text(
                            '暂无数据\n开始记录体重后显示图表',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // 段位建议
                if (suggestions.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前段位：$currentLevel',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...suggestions.map((suggestion) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 提醒设置
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '每日提醒',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _personalSettings.reminderEnabled,
                            onChanged: _toggleReminder,
                            activeColor: Colors.orange,
                          ),
                        ],
                      ),
                      if (_personalSettings.reminderEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('提醒时间：'),
                            TextButton(
                              onPressed: _selectReminderTime,
                              child: Text(_personalSettings.reminderTime),
                            ),
                          ],
                        ),
                        if (_isPurchased) ...[
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: '自定义提醒文案（30字内）',
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 30,
                            onChanged: (value) {
                              // 延迟保存，避免频繁写入
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                if (mounted) {
                                  _updateCustomReminderText(value);
                                }
                              });
                            },
                            controller: TextEditingController(
                              text: _personalSettings.customReminderText,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 数据管理按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _weightRecords.isNotEmpty ? _exportCSV : null,
                        icon: const Icon(Icons.download),
                        label: const Text('导出CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _weightRecords.isNotEmpty
                            ? _deleteOldRecords
                            : null,
                        icon: const Icon(Icons.delete),
                        label: const Text('删除旧数据'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // 底部留白
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 为了使用时间功能，需要导入timezone
