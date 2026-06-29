import 'package:flutter/material.dart';
import '../models/data_model.dart';
import '../utils/storage_utils.dart';

/// 反馈弹窗组件
class FeedbackDialog {
  /// 显示反馈弹窗
  static Future<void> show(
    BuildContext context, {
    required WeightAnalysis analysis,
    required String? avatarPath,
    required bool isPurchased,
  }) async {
    // 获取反馈语句
    String feedbackMessage;
    Color messageColor;
    String title;

    if (analysis.changeType == WeightChangeType.none) {
      // 首次记录
      feedbackMessage =
          '首次记录：BMI${analysis.currentBMI.toStringAsFixed(2)}，段位：${analysis.currentLevel}';
      messageColor = Colors.grey;
      title = '记录成功';
    } else {
      // 获取自定义语句库
      final CustomPhrases customPhrases = await StorageUtils.getCustomPhrases();
      feedbackMessage = customPhrases.getRandomPhrase(
        analysis.changeType,
        isPurchased,
        analysis.currentBMI,
        analysis.currentLevel,
      );

      // 根据变化类型设置颜色和标题
      switch (analysis.changeType) {
        case WeightChangeType.lost:
          messageColor = const Color(0xFF34C759); // 绿色
          title = '瘦了！';
          break;
        case WeightChangeType.gained:
          messageColor = const Color(0xFFFF3B30); // 红色
          title = '胖了～';
          break;
        case WeightChangeType.stable:
          messageColor = const Color(0xFF8E8E93); // 灰色
          title = '正常波动';
          break;
        case WeightChangeType.none:
          messageColor = Colors.grey;
          title = '记录成功';
          break;
      }
    }

    // 显示弹窗
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FeedbackDialogWidget(
        title: title,
        feedbackMessage: feedbackMessage,
        messageColor: messageColor,
        avatarPath: avatarPath,
        analysis: analysis,
      ),
    );
  }
}

/// 反馈弹窗Widget
class FeedbackDialogWidget extends StatelessWidget {
  final String title;
  final String feedbackMessage;
  final Color messageColor;
  final String? avatarPath;
  final WeightAnalysis analysis;

  const FeedbackDialogWidget({
    Key? key,
    required this.title,
    required this.feedbackMessage,
    required this.messageColor,
    this.avatarPath,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
            // 头部和标题
            Row(
              children: [
                // 用户头像
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: avatarPath != null && avatarPath!.isNotEmpty
                      ? ClipOval(
                          child: Image.asset(
                            avatarPath!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 25,
                          color: Colors.orange,
                        ),
                ),
                const SizedBox(width: 16),
                // 标题
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: messageColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 反馈消息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: messageColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feedbackMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: messageColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 详细信息
            if (analysis.changeType != WeightChangeType.none) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'BMI',
                      '${analysis.currentBMI.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '段位',
                      analysis.currentLevel,
                    ),
                    if (analysis.weightDiff != 0) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '体重变化',
                        '${analysis.weightDiff > 0 ? '+' : ''}${analysis.weightDiff.toStringAsFixed(1)}kg',
                        valueColor:
                            analysis.weightDiff > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 关闭按钮
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 简单的反馈提示组件（用于非弹窗场景）
class FeedbackMessage extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const FeedbackMessage({
    Key? key,
    required this.message,
    required this.color,
    this.icon = Icons.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 体重变化指示器组件
class WeightChangeIndicator extends StatelessWidget {
  final WeightChangeType changeType;
  final double weightDiff;

  const WeightChangeIndicator({
    Key? key,
    required this.changeType,
    required this.weightDiff,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (changeType) {
      case WeightChangeType.lost:
        icon = Icons.trending_down;
        color = const Color(0xFF34C759);
        text = '瘦了 ${weightDiff.abs().toStringAsFixed(1)}kg';
        break;
      case WeightChangeType.gained:
        icon = Icons.trending_up;
        color = const Color(0xFFFF3B30);
        text = '胖了 ${weightDiff.abs().toStringAsFixed(1)}kg';
        break;
      case WeightChangeType.stable:
        icon = Icons.trending_flat;
        color = const Color(0xFF8E8E93);
        text = '正常波动';
        break;
      case WeightChangeType.none:
        icon = Icons.add_circle_outline;
        color = Colors.grey;
        text = '首次记录';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// BMI段位标签组件
class BMILevelBadge extends StatelessWidget {
  final String level;
  final double bmi;

  const BMILevelBadge({
    Key? key,
    required this.level,
    required this.bmi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    Color backgroundColor;

    switch (level) {
      case "轻盈闪电":
        levelColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case "体重赢家":
        levelColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        break;
      case "燃脂预备役":
        levelColor = Colors.orange;
        backgroundColor = Colors.orange.withOpacity(0.1);
        break;
      case "不动如山":
        levelColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        break;
      default:
        levelColor = Colors.grey;
        backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level,
            style: TextStyle(
              fontSize: 14,
              color: levelColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'BMI ${bmi.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              color: levelColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
