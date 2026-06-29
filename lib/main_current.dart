import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '瘦了么',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'PingFang SC',
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('瘦了么'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎉 瘦了么 BMI体重监测',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Flutter应用成功运行！',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 测试按钮
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('测试按钮'),
            ),
            const SizedBox(height: 20),
            const Text(
              '📱 iOS模拟器已启动',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
