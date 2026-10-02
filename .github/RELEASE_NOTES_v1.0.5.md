# 🪙 分厘 (Cently) v1.0.5 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、纯本地、无后端的个人记账与财务分析应用。v1.0.5 版本聚焦于**版本更新感知能力的建立**：新增基于 GitHub Releases 的检查更新功能（自动 + 手动），让用户无需盯守仓库即可知晓新版本并一键前往下载；同时将应用版本号改为动态读取，并修复了 macOS 沙盒的出站网络权限。100% 离线隐私安全定位与严格的测试保障保持不变——检查更新是全应用唯一的网络能力，仅在用户主动开启或触发时访问 GitHub，不上传任何数据。

---

### 📋 版本发布信息

- **版本号**：`v1.0.5`（构建版本 `1.0.5+6`）
- **发布日期**：2026-10-02
- **Git 标签**：`v1.0.5`
- **发布地址**：[GitHub Releases v1.0.5](https://github.com/e69d8e/Cently/releases/tag/v1.0.5)
- **代码对比**：[`v1.0.4...v1.0.5`](https://github.com/e69d8e/Cently/compare/v1.0.4...v1.0.5)

---

### ✨ 新增与优化内容 (Changelog)

#### 1. 🚀 检查更新功能（自动 + 手动）
- **设置页「关于应用」分区扩展**：新增「自动检查更新」开关（**默认关闭**，副标题注明"仅连接 GitHub，不上传任何数据"）与「检查更新」手动入口（检查中显示加载动画），开关状态持久化至本地 SQLite，重启后自动恢复。
- **启动自动检查**：开启后每次启动延迟 2 秒静默请求 GitHub 最新 Release，按日历日节流（**每天最多一次**，同日重启应用不再重复请求）；发现新版本时弹窗提示，任何网络失败仅记录日志静默降级，绝不阻塞启动、绝不打扰使用。
- **手动检查不受限**：无论开关与节流状态均可立即检查；有新版本时弹出「当前版本 → 新版本」对比与完整发布说明，一键「前往下载」直达对应 Releases 页面；已是最新 / 检查失败均以 SnackBar 即时反馈（`当前已是最新版本` / `检查更新失败，请检查网络连接`）。
- **版本比较与请求服务**：新增 `lib/services/update_service.dart` 统一承载——逐段数值比较点分版本号（`1.0.10 > 1.0.9`、长度不等自动补零），请求带 `Accept: application/vnd.github+json` 头、10 秒超时、404（仓库暂无 Release）视为无更新；构造函数支持注入 `http.Client` 与自定义 API 地址，网络层完全可测。

#### 2. 🏷️ 版本号动态读取
- **关于卡片版本号与 pubspec 自动同步**：引入 `package_info_plus`，设置页「关于 分厘」副标题的版本号不再硬编码，随构建自动更新，彻底告别"改了版本号忘了改文案"；插件不可用（如部分 Web 环境）时静默回退兜底常量，不影响展示。
- **导出 JSON 版本号同步**：数据导出文件中的 `version` 字段同步更新至当前版本。

#### 3. 🍎 macOS 沙盒网络权限修复
- **补齐 `com.apple.security.network.client`**：`DebugProfile.entitlements` 与 `Release.entitlements` 均已添加出站网络权限。此前应用完全离线故无影响；检查更新上线后，沙盒应用的出站连接默认被拒，会导致 macOS 端 API 请求失败、`url_launcher` 无法打开链接——本次一并修复。

#### 4. 🧪 自动化测试与代码质量
- **104 项测试全量绿灯通过**（较上版 +28）：新增 `UpdateService` 单测（版本比较边界、GitHub JSON 解析、`MockClient` 注入覆盖新版本 / 相同版本 / 旧版本 / 404 / 500 / 断网 / 畸形 JSON / 自定义端点与请求头校验）、自动检查开关与每日节流的持久化测试、「关于应用」分区 Widget 测试（懒构建滚动定位、开关默认关闭、整行点选切换）。
- **静态分析零告警**：`flutter analyze` 保持 0 Warning / 0 Error。

#### 5. 📦 依赖变更与隐私边界
- 新增 `http`（GitHub API 请求）、`package_info_plus`（版本读取）、`url_launcher`（跳转下载页）。
- **隐私边界不变**：检查更新是全应用唯一的网络能力，仅在用户开启自动检查或手动触发时访问 `api.github.com`，不上传任何数据；100% 本地 SQLite 存储、零云端的定位保持。

---

### 📦 全平台安装包下载指南

| 平台 / 系统 | 推荐下载文件 | 说明 |
| :--- | :--- | :--- |
| **🪟 Windows** | `Cently-Windows-x64-v1.0.5-Setup.exe` | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*亦提供 `Cently-Windows-x64-v1.0.5.zip` 绿色免安装版* |
| **🍎 macOS** | `Cently-macOS-v1.0.5.dmg` | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 `Cently-macOS-v1.0.5.zip` 原生应用压缩包* |
| **🐧 Linux** | `Cently-Linux-amd64-v1.0.5.deb` | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装。<br>*亦提供 `Cently-Linux-x64-v1.0.5.tar.gz` 独立运行包* |
| **🍏 iOS** | `Cently-iOS-unsigned-v1.0.5.ipa` | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | `Cently-Android-arm64-v8a-v1.0.5.apk` | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：`Cently-Android-Universal-v1.0.5.apk`<br>• 32 位老旧机型：`Cently-Android-armeabi-v7a-v1.0.5.apk`<br>• PC 模拟器及 x86：`Cently-Android-x86_64-v1.0.5.apk`<br>• Google Play 格式：`Cently-Android-v1.0.5.aab` |
| **🌐 Web** | `Cently-Web-v1.0.5.zip` | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

### 🔐 安装包签名校验

Android 产物由 **Cently 官方 release 密钥**签名，可用以下命令核对：

```bash
# APK
apksigner verify --print-certs Cently-Android-Universal-v1.0.5.apk
# AAB
keytool -printcert -jarfile Cently-Android-v1.0.5.aab
```

官方签名证书指纹（应与输出完全一致）：

- **SHA-256**：`2B:E3:1B:55:C2:A8:58:D4:F3:39:0D:83:4A:BB:7E:28:77:D6:BA:2F:AD:8A:29:FE:80:F5:E8:11:50:E7:8B:68`
- **SHA-1**：`F3:E0:B7:CA:7C:C3:F5:DB:8F:D6:78:FB:9F:36:43:04:55:DE:D3:60`
- **证书主体**：`CN=Cently, OU=Cently Mobile, O=Cently, L=Beijing, ST=Beijing, C=CN`

> ⚠️ iOS 产物为未签名 `.ipa`（`--no-codesign`），需自行签名后安装；Windows / macOS / Linux 桌面产物未做代码签名。

---

### 🗄️ 数据兼容说明

- 本版本**无数据库结构变更**（schema 维持 v6），升级不触碰任何账单、分类与回收站数据。
- 旧版本数据无缝延续；新增的 `autoCheckUpdate` 等设置键被 v1.0.4 及更早版本忽略，不影响其运行。

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.5

---

**Full Changelog**: https://github.com/e69d8e/Cently/compare/v1.0.4...v1.0.5
