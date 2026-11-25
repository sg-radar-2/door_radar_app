import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../app/constants.dart';
import 'models/pi_device.dart';

/// 같은 Wi-Fi 에서 찾은 파이 (`_doorradar._tcp`)
class FoundDevice {
  const FoundDevice({required this.name, this.host, required this.ip, required this.port});

  /// mDNS 서비스 이름 ("doorradar")
  final String name;

  /// "rad2pi.local" 같은 호스트 이름 (없을 수 있음)
  final String? host;
  final String ip;
  final int port;

  /// 카드 제목: 호스트 이름이 있으면 그것, 없으면 서비스 이름
  String get title {
    final h = host;
    if (h == null || h.isEmpty) return name;
    return h.endsWith('.') ? h.substring(0, h.length - 1) : h;
  }

  /// IP 로 연결한다 (Android 는 .local 이름 풀이가 기기마다 달라서)
  PiDevice get device => PiDevice(host: ip, port: port, name: name);

  @override
  bool operator ==(Object other) => other is FoundDevice && other.ip == ip && other.port == port;

  @override
  int get hashCode => Object.hash(ip, port);
}

/// mDNS 기기 찾기. 시작하면 찾은 목록이 바뀔 때마다 [devices] 로 흘려보낸다.
abstract interface class DeviceDiscovery {
  Stream<List<FoundDevice>> get devices;
  Future<void> start();
  Future<void> stop();
}

final deviceDiscoveryProvider = Provider.autoDispose<DeviceDiscovery>((ref) {
  final d = NsdDiscovery();
  ref.onDispose(d.stop);
  return d;
});

/// nsd 패키지 구현. 서비스를 찾으면 IPv4 주소까지 풀어서 준다.
class NsdDiscovery implements DeviceDiscovery {
  final _out = StreamController<List<FoundDevice>>.broadcast();
  nsd.Discovery? _discovery;

  @override
  Stream<List<FoundDevice>> get devices => _out.stream;

  @override
  Future<void> start() async {
    if (_discovery != null) return;
    final d = await nsd.startDiscovery(PiServer.mdnsType, ipLookupType: nsd.IpLookupType.v4);
    _discovery = d;
    d.addListener(() => _emit(d.services));
    _emit(d.services);
  }

  void _emit(List<nsd.Service> services) {
    if (_out.isClosed) return;
    _out.add(toFoundDevices(services));
  }

  @override
  Future<void> stop() async {
    final d = _discovery;
    _discovery = null;
    if (d != null) {
      try {
        await nsd.stopDiscovery(d);
      } catch (e) {
        debugPrint('mDNS 멈추기 실패: $e');
      }
    }
    await _out.close();
  }
}

/// nsd 서비스 → 카드 목록. IPv4 가 풀린 것만, 같은 IP·포트는 하나로.
List<FoundDevice> toFoundDevices(List<nsd.Service> services) {
  final out = <FoundDevice>{};
  for (final s in services) {
    final ip = s.addresses?.where((a) => a.type == InternetAddressType.IPv4).firstOrNull?.address;
    if (ip == null) continue;
    out.add(FoundDevice(name: s.name ?? 'doorradar', host: s.host, ip: ip, port: s.port ?? PiServer.port));
  }
  return out.toList()..sort((a, b) => a.title.compareTo(b.title));
}
