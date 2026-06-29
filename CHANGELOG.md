# Changelog

本文件记录「瘦了么」(Shouleme) 的版本变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026

### Added
- BMI 实时计算与分级反馈
- 近 30 天体重 / BMI 双轨折线图（`fl_chart`）
- 每日称重本地提醒，支持自定义文案（`flutter_local_notifications`）
- 应用内购买解锁高级功能（自定义语句库）（`in_app_purchase`）
- 壁纸、头像、透明度等个性化设置
- 体重数据 CSV 导出（`csv` + `path_provider`）
- 首次启动隐私政策弹窗

### Technical
- Flutter 3.10+ / Dart 3.0+ 多端工程（iOS / macOS / Android / Web / Linux / Windows）
- 数据本地存储（`SharedPreferences`），无网络依赖

[1.0.0]: https://github.com/uninhibited-scholar/BMI.app/releases/tag/v1.0.0
