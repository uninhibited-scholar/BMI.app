# 瘦了么 (Shouleme) — BMI 体重监测 APP

一款极简本地 BMI 体重监测 Flutter 应用，支持 iOS 端运行，包含应用内购买功能，所有数据本地存储，无需网络连接。
## 项目概述
「瘦了么」是一款极简本地BMI体重监测Flutter应用，支持iOS端运行，包含应用内购买功能，所有数据本地存储，无需网络连接。

## 技术栈
- Flutter 3.10.0+
- Dart 3.0.0+
- 本地存储：SharedPreferences
- 图表：fl_chart
- 应用内购买：in_app_purchase
- 本地通知：flutter_local_notifications
- 图片选择：image_picker

## 环境要求
- macOS系统
- Xcode 14.0+
- iOS模拟器 15.0+ 或真机
- Flutter SDK 3.10.0+
- CocoaPods

## 安装运行步骤

### 1. 环境准备
```bash
# 检查Flutter环境
flutter doctor

# 如果没有安装Flutter，请访问 https://flutter.dev/docs/get-started/install/macos
```

### 2. 项目初始化
```bash
# 进入项目目录
cd /Users/zhujiehan

# 安装依赖
flutter pub get

# iOS项目初始化
cd ios
pod install
cd ..
```

### 3. iOS配置
```bash
# 打开iOS项目配置
open ios/Runner.xcworkspace
```

在Xcode中进行以下配置：
1. 选择项目target -> Signing & Capabilities
2. 配置Apple ID开发者账号
3. 修改Bundle Identifier为唯一标识（如：com.yourname.shouleme）
4. 确保Signing配置正确

### 4. 运行应用
```bash
# 查看可用设备
flutter devices

# 运行到iOS模拟器
flutter run -d "iPhone 14"

# 或运行到真机（需连接设备）
flutter run
```

## 应用内购买测试

### 1. 沙盒测试账号配置
1. 访问App Store Connect：https://appstoreconnect.apple.com
2. 进入"用户和访问" -> "沙盒测试员"
3. 添加测试账号（使用非Apple ID的邮箱）

### 2. 商品配置
1. 在App Store Connect中创建应用
2. 进入"功能" -> "应用内购买"
3. 创建非消耗型商品：
   - 产品ID：`com.shouleme.advanced.features`
   - 价格：3元人民币档位
   - 名称：高级功能解锁

### 3. 设备沙盒配置
在测试设备上：
1. 打开"设置" -> "App Store"
2. 滚动到底部，登录沙盒测试账号
3. 在应用中测试购买功能

### 4. 恢复购买测试
1. 删除应用重新安装
2. 进入"我的"页面
3. 点击"恢复购买"
4. 验证是否能找回解锁状态

## 核心功能测试

### 基础功能
1. **首次使用**：输入身高性别，记录体重，查看BMI计算和反馈弹窗
2. **日常记录**：输入体重，查看体重变化分析和个性化反馈
3. **数据图表**：查看近30天体重和BMI双轨折线图
4. **个性化设置**：设置壁纸、头像、调整透明度

### 高级功能（付费解锁）
1. **解锁测试**：点击"解锁高级功能"完成购买流程
2. **语句库管理**：进入"自定义语句库"，添加/编辑/删除个性化语句
3. **提醒功能**：设置每日提醒时间和自定义文案

### 数据管理
1. **CSV导出**：点击"导出CSV"，查看文件保存位置
2. **数据删除**：点击"删除旧数据"，确认删除3个月前数据

## 常见问题解决

### 1. 依赖安装失败
```bash
# 清理缓存重新安装
flutter clean
flutter pub get
cd ios && pod install --repo-update
```

### 2. iOS构建失败
- 检查Xcode版本是否满足要求
- 确认开发者账号配置正确
- 检查Bundle Identifier是否唯一

### 3. IAP功能异常
- 确保商品ID配置正确：`com.shouleme.advanced.features`
- 检查沙盒测试账号登录状态
- 验证网络连接（IAP需要网络验证）

### 4. 通知功能异常
- 检查应用通知权限
- 确保iOS版本支持本地通知
- 验证提醒时间设置

## App Store发布准备

### 1. 应用信息
- 应用名称：瘦了么
- 副标题：BMI体重监测助手
- 分类：健康健身
- 年龄分级：4+

### 2. 隐私政策
应用已在首次启动时显示隐私政策弹窗，符合Apple审核要求。

### 3. 应用内购买
确保在App Store Connect中正确配置3元档位的非消耗型商品。

### 4. 元数据准备
- 应用图标：1024x1024 PNG
- 截图：各尺寸设备截图
- 关键词：BMI、体重、减肥、健康、健身

## 注意事项

1. **测试环境**：建议使用iOS模拟器进行基础功能测试，真机测试IAP功能
2. **数据备份**：测试期间重要数据建议手动备份
3. **性能优化**：在真机上测试应用性能表现
4. **权限处理**：确保相机、相册、通知等权限申请正常
5. **内存管理**：长时间使用检查内存泄漏情况

## 技术支持
如遇到问题，请检查：
1. Flutter和Xcode版本是否满足要求
2. 网络连接是否正常（IAP测试需要）
3. 设备权限是否正确授予
4. 控制台日志输出信息

项目已完成所有核心功能开发，代码注释完整，可直接运行测试。