import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moviezone/api/get_home.dart';
import 'package:moviezone/db/db.dart';
import 'package:moviezone/models/home_models.dart';
import 'package:shared_code/models/ott.dart';

import 'package:moviezone/log.dart';

const l = L('home_abstract');
abstract class Home extends StatefulWidget {
  final int tab;
  const Home({required this.tab, super.key});
}

abstract class HomeState<T extends HomeModel, W extends Home> extends State<W> {
  T? data;
  abstract final OTT ott;
  String get currentTabName {
    return switch (widget.tab) {
      0 => "home",
      1 => "tvshows",
      2 => "movies",
      _ => "home",
    };
  }

  String? get studioName => null;

  @override
  void initState() {
    l.debug("init state for tab: $currentTabName, studio: $studioName");
    loadDataFromLocal();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadDataFromLocal() async {
    // MovieZone is the source of truth; refresh on app/session entry so the UI
    // always gets the current published catalog and image registry.
    await loadDataFromOnline();
  }

  Future<void> loadDataFromOnline() async {
    final raw = await getHome(id: widget.tab, ott: ott, studio: studioName);
    final onlineData = HomeModel.parse(raw, ott) as T;
    setState(() {
      data = onlineData;
    });
    DB.home.add(currentTabName, onlineData, ott);
  }

  void goToMovie(String id) {
    GoRouter.of(context).push("/movie/${ott.id}/$id");
  }
}
