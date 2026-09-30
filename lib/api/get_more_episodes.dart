import 'package:shared_code/models/movie_model.dart' as shared;
import 'package:shared_code/models/ott.dart';

Future<List<shared.Episode>> getMoreEpisodes({
  required String s,
  required String series,
  required OTT ott,
  int? page,
}) async {
  // MovieZone backend returns complete episode metadata from /api/media/:id.
  // Pagination is intentionally not performed against the old MovieZone APIs.
  return <shared.Episode>[];
}
