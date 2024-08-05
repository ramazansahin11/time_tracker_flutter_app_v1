import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:time_tracker/model/task.dart';

const String serverUrl = '......';

Future<List<Task>> fetchTasks() async {
  final response = await http.get(Uri.parse('$serverUrl/api/task'));

  if (response.statusCode == 200) {
    final List<dynamic> taskList = jsonDecode(response.body);

    final List<Task> items = taskList.map((task) {
      return Task.fromJson(task);
    }).toList();

    return items;
  } else {
    throw Exception('Failed to fetch items');
  }
}

Future<Task> addTask(
  String name,
  int seconds,
) async {
  final response = await http.post(Uri.parse('$serverUrl/api/task'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'seconds': seconds,
      }));

  if (response.statusCode == 201) {
    final dynamic json = jsonDecode(response.body);
    final Task task = Task.fromJson(json);
    return task;
  } else {
    throw Exception('Failed to add item');
  }
}

Future<void> deleteTask(int id) async {
  final response = await http.delete(Uri.parse('$serverUrl/api/task/$id'));

  if (response.statusCode != 200) {
    throw Exception("Failed to delete item");
  }
}

Future<void> updateTask(
  int id,
  String name,
  int seconds,
) async {
  final response = await http.put(Uri.parse('$serverUrl/api/task/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': id,
        'name': name,
        'seconds': seconds,
      }));

  if (response.statusCode != 200) {
    throw Exception("Failed to update item");
  }
}
