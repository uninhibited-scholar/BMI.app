<div align="center">

# 瘦了么 · Shouleme

**一款极简的本地 BMI 体重监测 Flutter 应用**

iOS · macOS · Android · Web · Linux · Windows ｜ 数据 100% 本地存储 · 无需联网

</div>

---

## 📖 项目简介

「瘦了么」是一款专注于 **BMI 体重监测** 的极简 Flutter 应用。所有数据通过 `SharedPreferences` 保存在设备本地，**不联网、不上传、无账号**，注重隐私。应用已按 Apple App Store（健康健美分类）要求准备上架资料。

> **关于项目名与 Bundle ID**
> - `pubspec.yaml` 中的 Dart 包名：`shouleme`
> - iOS Bundle Identifier：`com.example.shouleme`
> - 应用显示名（`CFBundleDisplayName`）：`Shouleme`
>
> 上架前请将 Bundle ID 改为你自己的唯一标识（如 `com.<yourname>.shouleme`）。

## ✨ 功能特性

| 模块 | 说明 |
|------|------|
| 🧮 **BMI 计算** | 输入身高 / 体重，实时计算 BMI 并给出分级反馈 |
| 📈 **趋势图表** | 基于 `fl_chart` 的近 30 天体重 / BMI 双轨折线图 |
| 🔔 **本地提醒** | `flutter_local_notifications` 每日定时称重提醒，支持自定义文案 |
| 🛒 **应用内购买** | `in_app_purchase` 非消耗型商品解锁「高级功能」（自定义语句库等） |
| 🖼️ **个性化** | 壁纸、头像、透明度自定义 |
| 📤 **数据导出** | 一键导出 CSV（`csv` + `path_provider`） |
| 🔒 **隐私优先** | 无网络权限，数据仅存本地 |

## 🛠️ 技术栈

- **Flutter** `>=3.10.0`  /  **Dart** `>=3.0.0`
- 本地存储：[`shared_preferences`](https://pub.dev/packages/shared_preferences)
- 图表：[`fl_chart`](https://pub.dev/packages/fl_chart)
- 应用内购买：[`in_app_purchase`](https://pub.dev/packages/in_app_purchase)
- 本地通知：[`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- 图片选择：[`image_picker`](https://pub.dev/packages/image_picker)
- CSV 导出：[`csv`](https://pub.dev/packages/csv) + [`path_provider`](https://pub.dev/packages/path_provider)
- 权限：[`permission_handler`](https://pub.dev/packages/permission_handler)

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.10.0+（`flutter doctor` 全绿）
- iOS 构建：macOS + Xcode 14.0+ + CocoaPods
- Android 构建：Android Studio / Android SDK

### 安装与运行

```bash
# 1. 安装依赖
flutter pub get

# 2. (iOS) 安装 Pods
cd ios && pod install && cd ..

# 3. 运行
flutter run
```

### iOS 签名配置

1. 打开 `ios/Runner.xcworkspace`
2. **Signing & Capabilities** → 选择你的 Apple Developer 团队
3. 把 **Bundle Identifier** 改成你的唯一标识（如 `com.yourname.shouleme`）
4. 在 [App Store Connect](https://appstoreconnect.apple.com) 配置应用内购买商品：
   - 产品 ID：`com.shouleme.advanced.features`
   - 类型：非消耗型

## 📁 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
├── pages/                 # 页面（首页 / 记录 / 我的 等）
├── widgets/               # 可复用组件
└── utils/                 # 工具类（存储 / 通知 / IAP 等）
```

## 🧪 测试要点

- **基础流程**：首次输入身高性别 → 记录体重 → 查看 BMI 反馈与趋势图
- **IAP 沙盒**：在 App Store Connect 配置沙盒测试账号，验证购买与「恢复购买」
- **提醒**：设置每日提醒时间，确认本地通知按时触发
- **数据导出**：导出 CSV 并核对内容

## 📤 上架清单（App Store）

- [ ] 应用图标 1024×1024 PNG
- [ ] 各机型截图（6.7" / 6.5" / 5.5"）
- [ ] 隐私政策（首次启动已弹窗）
- [ ] 修改 Bundle ID 为唯一值
- [ ] App Store Connect 配置 IAP 商品
- [ ] 关键词：BMI、体重、减肥、健康、健身

## ❓ 常见问题

<details>
<summary>依赖安装失败 / iOS 构建失败</summary>

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
```
- 检查 Xcode 版本与开发者账号配置
- 确认 Bundle Identifier 唯一

</details>

<details>
<summary>IAP 异常 / 通知不触发</summary>

- IAP 商品 ID 须为 `com.shouleme.advanced.features`，且沙盒账号已登录
- 通知：检查系统通知权限与提醒时间设置

</details>

## 📄 许可证

本项目仅供学习参考。

<div align="center">

<sub>Built with Flutter · 数据本地存储 · 注重隐私</sub>

</div>
