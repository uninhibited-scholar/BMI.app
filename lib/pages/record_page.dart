import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/data_model.dart';
import '../utils/storage_utils.dart';
import '../widgets/feedback_dialog.dart';

/// 体重记录&反馈页面
class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  UserProfile? _userProfile;
  PersonalSettings _personalSettings = PersonalSettings();
  bool _isFirstTime = true;
  bool _isLoading = false;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  /// 加载用户数据
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final UserProfile? profile = await StorageUtils.getUserProfile();
      final PersonalSettings settings =
          await StorageUtils.getPersonalSettings();

      setState(() {
        _userProfile = profile;
        _personalSettings = settings;
        _isFirstTime = profile == null;
        _avatarPath = settings.avatarPath;

        // 设置初始值
        if (profile != null) {
          _heightController.text = profile.height.toString();
          _genderController.text = profile.gender == 'male' ? '男' : '女';
        } else {
          _heightController.text = '';
          _genderController.text = '';
        }

        _weightController.text = '';
        _isLoading = false;
      });
    } catch (e) {
      print('加载用户数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 保存或更新用户基础信息
  Future<void> _saveOrUpdateProfile() async {
    final String heightStr = _heightController.text.trim();
    final String genderText = _genderController.text.trim();
    final String weightStr = _weightController.text.trim();

    // 输入验证
    if (heightStr.isEmpty || genderText.isEmpty || weightStr.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    final double? height = double.tryParse(heightStr);
    final double? weight = double.tryParse(weightStr);

    if (height == null || weight == null) {
      _showMessage('请输入有效数字');
      return;
    }

    if (height < 100 || height > 250) {
      _showMessage('身高输入异常，请检查');
      return;
    }

    if (weight < 20 || weight > 300) {
      _showMessage('体重输入异常，请检查');
      return;
    }

    final String gender = genderText == '男' ? 'male' : 'female';

    try {
      // 保存用户基础信息
      final UserProfile profile = UserProfile(
        height: height,
        gender: gender,
        lastUpdate: DateTime.now(),
      );
      await StorageUtils.saveUserProfile(profile);

      // 计算BMI并保存体重记录
      final double bmi = weight / ((height / 100) * (height / 100));
      final String level = BMILevel.getBMILevel(bmi);
      final String today = DateTime.now().toIso8601String().split('T')[0];

      final WeightRecord record = WeightRecord(
        date: today,
        weight: weight,
        bmi: bmi,
        level: level,
        timestamp: DateTime.now(),
      );

      await StorageUtils.saveWeightRecord(record);

      // 获取前一次体重进行分析
      final double lastWeight = await StorageUtils.getLastWeight();
      final WeightAnalysis analysis = WeightAnalysis.analyzeWeightChange(
        currentWeight: weight,
        previousWeight: lastWeight == weight ? 0 : lastWeight, // 避免同一天重复记录
        height: height,
      );

      // 获取付费状态
      final bool isPurchased = await StorageUtils.getIsPurchased();

      // 显示反馈弹窗
      if (mounted) {
        await FeedbackDialog.show(
          context,
          analysis: analysis,
          avatarPath: _avatarPath,
          isPurchased: isPurchased,
        );
      }

      // 更新状态
      setState(() {
        _userProfile = profile;
        _isFirstTime = false;
        _weightController.text = '';
      });

      _showMessage('记录成功');
    } catch (e) {
      print('保存记录失败: $e');
      _showMessage('保存失败，请重试');
    }
  }

  /// 显示修改身高性别弹窗
  void _showEditProfileDialog() {
    final TextEditingController heightController = TextEditingController(
      text: _userProfile?.height.toString() ?? '',
    );
    final TextEditingController genderController = TextEditingController(
      text: _userProfile?.gender == 'male' ? '男' : '女',
    );

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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(
                labelText: '性别',
                hintText: '请输入：男 或 女',
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
            onPressed: () async {
              final String heightStr = heightController.text.trim();
              final String genderText = genderController.text.trim();

              if (heightStr.isEmpty || genderText.isEmpty) {
                _showMessage('请填写完整信息');
                return;
              }

              final double? height = double.tryParse(heightStr);
              if (height == null) {
                _showMessage('请输入有效数字');
                return;
              }

              final String gender = genderText == '男' ? 'male' : 'female';

              try {
                final UserProfile profile = UserProfile(
                  height: height,
                  gender: gender,
                  lastUpdate: DateTime.now(),
                );
                await StorageUtils.saveUserProfile(profile);

                setState(() {
                  _userProfile = profile;
                  _heightController.text = height.toString();
                  _genderController.text = genderText;
                });

                Navigator.of(context).pop();
                _showMessage('修改成功');
              } catch (e) {
                _showMessage('修改失败，请重试');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 选择头像
  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (image != null) {
        // 显示版权提示
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('版权声明'),
            content: const Text(
              '您上传的所有图片文件版权由您自行负责，请勿使用侵权内容。如因上传侵权内容引发纠纷，本APP不承担任何责任。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('我已知晓'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // 保存头像路径（实际项目中需要保存图片到本地存储）
          final PersonalSettings updatedSettings = _personalSettings.copyWith(
            avatarPath: image.path,
          );
          await StorageUtils.savePersonalSettings(updatedSettings);

          setState(() {
            _avatarPath = image.path;
            _personalSettings = updatedSettings;
          });

          _showMessage('头像设置成功');
        }
      }
    } catch (e) {
      print('选择头像失败: $e');
      _showMessage('选择头像失败');
    }
  }

  /// 体重微调
  void _adjustWeight(double delta) {
    final String currentText = _weightController.text;
    final double? currentWeight = double.tryParse(currentText);

    if (currentWeight != null) {
      final double newWeight = (currentWeight + delta).clamp(20.0, 300.0);
      _weightController.text = newWeight.toStringAsFixed(1);
    } else {
      _weightController.text = '60.0'; // 默认值
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: _personalSettings.page1WallpaperPath.isNotEmpty
              ? DecorationImage(
                  image: AssetImage(_personalSettings.page1WallpaperPath),
                  fit: BoxFit.cover,
                  opacity: _personalSettings.wallpaperOpacity,
                )
              : null,
        ),
        child: SafeArea(
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
                          onTap: _showEditProfileDialog,
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
                                  '当前身高：${_userProfile?.height ?? 0} cm | 性别：${_genderController.text}',
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
                            onPressed: () => _adjustWeight(-0.1),
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 32,
                            color: Colors.orange,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                labelText: '体重 (kg)',
                                hintText: '请输入体重',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _adjustWeight(0.1),
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
                          onPressed: _saveOrUpdateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
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
      ),
      // 悬浮头像按钮（点击设置头像）
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _pickAvatar,
        backgroundColor: Colors.orange,
        child: _avatarPath != null && _avatarPath!.isNotEmpty
            ? ClipOval(
                child: Image.asset(
                  _avatarPath!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}
