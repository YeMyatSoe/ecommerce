class Brand {
  final String name;

  Brand({required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      name: json['name'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
