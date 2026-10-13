const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime? parseDate(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime? d) => d == null ? '—' : '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';

String formatDateTime(DateTime? d) => d == null ? '—' : '${formatDate(d)}, ${_two(d.hour)}:${_two(d.minute)}';

String timeAgo(DateTime? d) {
  if (d == null) return '—';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(d);
}

String formatDuration(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  final d = end.difference(start);
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  return '${d.inMinutes}m ${d.inSeconds % 60}s';
}

const Set<String> _acronyms = {'dns', 'ssl', 'tls', 'http', 'https', 'ip', 'tcp', 'url', 'cdn', 'api'};

/// `port_opened` -> `Port opened`, `ssl_expired` -> `SSL expired`.
String humanize(String value) {
  final words = value.replaceAll('_', ' ').toLowerCase().split(' ');
  final text = words.map((w) => _acronyms.contains(w) ? w.toUpperCase() : w).join(' ');
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
