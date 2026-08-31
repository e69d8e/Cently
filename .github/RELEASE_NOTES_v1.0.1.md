# 🪙 分厘 (Cently) v1.0.1 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。v1.0.1 版本带来了全新的账单回收站、记账交互优化、测试覆盖与多项稳定性提升。

---

### ✨ 新增与优化内容 (Changelog)

#### 1. 🗑️ 账单回收站与防误删机制
- **30 天软删除保护**：删除账单自动移入回收站，支持 30 天内随时一键找回或批量清空。
- **全新回收站管理界面**：在「设置 -> 数据管理与备份」中新增「账单回收站」，支持单笔还原、永久删除与一键清空。

#### 2. ⚡️ 记账体验与数字键盘全面优化
- **键盘计算与小数逻辑升级**：优化即时算式与小数点重置输入，提升计算流畅度。
- **退出防误触拦截**：金额大于 0 时返回将弹出放弃提示，避免误触丢失输入。
- **再记一笔智能预填**：优化快速连续记账流程，自动带入上一笔分类与常用预设。
- **物理键盘与快捷输入**：进一步优化桌面端物理键盘键位与回车确认交互。

#### 3. 📊 统计分析与界面细节优化
- **统计图表空状态与切换优化**：优化空数据下的视觉占位与多月份切换平滑度。
- **暗黑主题与色彩细节打磨**：微调卡片、边框及标签配色，提升全平台质感。

#### 4. 🧪 自动化测试与代码质量
- **全面单元测试与 Widget 测试**：新增回收站 CRUD、键盘逻辑、日期选择器及表单验证等 38+ 自动化测试用例，全部绿灯通过。

---

### 📦 全平台安装包下载与使用指南

| 平台 / 系统 | 推荐下载文件 | 说明 |
| :--- | :--- | :--- |
| **🪟 Windows** | [`Cently-Windows-x64-1.0.1-Setup.exe`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Windows-x64-1.0.1-Setup.exe) | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*若需绿色免安装版可下载 `Cently-Windows-x64-v1.0.1.zip`* |
| **🍎 macOS** | [`Cently-macOS-v1.0.1.dmg`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-macOS-v1.0.1.dmg) | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 `Cently-macOS-v1.0.1.zip` 原生应用压缩包* |
| **🐧 Linux** | [`Cently-Linux-amd64-v1.0.1.deb`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Linux-amd64-v1.0.1.deb) | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装，自动注册系统应用菜单。<br>*亦提供 `Cently-Linux-x64-v1.0.1.tar.gz` 独立运行包* |
| **🍏 iOS** | [`Cently-iOS-unsigned-v1.0.1.ipa`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-iOS-unsigned-v1.0.1.ipa) | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | [`Cently-Android-arm64-v8a-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-arm64-v8a-v1.0.1.apk) | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：[`Cently-Android-Universal-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-Universal-v1.0.1.apk)<br>• 32 位老旧机型：`Cently-Android-armeabi-v7a-v1.0.1.apk`<br>• PC 模拟器及 x86 设备：`Cently-Android-x86_64-v1.0.1.apk`<br>• Google Play 格式：`Cently-Android-v1.0.1.aab` |
| **🌐 Web** | [`Cently-Web-v1.0.1.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Web-v1.0.1.zip) | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.1
