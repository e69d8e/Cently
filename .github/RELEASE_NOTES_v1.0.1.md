# 🪙 分厘 (Cently) v1.0.1 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。v1.0.1 版本带来了全新的账单回收站、记账交互优化、测试覆盖与多项稳定性提升。

---

### 📋 版本发布信息

- **版本号**：`v1.0.1`（构建版本 `1.0.1+2`）
- **发布日期**：2026-08-31
- **Git 标签 / Commit**：`v1.0.1` (`b9ff9d7`)
- **发布地址**：[GitHub Releases v1.0.1](https://github.com/e69d8e/Cently/releases/tag/v1.0.1)
- **代码对比**：[`v1.0.0...v1.0.1`](https://github.com/e69d8e/Cently/compare/v1.0.0...v1.0.1)

---

### ✨ 新增与优化内容 (Changelog)

#### 1. 🗑️ 账单回收站与防误删机制
- **30 天软删除保护**：删除账单自动移入回收站（新增 `deletedAt` 时间戳标识），支持 30 天内随时一键找回或批量彻底清除。
- **全新回收站管理界面**：在「设置 -> 数据管理与备份」中新增「账单回收站」独立页面，支持按时间排序浏览、单笔还原、永久删除与一键全量清空。

#### 2. ⚡️ 记账体验与数字键盘全面优化
- **键盘计算与小数逻辑升级**：优化即时算式与小数点重置输入，修复连续运算符号输入的边界问题，提升计算流畅度。
- **退出防误触拦截**：金额大于 0 时点击返回将弹出放弃提示弹窗，避免误触造成录入数据丢失。
- **再记一笔智能预填**：优化快速连续记账流程，自动带入上一笔分类与常用预设项，大幅降低重复操作成本。
- **物理键盘与快捷输入**：进一步优化桌面端物理键盘数字键与回车确认的交互体验。

#### 3. 📊 统计分析与界面细节优化
- **统计图表空状态与切换优化**：优化无数据场景下的视觉占位图文与多月份平滑切换过渡。
- **暗黑主题与色彩细节打磨**：微调卡片、边框及标签配色对比度，提升全平台深浅色一致性。

#### 4. 🧪 自动化测试与代码质量
- **全面单元测试与 Widget 测试**：新增回收站 CRUD、键盘逻辑、日期选择器及表单验证等 **38+ 自动化测试用例**，保障版本迭代稳定性。

---

### 📦 全平台安装包下载指南

| 平台 / 系统 | 推荐下载文件 | 文件大小 | 说明 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows** | [`Cently-Windows-x64-1.0.1-Setup.exe`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Windows-x64-1.0.1-Setup.exe) | 15.15 MB | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*若需绿色免安装版可下载 [`Cently-Windows-x64-v1.0.1.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Windows-x64-v1.0.1.zip) (18.49 MB)* |
| **🍎 macOS** | [`Cently-macOS-v1.0.1.dmg`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-macOS-v1.0.1.dmg) | 28.49 MB | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 [`Cently-macOS-v1.0.1.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-macOS-v1.0.1.zip) (28.57 MB) 原生应用压缩包* |
| **🐧 Linux** | [`Cently-Linux-amd64-v1.0.1.deb`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Linux-amd64-v1.0.1.deb) | 14.29 MB | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装，自动注册系统应用菜单。<br>*亦提供 [`Cently-Linux-x64-v1.0.1.tar.gz`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Linux-x64-v1.0.1.tar.gz) (16.29 MB) 独立运行包* |
| **🍏 iOS** | [`Cently-iOS-unsigned-v1.0.1.ipa`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-iOS-unsigned-v1.0.1.ipa) | 16.06 MB | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | [`Cently-Android-arm64-v8a-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-arm64-v8a-v1.0.1.apk) | 25.71 MB | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：[`Cently-Android-Universal-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-Universal-v1.0.1.apk) (63.00 MB)<br>• 32 位老旧机型：[`Cently-Android-armeabi-v7a-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-armeabi-v7a-v1.0.1.apk) (23.30 MB)<br>• PC 模拟器及 x86：[`Cently-Android-x86_64-v1.0.1.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-x86_64-v1.0.1.apk) (27.09 MB)<br>• Google Play 格式：[`Cently-Android-v1.0.1.aab`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Android-v1.0.1.aab) (61.56 MB) |
| **🌐 Web** | [`Cently-Web-v1.0.1.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.1/Cently-Web-v1.0.1.zip) | 20.31 MB | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

### 🛡️ 安装包 SHA-256 完整性校验

| 产物文件名 | SHA-256 校验指纹 |
| :--- | :--- |
| `Cently-Windows-x64-1.0.1-Setup.exe` | `f49df8db15a0ba9d04a3eb1850984b217d13dbc53f7e301a2d776c3278124c57` |
| `Cently-Windows-x64-v1.0.1.zip` | `54ba6352d1caf67c9c7d8cb10bb4d71574e186c42295bda8c9de374057b3910c` |
| `Cently-macOS-v1.0.1.dmg` | `33e1728294555b7bb9bf3f879a7eb80a710989d3e5677ac27cb01c4e5eea852d` |
| `Cently-macOS-v1.0.1.zip` | `f293d4875616d11e0d9c0f84331deaf51611ca5a05d29f9d87ee039f9572ae98` |
| `Cently-Linux-amd64-v1.0.1.deb` | `6640f20937592327679aae4c2a17b4629d0e010638a9ad44ae728cbd8e121aa7` |
| `Cently-Linux-x64-v1.0.1.tar.gz` | `58a9ba14a20d822f6cea54df130c5a74b2e688f942d394f2a7d92842bebf4aa8` |
| `Cently-iOS-unsigned-v1.0.1.ipa` | `e6e528e71e9f63173110e20b9d49232e81fc9c3479634875e28568c78705c2ea` |
| `Cently-Android-arm64-v8a-v1.0.1.apk` | `498ab30cecc1c8cd561f36f511675438fbaf3596b63a14a2b45ea1c4978cfc50` |
| `Cently-Android-Universal-v1.0.1.apk` | `4b6984c922c26fe4c50adba451004fb5fc57459f183aa3850b291c7668be5d7d` |
| `Cently-Android-armeabi-v7a-v1.0.1.apk` | `d34a5560b79296d0fb4edcbb817d2ab146459857bede8db5512cf2d3321d046a` |
| `Cently-Android-x86_64-v1.0.1.apk` | `cba1957396962e093827be39adca152bacfe4c56562e6e0da92b27f75c78ccc6` |
| `Cently-Android-v1.0.1.aab` | `abafc3e61b5d694e2b98373e1762035dc99f8cffaa4eb413da2b2fca24eaf87c` |
| `Cently-Web-v1.0.1.zip` | `f9844fe359db3cb6b440a1c20f884802a72dc12376d5ec9238c6ed3839bb6898` |

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.1
