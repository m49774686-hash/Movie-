import 'constants.dart';

enum OTT {
  // none("", name: "Netflix"),
  // pv("pv", name: "Prime Video"),
  // dh("dh", name: "Disney + Hotstar"),
  // lionGate("lg", name: "Lionsgate"),
  // hbo("hbo", name: "HBO");

  netflix(
    "",
    0,
    name: "Netflix",
    vImgHeight: 233,
    vImgWidth: 166,
    hImgHeight: 374,
    hImgWidth: 665,
  ),
  pv(
    "pv",
    1,
    name: "Prime Video",
    // vImgHeight: 0,
    // vImgWidth: 0,
    // hImgHeight: 0,
    // hImgWidth: 0,
    // todo: ,temporary using netflix aspect ratio
    vImgHeight: 233,
    vImgWidth: 166,
    hImgHeight: 374,
    hImgWidth: 665,
  ),
  hotstar(
    "hs",
    2,
    name: "Disney + Hotstar",
    // vImgHeight: 0,
    // vImgWidth: 0,
    // hImgHeight: 0,
    // hImgWidth: 0,
    // todo: ,temporary using netflix aspect ratio
    vImgHeight: 233,
    vImgWidth: 166,
    hImgHeight: 233,
    hImgWidth: 166,
  ),
  lionGate(
    "lg",
    3,
    name: "Lionsgate",
    vImgHeight: 0,
    vImgWidth: 0,
    hImgHeight: 0,
    hImgWidth: 0,
  ),
  hbo(
    "hbo",
    4,
    name: "HBO",
    vImgHeight: 0,
    vImgWidth: 0,
    hImgHeight: 0,
    hImgWidth: 0,
  );

  final String value;
  final int id;
  final String name;
  final double vImgHeight;
  final double vImgWidth;
  final double hImgHeight;
  final double hImgWidth;
  final double vAspectRatio;
  final double hAspectRatio;

  static final list = [netflix, pv, hotstar, lionGate, hbo];
  static final Map<String, String> movieZonePosterRegistry = {};
  static final Map<String, String> movieZoneBackdropRegistry = {};

  const OTT(
    this.value,
    this.id, {
    this.name = '',
    required this.vImgHeight,
    required this.vImgWidth,
    required this.hImgHeight,
    required this.hImgWidth,
    // required this.vImgRatio = hImgHeight / hImgWidth,
  }) : vAspectRatio = vImgWidth / vImgHeight,
       hAspectRatio = hImgWidth / hImgHeight;

  get url => value.isEmpty ? '' : '$value/';

  double get aspectRatio => isDesk ? hAspectRatio : vAspectRatio;

  get cookie => value.isEmpty ? 'nf' : value;

  String getImg(
    String id, {
    bool largeImg = false,
    bool forceHorizontal = false,
    bool forceVertical = false,
  }) {
    if (this == OTT.netflix) {
      late String direction;

      if (forceHorizontal) {
        direction = "341";
      } else if (forceVertical) {
        direction = "v";
      } else {
        direction = isDesk ? "341" : "v";
      }

      return "";
    }
    if (this == OTT.hotstar) {
      final direction = (largeImg || forceHorizontal) ? "h" : "v";
      final size = largeImg ? "700" : "166";
      if (largeImg || forceHorizontal) {}
      return "";
    }
    return "";
  }

  String getBackdrop(String id) {
    final registered = movieZoneBackdropRegistry[id];
    if (registered != null && registered.isNotEmpty) return registered;
    final poster = movieZonePosterRegistry[id];
    if (poster != null && poster.isNotEmpty) return poster;
    return getImg(id, largeImg: true, forceHorizontal: true);
  }

  factory OTT.fromValue(String value) {
    return OTT.values.firstWhere((element) => element.value == value);
  }

  factory OTT.fromId(int id) {
    // return OTT.values.firstWhere((element) => element.id == id);
    if (id < 0 || id >= OTT.values.length) {
      throw ArgumentError("Invalid OTT id: $id");
    }
    return OTT.values[id];
  }
}
