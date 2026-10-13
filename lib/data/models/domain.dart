import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';

class Domain {
  final String id;
  final String name;
  final String url;
  final String status;
  final DateTime? createdAt;

  const Domain({required this.id, required this.name, required this.url, required this.status, this.createdAt});

  bool get isActive => status == 'ACTIVE';

  factory Domain.fromJson(Json json) => Domain(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
    status: json['status'] as String? ?? 'ACTIVE',
    createdAt: parseDate(json['createdAt']),
  );
}
