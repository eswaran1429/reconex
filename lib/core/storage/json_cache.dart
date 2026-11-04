import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:reconex/core/network/paginated.dart';

/// On-disk JSON cache so screens paint stored data instantly, then refresh from
/// the network. Best-effort: every call swallows errors and degrades to no cache.
class JsonCache {
  Directory? _dir;

  Future<File?> _file(String key) async {
    try {
      _dir ??= await getApplicationSupportDirectory();
      final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      return File('${_dir!.path}/cache_$safe.json');
    } catch (_) {
      return null;
    }
  }

  Future<Json?> readMap(String key) async {
    try {
      final file = await _file(key);
      if (file == null || !file.existsSync()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Json.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object value) async {
    try {
      final file = await _file(key);
      await file?.writeAsString(jsonEncode(value));
    } catch (_) {
      // Caching is optional; ignore write failures.
    }
  }
}
