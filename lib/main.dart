import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ShouLeMeApp());
}

class ShouLeMeApp extends StatelessWidget {
  const ShouLeMeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '瘦了么',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'PingFang SC',
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _showPrivacyDialog();
  }

  void _showPrivacyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownPrivacy = prefs.getBool('hasShownPrivacy') ?? false;

    if (!hasShownPrivacy && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('隐私政策'),
            content: const Text(
              '本APP的自定义壁纸、头像、语句库、提醒文案功能均为本地工具功能，'
              '用户上传的图片、编辑的文本仅存储在用户个人设备中，本APP不收集、不存储、'
              '不分发任何用户上传/编辑的内容。如用户上传/编辑侵权内容引发法律纠纷，'
              '全部责任由用户自行承担，本APP不承担连带责任。',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.setBool('hasShownPrivacy', true);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('我已阅读并同意'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const RecordPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('瘦了么'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '记录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: '图表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class WeightRecord {
  final String date;
  final double weight;
  final double bmi;
  final String level;

  WeightRecord({
    required this.date,
    required this.weight,
    required this.bmi,
    required this.level,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      date: json['date'] as String,
      weight: (json['weight'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      level: json['level'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weight': weight,
      'bmi': bmi,
      'level': level,
    };
  }
}

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final TextEditingController _heightController =
      TextEditingController(text: '170');
  final TextEditingController _weightController =
      TextEditingController(text: '65');
  final TextEditingController _genderController =
      TextEditingController(text: '男');
  bool _isFirstTime = true;
  List<WeightRecord> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? height = prefs.getDouble('user_height');
      final String? gender = prefs.getString('user_gender');

      if (height != null && gender != null) {
        setState(() {
          _isFirstTime = false;
          _heightController.text = height.toString();
          _genderController.text = gender;
        });
      }

      // 加载历史记录
      final recordsJson = prefs.getStringList('weight_records') ?? [];
      setState(() {
        _records = recordsJson
            .map((json) =>
                WeightRecord.fromJson(Map<String, dynamic>.fromEntries(
                  json.split(',').map((e) {
                    final parts = e.split(':');
                    return MapEntry(parts[0].trim(), parts[1].trim());
                  }),
                )))
            .toList();
      });
    } catch (e) {
      print('加载用户数据失败: $e');
    }
  }

  double _calculateBMI() {
    final double height = double.tryParse(_heightController.text) ?? 170.0;
    final double weight = double.tryParse(_weightController.text) ?? 65.0;
    return weight / ((height / 100) * (height / 100));
  }

  String _getBMILevel(double bmi) {
    if (bmi < 18.5) return '轻盈闪电';
    if (bmi < 24.0) return '体重赢家';
    if (bmi < 28.0) return '燃脂预备役';
    return '不动如山';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '轻盈闪电':
        return Colors.blue;
      case '体重赢家':
        return Colors.green;
      case '燃脂预备役':
        return Colors.orange;
      case '不动如山':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFeedbackMessage(double weightDiff) {
    if (weightDiff > 0.5) {
      return [
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
      ][(DateTime.now().millisecond % 10)];
    } else if (weightDiff < -0.5) {
      return [
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
      ][(DateTime.now().millisecond % 10)];
    } else {
      return [
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
      ][(DateTime.now().millisecond % 10)];
    }
  }

  Color _getFeedbackColor(double weightDiff) {
    if (weightDiff > 0.5) return Colors.red;
    if (weightDiff < -0.5) return Colors.green;
    return Colors.grey;
  }

  String _getFeedbackTitle(double weightDiff) {
    if (weightDiff > 0.5) return '胖了～';
    if (weightDiff < -0.5) return '瘦了！';
    return '正常波动';
  }

  Future<void> _saveRecord() async {
    if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height == null || weight == null) {
      _showMessage('请输入有效数字');
      return;
    }

    if (height! < 100 || height! > 250) {
      _showMessage('身高输入异常，请检查');
      return;
    }

    if (weight! < 20 || weight! > 300) {
      _showMessage('体重输入异常，请检查');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存用户基础信息
      await prefs.setDouble('user_height', height!);
      await prefs.setString('user_gender', _genderController.text);

      // 计算BMI和段位
      final double bmi = _calculateBMI();
      final String level = _getBMILevel(bmi);

      // 创建记录
      final DateTime now = DateTime.now();
      final String dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final record = WeightRecord(
        date: dateStr,
        weight: weight!,
        bmi: bmi,
        level: level,
      );

      // 计算体重变化
      double weightDiff = 0;
      if (_records.isNotEmpty) {
        weightDiff = weight! - _records.last.weight;
      }

      // 保存记录
      _records.add(record);
      if (_records.length > 30) {
        _records.removeAt(0);
      }

      // 保存到本地存储
      final recordsJson = _records
          .map((record) =>
              '${record.date}:${record.weight}:${record.bmi.toStringAsFixed(2)}:${record.level}')
          .toList();
      await prefs.setStringList('weight_records', recordsJson);

      setState(() {
        _isFirstTime = false;
      });

      // 显示反馈
      if (weightDiff != 0) {
        _showFeedbackDialog(weightDiff, bmi, level);
      } else {
        _showFirstRecordDialog(bmi, level);
      }

      _showMessage('记录成功');
    } catch (e) {
      print('保存记录失败: $e');
      _showMessage('保存失败，请重试');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFeedbackDialog(double weightDiff, double bmi, String level) {
    final String message = _getFeedbackMessage(weightDiff);
    final Color color = _getFeedbackColor(weightDiff);
    final String title = _getFeedbackTitle(weightDiff);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: color,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('BMI', '${bmi.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('段位', level),
                    if (weightDiff != 0) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('体重变化',
                          '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)}kg'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '好的',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFirstRecordDialog(double bmi, String level) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '记录成功',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('BMI', '${bmi.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('段位', level),
                    const SizedBox(height: 8),
                    const Text(
                      '首次记录完成！\n继续保持良好的记录习惯。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '好的',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bmi = _calculateBMI();
    final String level = _getBMILevel(bmi);
    final Color levelColor = _getLevelColor(level);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // 米黄色背景
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题
              const Text(
                '瘦了么',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '记录今日体重，开启健康生活',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const Spacer(),

              // 输入区域
              Container(
                padding: const EdgeInsets.all(20),
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
                    // 首次打开显示身高性别输入
                    if (_isFirstTime) ...[
                      const Text(
                        '首次使用，请填写基础信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '身高 (cm)',
                                hintText: '请输入身高',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _genderController,
                              decoration: const InputDecoration(
                                labelText: '性别',
                                hintText: '男 或 女',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // 非首次显示当前信息和修改入口
                      GestureDetector(
                        onTap: () {
                          _showEditProfileDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '当前身高：${_heightController.text} cm | 性别：${_genderController.text}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const Text(
                                '修改身高性别',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 体重输入框（带微调按钮）
                    const Text(
                      '今日体重',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            final double currentWeight =
                                double.tryParse(_weightController.text) ?? 65.0;
                            final double newWeight =
                                (currentWeight - 0.1).clamp(20.0, 300.0);
                            _weightController.text =
                                newWeight.toStringAsFixed(1);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                          color: Colors.orange,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '体重 (kg)',
                              hintText: '请输入体重',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final double currentWeight =
                                double.tryParse(_weightController.text) ?? 65.0;
                            final double newWeight =
                                (currentWeight + 0.1).clamp(20.0, 300.0);
                            _weightController.text =
                                newWeight.toStringAsFixed(1);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                          color: Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 记录按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                _isFirstTime ? '完成首次记录' : '记录今日体重',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController heightController =
        TextEditingController(text: _heightController.text);
    final TextEditingController genderController =
        TextEditingController(text: _genderController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改身高性别'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '身高 (cm)',
                hintText: '请输入身高',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(
                labelText: '性别',
                hintText: '请输入：男 或 女',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _heightController.text = heightController.text;
                _genderController.text = genderController.text;
              });
              Navigator.of(context).pop();
              _showMessage('修改成功');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
