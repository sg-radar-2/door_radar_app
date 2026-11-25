import '../../app/constants.dart';

/// 연결할 파이의 주소. 입력칸의 "192.168.0.10", "10.0.2.2:8080", "http://doorradar.local:8080/" 모두 받는다.
class PiDevice {
  const PiDevice({required this.host, this.port = PiServer.port, this.name});

  final String host;
  final int port;
  final String? name; // /api/info 의 name (모르면 null)

  Uri get baseUri => Uri(scheme: 'http', host: host, port: port);

  /// 화면·저장용 짧은 주소. 기본 포트(8080)면 생략.
  String get address => port == PiServer.port ? host : '$host:$port';

  PiDevice copyWith({String? name}) => PiDevice(host: host, port: port, name: name ?? this.name);

  static final _hostPattern = RegExp(r'^[A-Za-z0-9.\-]+$');

  /// 잘못된 입력이면 null.
  static PiDevice? tryParse(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (!s.contains('://')) s = 'http://$s';
    final uri = Uri.tryParse(s);
    if (uri == null || uri.scheme != 'http' || uri.host.isEmpty) return null;
    if (uri.path.isNotEmpty && uri.path != '/') return null;
    if (!_hostPattern.hasMatch(uri.host)) return null;
    final port = uri.hasPort ? uri.port : PiServer.port;
    if (port < 1 || port > 65535) return null;
    return PiDevice(host: uri.host, port: port);
  }

  @override
  bool operator ==(Object other) => other is PiDevice && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => 'PiDevice($address)';
}
