import 'package:flutter/material.dart';

class AppIcons {
  static const Map<String, IconData> iconMap = {
    // 餐饮 & 美食
    'restaurant': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_bar': Icons.local_bar_rounded,
    'bakery_dining': Icons.bakery_dining_rounded,
    'icecream': Icons.icecream_rounded,

    // 交通 & 出行
    'commute': Icons.directions_subway_rounded,
    'directions_car': Icons.directions_car_rounded,
    'local_taxi': Icons.local_taxi_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'two_wheeler': Icons.two_wheeler_rounded,
    'pedal_bike': Icons.pedal_bike_rounded,

    // 购物 & 消费
    'shopping_bag': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'checkroom': Icons.checkroom_rounded,
    'devices': Icons.devices_rounded,
    'storefront': Icons.storefront_rounded,

    // 居家 & 生活
    'home': Icons.home_rounded,
    'water_drop': Icons.water_drop_rounded,
    'bolt': Icons.bolt_rounded,
    'wifi': Icons.wifi_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,

    // 娱乐 & 休闲
    'sports_esports': Icons.sports_esports_rounded,
    'movie': Icons.movie_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'pets': Icons.pets_rounded,
    'park': Icons.park_rounded,
    'celebration': Icons.celebration_rounded,

    // 医疗 & 健康
    'local_hospital': Icons.local_hospital_rounded,
    'medication': Icons.medication_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,

    // 收入 & 财务
    'work': Icons.work_rounded,
    'account_balance': Icons.account_balance_rounded,
    'trending_up': Icons.trending_up_rounded,
    'savings': Icons.savings_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'redeem': Icons.redeem_rounded,
    'attach_money': Icons.attach_money_rounded,
    'payments': Icons.payments_rounded,

    // 其他
    'category': Icons.category_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'description': Icons.description_rounded,
    'favorite': Icons.favorite_rounded,
  };

  static IconData getIcon(String? iconKey) {
    if (iconKey == null || !iconMap.containsKey(iconKey)) {
      return Icons.category_rounded;
    }
    return iconMap[iconKey]!;
  }

  static List<String> getAllIconKeys() {
    return iconMap.keys.toList();
  }
}
