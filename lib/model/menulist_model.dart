// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MenulistModel {
  int? id;
  String? name;
  String? category;
  int? home;
  int? sequence;
  DateTime? createdAt;
  DateTime? updatedAt;

  MenulistModel({
    this.id,
    this.name,
    this.category,
    this.home,
    this.sequence,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'home': home,
      'sequence': sequence,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory MenulistModel.fromMap(Map<String, dynamic> map) {
    return MenulistModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      category: map['category'] != null ? map['category'] as String : null,
      home: map['home'] != null ? map['home'] as int : null,
      sequence: map['sequence'] != null ? map['sequence'] as int : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MenulistModel.fromJson(String source) =>
      MenulistModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MenulistModel(id: $id, name: $name, category: $category, home: $home, sequence: $sequence, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
