import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists JSON drafts on device. Swap for an encrypted store (drift +
/// SQLCipher) before shipping PAN / bank details.
class DraftStore {
  const DraftStore();

  static const _itrKey = 'taxos.itr.draft.v1';
  static const _gstKey = 'taxos.gst.draft.v1';

  Future<Map<String, Object?>?> loadItr() => _load(_itrKey);
  Future<void> saveItr(Map<String, Object?> json) => _save(_itrKey, json);
  Future<Map<String, Object?>?> loadGst() => _load(_gstKey);
  Future<void> saveGst(Map<String, Object?> json) => _save(_gstKey, json);

  Future<Map<String, Object?>?> _load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, Object?>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(String key, Map<String, Object?> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(json));
    } catch (_) {
      // Persistence is best-effort; the in-memory draft is the source of truth.
    }
  }
}
