import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences? sp;
// const int kSmMovieItemWidth;
// const int kSmMovieItemHeight;

const Color kDeskBackgroundColor = Color.fromARGB(255, 20, 20, 20);

const double kLgScreenWidth = 750; // > 750
const double kMdLgScreenWidth = 900; // 750 < 900
const double kXLgScreenWidth = 1100; // > 900
const double kFullScreenBillBoard = 600;

const double kDLgMovieItemHeight = 164; //265 x 149
const double kDLgMovieItemWidth = 291.92;

const double kDMdMovieItemHeight = 120;
const double kDMdMovieItemWidth = 213; // 189 x 106.5

const double kDSmMovieItemHeight = 103;
const double kDSmMovieItemWidth = 183.34;

const double kMbMovieItemHeight = 170;
const double kMbMovieItemWidth = 120;

const movieZoneBackendUrl = String.fromEnvironment(
  'MOVIEZONE_BACKEND_URL',
  defaultValue: 'https://moviezone-backend-1r89.onrender.com',
);

// MovieZone uses backend-provided stream URLs; no legacy source constants are kept here.

final Map<String, String> movieZonePosterRegistry = {};
final Map<String, String> movieZoneBackdropRegistry = {};

void registerMovieZoneMedia(Map<String, dynamic> item) {
  final id = (item['id'] ?? item['tmdb_id'] ?? item['imdb_id'] ?? '').toString().trim();
  if (id.isEmpty) return;
  final poster = item['poster_path'] ?? item['poster_url'];
  final backdrop = item['backdrop_path'] ?? item['backdrop_url'];
  if (poster != null && (poster).toString().isNotEmpty) movieZonePosterRegistry[id] = (poster).toString();
  if (backdrop != null && (backdrop).toString().isNotEmpty) movieZoneBackdropRegistry[id] = (backdrop).toString();
}

final bool isDesk = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
const Dot = "•";
int parseIdFromUrl(String url) {
  // Use regular expression to find the part containing digits
  final match = RegExp(r'\d+').firstMatch(url);

  // Check if a match was found
  if (match != null) {
    // Return the captured group (the digits)
    return int.parse(match.group(0)!);
  } else {
    // No ID found, return an empty string
    return 1;
  }
}

extension ColorExtensions on Color {
  Color inc(BuildContext context, [double amount = 0.1]) {
    if (Theme.of(context).colorScheme.brightness == Brightness.dark) {
      return lighten(amount);
    }
    return darken(amount);
  }

  Color revInc(BuildContext context, [double amount = 0.1]) {
    if (Theme.of(context).colorScheme.brightness == Brightness.dark) {
      return lighten(amount);
    }
    return lighten(amount);
  }

  Color dec(BuildContext context, [double amount = 0.1]) {
    if (Theme.of(context).colorScheme.brightness == Brightness.dark) {
      return darken(amount);
    }
    return lighten(amount);
  }

  Color revDec(BuildContext context, [double amount = 0.1]) {
    if (Theme.of(context).colorScheme.brightness == Brightness.dark) {
      return darken(amount);
    }
    return darken(amount);
  }

  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }
}
