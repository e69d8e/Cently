# 🪙 分厘 (Cently) v1.0.0 正式发布

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。旨在提供无广告、无多余社交绑架、注重隐私的纯粹记账体验。数据全部保存在本地 SQLite 数据库中，支持多端运行、多维度图表统计与灵活的自定义分类管理。

---

### 📋 版本发布信息

- **版本号**：`v1.0.0`（构建版本 `1.0.0+1`）
- **发布日期**：2026-08-18
- **Git 标签 / Commit**：`v1.0.0` (`e5d5d04`)
- **发布地址**：[GitHub Releases v1.0.0](https://github.com/e69d8e/Cently/releases/tag/v1.0.0)

---

### ✨ 核心功能特性

- ⚡️ **极速收支记账**：内置数字计算键盘与即时算式解析，支持分类预设常用项一键填充、精准时间自定义与左滑防误删二次确认。
- 📊 **多维统计与分析**：清晰的月度结余概览，基于 `fl_chart` 的分类占比环形图、收支趋势折线图以及排行榜消费洞察。
- 🏷️ **灵活分类与预设**：丰富的预置收支类别，支持自定义分类名称、专属主题色彩与图标，并可自由维护每个分类下的常用细项。
- 🔒 **数据安全与本地备份**：100% 本地离线存储，数据绝不上传云端；支持标准 JSON / CSV 格式的完整数据备份、合并导入与全量恢复。
- 🎨 **极致美学与全平台响应**：原生深浅色（Light / Dark）主题无缝适配，优雅的排版色彩与流畅的转场微交互。
- 🤖 **CI/CD 自动化构建流水线**：配置矩阵式自动化编译流程，支持 Windows、macOS、Linux、Android、iOS 及 Web 独立发布产物。

---

### 📦 全平台安装包下载指南

| 平台 / 系统 | 推荐下载文件 | 文件大小 | 说明 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows** | [`Cently-Windows-x64-1.0.0-Setup.exe`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Windows-x64-1.0.0-Setup.exe) | 15.15 MB | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*若需绿色免安装版可下载 [`Cently-Windows-x64-v1.0.0.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Windows-x64-v1.0.0.zip) (18.49 MB)* |
| **🍎 macOS** | [`Cently-macOS-v1.0.0.dmg`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-macOS-v1.0.0.dmg) | 28.50 MB | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 [`Cently-macOS-v1.0.0.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-macOS-v1.0.0.zip) (28.58 MB) 原生应用压缩包* |
| **🐧 Linux** | [`Cently-Linux-amd64-v1.0.0.deb`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Linux-amd64-v1.0.0.deb) | 14.29 MB | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装，自动注册系统应用菜单。<br>*亦提供 [`Cently-Linux-x64-v1.0.0.tar.gz`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Linux-x64-v1.0.0.tar.gz) (16.29 MB) 独立运行包* |
| **🍏 iOS** | [`Cently-iOS-unsigned-v1.0.0.ipa`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-iOS-unsigned-v1.0.0.ipa) | 16.06 MB | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | [`Cently-Android-arm64-v8a-v1.0.0.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Android-arm64-v8a-v1.0.0.apk) | 25.58 MB | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：[`Cently-Android-Universal-v1.0.0.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Android-Universal-v1.0.0.apk) (62.66 MB)<br>• 32 位老旧机型：[`Cently-Android-armeabi-v7a-v1.0.0.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Android-armeabi-v7a-v1.0.0.apk) (23.21 MB)<br>• PC 模拟器及 x86：[`Cently-Android-x86_64-v1.0.0.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Android-x86_64-v1.0.0.apk) (26.97 MB)<br>• Google Play 格式：[`Cently-Android-v1.0.0.aab`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Android-v1.0.0.aab) (61.45 MB) |
| **🌐 Web** | [`Cently-Web-v1.0.0.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.0/Cently-Web-v1.0.0.zip) | 20.29 MB | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

### 🛡️ 安装包 SHA-256 完整性校验

| 产物文件名 | SHA-256 校验指纹 |
| :--- | :--- |
| `Cently-Windows-x64-1.0.0-Setup.exe` | `608da72ac855aaf033e009894a1fa7fc771a15034a6cd699e69d4aad4a5a2c3d` |
| `Cently-Windows-x64-v1.0.0.zip` | `ec2928bd4d69b82108eaa2e3b20ad5f38a4e37b2d09a77dd90e4e562e4677ed3` |
| `Cently-macOS-v1.0.0.dmg` | `bb303d8e56f68364d9df1d2c493bd1640cc503d611996162405e1feb9a1be715` |
| `Cently-macOS-v1.0.0.zip` | `a6abcee15386c8cfa1a18ef4f638fc5168c51d39035051b7badac5b4ad55b2c2` |
| `Cently-Linux-amd64-v1.0.0.deb` | `54d7461717601c8d040a655798b059b0c64a8a0cb87640f0d043610cde2fb376` |
| `Cently-Linux-x64-v1.0.0.tar.gz` | `9196ed64d559e02e0cd4f645faeb74cee52da631363eb16d3a51fbbf941163a8` |
| `Cently-iOS-unsigned-v1.0.0.ipa` | `7741fff39d5e06b3a1a2ae6720e0d792219c08794c05c58766157f30f9753517` |
| `Cently-Android-arm64-v8a-v1.0.0.apk` | `3bf36abae82598068ddfe323f71b78e1c0c1b80e5ca1d137f457bd7406de0bae` |
| `Cently-Android-Universal-v1.0.0.apk` | `2eb22bd4aee84860f74599676529375f08561fe8bed8db0e04ef823718f36cb1` |
| `Cently-Android-armeabi-v7a-v1.0.0.apk` | `ec8b9d861ac46d5e80be71f207bb2155043c435683ed92b1b6e50c8029f20386` |
| `Cently-Android-x86_64-v1.0.0.apk` | `4ac8600f90010d81d6cfffb70fedfa9914949d2bf63e6dd6bc9746ed4b546fcc` |
| `Cently-Android-v1.0.0.aab` | `ed65a775ecca135fa1422a3946f3bae83c2606f290e8a13ce0416ff9cca39dfb` |
| `Cently-Web-v1.0.0.zip` | `0252048568e2266fa2fa9a7f79fd19bdc9f70c75b711152b3f1f77104313213a` |

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.0
