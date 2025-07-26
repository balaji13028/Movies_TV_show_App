// ignore_for_file: public_member_api_docs, sort_constructors_first
class SlidesModel {
  int? id;
  String? title;
  String? description;
  String? imagePath;
  int? sequence;
  DateTime? createdAt;
  DateTime? updatedAt;

  SlidesModel({
    this.id,
    this.title,
    this.description,
    this.imagePath,
    this.sequence,
    this.createdAt,
    this.updatedAt,
  });

  factory SlidesModel.fromMap(Map<String, dynamic> json) => SlidesModel(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        imagePath: json["image_path"],
        sequence: json["sequence"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "description": description,
        "image_path": imagePath,
        "sequence": sequence,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return 'SlidesModel(id: $id, title: $title, description: $description, imagePath: $imagePath, sequence: $sequence, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
