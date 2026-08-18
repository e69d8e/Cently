import '../models/category.dart';
import '../models/preset_item.dart';

class DefaultData {
  static List<Category> getDefaultCategories() {
    return [
      // 支出分类
      Category(
        id: 'cat_exp_food',
        name: '餐饮',
        type: CategoryType.expense,
        iconKey: 'restaurant',
        colorValue: 0xFFE11D48,
        sortOrder: 0,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_transport',
        name: '交通',
        type: CategoryType.expense,
        iconKey: 'commute',
        colorValue: 0xFF0284C7,
        sortOrder: 1,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_shopping',
        name: '购物',
        type: CategoryType.expense,
        iconKey: 'shopping_bag',
        colorValue: 0xFFEA580C,
        sortOrder: 2,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_housing',
        name: '居家',
        type: CategoryType.expense,
        iconKey: 'home',
        colorValue: 0xFFD97706,
        sortOrder: 3,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_entertainment',
        name: '娱乐',
        type: CategoryType.expense,
        iconKey: 'sports_esports',
        colorValue: 0xFF7C3AED,
        sortOrder: 4,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_medical',
        name: '医疗',
        type: CategoryType.expense,
        iconKey: 'local_hospital',
        colorValue: 0xFF0D9488,
        sortOrder: 5,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_gift',
        name: '人情',
        type: CategoryType.expense,
        iconKey: 'card_giftcard',
        colorValue: 0xFFDB2777,
        sortOrder: 6,
        isDefault: true,
      ),
      Category(
        id: 'cat_exp_other',
        name: '其他',
        type: CategoryType.expense,
        iconKey: 'category',
        colorValue: 0xFF475569,
        sortOrder: 7,
        isDefault: true,
      ),

      // 收入分类
      Category(
        id: 'cat_inc_salary',
        name: '薪资',
        type: CategoryType.income,
        iconKey: 'work',
        colorValue: 0xFF059669,
        sortOrder: 0,
        isDefault: true,
      ),
      Category(
        id: 'cat_inc_parttime',
        name: '兼职',
        type: CategoryType.income,
        iconKey: 'trending_up',
        colorValue: 0xFF0D9488,
        sortOrder: 1,
        isDefault: true,
      ),
      Category(
        id: 'cat_inc_investment',
        name: '理财',
        type: CategoryType.income,
        iconKey: 'savings',
        colorValue: 0xFFD97706,
        sortOrder: 2,
        isDefault: true,
      ),
      Category(
        id: 'cat_inc_gift',
        name: '红包',
        type: CategoryType.income,
        iconKey: 'redeem',
        colorValue: 0xFFE11D48,
        sortOrder: 3,
        isDefault: true,
      ),
      Category(
        id: 'cat_inc_other',
        name: '其他收入',
        type: CategoryType.income,
        iconKey: 'payments',
        colorValue: 0xFF475569,
        sortOrder: 4,
        isDefault: true,
      ),
    ];
  }

  static List<PresetItem> getDefaultPresetItems() {
    final List<PresetItem> items = [];

    void addItems(String catId, List<String> names) {
      for (int i = 0; i < names.length; i++) {
        items.add(PresetItem(
          id: '${catId}_preset_$i',
          categoryId: catId,
          name: names[i],
          sortOrder: i,
          isDefault: true,
        ));
      }
    }

    // 餐饮
    addItems('cat_exp_food', ['早餐', '午餐', '晚餐', '外卖', '奶茶', '咖啡', '水果', '零食', '聚餐', '夜宵', '买菜']);
    // 交通
    addItems('cat_exp_transport', ['地铁', '公交', '打车', '加油', '停车费', '高铁', '机票', '共享单车']);
    // 购物
    addItems('cat_exp_shopping', ['日用品', '服饰鞋包', '数码硬件', '美妆护肤', '零食百货', '图书文具']);
    // 居家
    addItems('cat_exp_housing', ['房租', '水电燃气', '物业费', '宽带网费', '保洁家政', '家具家电']);
    // 娱乐
    addItems('cat_exp_entertainment', ['电影演出', '游戏充值', '旅游度假', '运动健身', '会员订阅', '聚会轰趴']);
    // 医疗
    addItems('cat_exp_medical', ['药品买药', '门诊挂号', '医疗检查', '保健养生']);
    // 人情
    addItems('cat_exp_gift', ['红包礼金', '送礼', '请客', '孝敬长辈']);
    // 其他支出
    addItems('cat_exp_other', ['杂项支出', '意外支出', '手续费', '捐赠']);

    // 薪资收入
    addItems('cat_inc_salary', ['基本工资', '年终奖金', '加班工资', '岗位补贴', '绩效奖金']);
    // 兼职副业
    addItems('cat_inc_parttime', ['劳务稿费', '咨询服务', '外包开发', '兼职打工']);
    // 理财收入
    addItems('cat_inc_investment', ['基金收益', '股票分红', '银行利息', '房屋租金']);
    // 红包礼金
    addItems('cat_inc_gift', ['亲友红包', '节日礼金', '长辈关爱']);
    // 其他收入
    addItems('cat_inc_other', ['报销到账', '二手闲置', '退款到账', '中奖福利']);

    return items;
  }
}
