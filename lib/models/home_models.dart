import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:shared_code/models/ott.dart';

abstract class HomeModel {
  final List<HomeTray> trays;
  final DateTime lastUpdated;

  static HomeModel parse(String raw, OTT ott) {
    final trimmed = raw.trimLeft();
    if (trimmed.startsWith('{')) {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      if (json['sections'] != null || json['shelves'] != null || json['hero'] != null) {
        return switch (ott) {
          OTT.netflix => NfHomeModel.fromMovieZoneJson(json),
          OTT.pv => PvHomeModel.fromMovieZoneJson(json),
          OTT.hotstar => HotstarModel.fromMovieZoneJson(json),
          _ => NfHomeModel.fromMovieZoneJson(json),
        };
      }
    }
    switch (ott) {
      case OTT.hotstar:
        return HotstarModel.parse(raw);
      case OTT.netflix:
        return NfHomeModel.parse(raw);
      case OTT.pv:
        return PvHomeModel.parse(raw);
      default:
        throw UnimplementedError('Parser not implemented for ${ott.name}');
    }
  }

  static HomeModel fromJson(Map<String, dynamic> json, OTT ott) {
    switch (ott) {
      case OTT.hotstar:
        return HotstarModel.fromJson(json);
      case OTT.netflix:
        return NfHomeModel.fromJson(json);
      case OTT.pv:
        return PvHomeModel.fromJson(json);
      default:
        throw UnimplementedError('Parser not implemented for ${ott.name}');
    }
  }

  HomeModel({required this.trays, required this.lastUpdated});

  static List<HomeTray> traysFromJson(Map<String, dynamic> json) {
    return List<HomeTray>.from(json["trays"].map((x) => HomeTray.fromJson(x)));
  }

  static List<HomeTray> parseTrays(Document document) {
    final trayElements = document.querySelectorAll(".tray-container, .top10");
    return trayElements.map((tray) {
      bool isTop10 = tray.className == "top10";
      String title;
      if (isTop10) {
        title = tray.querySelector("span")!.text;
      } else {
        title = tray.querySelector(".tray-link")!.text;
      }
      var x = tray
          .querySelectorAll("[data-post]")
          .map((post) => post.attributes["data-post"] as String);

      return HomeTray(isTop10: isTop10, title: title, postIds: x.toList());
    }).toList();
  }

  // Instance Methods

  List<Map<String, dynamic>> get traysToJson {
    return trays.map((tray) => tray.toJson()).toList();
  }

  Map<String, dynamic> toJson() {
    return {"trays": traysToJson, "lastUpdated": lastUpdated.toIso8601String()};
  }

  // stale means data is old
  bool get isStale {
    return DateTime.now().difference(lastUpdated).inHours > 24;
  }

  bool get isFresh => !isStale;
}

List<HomeTray> _movieZoneTrays(Map<String, dynamic> json) {
  final sections = json['sections'] is Map ? Map<String, dynamic>.from(json['sections']) : <String, dynamic>{};
  final trays = <HomeTray>[];
  void add(String title, dynamic value) {
    if (value is! List) return;
    final ids = <String>[];
    for (final item in value) {
      if (item is Map && item['id'] != null) ids.add((item['id']).toString());
    }
    if (ids.isNotEmpty) trays.add(HomeTray(isTop10: false, title: title, postIds: ids));
  }
  add('Trending', sections['trending'] ?? sections['popular']);
  add('Top Rated', sections['top_rated']);
  add('Latest Releases', sections['new_releases']);
  add('Movies', sections['movies']);
  add('TV Series', sections['series']);
  add('Anime', sections['anime']);
  final shelves = json['shelves'];
  if (shelves is List) {
    for (final shelf in shelves) {
      if (shelf is Map && shelf['items'] is List) add((shelf['title'] ?? shelf['name'] ?? 'Category').toString(), shelf['items']);
    }
  }
  return trays;
}

Map<String, dynamic>? _movieZoneHero(Map<String, dynamic> json) {
  if (json['hero'] is Map) return Map<String, dynamic>.from(json['hero']);
  final heroes = json['heroes'];
  if (heroes is List && heroes.isNotEmpty && heroes.first is Map) return Map<String, dynamic>.from(heroes.first);
  return null;
}

class HomeTray {
  final bool isTop10;
  final String title;
  final List<String> postIds;

  HomeTray({required this.isTop10, required this.title, required this.postIds});

  Map<String, dynamic> toJson() {
    return {"isTop10": isTop10, "title": title, "postIds": postIds};
  }

  factory HomeTray.fromJson(Map<String, dynamic> json) {
    return HomeTray(
      isTop10: json["isTop10"],
      title: json["title"],
      postIds: List<String>.from(json["postIds"]),
    );
  }
}

class PvHomeModel extends HomeModel {
  final List<PvHomeCarousel> carouselImages;

