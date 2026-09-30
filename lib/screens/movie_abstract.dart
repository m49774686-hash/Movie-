import 'dart:async';
import 'dart:developer';

import 'package:moviezone/log.dart';
import 'package:moviezone/models/watch_list_model.dart';
import 'package:moviezone/models/watch_history_model.dart';
import 'package:moviezone/utils/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moviezone/api/get_more_episodes.dart';
import 'package:moviezone/api/get_movie_details.dart';
import 'package:moviezone/constants.dart';
import 'package:moviezone/db/db.dart';
import 'package:moviezone/downloader/download_db.dart';
import 'package:moviezone/models/movie_model.dart';
import 'package:moviezone/widgets/windows_titlebar_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:shared_code/models/ott.dart';
import 'package:skeletonizer/skeletonizer.dart';

const l = L("moivie_abstract");

abstract class MovieScreen extends ConsumerStatefulWidget {
  const MovieScreen(this.id, {super.key});
  final String id;
}

abstract class MovieScreenState extends ConsumerState<MovieScreen>
    with TickerProviderStateMixin {
  abstract OTT ott;
  abstract bool extraTabForCast;

  bool inWatchlist = false;
  Movie? movie;
  Map<String, MiniDownloadItem> downloads = {};
  TabController? tabController;
  int seasonNumber = -1;
  bool episodesLoading = false;
  WatchHistory? watchHistory;
  List<WatchHistory> seasonWatchHistory = [];
  late AnimationController watchlistAnimationController;

  @override
  void initState() {
    super.initState();
    watchlistAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    loadData();
  }

  @override
  void dispose() {
    watchlistAnimationController.dispose();
    tabController?.dispose();
    super.dispose();
  }

  String get videoId {
    if (movie!.isMovie) return movie!.id;
    return movie!.getSeasonEpisodes(seasonNumber).entries.first.value.id;
  }

  Future<void> loadDownloads() async {
    final downloadList = await DownloadDb.instance.getMovieOrSeries(widget.id);
    final temp = Map.fromEntries(downloadList.map((e) => MapEntry(e.id, e)));
    setState(() {
      downloads = temp;
    });
  }

  Future<void> loadData() async {
    var localMovie = await DB.movie.get(widget.id, ott.id);

    loadDownloads();

    if (localMovie != null) {
      final List<dynamic> results = await Future.wait([
        getWatchHistory(localMovie),
        DB.watchList.isIn(localMovie.id, ott.id),
      ]);
      int tabLen = 0;
      if (localMovie.isShow) tabLen++;
      if (localMovie.suggest.isNotEmpty) tabLen++;
      if (extraTabForCast) tabLen++;
      tabController = TabController(length: tabLen, vsync: this);

      setState(() {
        inWatchlist = results[1] as bool;
        movie = localMovie;
        seasonNumber =
            localMovie.latestSeasonNumber; // Use latest season number
      });
      l.debug("movie got from db: ${localMovie.id}");
    }

    if (localMovie == null || localMovie.isStale) {
      loadDataFromOnline();
    }
  }

  Future<void> loadDataFromOnline() async {
    var onlineMovie = await getMovie(widget.id, ott);
    l.debug("movie got from online: ${onlineMovie.id}");
    if (tabController == null) {
      int tabLen = 0;
      if (onlineMovie.isShow) tabLen++;
      if (onlineMovie.suggest.isNotEmpty) tabLen++;
      if (extraTabForCast) tabLen++;

      tabController = TabController(length: tabLen, vsync: this);
      setState(() {
        movie = onlineMovie;
        seasonNumber =
            onlineMovie.latestSeasonNumber; // Use latest season number
      });
    } else {
      setState(() {
        movie = onlineMovie;
      });
    }

    DB.movie.add(widget.id, ott.id, onlineMovie);
  }

  Future<void> getWatchHistory(Movie? m, [int? seasonNum]) async {
    if (m == null) return;
    if (m.isMovie) {
      final result = await DB.watchHistory.get(
        id: m.id,
        ottId: ott.id,
        videoId: m.id,
      );
      watchHistory = result;
    } else {
      final result = await DB.watchHistory.getShowHistory(
        ottId: ott.id,
        seasonNumber: seasonNum ?? m.latestSeasonNumber, // Use season number
        seriesId: m.id,
      );
      l.debug("season watch history len: ${result.length}");
      seasonWatchHistory = result;
    }
  }

  void handleSeasonChange(int newSeasonNumber) async {
    l.debug("Changing season to $newSeasonNumber");

    setState(() {
      seasonNumber = newSeasonNumber;
    });
    final watchHistoryFuture = getWatchHistory(movie, newSeasonNumber);
    log("watch history: ${watchHistory?.id}, ${watchHistory?.current}");

    final season = movie!.getSeason(newSeasonNumber);
    if (season.episodes == null) {
      log("episodes are loading");
      final moreEpisodes = await getMoreEpisodes(
        s: season.id,
        series: widget.id,
        ott: movie!.ott,
      );
      await watchHistoryFuture;

      setState(() {
        // Update the season with episodes
        movie!.seasons[newSeasonNumber] = season.copyWithEpisodes(moreEpisodes);
      });
      DB.movie.add(widget.id, ott.id, movie!);
    } else {
      log("episodes already loaded");
    }
  }

  void shareDeepLinkUrl() {
    log("Sharing movie: ${movie!.id}");
    SharePlus.instance.share(
      ShareParams(
        uri: Uri.parse("https://moviezone.com/movie/${ott.id}/${movie!.id}"),
      ),
    );
  }

  void loadMoreEpisodes() async {
    if (episodesLoading) return;
    log("surya abstract class: loadMoreEpisodes()");

    log("loading more episodes");
    episodesLoading = true;
    final season = movie!.getSeason(seasonNumber);
    final currentEpisodes = movie!.getSeasonEpisodes(seasonNumber);
    final pageNum = currentEpisodes.length ~/ 10 + 1; // page number

    final moreEpisodes = await getMoreEpisodes(
      s: season.id,
      series: widget.id,
      page: pageNum,
      ott: movie!.ott,
    );

    setState(() {
      // Create new episodes map with existing and new episodes
      final currentEpisodesMap = season.episodes ?? <int, Episode>{};
      for (final episode in moreEpisodes) {
        currentEpisodesMap[episode.epNum] = episode;
      }

      movie!.seasons[seasonNumber] = Season(
        s: season.s,
        ep: season.ep,
        id: season.id,
        episodes: currentEpisodesMap,
      );
      episodesLoading = false;
      DB.movie.add(widget.id, ott.id, movie!);
    });
  }

  void playMovieOrEpisode() {
    if (movie!.isShow) {
      playEpisode(movie!.getFirstEpisdoe(seasonNumber).epNum);
    } else {
      playMovie();
    }
  }

  void playMovie() async {
    l.info('MovieZone play requested: ${movie!.id}');
    goToPlayer(movie: movie!, subtitleUrl: null);
  }

  void playEpisode(int episodeNumber) async {
    final episode = movie!.getEpisode(seasonNumber, episodeNumber);
    l.info('MovieZone episode play requested: ${movie!.id} S$seasonNumber E$episodeNumber');
    goToPlayer(movie: movie!, eNum: episodeNumber, subtitleUrl: null);
  }

  void goToPlayer({
    required Movie movie,
    WatchHistory? wh,
    int? sNum,
    int? eNum,
    String? subtitleUrl,
  }) {
    goToPlayerNew(
      context: context,
      ref: ref,
      movie: movie,
      wh: wh,
      sNum: sNum ?? seasonNumber,
      eNum: eNum,
      subtitleUrl: subtitleUrl,
    );
  }

  void downloadMovieOrSeason() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloads are not available from the MovieZone backend yet.')),
    );
  }

  void downloadEpisode(int episodeNumber, int seasonNum) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Episode downloads are not available yet (S$seasonNum E$episodeNumber).')),
    );
  }

}

