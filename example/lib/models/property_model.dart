// To parse this JSON data, do
//
//     final propertyModel = propertyModelFromJson(jsonString);

import 'dart:convert';

PropertyModel propertyModelFromJson(String str) =>
    PropertyModel.fromJson(json.decode(str));

String propertyModelToJson(PropertyModel data) => json.encode(data.toJson());

class PropertyModel {
  final String? title;
  final String? description;
  final int? price;
  final String? image;
  final String? id;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    this.title,
    this.description,
    this.price,
    this.image,
    this.id,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
    title: json["title"],
    description: json["description"],
    price: json["price"],
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
    "description": description,
    "price": price,
    "image": image,
    "type": type,
    "_id": id,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
