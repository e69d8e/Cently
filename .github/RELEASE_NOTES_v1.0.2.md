# 🪙 分厘 (Cently) v1.0.2 发布说明

> *分厘之间，细致入微 · 分文厘毫，了然于胸*

**分厘 (Cently)** 是一款基于 Flutter 构建的高颜值、轻量级个人记账与财务分析应用。v1.0.2 版本聚焦于**核心渲染与数据衍生计算的深度性能优化**，并建立了覆盖核心逻辑的高质量单元测试矩阵。

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

### 📦 安装与下载（仅 Android）

发布流水线只构建以下三个 Android 安装包：

| 安装包 | 适用设备 | 说明 |
| :--- | :--- | :--- |
| 🤖 `Cently-Android-arm64-v8a-v1.0.2.apk` | 绝大多数现代 64 位 Android 手机 | **推荐**，体积最小 |
| 🤖 `Cently-Android-armeabi-v7a-v1.0.2.apk` | 老旧 32 位 ARM 设备 | 兼容性优先 |
| 🤖 `Cently-Android-Universal-v1.0.2.apk` | 全部架构（含 x86_64 模拟器） | 通用包，体积稍大 |

> iOS / macOS / Windows / Linux / Web 版本不再随 Releases 发布；如需使用请在本地自行编译（见仓库 README 的「打包构建」章节）。

---

**Full Changelog**: https://github.com/e69d8e/Cently/compare/v1.0.1...v1.0.2
