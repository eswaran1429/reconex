typedef Json = Map<String, dynamic>;

/// Shape returned by every paginated endpoint: `{ items, pagination }`.
class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Paginated.fromJson(Json json, T Function(Json) fromItem) {
    final pagination = json['pagination'] as Json;
    return Paginated(
      items: (json['items'] as List<dynamic>).map((e) => fromItem(e as Json)).toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }
}
