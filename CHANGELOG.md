# 更新日志与版本发布归档 (Changelog & Release Information)

本文档整理并归档了 **分厘 (Cently)** 自项目开源以来的所有版本发布信息、技术架构演进、变更说明及官方全平台构建产物校验矩阵。

---

## 目录
- [版本发布总览](#版本发布总览)
- [v1.0.2 (2026-09-04) - 性能优化与测试矩阵扩充](#v102---2026-09-04)
- [v1.0.1 (2026-08-31) - 账单回收站与交互打磨](#v101---2026-08-31)
- [v1.0.0 (2026-08-18) - 官方首个正式版](#v100---2026-08-18)
- [全平台构建产物与 SHA-256 校验指纹](#全平台构建产物与-sha-256-校验指纹)

---

## 版本发布总览

| 版本号 | 构建号 | Git 标签 / Commit | 发布时间 (CST) | 核心主题 | 变动统计 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`v1.0.2`** | `1.0.2+3` | [`v1.0.2`](https://github.com/e69d8e/Cently/releases/tag/v1.0.2) (`6878869`) | 2026-09-04 12:12 | 核心渲染零计算、键盘即时响应、SQLite 覆盖索引、59 项测试 | 15 文件 (+878 / -56) |
| **`v1.0.1`** | `1.0.1+2` | [`v1.0.1`](https://github.com/e69d8e/Cently/releases/tag/v1.0.1) (`b9ff9d7`) | 2026-08-31 16:35 | 账单回收站与防误删、数字键盘与记账体验优化、38+ 项测试 | 22 文件 (+3333 / -948) |
| **`v1.0.0`** | `1.0.0+1` | [`v1.0.0`](https://github.com/e69d8e/Cently/releases/tag/v1.0.0) (`e5d5d04`) | 2026-08-18 20:35 | 首个正式版发布：极速记账、多维图表、分类预设、全平台自动化矩阵 | 初始版本提交上线 |

---

## [v1.0.2] - 2026-09-04

- **发布页面**：[GitHub Release v1.0.2](https://github.com/e69d8e/Cently/releases/tag/v1.0.2)
- **代码对比**：[`v1.0.1...v1.0.2`](https://github.com/e69d8e/Cently/compare/v1.0.1...v1.0.2)
- **构建版本**：`1.0.2+3`
- **提交哈希**：`6878869`
- **发布说明源码**：[.github/RELEASE_NOTES_v1.0.2.md](.github/RELEASE_NOTES_v1.0.2.md)

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

## [v1.0.1] - 2026-08-31

- **发布页面**：[GitHub Release v1.0.1](https://github.com/e69d8e/Cently/releases/tag/v1.0.1)
- **代码对比**：[`v1.0.0...v1.0.1`](https://github.com/e69d8e/Cently/compare/v1.0.0...v1.0.1)
- **构建版本**：`1.0.1+2`
- **提交哈希**：`b9ff9d7`
- **发布说明源码**：[.github/RELEASE_NOTES_v1.0.1.md](.github/RELEASE_NOTES_v1.0.1.md)

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

## [v1.0.0] - 2026-08-18

- **发布页面**：[GitHub Release v1.0.0](https://github.com/e69d8e/Cently/releases/tag/v1.0.0)
- **提交记录**：[`commits/v1.0.0`](https://github.com/e69d8e/Cently/commits/v1.0.0)
- **构建版本**：`1.0.0+1`
- **提交哈希**：`e5d5d04`
- **发布说明源码**：[.github/RELEASE_NOTES_v1.0.0.md](.github/RELEASE_NOTES_v1.0.0.md)

### ✨ 核心功能特性 (Initial Release)

- ⚡️ **极速收支记账**：内置数字计算键盘与即时算式解析，支持分类预设常用项一键填充、精准时间自定义与左滑防误删二次确认。
- 📊 **多维统计与分析**：清晰的月度结余概览，基于 `fl_chart` 的分类占比环形图、收支趋势折线图以及排行榜消费洞察。
- 🏷️ **灵活分类与预设**：丰富的预置收支类别，支持自定义分类名称、专属主题色彩与图标，并可自由维护每个分类下的常用细项。
- 🔒 **数据安全与本地备份**：100% 本地离线存储，数据绝不上传云端；支持标准 JSON / CSV 格式的完整数据备份、合并导入与全量恢复。
- 🎨 **极致美学与全平台响应**：原生深浅色（Light / Dark）主题无缝适配，优雅的排版色彩与流畅的转场微交互。
- 🤖 **CI/CD 自动化构建流水线**：配置矩阵式自动化编译，生成 Windows、macOS、Linux、Android、iOS 及 Web 独立发布产物。

---

## 全平台构建产物与 SHA-256 校验指纹

### 最新版本 (v1.0.2) 产物清单

| 平台 / 架构 | 发布文件名 | 大小 | SHA-256 校验指纹 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows Setup** | `Cently-Windows-x64-1.0.2-Setup.exe` | 15.15 MB | `6087d36e2c42ca28c67ec082ffa94cf7b7d02558aa3b7f8583ab5e299361e7c9` |
| **🪟 Windows Portable** | `Cently-Windows-x64-v1.0.2.zip` | 18.49 MB | `51446739f73248813ad0f2fb7c1e9142c0c71efe63fb5bba8eab3638e387966a` |
| **🍎 macOS DMG** | `Cently-macOS-v1.0.2.dmg` | 28.50 MB | `16061157696696cf2f7c2f2fb7ac0375cfbc9cd9a00223d3ea6451fca5adb5ef` |
| **🍎 macOS ZIP** | `Cently-macOS-v1.0.2.zip` | 28.57 MB | `0914f146f564c92e4cda0055237add0ea32bbbf2386681970807b16d5d5b2500` |
| **🐧 Linux DEB** | `Cently-Linux-amd64-v1.0.2.deb` | 14.29 MB | `532f51253dcb13a99c51fcadd3b9a34aaef80ebaef5bc020a0b9fec7bc98c103` |
| **🐧 Linux Tarball** | `Cently-Linux-x64-v1.0.2.tar.gz` | 16.30 MB | `6897feeaeb30ebf27789d7d2af5d15cca9ce70981045eec2daf0998b5d2e2291` |
| **🍏 iOS (自签名)** | `Cently-iOS-unsigned-v1.0.2.ipa` | 16.06 MB | `a62c02a5bfbe0258824ec6c5ff0b7ad74787393173e633339aa73ac10577e3e4` |
| **🤖 Android arm64** | `Cently-Android-arm64-v8a-v1.0.2.apk` | 25.71 MB | `8ce261d7a963c7c7c4b1c8c0426f131d4003c644e936b8dfa6e4ca8ec62f9157` |
| **🤖 Android Universal** | `Cently-Android-Universal-v1.0.2.apk` | 63.00 MB | `71ecaa39c7e2d379c2c4bac19127306d5f8d892583761cf06dcdfdf21688134f` |
| **🤖 Android armeabi-v7a**| `Cently-Android-armeabi-v7a-v1.0.2.apk`| 23.30 MB | `a79cf1d0bd331ec8fef457febac5c884e0e605ab4140e26bc70fe8afef86d403` |
| **🤖 Android x86_64** | `Cently-Android-x86_64-v1.0.2.apk` | 27.09 MB | `d1e4ebb36f310b60f22d0dbc1420cd58f2192e05b2984a60fa91b286031399e9` |
| **🤖 Android AAB** | `Cently-Android-v1.0.2.aab` | 61.56 MB | `d1d5f4bda7dbd494066c28419e57d79aa063e5b311f52ef74de809b3f7960179` |
| **🌐 Web 静态包** | `Cently-Web-v1.0.2.zip` | 20.31 MB | `6637b63d7967bc764ff54536746ea84d9e7d5856bea581070e5f784b936e82eb` |

---

### 历史版本 (v1.0.1) 产物清单

| 平台 / 架构 | 发布文件名 | 大小 | SHA-256 校验指纹 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows Setup** | `Cently-Windows-x64-1.0.1-Setup.exe` | 15.15 MB | `f49df8db15a0ba9d04a3eb1850984b217d13dbc53f7e301a2d776c3278124c57` |
| **🪟 Windows Portable** | `Cently-Windows-x64-v1.0.1.zip` | 18.49 MB | `54ba6352d1caf67c9c7d8cb10bb4d71574e186c42295bda8c9de374057b3910c` |
| **🍎 macOS DMG** | `Cently-macOS-v1.0.1.dmg` | 28.49 MB | `33e1728294555b7bb9bf3f879a7eb80a710989d3e5677ac27cb01c4e5eea852d` |
| **🍎 macOS ZIP** | `Cently-macOS-v1.0.1.zip` | 28.57 MB | `f293d4875616d11e0d9c0f84331deaf51611ca5a05d29f9d87ee039f9572ae98` |
| **🐧 Linux DEB** | `Cently-Linux-amd64-v1.0.1.deb` | 14.29 MB | `6640f20937592327679aae4c2a17b4629d0e010638a9ad44ae728cbd8e121aa7` |
| **🐧 Linux Tarball** | `Cently-Linux-x64-v1.0.1.tar.gz` | 16.29 MB | `58a9ba14a20d822f6cea54df130c5a74b2e688f942d394f2a7d92842bebf4aa8` |
| **🍏 iOS (自签名)** | `Cently-iOS-unsigned-v1.0.1.ipa` | 16.06 MB | `e6e528e71e9f63173110e20b9d49232e81fc9c3479634875e28568c78705c2ea` |
| **🤖 Android arm64** | `Cently-Android-arm64-v8a-v1.0.1.apk` | 25.71 MB | `498ab30cecc1c8cd561f36f511675438fbaf3596b63a14a2b45ea1c4978cfc50` |
| **🤖 Android Universal** | `Cently-Android-Universal-v1.0.1.apk` | 63.00 MB | `4b6984c922c26fe4c50adba451004fb5fc57459f183aa3850b291c7668be5d7d` |
| **🤖 Android armeabi-v7a**| `Cently-Android-armeabi-v7a-v1.0.1.apk`| 23.30 MB | `d34a5560b79296d0fb4edcbb817d2ab146459857bede8db5512cf2d3321d046a` |
| **🤖 Android x86_64** | `Cently-Android-x86_64-v1.0.1.apk` | 27.09 MB | `cba1957396962e093827be39adca152bacfe4c56562e6e0da92b27f75c78ccc6` |
| **🤖 Android AAB** | `Cently-Android-v1.0.1.aab` | 61.56 MB | `abafc3e61b5d694e2b98373e1762035dc99f8cffaa4eb413da2b2fca24eaf87c` |
| **🌐 Web 静态包** | `Cently-Web-v1.0.1.zip` | 20.31 MB | `f9844fe359db3cb6b440a1c20f884802a72dc12376d5ec9238c6ed3839bb6898` |

---

### 历史版本 (v1.0.0) 产物清单

| 平台 / 架构 | 发布文件名 | 大小 | SHA-256 校验指纹 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows Setup** | `Cently-Windows-x64-1.0.0-Setup.exe` | 15.15 MB | `608da72ac855aaf033e009894a1fa7fc771a15034a6cd699e69d4aad4a5a2c3d` |
| **🪟 Windows Portable** | `Cently-Windows-x64-v1.0.0.zip` | 18.49 MB | `ec2928bd4d69b82108eaa2e3b20ad5f38a4e37b2d09a77dd90e4e562e4677ed3` |
| **🍎 macOS DMG** | `Cently-macOS-v1.0.0.dmg` | 28.50 MB | `bb303d8e56f68364d9df1d2c493bd1640cc503d611996162405e1feb9a1be715` |
| **🍎 macOS ZIP** | `Cently-macOS-v1.0.0.zip` | 28.58 MB | `a6abcee15386c8cfa1a18ef4f638fc5168c51d39035051b7badac5b4ad55b2c2` |
| **🐧 Linux DEB** | `Cently-Linux-amd64-v1.0.0.deb` | 14.29 MB | `54d7461717601c8d040a655798b059b0c64a8a0cb87640f0d043610cde2fb376` |
| **🐧 Linux Tarball** | `Cently-Linux-x64-v1.0.0.tar.gz` | 16.29 MB | `9196ed64d559e02e0cd4f645faeb74cee52da631363eb16d3a51fbbf941163a8` |
| **🍏 iOS (自签名)** | `Cently-iOS-unsigned-v1.0.0.ipa` | 16.06 MB | `7741fff39d5e06b3a1a2ae6720e0d792219c08794c05c58766157f30f9753517` |
| **🤖 Android arm64** | `Cently-Android-arm64-v8a-v1.0.0.apk` | 25.58 MB | `3bf36abae82598068ddfe323f71b78e1c0c1b80e5ca1d137f457bd7406de0bae` |
| **🤖 Android Universal** | `Cently-Android-Universal-v1.0.0.apk` | 62.66 MB | `2eb22bd4aee84860f74599676529375f08561fe8bed8db0e04ef823718f36cb1` |
| **🤖 Android armeabi-v7a**| `Cently-Android-armeabi-v7a-v1.0.0.apk`| 23.21 MB | `ec8b9d861ac46d5e80be71f207bb2155043c435683ed92b1b6e50c8029f20386` |
| **🤖 Android x86_64** | `Cently-Android-x86_64-v1.0.0.apk` | 26.97 MB | `4ac8600f90010d81d6cfffb70fedfa9914949d2bf63e6dd6bc9746ed4b546fcc` |
| **🤖 Android AAB** | `Cently-Android-v1.0.0.aab` | 61.45 MB | `ed65a775ecca135fa1422a3946f3bae83c2606f290e8a13ce0416ff9cca39dfb` |
| **🌐 Web 静态包** | `Cently-Web-v1.0.0.zip` | 20.29 MB | `0252048568e2266fa2fa9a7f79fd19bdc9f70c75b711152b3f1f77104313213a` |
