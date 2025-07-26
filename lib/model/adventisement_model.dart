// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AdventisementModel {
  int? id;
  String? title;
  String? videoPath;
  int? display;
  int? sequence;
  DateTime? createdAt;
  DateTime? updatedAt;

  AdventisementModel({
    this.id,
    this.title,
    this.videoPath,
    this.display,
    this.sequence,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'videoPath': videoPath,
      'display': display,
      'sequence': sequence,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory AdventisementModel.fromMap(Map<String, dynamic> map) {
    return AdventisementModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] != null ? map['title'] as String : null,
      videoPath: map['video_path'] != null ? map['video_path'] as String : null,
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

  factory AdventisementModel.fromJson(String source) =>
      AdventisementModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AdventisementModel(id: $id, title: $title, videoPath: $videoPath, display: $display, sequence: $sequence, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
