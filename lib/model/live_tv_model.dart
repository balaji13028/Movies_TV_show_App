// ignore_for_file: public_member_api_docs, sort_constructors_first
class LiveTvModel {
  int? id;
  String? channelName;
  String? channelNo;
  String? thumbnail;
  String? description;
  String? websiteAddress;
  int? smartTv;
  int? mobile;
  int? website;
  String? liveSource;
  int? sequence;
  DateTime? createdAt;
  DateTime? updatedAt;

  LiveTvModel({
    this.id,
    this.channelName,
    this.channelNo,
    this.thumbnail,
    this.description,
    this.websiteAddress,
    this.smartTv,
    this.mobile,
    this.website,
    this.liveSource,
    this.sequence,
    this.createdAt,
    this.updatedAt,
  });

  factory LiveTvModel.fromMap(Map<String, dynamic> json) => LiveTvModel(
        id: json["id"],
        channelName: json["channel_name"],
    channelNo: json["channel_no"],
        thumbnail: json["thumbnail"],
        description: json["description"],
        websiteAddress: json["website_address"],
        smartTv: json["smart_tv"],
        mobile: json["mobile"],
        website: json["website"],
        liveSource: json["live_source"],
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
        "channel_name": channelName,
        "channel_no": channelNo,
        "thumbnail": thumbnail,
        "description": description,
        "website_address": websiteAddress,
        "smart_tv": smartTv,
        "mobile": mobile,
        "website": website,
        "live_source": liveSource,
        "sequence": sequence,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return 'LiveTvModel(id: $id, channelName: $channelName, channelNo:$channelNo, thumbnail: $thumbnail, description: $description, websiteAddress: $websiteAddress, smartTv: $smartTv, mobile: $mobile, website: $website, liveSource: $liveSource, sequence: $sequence, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
