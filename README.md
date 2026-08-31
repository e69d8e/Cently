# 分厘 (Cently)

<div align="center">

<img src="assets/icon/app_icon.png" alt="Cently Logo" width="120" height="120" style="border-radius: 24px;" />

### 简约、轻量、纯粹的现代化个人记账应用
*分厘之间，细致入微 · 分文厘毫，了然于胸*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20macOS%20|%20Windows%20|%20Web-blue.svg)](#平台支持)
[![Release](https://img.shields.io/github/v/release/e69d8e/Cently?color=orange&logo=github)](https://github.com/e69d8e/Cently/releases)

[功能特性](#-功能特性) • [技术架构](#-技术架构) • [快速开始](#-快速开始) • [打包构建](#-打包构建) • [CI/CD 自动化](#-cicd-自动化发布) • [开源协议](#-开源协议)

</div>

---

## 📖 项目简介

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。旨在提供无广告、无多余社交绑架、注重隐私的纯粹记账体验。数据全部保存在本地 SQLite 数据库中，支持多端运行、多维度图表统计与灵活的自定义分类管理。

---

## ✨ 功能特性

### 1. ⚡️ 极速收支记账
- **自定义计算键盘**：内置数字键盘与算式解析，支持即时计算。
- **预设常用项一键录入**：每个分类支持常用预设消费项，点击直接填充，免去繁琐输入。
- **自定义日期与时间**：支持精准到分钟的记账时间自定义及“今天/昨天”快捷切换。
- **防误触二次确认**：左滑删除与列表操作均包含确认保护，防止误删账单。

### 2. 📊 多维统计与图表分析
- **收支概览**：清晰的月度结余、总支出、总收入一目了然。
- **动态图表**：基于 `fl_chart` 构建的分类占比环形图/饼图，以及周期性收支趋势分析。
- **排行榜明细**：按分类及条目智能聚类与排行，快速洞察消费重点。

### 3. 🏷️ 分类与预设管理
- **丰富的内置分类**：预置餐饮、购物、日用、交通、娱乐等主流收支类别。
- **高度自定义**：支持自由新增、编辑分类名称、专属主题色及图标。
- **分类预设子项**：可自由维护每个分类下的常用细项，记账快人一步。

### 4. 🔒 隐私安全与数据备份
- **100% 离线与隐私**：所有账单数据均保存在设备本地，不上传任何第三方云端。
- **账单回收站与防误删**：支持 30 天已删除账单软删除存储，随时一键还原或彻底清空。
- **数据导入与导出**：支持标准 JSON / CSV 格式的完整数据备份、合并导入与全量覆盖。

### 5. 🎨 现代美学设计与多端支持
- **深浅色主题适配**：原生支持 Light / Dark 主题自适应，色彩柔和，视觉层次清晰。
- **全平台响应式**：针对移动端（Android / iOS）、桌面端（macOS / Windows / Linux）以及 Web 端提供良好的适配。

---

## 🛠️ 技术架构

本项目遵循清晰的响应式状态管理与分层架构设计：

```
lib/
├── data/              # 本地数据库访问层 (DatabaseHelper) 与预置默认数据 (DefaultData)
├── models/            # 核心数据模型 (Category, PresetItem, TransactionRecord)
├── providers/         # 状态管理层 (CategoryProvider, TransactionProvider)
├── screens/           # UI 页面
│   ├── category_manage/ # 分类与预设管理页面及弹窗
│   ├── home/            # 首页账单明细流水与日历视图
│   ├── record/          # 记账录入与键盘交互页面
│   ├── settings/        # 设置中心、数据备份与恢复
│   └── stats/           # 统计分析与图表展示
├── theme/             # 全局主题配置、色彩系统与间距规范
├── utils/             # 格式化工具 (CurrencyFormat, DateFormatHelper 等)
└── widgets/           # 通用可复用组件 (分类图标、底部弹窗、日期选择器等)
```

### 核心依赖库

| 依赖库 | 用途 |
| :--- | :--- |
| [`provider`](https://pub.dev/packages/provider) | 响应式应用状态管理 |
| [`sqflite`](https://pub.dev/packages/sqflite) / [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) | 本地 SQLite 数据库（移动端/桌面端） |
| [`sqflite_common_ffi_web`](https://pub.dev/packages/sqflite_common_ffi_web) | Web 端 SQLite 数据库支持 |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | 统计图表绘制（环形图、折线趋势） |
| [`intl`](https://pub.dev/packages/intl) | 日期国际化与数字格式化 |
| [`uuid`](https://pub.dev/packages/uuid) | 唯一账单与分类 ID 生成 |

---

## 🚀 快速开始

### 前置环境准备
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (推荐版本 >= 3.13.0)
- [Dart SDK](https://dart.dev/get-dart) (推荐版本 >= 3.13.0)
- Android Studio / Xcode / VS Code (安装 Flutter 扩展)

### 1. 克隆项目
```bash
git clone https://github.com/e69d8e/Cently.git
cd Cently
```

### 2. 获取依赖
```bash
flutter pub get
```

### 3. 本地运行调试
```bash
# 启动本地连接的设备或模拟器运行
flutter run

# 指定运行平台（例如 Chrome / macOS）
flutter run -d chrome
flutter run -d macos
```

### 4. 运行自动化测试
```bash
flutter test
```

---

## 📦 打包构建

### 1. Android 端打包 (全架构与分包)
```bash
# 构建全架构通用 APK (Universal APK)
flutter build apk --release

# 构建分架构独立 APK (生成 32位 armeabi-v7a、64位 arm64-v8a、64位 x86_64)
flutter build apk --split-per-abi --release

# 构建 Google Play App Bundle (.aab)
flutter build appbundle --release
```

### 2. iOS 端打包 (IPA)
```bash
# 构建 iOS 归档并导出 IPA
flutter build ipa --no-codesign --release
```

### 3. 桌面端打包 (macOS / Windows / Linux)
```bash
# macOS 应用包 (.app / .dmg)
flutter build macos --release

# Windows x64 应用包 (.exe 安装包 / 绿色包)
flutter build windows --release

# Linux x64 应用包 (.deb / .tar.gz)
flutter build linux --release
```

### 4. Web 端打包
```bash
flutter build web --release
```

---

## 🤖 CI/CD 自动化全平台发布

项目配置了完整的 GitHub Actions 自动化流水线（支持矩阵式多平台与原生安装包构建）：

- **CI 流水线 (`.github/workflows/ci.yml`)**：在向 `main` 分支提交代码或发起 PR 时，自动执行代码静态分析 (`flutter analyze`) 与单元测试 (`flutter test`)。
- **Release 流水线 (`.github/workflows/release.yml`)**：
  - **触发方式**：推送版本标签（例如 `git tag v1.0.1 && git push origin v1.0.1`）或在 GitHub Actions 页面手动触发；
  - **全平台构建产物矩阵**：
    - 🤖 **Android**：
      - `Cently-Android-Universal-v*.apk`（全架构通用版）
      - `Cently-Android-arm64-v8a-v*.apk`（主流 64 位 ARM 手机，体积更小）
      - `Cently-Android-armeabi-v7a-v*.apk`（老旧 32 位 ARM 手机）
      - `Cently-Android-x86_64-v*.apk`（模拟器 / x86_64 架构设备）
      - `Cently-Android-v*.aab`（Google Play 格式包）
    - 🍏 **iOS**：
      - `Cently-iOS-unsigned-v*.ipa`（iOS 独立应用安装包，支持 TrollStore / AltStore / Sideloadly 等自签名分发）
    - 🪟 **Windows**：
      - `Cently-Windows-x64-v*-Setup.exe`（Windows 安装向导程序）
      - `Cently-Windows-x64-v*.zip`（Windows x64 绿色免安装包）
    - 🍎 **macOS**：
      - `Cently-macOS-v*.dmg`（macOS 拖拽安装镜像）
      - `Cently-macOS-v*.zip`（macOS 原生 `.app` 应用压缩包）
    - 🐧 **Linux**：
      - `Cently-Linux-amd64-v*.deb`（Debian / Ubuntu 安装包）
      - `Cently-Linux-x64-v*.tar.gz`（Linux x64 独立运行包）
    - 🌐 **Web**：
      - `Cently-Web-v*.zip`（Web 静态部署资源包）
  - **自动发布**：所有产物自动打包并聚合发布到 [GitHub Releases](https://github.com/e69d8e/Cently/releases)，同时自动生成 Release Notes。

---

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 许可证开源，欢迎自由使用、学习与修改。

