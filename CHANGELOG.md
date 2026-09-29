# 更新日志与版本发布归档 (Changelog & Release Information)

本文档整理并归档了 **分厘 (Cently)** 自项目开源以来的所有版本发布信息、技术架构演进、变更说明及官方全平台构建产物校验矩阵。

---

## 目录
- [版本发布总览](#版本发布总览)
- [v1.0.4 (2026-09-29) - 全局检索强化与跨页面数据串联](#v104---2026-09-29)
- [v1.0.3 (2026-09-12) - 界面视觉与微交互体验全面升级](#v103---2026-09-12)
- [v1.0.2 (2026-09-04) - 性能优化与测试矩阵扩充](#v102---2026-09-04)
- [v1.0.1 (2026-08-31) - 账单回收站与交互打磨](#v101---2026-08-31)
- [v1.0.0 (2026-08-18) - 官方首个正式版](#v100---2026-08-18)
- [全平台构建产物与 SHA-256 校验指纹](#全平台构建产物与-sha-256-校验指纹)

---

## 版本发布总览

| 版本号 | 构建号 | Git 标签 / Commit | 发布时间 (CST) | 核心主题 | 变动统计 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`v1.0.4`** | `1.0.4+5` | [`v1.0.4`](https://github.com/e69d8e/Cently/releases/tag/v1.0.4) | 2026-09-29 23:00 | 全局检索强化（关键词高亮 + 金额双格式）、统计榜单一键回看明细、主题模式持久化、记账一键撤销、76 项测试 | 16 文件 (+799 / -123) |
| **`v1.0.3`** | `1.0.3+4` | [`v1.0.3`](https://github.com/e69d8e/Cently/releases/tag/v1.0.3) | 2026-09-12 14:45 | 界面视觉与微交互体验升级、等宽数字排版、暗黑模式对比度重塑、65 项测试 | 15 文件 |
| **`v1.0.2`** | `1.0.2+3` | [`v1.0.2`](https://github.com/e69d8e/Cently/releases/tag/v1.0.2) (`6878869`) | 2026-09-04 12:12 | 核心渲染零计算、键盘即时响应、SQLite 覆盖索引、59 项测试 | 15 文件 (+878 / -56) |
| **`v1.0.1`** | `1.0.1+2` | [`v1.0.1`](https://github.com/e69d8e/Cently/releases/tag/v1.0.1) (`b9ff9d7`) | 2026-08-31 16:35 | 账单回收站与防误删、数字键盘与记账体验优化、38+ 项测试 | 22 文件 (+3333 / -948) |
| **`v1.0.0`** | `1.0.0+1` | [`v1.0.0`](https://github.com/e69d8e/Cently/releases/tag/v1.0.0) (`e5d5d04`) | 2026-08-18 20:35 | 首个正式版发布：极速记账、多维图表、分类预设、全平台自动化矩阵 | 初始版本提交上线 |

---

## [v1.0.4] - 2026-09-29

- **发布页面**：[GitHub Release v1.0.4](https://github.com/e69d8e/Cently/releases/tag/v1.0.4)
- **代码对比**：[`v1.0.3...v1.0.4`](https://github.com/e69d8e/Cently/compare/v1.0.3...v1.0.4)
- **构建版本**：`1.0.4+5`
- **发布说明源码**：[.github/RELEASE_NOTES_v1.0.4.md](.github/RELEASE_NOTES_v1.0.4.md)

### ✨ 新增与优化内容 (Changelog)

#### 1. 🔍 全局检索能力升级（搜索即导航）
- **统计排行榜一键回看明细**：统计页排行榜每行均可点击，自动跳转「明细」Tab 并以该项目名称发起搜索，消费洞察与原始流水之间再无断点。
- **命中关键词高亮**：搜索结果中的名称、分类、备注与金额会将匹配片段以主题蓝色加粗渲染（暗色模式使用柔和蓝 `#7CB0FF`），新增 `_HighlightedText` 组件统一承载富文本高亮逻辑。
- **跨页面唤起搜索栏**：由统计页等外部入口发起检索时，主页搜索栏自动展开并同步关键词，同时不弹出软键盘；搜索栏自身手动展开时仍保持自动聚焦。

#### 2. 💰 金额检索双格式覆盖
- **千分位与两位小数通吃**：搜索词同时匹配千分位格式（`5,000.00`）与紧凑小数格式（`5000.00`），补齐了此前仅能按名称、分类、备注检索的短板。

#### 3. 🎨 主题模式持久化（跟随系统 / 浅色 / 深色）
- **全新「外观」设置分区**：提供「跟随系统 / 浅色模式 / 深色模式」三档单选，当前生效项以主色对勾标识。
- **重启后自动恢复**：主题偏好写入本地 SQLite 新增的 `app_settings` 键值表（数据库升级至 v6），冷启动自动读回；读写异常均静默降级为「跟随系统」，绝不阻塞启动。
- **切换即时生效**：选择后全应用主题即时切换，无需重启。

#### 4. ↩️ 记账保存反馈与一键撤销
- **全局保存提示**：新增与编辑账单保存成功后弹出位于底部导航之上的浮动提示（`已记一笔「早餐」 ¥12.00`），记账操作有了明确完成感。
- **新增可撤销**：新增账单提示附带「撤销」动作，误操作可一键彻底移除；编辑保存仅提示不提供撤销，避免歧义。
- **保存结果结构化返回**：记账页回收时携带落库后的完整记录（含生成的唯一 ID），为「保存并再记一笔」等扩展流程打好基础。

#### 5. 📊 统计与主页细节打磨
- **日均收支双口径**：统计概览的日均指标不再仅限支出，收入视图下同样展示「日均收入」。
- **主页看板可点击跳转**：主页月度看板整体可点击直达统计图表 Tab，附带悬停提示与 Material 水波纹反馈。
- **再次点击 Tab 回到顶部**：重复点击底部导航当前 Tab 时，明细列表平滑滚动回顶部（320ms `easeOutCubic`）。

#### 6. 🧪 自动化测试与代码质量
- **76 项测试全量绿灯通过**：新增外观主题切换 Widget 测试、`SettingsProvider` 状态与持久化测试、`app_settings` 键值存储与数据表共存测试，以及金额双格式检索边界测试。
- **静态分析零告警**：`flutter analyze` 保持 0 Warning / 0 Error。

#### 7. 🗄️ 数据兼容性
- 数据库自动从 **v5 平滑升级至 v6**，仅新增 `app_settings` 表（`CREATE TABLE IF NOT EXISTS`），**不触碰任何既有账单、分类与回收站数据**，升级后历史账目完整保留。

---

## [v1.0.3] - 2026-09-12

- **发布页面**：[GitHub Release v1.0.3](https://github.com/e69d8e/Cently/releases/tag/v1.0.3)
- **代码对比**：[`v1.0.2...v1.0.3`](https://github.com/e69d8e/Cently/compare/v1.0.2...v1.0.3)
- **构建版本**：`1.0.3+4`
- **发布说明源码**：[.github/RELEASE_NOTES_v1.0.3.md](.github/RELEASE_NOTES_v1.0.3.md)

### ✨ 新增与优化内容 (Changelog)

#### 1. 🔠 全局等宽数字排版 (Tabular Figures)
- **消除高频数字抖动**：在全局 Light / Dark TextTheme 中注入 `FontFeature.tabularFigures()`，并在主页看板、流水明细、数字键盘、记账输入与实时计算预览、统计排行榜、回收站天数等所有核心展示位显式启用等宽数字排版，彻底消除敲击与滚动时的字形跳动。

#### 2. 🌙 暗黑模式对比度与层级重构
- **主记账 FAB 按钮焦点重塑**：暗黑模式下改用极简高反差白亮表面 (`#F8FAFC`) 配深色图标，配合精细环形外圈描边，解决深色底栏下 FAB 融于背景的问题。
- **柔和财务背景色阶**：引入 `expenseBgDark`、`incomeBgDark`、`balanceBgDark` 等专为暗色适配的半透明微底色，带来舒适高质感的暗色财务体验。

#### 3. 📱 主页操作体验与看板美化
- **左右轻扫快速切月**：账单流水列表支持水平滑动手势（`onHorizontalDragEnd`），左右滑动即可轻快在各月份之间切换并伴随触觉反馈。
- **现代财务看板重构**：独立 Capsule Pill 标识账期，突出呈现“结余”Hero 金额及平滑淡入淡出动画，搭配收支双栏柔和卡片。
- **搜索体验增强**：搜索栏支持匹配笔数实时胶囊指示（`共匹配到 X 笔记录`）与一键清空按钮。
- **滑动删除交互**：滑动删除升级为带图标与提示文本的圆角胶囊背景。

#### 4. ⌨️ 记账流程与计算键盘交互升级
- **分类 5 列紧凑网格一键展开**：在记账页引入分类展开/收起按钮，支持在“单行横划”与“5列紧凑网格”之间一键平滑切换，海量自定义分类也能一屏直选。
- **计算器键盘实时算式激活**：`+` / `-` 运算符处于活动状态时按键高亮展示，金额显示区实时计算并预览运算结果。
- **预设芯片优化**：选中项配备主色细边框与对勾图标，配合微动画自然过渡。

#### 5. 📊 统计分析与排行榜排版
- **金银铜专属奖牌徽章**：排行榜前三名显式增加 `#1`（金）、`#2`（银）、`#3`（铜）高反差徽章，层次分明。
- **动效微调**：饼图中心数据切换增加平滑淡入淡出动效，进度条升级为两端全圆角的 5dp 胶囊槽。

#### 6. 🏷️ 图标选择器语义化过滤
- **9 大语义分类**：新增「全部、餐饮、交通、购物、居家、娱乐、医疗、财务、其他」过滤标签，快速缩小图标搜寻范围。

#### 7. 🧪 自动化测试与代码质量
- **65 项测试全量绿灯通过**：覆盖模型、状态机、多字段搜索、回收站 30 天自动清理规则及全套 Widget 交互测试。
- **静态分析零告警**：`flutter analyze` 保持 0 Warning / 0 Error。

#### 8. 🔐 Android 官方发布签名
- **告别 debug 签名**：Android 发布产物（APK / AAB）改用 Cently 官方 release 密钥（PKCS12，alias `cently`，有效期 30 年）签名，安装包可正常覆盖升级与分发校验。
- **CI 全自动签名与验签**：Release 流水线通过 `ANDROID_KEYSTORE_BASE64` 等 Repository Secrets 还原密钥库，打包后自动执行 `apksigner` / `keytool` 证书指纹校验，签名不符即构建失败（详见 [README](README.md#-android-发布签名)）。

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

### 最新版本 (v1.0.4) 产物清单

| 平台 / 架构 | 发布文件名 | 大小 | SHA-256 校验指纹 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows Setup** | `Cently-Windows-x64-1.0.4-Setup.exe` | 15.38 MB | `b90c7c1ac8be488dccd60d3e79b8374f5655cc66e9c5c048ca5db601ebcb54b4` |
| **🪟 Windows Portable** | `Cently-Windows-x64-v1.0.4.zip` | 18.86 MB | `0d26194a9454fa39e19abd15fe11aa31ce67699c2f4badda2ee71a3654f8d5fa` |
| **🍎 macOS DMG** | `Cently-macOS-v1.0.4.dmg` | 28.79 MB | `c40fcbf677209bb7043b864530cb71f99de869df61dd45b7ca9a9e03d2a56c21` |
| **🍎 macOS ZIP** | `Cently-macOS-v1.0.4.zip` | 28.87 MB | `7f17218a013b136193c2b220ae0ea151be2f3ab2795a20b37e31b2e70992dbbc` |
| **🐧 Linux DEB** | `Cently-Linux-amd64-v1.0.4.deb` | 14.46 MB | `cbebb2606552912376bc52f092bfddc2c06f534737f5f65badd925a7f742bfba` |
| **🐧 Linux Tarball** | `Cently-Linux-x64-v1.0.4.tar.gz` | 16.52 MB | `fe30aa509681369c5feaa2bd63bf6ad2ec317cc9a42a440d5d2281a483e17ac7` |
| **🍏 iOS (自签名)** | `Cently-iOS-unsigned-v1.0.4.ipa` | 16.21 MB | `fbe9f41be554b718ca4867455f25ef2014466a43e2093650bd9646a5c911ce80` |
| **🤖 Android arm64** | `Cently-Android-arm64-v8a-v1.0.4.apk` | 26.00 MB | `ab078b7bf592505c25e1db55b3a7f869a285a8912b29be6aa6b5164415cacfdb` |
| **🤖 Android Universal** | `Cently-Android-Universal-v1.0.4.apk` | 63.78 MB | `a52ae735c5dedc86e2c405eaab02e73d4ccf9289d2fd0fb07f94f45348ffc07c` |
| **🤖 Android armeabi-v7a**| `Cently-Android-armeabi-v7a-v1.0.4.apk`| 23.58 MB | `511d51269b23ce1cef28957b96d02933f2b935e44e8c269589238c1dfcaf067a` |
| **🤖 Android x86_64** | `Cently-Android-x86_64-v1.0.4.apk` | 27.39 MB | `cef5b405aac23c476b6c4b946d3cab27f98ab35aa365d85a5b47075423f71ba1` |
| **🤖 Android AAB** | `Cently-Android-v1.0.4.aab` | 62.27 MB | `cf485242d0afb35122fc25d618819f7765bb867a06c5651dc31d646895e4d82a` |
| **🌐 Web 静态包** | `Cently-Web-v1.0.4.zip` | 20.36 MB | `fe2a1e46640662f072adbaf8fce27058748012596bc29baff4168cb176658c4a` |

> 🔐 自 v1.0.3 起，Android 产物（APK / AAB）使用 **Cently 官方 release 密钥**签名（证书 SHA-256 `2B:E3:1B:55:C2:A8:58:D4:F3:39:0D:83:4A:BB:7E:28:77:D6:BA:2F:AD:8A:29:FE:80:F5:E8:11:50:E7:8B:68`），校验方式见 [README 签名章节](README.md#-android-发布签名)。

---

### 历史版本 (v1.0.3) 产物清单

| 平台 / 架构 | 发布文件名 | 大小 | SHA-256 校验指纹 |
| :--- | :--- | :--- | :--- |
| **🪟 Windows Setup** | `Cently-Windows-x64-1.0.3-Setup.exe` | 15.38 MB | `4c821fbcaf9c84f4651a23a24226752e45fb7511634acb083b730cb0f08a6db8` |
| **🪟 Windows Portable** | `Cently-Windows-x64-v1.0.3.zip` | 18.86 MB | `56d12706843e1aee53e18526d39eb94d4ae5b021afaf24c3713f6832ce3a40e6` |
| **🍎 macOS DMG** | `Cently-macOS-v1.0.3.dmg` | 28.78 MB | `950c2eabfdaa0e4f757572332d8609d4ecdc39e22785ed33db00aa6fbe54c4ae` |
| **🍎 macOS ZIP** | `Cently-macOS-v1.0.3.zip` | 28.86 MB | `c795e88bd77f03b0a794666ea6195e830db4107aab7978f56e14ab6fa06a828f` |
| **🐧 Linux DEB** | `Cently-Linux-amd64-v1.0.3.deb` | 14.46 MB | `6087ff1c5b0f42a48c9ae84ba93fb60de286d4b9bb1d06e0dc6badfa3b162ee6` |
| **🐧 Linux Tarball** | `Cently-Linux-x64-v1.0.3.tar.gz` | 16.52 MB | `9aa342fa08ed4ab037a3887845ee74ec3435dc6ac47e4e3e6d37fe355fcad7d1` |
| **🍏 iOS (自签名)** | `Cently-iOS-unsigned-v1.0.3.ipa` | 16.21 MB | `33e434b7abc6397ea25e1fbd4773969f6e07adf8e7390345d994302e68946449` |
| **🤖 Android arm64** | `Cently-Android-arm64-v8a-v1.0.3.apk` | 26.01 MB | `cb0bd38890d7865a1a96f20e7e97ddc0820974fcb3547dda1adfef3f17436196` |
| **🤖 Android Universal** | `Cently-Android-Universal-v1.0.3.apk` | 63.77 MB | `44a5207c906116b80523b2cea9995d0b64a27a5e20fa888121341e9f68a957ff` |
| **🤖 Android armeabi-v7a**| `Cently-Android-armeabi-v7a-v1.0.3.apk`| 23.57 MB | `d9f6dec4124974313ccd619953b9ac82d3e45d61168f5a089dc9d9bfcc9a2b75` |
| **🤖 Android x86_64** | `Cently-Android-x86_64-v1.0.3.apk` | 27.39 MB | `c167e222e30abe046c14eda56716f96fa3965f256cf82d3491843d058767436c` |
| **🤖 Android AAB** | `Cently-Android-v1.0.3.aab` | 62.24 MB | `62e76804d73072555c1ecf1a1a12125f10977d364392dda1767a1657db0b6ff5` |
| **🌐 Web 静态包** | `Cently-Web-v1.0.3.zip` | 20.37 MB | `9af3517efe3aed5f739879ae53bd6b0605aaf75c23cdd593db98faac8257e9f8` |

> 🔐 自 v1.0.3 起，Android 产物（APK / AAB）使用 **Cently 官方 release 密钥**签名（证书 SHA-256 `2B:E3:1B:55:C2:A8:58:D4:F3:39:0D:83:4A:BB:7E:28:77:D6:BA:2F:AD:8A:29:FE:80:F5:E8:11:50:E7:8B:68`），校验方式见 [README 签名章节](README.md#-android-发布签名)。

---

### 历史版本 (v1.0.2) 产物清单

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
