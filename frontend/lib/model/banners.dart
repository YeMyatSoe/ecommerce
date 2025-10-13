import 'banner_image.dart'; // Import the BannerImage class

class Banner {
  final int id;
  final String title;
  final String description;
  final String? link;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BannerImage> images;

  Banner({
    required this.id,
    required this.title,
    required this.description,
    this.link,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      link: json['link'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      images: (json['images'] as List<dynamic>)
          .map((item) => BannerImage.fromJson(item))
          .toList(),
    );
  }
}
