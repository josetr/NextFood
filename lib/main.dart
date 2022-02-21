import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:next_food/food.dart';
import 'package:next_food/food_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextFood',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'NextFood'),
    );
  }
}

class MyHomePage extends HookWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foods = useState(<Food>[]);
    final editIndex = useState(-1);
    final addEnabled = useState(true);
    final addController = useTextEditingController();
    final editController = useTextEditingController();
    final foodRepository = useMemoized(() => FoodRepository());

    useEffect(() {
      late Database database;
      Future.microtask(() async {
        database = await openDatabase('db.db');
        await foodRepository.open(database);
        foods.value = await foodRepository.load();
      });

      return () {
        database.close();
      };
    }, []);

    void simpleError(String errorr) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(errorr),
          );
        },
      );
    }

    void add(String name) {
      if (name.isEmpty) {
        simpleError('Food name cannot be empty');
        return;
      }

      if (foods.value.any((Food x) => x.name == name)) {
        simpleError('Food already exists');
        return;
      }

      final food = Food(name, 0);
      foodRepository.addFood(food);
      foods.value = [...foods.value, food];
      addController.clear();
    }

    void cancel() {
      editIndex.value = -1;
    }

    void save(Food food, String name) {
      final index =
          foods.value.indexWhere((element) => element.name == food.name);
      if (index == -1) return;

      final newFood = food.copyWith(name: name);
      foodRepository.changeName(food.name, newFood.name);
      foods.value = foods.value.toList()..setAll(index, [newFood]);
      editIndex.value = -1;
    }

    void delete(String name) {
      foodRepository.deleteFood(name);
      foods.value = foods.value.toList()..removeWhere((e) => e.name == name);
      editIndex.value = -1;
    }

    void select(int i) {
      foods.value = foods.value.map((food) {
        if (food == foods.value[i]) {
          return food.select(!foods.value[i].isSelected);
        }

        return food;
      }).toList();
    }

    int getRandomUnused() {
      if (!foods.value.any((element) => element.date == 0)) return -1;
      if (foods.value.length == 1) return 0;

      final rng = Random();
      const min = 0;
      final max = (foods.value.length);

      while (true) {
        final rand = min + rng.nextInt(max);
        Food food = foods.value[rand];
        if (!food.isSelected) return rand;
      }
    }

    void chooseRandom() {
      final index = getRandomUnused();
      if (index == -1) {
        simpleError('No food available');
        return;
      }

      if (!foods.value[index].isSelected) select(index);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            PopupMenuButton(
              child: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  if (addEnabled.value)
                    PopupMenuItem(
                        child: const Text('Disable edit mode'),
                        onTap: () => addEnabled.value = false),
                  if (!addEnabled.value)
                    PopupMenuItem(
                        child: const Text('Enable edit mode'),
                        onTap: () => addEnabled.value = true),
                ];
              },
            ),
            const SizedBox(width: 50),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(children: [
              ListTile(
                  onTap: chooseRandom,
                  title: Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Choose random food"),
                      const Icon(Icons.refresh),
                    ],
                  ))),
              Expanded(
                child: ListView.builder(
                  itemCount: foods.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      color: foods.value[index].isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.5)
                          : Colors.transparent,
                      margin: const EdgeInsets.only(bottom: 5),
                      child: editIndex.value == index
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.cancel),
                                    splashRadius: 24,
                                    padding: EdgeInsets.all(0),
                                    onPressed: cancel,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: editController,
                                      onSubmitted: (va) {
                                        save(foods.value[editIndex.value],
                                            editController.text);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: () => save(
                                        foods.value[editIndex.value],
                                        editController.text),
                                  ),
                                ],
                              ))
                          : ListTile(
                              title: Text(foods.value[index].name),
                              onTap: () {},
                              onLongPress: () => select(index),
                              trailing: PopupMenuButton(
                                child: const Icon(Icons.more_vert),
                                itemBuilder: (context) {
                                  return [
                                    if (editIndex.value == -1)
                                      PopupMenuItem(
                                        child: const Text('Edit'),
                                        onTap: () {
                                          editIndex.value = index;
                                          editController.text =
                                              foods.value[index].name;
                                        },
                                      ),
                                    PopupMenuItem(
                                      child: const Text('Delete'),
                                      onTap: () =>
                                          delete(foods.value[index].name),
                                    ),
                                  ];
                                },
                              ),
                            ),
                    );
                  },
                ),
              ),
              if (addEnabled.value)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Food name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => add(addController.text),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ));
  }
}
