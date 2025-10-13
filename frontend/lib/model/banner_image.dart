class BannerImage {
  final int id;
  final String image;
  final int order;

  BannerImage({
    required this.id,
    required this.image,
    required this.order,
  });

  // Factory constructor to create a BannerImage object from JSON
  factory BannerImage.fromJson(Map<String, dynamic> json) {
    return BannerImage(
      id: json['id'],
      image: json['image'],
      order: json['order'],
    );
  }
}
