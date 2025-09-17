class Recording {
  final String id;
  final String path;
  final String name;
  final double duration;
  final DateTime date;
  
  Recording({
    required this.id,
    required this.path,
    required this.name,
    required this.duration,
    required this.date,
  });
  
  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }
  
  // Create from map
  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'],
      path: map['path'],
      name: map['name'],
      duration: map['duration'],
      date: DateTime.parse(map['date']),
    );
  }
}