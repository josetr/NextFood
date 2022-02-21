import 'package:next_food/food.dart';
import 'package:next_food/util.dart';
import 'package:sqflite/sqflite.dart';

class FoodRepository {
  late Database database;

  Future<void> open(Database database) async {
    this.database = database;
    database.execute(
        'CREATE TABLE IF NOT EXISTS foods(name VARCHAR UNIQUE, date int);');
  }

  Future<List<Food>> load() async {
    final list = await database
        .rawQuery('SELECT name, date FROM foods ORDER BY date ASC, name ASC');
    final List<Food> result = [];
    final unixTime = getUnixTimeInSeconds();
    const sevenDaysInSeconds = 7 * 24 * 60 * 60;

    for (var i = 0; i < list.length; ++i) {
      final name = list[i]['name'] as String;
      int dt = list[i]['date'] as int;
      if (dt < (unixTime - sevenDaysInSeconds)) dt = 0;
      result.add(Food(name, dt));
    }

    return result;
  }

  void changeName(String from, String to) {
    database.update('foods', {'name': to}, where: 'name=?', whereArgs: [from]);
  }

  void addFood(Food food) {
    database.insert('foods', {'name': food.name, 'date': food.date});
  }

  void deleteFood(String name) {
    database.delete('foods', where: 'name=?', whereArgs: [name]);
  }
}