  PvHomeModel({
    required this.carouselImages,
    required super.trays,
    required super.lastUpdated,
  });

  factory PvHomeModel.parse(String raw) {
    final document = parse(raw);

    final carousels = document.querySelectorAll(".spotlight").map((spotlight) {
      final postId = spotlight.parent!.attributes["onclick"]!.split("'")[1];
      final img = spotlight.querySelector("img.slider-img")!.attributes["src"]!;
      return PvHomeCarousel(img: img, id: postId);
    });

    log("images: len: ${carousels.length}");
    final trays = HomeModel.parseTrays(document);
    return PvHomeModel(
      carouselImages: carousels.toList(),
      trays: trays,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "carouselImages": carouselImages.map((e) => e.toJson()).toList(),
    };
  }

  factory PvHomeModel.fromMovieZoneJson(Map<String, dynamic> json) {
    final hero = _movieZoneHero(json);
    final list = <PvHomeCarousel>[];
    final heroes = json['heroes'];
    if (heroes is List) {
      for (final h in heroes) {
        if (h is Map && h['id'] != null) {
          final id = (h['media_id'] ?? h['id']).toString();
          final img = (h['image_url'] ?? h['backdrop_path'] ?? h['poster_path'] ?? '').toString();
          if (img.isNotEmpty) list.add(PvHomeCarousel(img: img, id: id));
        }
      }
    }
    if (list.isEmpty && hero != null && hero['id'] != null) {
      list.add(PvHomeCarousel(img: (hero['image_url'] ?? hero['backdrop_path'] ?? hero['poster_path'] ?? '').toString(), id: (hero['id']).toString()));
    }
    return PvHomeModel(carouselImages: list, trays: _movieZoneTrays(json), lastUpdated: DateTime.now());
  }

  factory PvHomeModel.fromJson(Map<String, dynamic> json) {
    return PvHomeModel(
      carouselImages: List<PvHomeCarousel>.from(
        json["carouselImages"].map((x) => PvHomeCarousel.fromJson(x)),
      ),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }
}

class NfHomeModel extends HomeModel {
  final String spotlightId;
  final List<String> genre;
  final Color gradientColor;

  NfHomeModel({
    required this.spotlightId,
    required this.genre,
    required this.gradientColor,
    required super.trays,
    required super.lastUpdated,
  });

  @override
  factory NfHomeModel.parse(String raw) {
    final document = parse(raw);

    // <div
    //     class="spotlight"
    //     style="
    //       background-image: url('https://imgcdn.media/poster/c/16539454.jpg');
    //       background: linear-gradient(#9f2a37 74%, #5757574f);
    //       margin-bottom: 0px;
    //       height: 83vh;
    //     "
    //   >

    final spotlight = document.querySelector(".spotlight");
    final style = spotlight?.attributes['style'] ?? '';
    final gradientColor =
        RegExp(
          r'linear-gradient\((#[0-9a-fA-F]+)',
        ).firstMatch(style)?.group(1) ??
        '#000000';
    // get color from #color string
    debugPrint("color str: $gradientColor");
    Color color = Color(
      int.parse('FF${gradientColor.substring(1)}', radix: 16),
    );
    final hsl = HSLColor.fromColor(color);
    log("current saturation: ${hsl.saturation}");
    color = hsl.withLightness(0.3).toColor();

    // color = Color.fromRGBO(61, 98, 112, 1);
    // Color.fromARGB(255, 61, 98, 112);
    final genre = spotlight!.querySelector(".genre")!.text.split("•");

    final id = spotlight.querySelector(".btn-play")!.attributes["data-post"];

    return NfHomeModel(
      spotlightId: id!,
      genre: genre,
      gradientColor: color,
      trays: HomeModel.parseTrays(document),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "spotlightId": spotlightId,
      "genre": genre,
      "gradientColor": gradientColor.toARGB32(),
    };
  }

