class AboutPageModel {
  final String image;
  final String title;
  final String description;
  final String historyTitle;
  final String historyDescription;
  final String customersTitle;
  final String customersMapImage;
  final List<BlogModel> blogs;
  final List<PartnerModel> partners;

  AboutPageModel({
    required this.image,
    required this.title,
    required this.description,
    required this.historyTitle,
    required this.historyDescription,
    required this.customersTitle,
    required this.customersMapImage,
    required this.blogs,
    required this.partners,
  });

  factory AboutPageModel.fromJson(Map<String, dynamic> json) {
    return AboutPageModel(
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      historyTitle: json['history_title'] ?? '',
      historyDescription: json['history_description'] ?? '',
      customersTitle: json['customers_title'] ?? '',
      customersMapImage: json['customers_map_image'] ?? '',
      blogs: (json['blogs'] as List<dynamic>?)
          ?.map((b) => BlogModel.fromJson(b))
          .toList() ??
          [],
      partners: (json['partners'] as List<dynamic>?)
          ?.map((p) => PartnerModel.fromJson(p))
          .toList() ??
          [],
    );
  }
}

class BlogModel {
  final int id;
  final String title;
  final String imageUrl;

  BlogModel({required this.id, required this.title, required this.imageUrl});

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class PartnerModel {
  final int id;
  final String name;
  final String logoUrl;

  PartnerModel({required this.id, required this.name, required this.logoUrl});

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
    );
  }
}
