class Task {
  int id;
  String name;
  int seconds;

  Task({
    required this.id,
    required this.name,
    required this.seconds,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      seconds: json['seconds'],
    );
  }
}
