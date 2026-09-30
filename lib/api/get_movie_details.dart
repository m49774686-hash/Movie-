import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:moviezone/constants.dart';
import 'package:moviezone/models/movie_model.dart';
import 'package:shared_code/models/movie_model.dart' as shared;
import 'package:shared_code/models/ott.dart';

Future<Movie> getMovie(String id, OTT ott) async {
  final uri = Uri.parse('$movieZoneBackendUrl/api/media/${Uri.encodeComponent(id)}');
  final res = await http.get(uri, headers: {'Accept': 'application/json'});
  if (res.statusCode != 200) throw Exception('MovieZone media HTTP ${res.statusCode}');
  final root = jsonDecode(res.body) as Map<String, dynamic>;
  final media = Map<String, dynamic>.from((root['media'] as Map?) ?? root);
  Map<String, dynamic> relatedRoot = const {};
  try {
    final rr = await http.get(Uri.parse('$movieZoneBackendUrl/api/media/${Uri.encodeComponent(id)}/related'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (rr.statusCode == 200) relatedRoot = Map<String, dynamic>.from(jsonDecode(rr.body) as Map);
  } catch (_) {}
  registerMovieZoneMedia(media);
  final mediaId = (media['id'] ?? id).toString();
  final pp = media['poster_path'];
  final bb = media['backdrop_path'];
  if (pp != null) shared.OTT.movieZonePosterRegistry[mediaId] = (pp).toString();
  if (bb != null) shared.OTT.movieZoneBackdropRegistry[mediaId] = (bb).toString();
  final realId = (media['id'] ?? id).toString();
  final isMovie = (media['catalog_type'] ?? media['media_type'] ?? 'movie').toString() == 'movie';

  final seasons = <int, shared.Season>{};
  final rawSeasons = media['seasons'];
  if (rawSeasons is List) {
    for (final raw in rawSeasons) {
      if (raw is! Map) continue;
      final sn = int.tryParse('${raw['season_number']}') ?? 0;
      if (sn <= 0) continue;
      final eps = <int, shared.Episode>{};
      final rawEpisodes = raw['episodes'] is List ? raw['episodes'] as List : const [];
      for (final e in rawEpisodes) {
        if (e is! Map) continue;
        final en = int.tryParse('${e['episode_number']}') ?? 0;
        if (en <= 0) continue;
        final epId = '$realId-s${sn}e${en}';
        final still = e['still_path'];
        if (still != null) {
          shared.OTT.movieZonePosterRegistry[epId] = (still).toString();
          movieZonePosterRegistry[epId] = (still).toString();
        }
        eps[en] = shared.Episode(
          id: epId,
          t: (e['name'] ?? 'Episode $en').toString(),
          s: 'S$sn', ep: 'E$en',
          time: '${e['runtime'] ?? 0}',
        );
      }
      seasons[sn] = shared.Season(s: sn, ep: eps.length, id: '$realId-s$sn', episodes: eps);
    }
  }

  final langs = <shared.Language>[];
  for (final x in (media['languages'] as List? ?? const [])) {
    langs.add(shared.Language(l: (x).toString(), s: (x).toString()));
  }
  final suggestions = <shared.Suggestion>[];
  final related = relatedRoot['items'] is List ? relatedRoot['items'] as List : const [];
  for (final x in related) {
    if (x is Map && x['id'] != null) {
      final relatedMap = Map<String, dynamic>.from(x);
      registerMovieZoneMedia(relatedMap);
      final rid = (relatedMap['id']).toString();
      if (relatedMap['poster_path'] != null) shared.OTT.movieZonePosterRegistry[rid] = (relatedMap['poster_path']).toString();
      if (relatedMap['backdrop_path'] != null) shared.OTT.movieZoneBackdropRegistry[rid] = (relatedMap['backdrop_path']).toString();
      suggestions.add(shared.Suggestion(id: rid));
    }
  }
  final genres = (media['genres'] as List? ?? const []).map((e) => e.toString()).toList();
  final title = (media['title'] ?? 'Unknown').toString();
  final overview = (media['overview'] ?? '').toString();
  final year = (media['year'] ?? (media['release_date'] ?? '').toString().split('-').first).toString();
  final rating = NumberFormatHelper.number(media['rating']);
  final type = isMovie ? 'm' : 's';

  log('MovieZone media loaded: $title [$realId]');
  return Movie(
    id: realId, status: (media['content_status'] ?? 'published').toString(), dLang: media['original_language']?.toString(),
    title: title, year: year, ua: '', match: '', runtime: null, hdsd: null, type: type,
    creator: '', director: '', writer: '', shortCast: null, cast: '', genre: genres,
    genreStr: genres.join(', '), thisMovieIs: null, mDesc: overview, mReason: '', desc: overview,
    oin: media['imdb_id']?.toString(), resume: '', lang: langs, suggest: suggestions,
    error: null, ott: ott, lastUpdated: DateTime.now(), seasons: seasons,
  );
}

class NumberFormatHelper {
  static String number(dynamic value) => (double.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(1);
}
