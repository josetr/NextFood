import 'package:next_food/util.dart';

class Food {
  final String name;
  final int date;

  Food(this.name, this.date);

  bool get isSelected {
    return date != 0;
  }

  Food select(bool select) {
    if (!select) return Food(name, 0);

    final now = DateTime.now();
    return Food(name, getUnixTimeInSeconds());
  }

  Food copyWith({String? name, int? date}) {
    return Food(name ?? this.name, date ?? this.date);
  }

  @override
  bool operator ==(Object? other) {
    final food = other as Food?;
    return food != null && food.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