  factory NfHomeModel.fromMovieZoneJson(Map<String, dynamic> json) {
    final sections = json['sections'] is Map ? Map<String, dynamic>.from(json['sections']) : <String, dynamic>{};
    final trays = <HomeTray>[];
    void addTray(String title, dynamic value) {
      if (value is! List) return;
      final ids = <String>[];
      for (final item in value) {
        if (item is Map) {
          final id = (item['id'] ?? item['tmdb_id'] ?? '').toString();
          if (id.isNotEmpty) ids.add(id);
        }
      }
      if (ids.isNotEmpty) trays.add(HomeTray(isTop10: false, title: title, postIds: ids));
    }
    const order = [
      ['Trending', 'trending'], ['Top Rated', 'top_rated'], ['Latest Releases', 'new_releases'],
      ['Movies', 'movies'], ['TV Series', 'series'], ['Anime', 'anime'], ['Recommended', 'recommended']
    ];
    for (final pair in order) addTray(pair[0], sections[pair[1]]);
    if (trays.isEmpty) addTray('Trending', sections['popular']);
    final rawShelves = json['shelves'];
    if (rawShelves is List) {
      for (final shelf in rawShelves) {
        if (shelf is Map) {
          final title = (shelf['title'] ?? shelf['name'] ?? '').toString();
          if (title.isNotEmpty && shelf['items'] is List) addTray(title, shelf['items']);
        }
      }
    }

    final heroes = json['heroes'] is List ? List.from(json['heroes']) : const [];
    Map<String, dynamic>? hero = json['hero'] is Map ? Map<String, dynamic>.from(json['hero']) : null;
    if (hero == null && heroes.isNotEmpty && heroes.first is Map) hero = Map<String, dynamic>.from(heroes.first);
    final heroId = (hero?['media_id'] ?? hero?['id'] ?? hero?['tmdb_id'] ?? (trays.isNotEmpty ? trays.first.postIds.first : '')).toString();
    final genres = hero?['genres'] is List ? (hero!['genres'] as List).map((e) => e.toString()).toList() : <String>[];
    return NfHomeModel(
      spotlightId: heroId,
      genre: genres,
      gradientColor: Colors.black,
      trays: trays,
      lastUpdated: DateTime.now(),
    );
  }

  factory NfHomeModel.fromJson(Map<String, dynamic> json) {
    return NfHomeModel(
      spotlightId: json["spotlightId"],
      genre: List<String>.from(json["genre"]),
      gradientColor: Color(json["gradientColor"]),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }
}

class PvHomeCarousel {
  final String img;
  final String id;

  PvHomeCarousel({required this.img, required this.id});

  Map<String, dynamic> toJson() {
    return {"img": img, "id": id};
  }

  factory PvHomeCarousel.fromJson(Map<String, dynamic> json) {
    return PvHomeCarousel(img: json["img"], id: json["id"]);
  }
}

class HotstarModel extends HomeModel {
  final List<HotstarStudio> studios;
  final String spotlightImg;
  final String titleImg;

  HotstarModel({
    required this.studios,
    required this.spotlightImg,
    required this.titleImg,
    required super.trays,
    required super.lastUpdated,
  });

  factory HotstarModel.parse(String raw) {
    final document = parse(raw);

    final studios = document.querySelectorAll(".ott-studio").map((studio) {
      final img = studio.querySelector("img");

      return HotstarStudio(
        studio: studio.attributes["data-studio"] ?? "Unknown",
        logoUrl: img?.attributes["src"] ?? "",
        name: studio.attributes["data-studio"] ?? "Unknown",
      );
    });
    final spotlight =
        document.querySelector(".spotlight-hs") ??
        document.querySelector(".spotlight");
    late String titleImg;
    late String bgImg;
    if (spotlight != null) {
      final style = spotlight.attributes['style']!;
      final backgroundImageMatch = RegExp(
        r"""background-image:\s*url\(["\']?([^"\']+)["\']?\)""",
      ).firstMatch(style);
      titleImg =
          spotlight.querySelector("img.img-title")?.attributes["src"] ?? "";
      log("bg: ${backgroundImageMatch?.group(1)}");
      bgImg = backgroundImageMatch?.group(1) ?? "";
    } else {
      titleImg = "";
      bgImg = "";
    }
    log("images: len: ${studios.length}");
    final trays = HomeModel.parseTrays(document);
    return HotstarModel(
      studios: studios.toList(),
      spotlightImg: bgImg,
      titleImg: titleImg,
      trays: trays,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "spotlightImg": spotlightImg,
      "studios": studios.map((e) => e.toJson()).toList(),
      "titleImg": titleImg,
    };
  }

  factory HotstarModel.fromMovieZoneJson(Map<String, dynamic> json) {
    final hero = _movieZoneHero(json);
    final heroImage = (hero?['image_url'] ?? hero?['backdrop_path'] ?? hero?['poster_path'] ?? '').toString();
    return HotstarModel(
      studios: const [],
      spotlightImg: heroImage,
      titleImg: heroImage,
      trays: _movieZoneTrays(json),
      lastUpdated: DateTime.now(),
    );
  }

  factory HotstarModel.fromJson(Map<String, dynamic> json) {
    return HotstarModel(
      spotlightImg: json["spotlightImg"],
      studios: List<HotstarStudio>.from(
        json["studios"].map((x) => HotstarStudio.fromJson(x)),
      ),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
      titleImg: json["titleImg"],
    );
  }
}

class HotstarStudio {
  final String name;
  final String studio;
  final String logoUrl;

  HotstarStudio({
    required this.name,
    required this.studio,
    required this.logoUrl,
  });

  Map<String, dynamic> toJson() {
    return {"name": name, "logoUrl": logoUrl, "studio": studio};
  }

  factory HotstarStudio.fromJson(Map<String, dynamic> json) {
    return HotstarStudio(
      name: json["name"],
      studio: json["studio"],
      logoUrl: json["logoUrl"],
    );
  }
}
