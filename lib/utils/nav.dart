
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moviezone/constants.dart';
import 'package:moviezone/models/movie_model.dart';
import 'package:moviezone/models/watch_history_model.dart';

import 'package:moviezone/log.dart';

const l = L('nav');
Future goToMovie(BuildContext context, int ottId, String movieId) {
  debugPrint("Navigating to movie: $movieId on OTT: $ottId");
  return GoRouter.of(context).push("/movie/$ottId/$movieId");
}

Future<void> goToPlayerNew({
  required BuildContext context,
  required WidgetRef ref,
  required Movie movie,
  WatchHistory? wh,
  int? sNum,
  int? eNum,
  String? subtitleUrl,
}) async {
  if (movie.isShow && (sNum == null || eNum == null)) return;
  try {
    final query = <String, String>{};
    if (movie.isShow) { query['season'] = '$sNum'; query['episode'] = '$eNum'; }
    final uri = Uri.parse('$movieZoneBackendUrl/api/stream/${Uri.encodeComponent(movie.id)}').replace(queryParameters: query);
    final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 30));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? data['error'] ?? 'No playable cached source');
    }
    final sources = (data['video_sources'] as List? ?? const []).whereType<Map>().toList();
    final primary = sources.isNotEmpty ? Map<String, dynamic>.from(sources.first) : <String, dynamic>{};
    final url = (primary['url'] ?? data['stream_url'] ?? '').toString();
    if (url.isEmpty) throw Exception('Backend returned an empty stream URL');
    final subtitleSources = (data['subtitle_sources'] as List? ?? const []).whereType<Map>().toList();
    final subtitle = subtitleSources.isNotEmpty ? (subtitleSources.first['url'] ?? '').toString() : subtitleUrl;
    final hdr = primary['headers'] is Map ? Map<String, dynamic>.from(primary['headers']) : <String, dynamic>{};
    final headersForPlayer = <String, String>{};
    hdr.forEach((k, v) { if (v != null) headersForPlayer[k] = '$v'; });
    if (data['media'] is Map) registerMovieZoneMedia(Map<String, dynamic>.from(data['media']));
    if (!context.mounted) return;
    GoRouter.of(context).push('/player', extra: (
      movie: movie, watchHistory: wh, seasonNumber: sNum, episodeNumber: eNum,
      url: url, subtitleUrl: subtitle, headers: headersForPlayer,
    ));
  } catch (e) {
    l.error('MovieZone stream failed: $e');
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback unavailable: $e')));
  }
}

