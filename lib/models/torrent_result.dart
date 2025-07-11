class TorrentResult {
  final String id;
  final String name;
  final String providerName;
  final int seed;
  final String link;
  final int size;
  final String? flags;

  TorrentResult({
    required this.id,
    required this.name,
    required this.providerName,
    required this.seed,
    required this.link,
    required this.size,
    this.flags,
  });

  factory TorrentResult.fromJson(Map<String, dynamic> json) {
    return TorrentResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      providerName: json['provider_name'] ?? '',
      seed: json['seed'] ?? 0,
      link: json['link'] ?? '',
      size: json['size'] ?? 0,
      flags: json['Flags'],
    );
  }
}
