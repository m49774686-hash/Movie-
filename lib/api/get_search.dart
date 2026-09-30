import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:moviezone/constants.dart';
import 'package:moviezone/models/search_results_model.dart';
import 'package:shared_code/models/ott.dart';

Future<SearchResults> getSearchResults(String query, {OTT ott = OTT.netflix}) async {
  final uri = Uri.parse('$movieZoneBackendUrl/api/search/v2').replace(queryParameters: {'q': query, 'limit': '40'});
  final res = await http.get(uri, headers: {'Accept': 'application/json'});
  if (res.statusCode != 200) throw Exception('MovieZone search HTTP ${res.statusCode}');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  for (final item in (data['items'] as List? ?? const [])) {
    if (item is Map<String, dynamic>) {
      registerMovieZoneMedia(item);
      final id = (item['id'] ?? '').toString();
      if (id.isNotEmpty) {
        final p = item['poster_path']; final b = item['backdrop_path'];
        if (p != null) OTT.movieZonePosterRegistry[id] = (p).toString();
        if (b != null) OTT.movieZoneBackdropRegistry[id] = (b).toString();
      }
    }
  }
  log('MovieZone search: $query -> ${(data['items'] as List? ?? const []).length}');
  return SearchResults.fromJson({
    'searchResult': (data['items'] as List? ?? const []).map((e) => {
      'id': e['id'], 't': e['title'], 'y': e['year'] ?? '', 'r': e['rating']?.toString() ?? '',
    }).toList(),
    'error': null,
  }, ott, query);
}
