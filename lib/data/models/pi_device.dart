import '../../app/constants.dart';

/// 앱이 붙는 서버 주소. 지금은 클라우드(SPEC 9장)이고, 개발 때는 목 서버.
/// "https://rad2-cloud.onrender.com", "10.0.2.2:8080", "http://192.168.0.10:8080/" 모두 받는다.
/// 이름은 예전(파이 직접 연결) 그대로 둔다. [name] 은 페어링한 파이의 이름(`/api/info`의 name).
class PiDevice {
  const PiDevice({required this.host, this.port = PiServer.port, this.name, this.secure = false});

  final String host;
  final int port;
  final String? name;

  /// https / wss
  final bool secure;

  /// 빌드 때 정한 클라우드 주소 (`--dart-define=CLOUD_URL=...`)
  static final PiDevice cloud = tryParse(CloudServer.url) ?? const PiDevice(host: '10.0.2.2');

  Uri get baseUri => Uri(scheme: secure ? 'https' : 'http', host: host, port: port);

  /// WebSocket 주소의 scheme
  String get wsScheme => secure ? 'wss' : 'ws';

  int get _defaultPort => secure ? 443 : PiServer.port;

  /// 화면·저장용 짧은 주소. 기본 포트면 생략, https 면 앞에 붙인다.
  String get address {
    final hp = port == _defaultPort ? host : '$host:$port';
    return secure ? 'https://$hp' : hp;
  }

  PiDevice copyWith({String? name}) => PiDevice(host: host, port: port, name: name ?? this.name, secure: secure);

  static final _hostPattern = RegExp(r'^[A-Za-z0-9.\-]+$');

  /// 잘못된 입력이면 null. scheme 이 없으면 http(포트 8080), https 는 포트 443.
  static PiDevice? tryParse(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (!s.contains('://')) s = 'http://$s';
    final uri = Uri.tryParse(s);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) return null;
    if (uri.path.isNotEmpty && uri.path != '/') return null;
    if (!_hostPattern.hasMatch(uri.host)) return null;
    final secure = uri.scheme == 'https';
    final port = uri.hasPort ? uri.port : (secure ? 443 : PiServer.port);
    if (port < 1 || port > 65535) return null;
    return PiDevice(host: uri.host, port: port, secure: secure);
  }

  @override
  bool operator ==(Object other) =>
      other is PiDevice && other.host == host && other.port == port && other.secure == secure;

  @override
  int get hashCode => Object.hash(host, port, secure);

  @override
  String toString() => 'PiDevice($address)';
}
