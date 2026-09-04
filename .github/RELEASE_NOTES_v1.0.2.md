# 🪙 分厘 (Cently) v1.0.2 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。v1.0.2 版本聚焦于**核心渲染与数据衍生计算的深度性能优化**，并建立了覆盖核心逻辑的高质量单元测试矩阵。

---

### 📋 版本发布信息

- **版本号**：`v1.0.2`（构建版本 `1.0.2+3`）
- **发布日期**：2026-09-04
- **Git 标签 / Commit**：`v1.0.2` (`6878869`)
- **发布地址**：[GitHub Releases v1.0.2](https://github.com/e69d8e/Cently/releases/tag/v1.0.2)
- **代码对比**：[`v1.0.1...v1.0.2`](https://github.com/e69d8e/Cently/compare/v1.0.1...v1.0.2)

---

### ✨ 新增与优化内容 (Changelog)

#### 1. ⚡️ 记账流水主列表零计算渲染
- **引入 `DailyTransactionGroup` 领域模型**：在底层派生计算中单趟倒序直接聚合日收支汇总与交易记录集。
- **去除视图层构建耗时**：`HomeScreen` 和 `_DayGroupCard` 彻底消除了每次重绘时的日期列表反复排序与每张日卡片内的循环求和，实现渲染阶段的 $O(1)$ 极速装载。

#### 2. ⌨️ 记账页计算器键盘极速响应
- **高频预设名称排序记忆化缓存**：将按频次优先排序的预设名称按分类进行缓存记忆，仅在分类切换或账单记录集变更时重新计算。
- **消除按键全量遍历**：用户在数字键盘连续敲击输入金额时，彻底避免了字符变更引发的 $O(N)$ 全量流水频次扫描，键盘输入达到毫秒级即时响应。

#### 3. 🗄️ SQLite 覆盖索引与工具类优化
- **新增覆盖索引**：为 SQLite `transactions` 表新增 `idx_transactions_active_order ON transactions(deletedAt, timestamp DESC, createdAt DESC)` 复合覆盖索引，避免 SQLite 内部二次物理文件排序。
- **异常恢复与字符裁剪优化**：增强了数据库单例初始化的 Future 缓存失效与重试保护；优化了货币算术表达式末尾符号的修剪逻辑，减少临时对象分配。

#### 4. 🧪 单元测试矩阵全面扩展
- **59 项测试全量绿灯通过**：新增日聚合性能基准测试（2,500 条流水单趟聚合稳定低于 35ms）、分类流转与拖拽排序测试、货币状态机边界测试等。
- **静态分析零警告**：`flutter analyze` 保持 0 Warning / 0 Error。

---

### 📦 全平台安装包下载指南

| 平台 / 系统 | 推荐下载文件 | 文件大小 | 说明 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows** | [`Cently-Windows-x64-1.0.2-Setup.exe`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Windows-x64-1.0.2-Setup.exe) | 15.15 MB | **Windows 标准安装向导程序**（推荐），支持创建桌面与开始菜单快捷方式。<br>*若需绿色免安装版可下载 [`Cently-Windows-x64-v1.0.2.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Windows-x64-v1.0.2.zip) (18.49 MB)* |
| **🍎 macOS** | [`Cently-macOS-v1.0.2.dmg`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-macOS-v1.0.2.dmg) | 28.50 MB | **macOS 拖拽安装镜像**（推荐），双击打开后拖拽至 Applications 目录即可。<br>*亦提供 [`Cently-macOS-v1.0.2.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-macOS-v1.0.2.zip) (28.57 MB) 原生应用压缩包* |
| **🐧 Linux** | [`Cently-Linux-amd64-v1.0.2.deb`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Linux-amd64-v1.0.2.deb) | 14.29 MB | **Debian / Ubuntu 安装包**（推荐），双击或通过 `sudo dpkg -i` 安装，自动注册系统应用菜单。<br>*亦提供 [`Cently-Linux-x64-v1.0.2.tar.gz`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Linux-x64-v1.0.2.tar.gz) (16.30 MB) 独立运行包* |
| **🍏 iOS** | [`Cently-iOS-unsigned-v1.0.2.ipa`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-iOS-unsigned-v1.0.2.ipa) | 16.06 MB | **iOS 独立应用包**，支持通过 TrollStore、AltStore、Sideloadly 或企业证书自签名安装。 |
| **🤖 Android** | [`Cently-Android-arm64-v8a-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-arm64-v8a-v1.0.2.apk) | 25.71 MB | **64 位 ARM 安装包**（推荐绝大多数现代 Android 手机），体积更小。<br>• 全架构通用版：[`Cently-Android-Universal-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-Universal-v1.0.2.apk) (63.00 MB)<br>• 32 位老旧机型：[`Cently-Android-armeabi-v7a-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-armeabi-v7a-v1.0.2.apk) (23.30 MB)<br>• PC 模拟器及 x86：[`Cently-Android-x86_64-v1.0.2.apk`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-x86_64-v1.0.2.apk) (27.09 MB)<br>• Google Play 格式：[`Cently-Android-v1.0.2.aab`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Android-v1.0.2.aab) (61.56 MB) |
| **🌐 Web** | [`Cently-Web-v1.0.2.zip`](https://github.com/e69d8e/Cently/releases/download/v1.0.2/Cently-Web-v1.0.2.zip) | 20.31 MB | **Web 静态网站资源包**，解压后可直接部署至 Nginx、Apache、Vercel 或 GitHub Pages。 |

---

### 🛡️ 安装包 SHA-256 完整性校验

| 产物文件名 | SHA-256 校验指纹 |
| :--- | :--- |
| `Cently-Windows-x64-1.0.2-Setup.exe` | `6087d36e2c42ca28c67ec082ffa94cf7b7d02558aa3b7f8583ab5e299361e7c9` |
| `Cently-Windows-x64-v1.0.2.zip` | `51446739f73248813ad0f2fb7c1e9142c0c71efe63fb5bba8eab3638e387966a` |
| `Cently-macOS-v1.0.2.dmg` | `16061157696696cf2f7c2f2fb7ac0375cfbc9cd9a00223d3ea6451fca5adb5ef` |
| `Cently-macOS-v1.0.2.zip` | `0914f146f564c92e4cda0055237add0ea32bbbf2386681970807b16d5d5b2500` |
| `Cently-Linux-amd64-v1.0.2.deb` | `532f51253dcb13a99c51fcadd3b9a34aaef80ebaef5bc020a0b9fec7bc98c103` |
| `Cently-Linux-x64-v1.0.2.tar.gz` | `6897feeaeb30ebf27789d7d2af5d15cca9ce70981045eec2daf0998b5d2e2291` |
| `Cently-iOS-unsigned-v1.0.2.ipa` | `a62c02a5bfbe0258824ec6c5ff0b7ad74787393173e633339aa73ac10577e3e4` |
| `Cently-Android-arm64-v8a-v1.0.2.apk` | `8ce261d7a963c7c7c4b1c8c0426f131d4003c644e936b8dfa6e4ca8ec62f9157` |
| `Cently-Android-Universal-v1.0.2.apk` | `71ecaa39c7e2d379c2c4bac19127306d5f8d892583761cf06dcdfdf21688134f` |
| `Cently-Android-armeabi-v7a-v1.0.2.apk` | `a79cf1d0bd331ec8fef457febac5c884e0e605ab4140e26bc70fe8afef86d403` |
| `Cently-Android-x86_64-v1.0.2.apk` | `d1e4ebb36f310b60f22d0dbc1420cd58f2192e05b2984a60fa91b286031399e9` |
| `Cently-Android-v1.0.2.aab` | `d1d5f4bda7dbd494066c28419e57d79aa063e5b311f52ef74de809b3f7960179` |
| `Cently-Web-v1.0.2.zip` | `6637b63d7967bc764ff54536746ea84d9e7d5856bea581070e5f784b936e82eb` |

---

**完整提交记录**：https://github.com/e69d8e/Cently/commits/v1.0.2
