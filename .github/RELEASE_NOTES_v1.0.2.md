# 🪙 分厘 (Cently) v1.0.2 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。v1.0.2 版本聚焦于**核心渲染与数据衍生计算的深度性能优化**，并建立了覆盖核心逻辑的高质量单元测试矩阵。

---

### ✨ 新增与优化内容 (Changelog)

#### 1. ⚡️ 记账流水主列表零计算渲染
- **引入 `DailyTransactionGroup` 领域模型**：在底层派生计算中单趟倒序直接聚合日收支汇总与交易记录集。
- **去除视图层构建耗时**：`HomeScreen` 和 `_DayGroupCard` 彻底消除了每次重绘时的日期列表反复排序与每张日卡片内的循环求和，实现渲染阶段的 \(O(1)\) 极速装载。

#### 2. ⌨️ 记账页计算器键盘极速响应
- **高频预设名称排序记忆化缓存**：将按频次优先排序的预设名称按分类进行缓存记忆，仅在分类切换或账单记录集变更时重新计算。
- **消除按键全量遍历**：用户在数字键盘连续敲击输入金额时，彻底避免了字符变更引发的 \(O(N)\) 全量流水频次扫描，键盘输入达到毫秒级即时响应。

#### 3. 🗄️ SQLite 覆盖索引与工具类优化
- **新增覆盖索引**：为 SQLite `transactions` 表新增 `idx_transactions_active_order ON transactions(deletedAt, timestamp DESC, createdAt DESC)` 复合覆盖索引，避免 SQLite 内部二次物理文件排序。
- **异常恢复与字符裁剪优化**：增强了数据库单例初始化的 Future 缓存失效与重试保护；优化了货币算术表达式末尾符号的修剪逻辑，减少临时对象分配。

#### 4. 🧪 单元测试矩阵全面扩展
- **59 项测试全量绿灯通过**：新增日聚合性能基准测试（2,500 条流水单趟聚合稳定低于 35ms）、分类流转与拖拽排序测试、货币状态机边界测试等。
- **静态分析零警告**：`flutter analyze` 零 Warning 零 Error。

---

### 📦 全平台安装包下载与使用指南

| 平台 / 系统 | 推荐下载文件 | 说明 |
| :--- | :--- | :--- |
| **🪟 Windows** | [`Cently-Windows-x64-1.0.2-Setup.exe`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Windows-x64-1.0.2-Setup.exe) | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*若需绿色免安装版可下载 `Cently-Windows-x64-v1.0.2.zip`* |
| **🍎 macOS** | [`Cently-macOS-v1.0.2.dmg`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-macOS-v1.0.2.dmg) | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 `Cently-macOS-v1.0.2.zip` 原生应用压缩包* |
| **🐧 Linux** | [`Cently-Linux-amd64-v1.0.2.deb`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Linux-amd64-v1.0.2.deb) | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装，自动注册系统应用菜单。<br>*亦提供 `Cently-Linux-x64-v1.0.2.tar.gz` 独立运行包* |
| **🍏 iOS** | [`Cently-iOS-unsigned-v1.0.2.ipa`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-iOS-unsigned-v1.0.2.ipa) | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | [`Cently-Android-arm64-v8a-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-arm64-v8a-v1.0.2.apk) | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：[`Cently-Android-Universal-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-Universal-v1.0.2.apk)<br>• 32 位老旧机型：`Cently-Android-armeabi-v7a-v1.0.2.apk`<br>• PC 模拟器及 x86 设备：`Cently-Android-x86_64-v1.0.2.apk`<br>• Google Play 格式：`Cently-Android-v1.0.2.aab` |
| **🌐 Web** | [`Cently-Web-v1.0.2.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Web-v1.0.2.zip) | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.2
