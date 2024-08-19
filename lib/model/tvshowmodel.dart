// ignore_for_file: public_member_api_docs, sort_constructors_first

class TvShowModel {
  int? id;
  String? title;
  String? description;
  String? source;
  String? thumbnail;
  bool? smartTv;
  bool? mobile;
  bool? website;
  int? sequence;
  List<String>? menuRights;
  DateTime? createdAt;
  DateTime? updatedAt;

  TvShowModel({
    this.id,
    this.title,
    this.description,
    this.source,
    this.thumbnail,
    this.smartTv,
    this.mobile,
    this.website,
    this.sequence,
    this.menuRights,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'thumbnail': thumbnail,
      'smartTv': smartTv,
      'mobile': mobile,
      'website': website,
      'sequence': sequence,
      'menuRights': menuRights,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory TvShowModel.fromMap(Map<String, dynamic> map) {
    return TvShowModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] != null ? map['title'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      source: map['source'] != null ? map['source'] as String : null,
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
      smartTv: map['smartTv'] != null ? map['smartTv'] as bool : null,
      mobile: map['mobile'] != null ? map['mobile'] as bool : null,
      website: map['website'] != null ? map['website'] as bool : null,
      sequence: map['sequence'] != null ? map['sequence'] as int : null,
      menuRights: map['menuRights'] != null
          ? List<String>.from((map['menuRights'] as List<String>))
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }
}
