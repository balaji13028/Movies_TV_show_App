// To parse this JSON data, do
// final socialLinkModel = socialLinkModelFromJson(jsonString);

import 'dart:convert';

SocialLinkModel socialLinkModelFromJson(String str) =>
    SocialLinkModel.fromJson(json.decode(str));

String socialLinkModelToJson(SocialLinkModel data) =>
    json.encode(data.toJson());

class SocialLinkModel {
  int? status;
  String? message;
  List<Result>? result;

  SocialLinkModel({
    this.status,
    this.message,
    this.result,
  });

  factory SocialLinkModel.fromJson(Map<String, dynamic> json) =>
      SocialLinkModel(
        status: json["status"],
        message: json["message"],
        result: List<Result>.from(
            json["result"]?.map((x) => Result.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null
            ? []
            : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
      };
}

class Result {
  int? id;
  String? name;
  String? image;
  String? url;
  int? status;
  String? createdAt;
  String? updatedAt;

  Result({
    this.id,
    this.name,
    this.image,
    this.url,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        url: json["url"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "image": image,
        "url": url,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
