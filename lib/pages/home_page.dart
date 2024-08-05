import 'dart:async';
import 'package:flutter/material.dart';
import 'package:time_tracker/network/network.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final nameController = TextEditingController();
  final secondsController = TextEditingController();
  int colorTask = 0;
  bool onSelected = false;

  // Timer state for each task
  final Map<int, Timer?> _timers = {};
  final Map<int, bool> _paused = {};
  final Map<int, int> _seconds = {};

  void startTimer(int id) {
    _timers[id] = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds[id] = (_seconds[id] ?? 0) + 1;
      });
    });
  }

  void stopTimer(int id) async {
    _timers[id]?.cancel();
  }

  void restart(int id) async {
    _seconds[id] = 0;
    _timers[id]?.cancel();
  }

  String formattedTime(int timeInSeconds) {
    int hrs = (timeInSeconds / 3600).floor();
    int min = ((timeInSeconds - hrs * 3600) / 60).floor();
    int sec = timeInSeconds - (hrs * 3600) - (min * 60);

    String hours = hrs.toString().length < 2 ? '0$hrs' : '$hrs';
    String minute = min.toString().length < 2 ? "0$min" : "$min";
    String second = sec.toString().length < 2 ? "0$sec" : "$sec";
    return "$hours : $minute : $second";
  }

  @override
  void dispose() {
    _timers.forEach((_, timer) => timer?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timeline',
          style: TextStyle(fontSize: 30),
        ),
      ),
      body: FutureBuilder(
        future: fetchTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final task = snapshot.data![index];
                  final taskId = task.id;

                  _seconds[taskId] ??= task.seconds;
                  _paused[taskId] ??= true;

                  return Dismissible(
                    crossAxisEndOffset: 0.2,
                    dismissThresholds: const {DismissDirection.endToStart: 0.2},
                    background: Container(
                      margin:
                          const EdgeInsets.only(top: 12, left: 12, right: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    onDismissed: (DismissDirection direction) async {
                      if (direction == DismissDirection.endToStart) {
                        await deleteTask(taskId);

                        setState(() {
                          _seconds.remove(taskId);
                          _timers.remove(taskId);
                          _paused.remove(taskId);
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin:
                          const EdgeInsets.only(top: 12, left: 12, right: 12),
                      height: 75,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 100,
                                child: Text(
                                  task.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              formattedTime(_seconds[taskId] ?? 0),
                              style: const TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  restart(taskId);
                                  _paused[taskId] = true;
                                  updateTask(
                                      taskId, task.name, _seconds[taskId] ?? 0);
                                });
                              },
                              icon: !_paused[taskId]!
                                  ? const Icon(
                                      Icons.restart_alt_outlined,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                  : const Text(' '),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _paused[taskId] = !_paused[taskId]!;
                                });
                                if (!_paused[taskId]!) {
                                  startTimer(taskId);
                                } else {
                                  stopTimer(taskId);
                                }
                                updateTask(
                                    taskId, task.name, _seconds[taskId] ?? 0);
                              },
                              icon: _paused[taskId]!
                                  ? const Icon(
                                      Icons.play_arrow,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.pause,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const SizedBox(
                        height: 20,
                      ),
                      const Text('Add a new Task'),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration:
                              const InputDecoration(labelText: 'Task Name'),
                          controller: nameController,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextButton(
                        onPressed: () async {
                          await addTask(nameController.text, 0);
                          setState(() {
                            nameController.clear();
                            _seconds.clear(); // Tüm süreleri sıfırla
                            _timers.clear(); // Tüm timer'ları sıfırla
                            _paused.clear(); // Tüm paused durumlarını sıfırla
                          });
                          Navigator.pop(context);
                        },
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.black),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
