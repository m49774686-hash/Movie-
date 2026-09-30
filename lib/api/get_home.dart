import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:moviezone/constants.dart';
import 'package:shared_code/models/ott.dart';

Future<String> getHome({int id = 0, required OTT ott, String? studio}) async {
  final uri = Uri.parse('$movieZoneBackendUrl/api/v2/home').replace(queryParameters: {
    'limit': '20',
  });
  try {
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('MovieZone home HTTP ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _registerAll(data);
    return jsonEncode(data);
  } catch (e, st) {
    log('MovieZone getHome failed: $e', stackTrace: st);
    rethrow;
  }
}

void _registerAll(Map<String, dynamic> data) {
  final seen = <String>{};
  void add(dynamic x) {
    if (x is Map<String, dynamic>) {
      registerMovieZoneMedia(x);
      final id = (x['id'] ?? '').toString();
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        final p = x['poster_path'];
        final b = x['backdrop_path'];
        if (p != null) movieZonePosterRegistry[id] = (p).toString();
        if (b != null) movieZoneBackdropRegistry[id] = (b).toString();
        OTT.movieZonePosterRegistry[id] = (p ?? '').toString();
        if (b != null) OTT.movieZoneBackdropRegistry[id] = (b).toString();
      }
    }
  }
  add(data['hero']);
  for (final h in (data['heroes'] as List? ?? const [])) add(h);
  final sections = data['sections'];
  if (sections is Map) {
    for (final value in sections.values) {
      if (value is List) for (final item in value) add(item);
    }
  }
  final shelves = data['shelves'];
  if (shelves is List) {
    for (final shelf in shelves) {
      if (shelf is Map && shelf['items'] is List) {
        for (final item in shelf['items']) add(item);
      }
    }
  }
}
