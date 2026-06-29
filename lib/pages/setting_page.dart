import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/data_model.dart';
import '../utils/storage_utils.dart';

/// 设置页面（我的页面）
class SettingPage extends StatefulWidget {
  final bool isPurchased;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final String productPrice;

  const SettingPage({
    Key? key,
    required this.isPurchased,
    required this.onPurchase,
    required this.onRestore,
    required this.productPrice,
  }) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  PersonalSettings _personalSettings = PersonalSettings();
  CustomPhrases _customPhrases = CustomPhrases(
    lostPhrases: [],
    gainedPhrases: [],
    stablePhrases: [],
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 加载设置数据
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final PersonalSettings settings =
          await StorageUtils.getPersonalSettings();
      final CustomPhrases phrases = await StorageUtils.getCustomPhrases();

      setState(() {
        _personalSettings = settings;
        _customPhrases = phrases;
        _isLoading = false;
      });
    } catch (e) {
      print('加载设置失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 设置页面1壁纸
  Future<void> _setPage1Wallpaper() async {
    await _setWallpaper(isPage1: true);
  }

  /// 设置页面2壁纸
  Future<void> _setPage2Wallpaper() async {
    await _setWallpaper(isPage1: false);
  }

  /// 设置壁纸通用方法
  Future<void> _setWallpaper({required bool isPage1}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
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
          final PersonalSettings updatedSettings = isPage1
              ? _personalSettings.copyWith(page1WallpaperPath: image.path)
              : _personalSettings.copyWith(page2WallpaperPath: image.path);

          await StorageUtils.savePersonalSettings(updatedSettings);

          setState(() {
            _personalSettings = updatedSettings;
          });

          _showMessage('壁纸设置成功');
        }
      }
    } catch (e) {
      print('设置壁纸失败: $e');
      _showMessage('设置壁纸失败');
    }
  }

  /// 调整壁纸透明度
  Future<void> _adjustWallpaperOpacity(double opacity) async {
    final PersonalSettings updatedSettings = _personalSettings.copyWith(
      wallpaperOpacity: opacity.clamp(0.5, 1.0),
    );

    await StorageUtils.savePersonalSettings(updatedSettings);

    setState(() {
      _personalSettings = updatedSettings;
    });
  }

  /// 设置头像
  Future<void> _setAvatar() async {
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
          final PersonalSettings updatedSettings = _personalSettings.copyWith(
            avatarPath: image.path,
          );

          await StorageUtils.savePersonalSettings(updatedSettings);

          setState(() {
            _personalSettings = updatedSettings;
          });

          _showMessage('头像设置成功');
        }
      }
    } catch (e) {
      print('设置头像失败: $e');
      _showMessage('设置头像失败');
    }
  }

  /// 显示付费解锁弹窗
  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解锁高级功能'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '价格：${widget.productPrice}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text('解锁后可获得：'),
            const SizedBox(height: 8),
            const Text('• 自定义反馈语句库'),
            const Text('• 自定义提醒文案'),
            const SizedBox(height: 16),
            const Text(
              '付费解锁后，您可自定义反馈语句库和提醒文案，所有编辑的文本内容版权归属您个人，本APP不参与内容审核，相关责任由您自行承担。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPurchase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('立即购买'),
          ),
        ],
      ),
    );
  }

  /// 管理自定义语句库
  void _manageCustomPhrases() async {
    if (!widget.isPurchased) {
      _showMessage('请先解锁高级功能');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomPhrasesPage(
          phrases: _customPhrases,
          onSave: (phrases) async {
            await StorageUtils.saveCustomPhrases(phrases);
            setState(() {
              _customPhrases = phrases;
            });
          },
        ),
      ),
    );
  }

  /// 重置壁纸
  Future<void> _resetWallpapers() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置壁纸'),
        content: const Text('确定要重置所有壁纸为默认吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final PersonalSettings updatedSettings = _personalSettings.copyWith(
        page1WallpaperPath: '',
        page2WallpaperPath: '',
        wallpaperOpacity: 1.0,
      );

      await StorageUtils.savePersonalSettings(updatedSettings);

      setState(() {
        _personalSettings = updatedSettings;
      });

      _showMessage('壁纸已重置');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // 头像
                  GestureDetector(
                    onTap: _setAvatar,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: _personalSettings.avatarPath.isNotEmpty
                          ? ClipOval(
                              child: Image.asset(
                                _personalSettings.avatarPath,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.orange,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '瘦了么用户',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isPurchased ? '高级用户' : '免费用户',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isPurchased
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 个性化设置
            const Text(
              '个性化设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 壁纸设置
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wallpaper),
                    title: const Text('记录页壁纸'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _setPage1Wallpaper,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.wallpaper),
                    title: const Text('图表页壁纸'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _setPage2Wallpaper,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.opacity),
                    title: Text(
                        '壁纸透明度：${(_personalSettings.wallpaperOpacity * 100).toInt()}%'),
                    subtitle: Slider(
                      value: _personalSettings.wallpaperOpacity,
                      min: 0.5,
                      max: 1.0,
                      divisions: 10,
                      onChanged: _adjustWallpaperOpacity,
                      activeColor: Colors.orange,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('重置壁纸'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _resetWallpapers,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 高级功能
            const Text(
              '高级功能',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.message),
                    title: const Text('自定义语句库'),
                    subtitle: widget.isPurchased
                        ? const Text('管理反馈语句库',
                            style: TextStyle(color: Colors.green))
                        : const Text('需要解锁高级功能',
                            style: TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _manageCustomPhrases,
                  ),
                  if (!widget.isPurchased) ...[
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _showPurchaseDialog,
                        icon: const Icon(Icons.lock_open),
                        label: Text('解锁高级功能（${widget.productPrice}）'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                  if (widget.isPurchased) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('恢复购买'),
                      subtitle: const Text('如果您已购买，点击恢复',
                          style: TextStyle(color: Colors.blue)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onRestore,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 关于
            const Text(
              '关于',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('版本信息'),
                    subtitle: const Text('瘦了么 v1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('隐私政策'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
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
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // 底部留白
          ],
        ),
      ),
    );
  }
}

/// 自定义语句库管理页面
class CustomPhrasesPage extends StatefulWidget {
  final CustomPhrases phrases;
  final Function(CustomPhrases) onSave;

  const CustomPhrasesPage({
    Key? key,
    required this.phrases,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CustomPhrasesPage> createState() => _CustomPhrasesPageState();
}

class _CustomPhrasesPageState extends State<CustomPhrasesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _lostController;
  late TextEditingController _gainedController;
  late TextEditingController _stableController;

  List<String> _lostPhrases = [];
  List<String> _gainedPhrases = [];
  List<String> _stablePhrases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _lostController = TextEditingController();
    _gainedController = TextEditingController();
    _stableController = TextEditingController();

    _lostPhrases = List.from(widget.phrases.lostPhrases);
    _gainedPhrases = List.from(widget.phrases.gainedPhrases);
    _stablePhrases = List.from(widget.phrases.stablePhrases);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lostController.dispose();
    _gainedController.dispose();
    _stableController.dispose();
    super.dispose();
  }

  /// 添加语句
  void _addPhrase(String type) {
    TextEditingController controller = _lostController;
    List<String> phrases = _lostPhrases;
    String title = '瘦了语句';

    switch (type) {
      case 'lost':
        controller = _lostController;
        phrases = _lostPhrases;
        title = '瘦了语句';
        break;
      case 'gained':
        controller = _gainedController;
        phrases = _gainedPhrases;
        title = '胖了语句';
        break;
      case 'stable':
        controller = _stableController;
        phrases = _stablePhrases;
        title = '正常波动语句';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加$title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '语句内容（50字内）',
            border: const OutlineInputBorder(),
          ),
          maxLength: 50,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final String text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  phrases.add(text);
                });
                controller.clear();
              }
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 编辑语句
  void _editPhrase(String type, int index) {
    List<String> phrases = _lostPhrases;
    TextEditingController controller = _lostController;
    String title = '瘦了语句';

    switch (type) {
      case 'lost':
        phrases = _lostPhrases;
        controller = _lostController;
        title = '瘦了语句';
        break;
      case 'gained':
        phrases = _gainedPhrases;
        controller = _gainedController;
        title = '胖了语句';
        break;
      case 'stable':
        phrases = _stablePhrases;
        controller = _stableController;
        title = '正常波动语句';
        break;
    }

    controller.text = phrases[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑$title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '语句内容（50字内）',
            border: const OutlineInputBorder(),
          ),
          maxLength: 50,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final String text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  phrases[index] = text;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 删除语句
  void _deletePhrase(String type, int index) {
    List<String> phrases = _lostPhrases;
    switch (type) {
      case 'lost':
        phrases = _lostPhrases;
        break;
      case 'gained':
        phrases = _gainedPhrases;
        break;
      case 'stable':
        phrases = _stablePhrases;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条语句吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                phrases.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 构建语句列表
  Widget _buildPhraseList(String type) {
    List<String> phrases = _lostPhrases;
    switch (type) {
      case 'lost':
        phrases = _lostPhrases;
        break;
      case 'gained':
        phrases = _gainedPhrases;
        break;
      case 'stable':
        phrases = _stablePhrases;
        break;
    }

    return Column(
      children: [
        // 添加按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addPhrase(type),
              icon: const Icon(Icons.add),
              label: const Text('添加语句'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),

        // 语句列表
        Expanded(
          child: phrases.isEmpty
              ? const Center(
                  child: Text(
                    '暂无自定义语句\n点击上方按钮添加',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: phrases.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(phrases[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editPhrase(type, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePhrase(type, index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义语句库'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '瘦了语句'),
            Tab(text: '胖了语句'),
            Tab(text: '正常波动'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final CustomPhrases updatedPhrases = CustomPhrases(
                lostPhrases: _lostPhrases,
                gainedPhrases: _gainedPhrases,
                stablePhrases: _stablePhrases,
              );
              widget.onSave(updatedPhrases);
              Navigator.of(context).pop();
            },
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhraseList('lost'),
          _buildPhraseList('gained'),
          _buildPhraseList('stable'),
        ],
      ),
    );
  }
}
