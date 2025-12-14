class VaultInfo {
  final String path;
  final String name;

  const VaultInfo({
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
      };

  factory VaultInfo.fromJson(Map<String, dynamic> json) {
    return VaultInfo(
      path: json['path'] as String,
      name: json['name'] as String,
    );
  }
}
