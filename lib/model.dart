class PostModels {
  final int? id;
  final String title;
  final String description;
  
  PostModels({
    this.id,
    required this.title,
    required this.description,
  });

  PostModels.fromMap(Map<String, dynamic> item)
      : id = item['id'],
        title = item['title'],
        description = item['description'];

  Map<String, Object?> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }
  
}
