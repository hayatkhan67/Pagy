// To parse this JSON data, do
//
//     final AnimeModel = AnimeModelFromJson(jsonString);

class AnimeModel {
  final String? title;
  final String? image;
  final String? id;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AnimeModel({
    this.title,
    this.image,
    this.id,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) => AnimeModel(
    title: json["title"],
    image: json["image"],
    id: json["_id"],
    type: json["type"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "image": image,
    "type": type,
    "_id": id,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
