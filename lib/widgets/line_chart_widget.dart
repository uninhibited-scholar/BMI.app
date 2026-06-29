import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/data_model.dart';

/// 折线图组件
class LineChartWidget extends StatefulWidget {
  final List<WeightRecord> records;

  const LineChartWidget({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  late List<WeightRecord> _records;
  bool _showWeight = true;
  bool _showBMI = true;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
  }

  @override
  void didUpdateWidget(LineChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.records != oldWidget.records) {
      setState(() {
        _records = List.from(widget.records);
      });
    }
  }

  /// 获取体重数据点
  List<FlSpot> _getWeightSpots() {
    return _records.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.weight,
      );
    }).toList();
  }

  /// 获取BMI数据点
  List<FlSpot> _getBMISpots() {
    return _records.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.bmi,
      );
    }).toList();
  }

  /// 获取Y轴标题
  Widget _getWeightTitle() {
    return const Text(
      '体重 (kg)',
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 获取BMI标题
  Widget _getBMITitle() {
    return const Text(
      'BMI',
      style: TextStyle(
        fontSize: 12,
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 获取底部标题
  Widget _getBottomTitle(double value, TitleMeta meta) {
    if (value.toInt() < 0 || value.toInt() >= _records.length) {
      return const Text('');
    }

    final String dateStr = _records[value.toInt()].date;
    final List<String> dateParts = dateStr.split('-');

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${dateParts[1]}/${dateParts[2]}',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 获取左侧标题
  Widget _getLeftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(0),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 获取右侧标题（BMI）
  Widget _getRightTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toStringAsFixed(0),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 获取触摸提示
  LineTooltipItem _getTooltipItem(LineBarSpot spot) {
    if (spot.x.toInt() < 0 || spot.x.toInt() >= _records.length) {
      return const LineTooltipItem('', TextStyle());
    }

    final WeightRecord record = _records[spot.x.toInt()];
    final String type = spot.barIndex == 0 ? '体重' : 'BMI';
    final String value = spot.barIndex == 0
        ? '${record.weight.toStringAsFixed(1)}kg'
        : record.bmi.toStringAsFixed(1);

    return LineTooltipItem(
      '${record.date}\n$type: $value\n段位: ${record.level}',
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_records.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // 图例
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 体重图例
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showWeight = !_showWeight;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _showWeight ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '体重',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showWeight ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // BMI图例
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showBMI = !_showBMI;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _showBMI ? Colors.orange : Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BMI',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showBMI ? Colors.orange : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 折线图
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LineChart(
              LineChartData(
                // 网格线
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),

                // 边框
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),

                // 标题
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: _getRightTitle,
                    ),
                    axisNameWidget: _getBMITitle(),
                    axisNameSize: 20,
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: _getBottomTitle,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: _getLeftTitle,
                    ),
                    axisNameWidget: _getWeightTitle(),
                    axisNameSize: 20,
                  ),
                ),

                // 鼠标悬停
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black.withOpacity(0.8),
                    getTooltipItems: (spots) {
                      return spots
                          .map((spot) => _getTooltipItem(spot))
                          .toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),

                // 数据线
                lineBarsData: [
                  // 体重线
                  if (_showWeight)
                    LineChartBarData(
                      spots: _getWeightSpots(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlue],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),

                  // BMI线
                  if (_showBMI)
                    LineChartBarData(
                      spots: _getBMISpots(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.3),
                            Colors.orange.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                ],

                // Y轴范围
                minY: 0,
                maxY: _calculateMaxY(),
                minX: 0,
                maxX: (_records.length - 1).toDouble(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 计算Y轴最大值
  double _calculateMaxY() {
    if (_records.isEmpty) return 100;

    final double maxWeight =
        _records.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
    final double maxBMI =
        _records.map((r) => r.bmi).reduce((a, b) => a > b ? a : b);

    // 根据显示的线条确定最大值
    double maxY = 0;
    if (_showWeight) {
      maxY = maxWeight;
    }
    if (_showBMI) {
      // BMI需要映射到体重轴上，这里简单放大10倍
      maxY = maxY > maxBMI * 10 ? maxY : maxBMI * 10;
    }

    // 添加20%的边距
    return maxY * 1.2;
  }
}

/// 简化的数据统计卡片
class DataStatsCard extends StatelessWidget {
  final List<WeightRecord> records;

  const DataStatsCard({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: const Center(
          child: Text(
            '暂无统计数据',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final WeightRecord latest = records.last;
    final WeightRecord? earliest = records.length > 1 ? records.first : null;

    final double currentWeight = latest.weight;
    final double currentBMI = latest.bmi;
    final String currentLevel = latest.level;

    double totalWeightChange = 0;
    int daysTracked = records.length;

    if (earliest != null) {
      totalWeightChange = currentWeight - earliest.weight;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '当前体重',
                  '${currentWeight.toStringAsFixed(1)}kg',
                  Icons.monitor_weight,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '当前BMI',
                  currentBMI.toStringAsFixed(1),
                  Icons.fitness_center,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '当前段位',
                  currentLevel,
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '记录天数',
                  '$daysTracked天',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          if (earliest != null) ...[
            const SizedBox(height: 16),
            _buildStatItem(
              '总体变化',
              '${totalWeightChange > 0 ? '+' : ''}${totalWeightChange.toStringAsFixed(1)}kg',
              totalWeightChange > 0 ? Icons.trending_up : Icons.trending_down,
              totalWeightChange > 0 ? Colors.red : Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
