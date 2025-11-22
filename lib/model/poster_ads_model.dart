// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PosterAdsModel {
  int? id;
  String? title;
  String? posterPath;
  int? display;
  int? sequence;
  DateTime? createdAt;
  DateTime? updatedAt;

  PosterAdsModel({
    this.id,
    this.title,
    this.posterPath,
    this.display,
    this.sequence,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'display': display,
      'sequence': sequence,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory PosterAdsModel.fromMap(Map<String, dynamic> map) {
    return PosterAdsModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] != null ? map['title'] as String : null,
      posterPath: map['poster_path'] != null ? map['poster_path'] as String : null,
      display: map['display'] != null ? map['display'] as int : null,
      sequence: map['sequence'] != null ? map['sequence'] as int : null,
      // createdAt: map['created_at'] != null
      //     ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
      //     : null,
      // updatedAt: map['updated_at'] != null
      //     ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
      //     : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PosterAdsModel.fromJson(String source) =>
      PosterAdsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PosterAdsModel(id: $id, title: $title, posterPath: $posterPath, display: $display, sequence: $sequence, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
