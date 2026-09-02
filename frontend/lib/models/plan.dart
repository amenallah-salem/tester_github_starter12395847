class Plan {
  final String id, title;
  final List<String> days;
  Plan({required this.id, required this.title, this.days = const []});
  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: j['id'], title: j['title'], days: List<String>.from(j['days'] ?? []));
}
