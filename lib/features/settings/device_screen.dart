import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../data/api/pi_api.dart';
import '../../data/models/models.dart';
import '../../state/connection.dart';
import '../../state/live.dart';
import '../../state/settings.dart';

/// 와이어프레임 Device.dc.html
/// 검은 상태 카드(이름·주소·프레임·지연·온도), 2×2 타일(레이더·카메라·판정 모델·저장 공간), 레이더 다시 연결, 다른 기기 연결.
class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  static const reconnectKey = Key('device.reconnect');
  static const otherKey = Key('device.other');

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  bool _reconnecting = false;

  /// `/api/status` 에 pending_photos 가 없을 때(mock) `/api/photos/pending` 으로 센다
  int? _pendingFallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    await ref.read(deviceStatusProvider.notifier).refresh();
    final api = ref.read(piApiProvider);
    if (api == null || ref.read(deviceStatusProvider)?.pendingPhotos != null) return;
    try {
      final ids = await api.pendingPhotos();
      if (mounted) setState(() => _pendingFallback = ids.length);
    } catch (_) {}
  }

  /// 레이더 다시 연결 (SPEC 8장 `POST /api/radar/reconnect`) → 잠시 뒤 상태 다시 읽기
  Future<void> _reconnectRadar() async {
    final api = ref.read(piApiProvider);
    if (api == null) return;
    setState(() => _reconnecting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      try {
        await api.radarReconnect();
      } on PiApiException catch (e) {
        if (e.statusCode != 404) rethrow; // 아직 이 API 가 없는 파이면 상태만 다시 읽는다
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      await ref.read(deviceStatusProvider.notifier).refresh();
      final radar = ref.read(deviceStatusProvider)?.radar;
      messenger.showSnackBar(SnackBar(
        content: Text(radar == 'ok' ? '레이더가 연결돼 있어요' : '레이더가 아직 연결되지 않았어요 (${radarWord(radar)})'),
      ));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('기기에 연결할 수 없어요')));
    } finally {
      if (mounted) setState(() => _reconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final status = ref.watch(deviceStatusProvider);
    final settings = ref.watch(piSettingsProvider);
    final linked = conn.status == LinkStatus.connected;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          backgroundColor: AppColors.surface,
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 24, AppSpace.screenH, 24),
            children: [
              Row(
                children: [
                  Tooltip(
                    message: '뒤로',
                    child: Material(
                      color: AppColors.surface,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.canPop() ? context.pop() : context.go('/settings'),
                        child: const SizedBox(
                            width: 48, height: 48, child: Icon(Icons.arrow_back, size: 22, color: AppColors.ink)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('기기 상태', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: AppSpace.gap),
              _StatusCard(conn: conn, status: status),
              const SizedBox(height: AppSpace.gap),
              _Tiles(
                status: linked ? status : null,
                info: conn.info,
                cameraOn: settings?.cameraOn,
                deviceKeepDays: settings?.deviceKeepDays ?? 30,
                pending: status?.pendingPhotos ?? _pendingFallback,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  key: DeviceScreen.reconnectKey,
                  onPressed: linked && !_reconnecting ? _reconnectRadar : null,
                  child: Text(_reconnecting ? '다시 연결하는 중…' : '레이더 다시 연결'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: DeviceScreen.otherKey,
                  onPressed: () => context.go('/connect'),
                  child: const Text('다른 기기 연결'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 레이더 상태 한 단어 (타일)
String radarWord(String? radar) => switch (radar) {
      'ok' => '연결됨',
      'connecting' => '연결 중',
      'stale' => '응답 없음',
      'disconnected' => '끊김',
      null => '-',
      _ => '확인 필요',
    };

/// `camera_backend`: helper(picamera2) · rpicam · fake · none
String? cameraBackendWord(String? backend) => switch (backend) {
      'helper' => 'picamera2',
      'fake' => '가짜 카메라',
      'none' || null => null,
      _ => backend,
    };

/// 켜진 시간: "3일 4시간째 켜짐", "2시간 5분째 켜짐", "12분째 켜짐"
String uptimeText(int seconds) {
  final d = seconds ~/ 86400;
  final h = seconds % 86400 ~/ 3600;
  final m = seconds % 3600 ~/ 60;
  if (d > 0) return '$d일 $h시간째 켜짐';
  if (h > 0) return '$h시간 $m분째 켜짐';
  return '$m분째 켜짐';
}

/// GB 숫자: 1.2 / 29
String gb(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.conn, required this.status});

  final PiConnection conn;
  final DeviceStatus? status;

  @override
  Widget build(BuildContext context) {
    final linked = conn.status == LinkStatus.connected;
    final s = linked ? status : null;
    final healthy = s != null && !s.piOffline && s.radarOk && s.cameraOk && s.judgeError == null;
    final headline = !linked
        ? conn.status.label
        : s == null
            ? '상태 확인 중'
            : s.piOffline
                ? piOfflineLabel
                : healthy
                    ? '정상 작동 중'
                    : '확인이 필요해요';
    final name = conn.info?.host ?? conn.info?.name ?? conn.device?.name ?? '-';
    final sub = [
      if (conn.info != null) '서버 ${conn.info!.version}',
      if (s != null && s.piOffline) piOfflineHint else '클라우드 연결',
    ].join(' · ');

    Widget fact(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onDarkMuted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.surface)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 라임은 실시간·정상 작동 표시에만 (DESIGN.md). 아니면 회색
                  color: healthy ? AppColors.point : AppColors.onDarkMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(headline,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.surface)),
              ),
              if (s?.uptimeS != null)
                Text(uptimeText(s!.uptimeS!), style: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(name,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: AppColors.surface)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.onDarkMuted)),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.mapArc),
          const SizedBox(height: 14),
          Row(
            children: [
              fact('프레임', s == null ? '-' : '${s.frameRate.round()} fps'),
              const SizedBox(width: 8),
              fact('지연', s?.latencyS == null ? '-' : '${s!.latencyS}초'),
              const SizedBox(width: 8),
              fact('CPU 온도', s?.cpuTempC == null ? '-' : '${s!.cpuTempC!.round()}°C'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.status,
    required this.info,
    required this.cameraOn,
    required this.deviceKeepDays,
    required this.pending,
  });

  final DeviceStatus? status;
  final DeviceInfo? info;
  final bool? cameraOn;
  final int deviceKeepDays;
  final int? pending;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final camera = s == null
        ? '-'
        : s.camera == 'none'
            ? '없음'
            : cameraOn == false
                ? '꺼짐'
                : switch (s.camera) {
                    'ok' => '대기 중',
                    'error' => '오류',
                    _ => '확인 필요',
                  };

    final radar = _Tile(
      icon: Icons.sensors,
      label: '레이더',
      value: radarWord(s?.radar),
      sub: s?.radarError ?? s?.radarHost ?? 'RETINA-4SN',
    );
    final cam = _Tile(icon: Icons.photo_camera_outlined, label: '카메라', value: camera, sub: cameraBackendWord(s?.cameraBackend));
    final model = _Tile(
      icon: Icons.account_tree_outlined,
      label: '판정 모델',
      value: info?.modelVersion == null ? (info == null ? '-' : 'model') : 'model ${info!.modelVersion}',
      sub: s?.judgeError ?? info?.model ?? '-',
    );

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: radar),
            const SizedBox(width: 10),
            Expanded(child: cam),
          ]),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: model),
            const SizedBox(width: 10),
            Expanded(child: _StorageTile(storage: s?.storage, deviceKeepDays: deviceKeepDays, pending: pending)),
          ]),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value, this.sub});

  final IconData icon;
  final String label;
  final String value;

  /// 없으면 줄을 비운다 (mock 처럼 정보가 없을 때)
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  const _StorageTile({required this.storage, required this.deviceKeepDays, required this.pending});

  final StorageInfo? storage;
  final int deviceKeepDays;
  final int? pending;

  @override
  Widget build(BuildContext context) {
    final st = storage;
    final ratio = st == null || st.totalGb <= 0 ? 0.0 : (st.usedGb / st.totalGb).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.softCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('저장 공간', style: TextStyle(fontSize: 12, color: AppColors.muted))),
              if (st != null) Text('사진 ${st.photos}장', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: st == null ? '-' : gb(st.usedGb),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.ink),
              children: [
                if (st != null)
                  TextSpan(
                    text: ' / ${gb(st.totalGb)} GB',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.background,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$deviceKeepDays일 임시 보관\n폰 전송 대기 ${pending ?? '-'}장',
            style: const TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
