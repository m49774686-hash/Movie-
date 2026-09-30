import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:moviezone/constants.dart';
import 'package:moviezone/data/options.dart';
import 'package:moviezone/log.dart';
import 'package:moviezone/provider/AudioTrackProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});
  @override ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

const l = L('initial_screen');

class _InitialScreenState extends ConsumerState<InitialScreen> {
  String status = 'Connecting to MovieZone...';
  bool failed = false;
  @override void initState() { super.initState(); _initial(); }

  Future<void> _initial() async {
    try {
      sp = await SharedPreferences.getInstance();
      ref.read(audioTrackProvider.notifier).initial();
      SettingsOptions.initialize(sp!);
      final res = await http.get(Uri.parse('$movieZoneBackendUrl/api/bootstrap'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('Backend HTTP ${res.statusCode}');
      final data = jsonDecode(res.body);
      if (data is! Map || data['success'] != true) throw Exception('MovieZone backend is not ready');
      if (!mounted) return;
      GoRouter.of(context).go(SettingsOptions.currentScreen, extra: 0);
    } catch (e) {
      l.error('MovieZone bootstrap failed: $e');
      if (!mounted) return;
      setState(() { failed = true; status = 'MovieZone backend connection failed'; });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('MovieZone', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
      const SizedBox(height: 22),
      if (!failed) const CircularProgressIndicator(color: Colors.red) else IconButton(onPressed: () { setState(() { failed=false; status='Connecting to MovieZone...'; }); _initial(); }, icon: const Icon(Icons.refresh, color: Colors.white, size: 32)),
      const SizedBox(height: 18), Text(status, style: const TextStyle(color: Colors.white70)),
      if (failed) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Check the Render service and try again.', style: TextStyle(color: Colors.white38))),
    ])),
  );
}
