import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../data/api/pi_api.dart';
import '../../data/discovery.dart';
import '../../data/models/pi_device.dart';
import '../../state/connection.dart';

/// 1 연결 (docs/wireframe/Main.dc.html)
/// IP 직접 입력 + 6자리 페어링 코드 → /api/info 확인 → /api/pair → 토큰 저장 → /home
/// 같은 Wi-Fi 기기 목록(mDNS)에서 고르면 IP 칸이 채워진다.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  static const ipFieldKey = Key('connect.ip');
  static const codeFieldKey = Key('connect.code');
  static const submitKey = Key('connect.submit');
  static const rescanKey = Key('connect.rescan');

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  late final TextEditingController _ip;
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _busy = false;
  String? _error;

  static const _codeLength = 6;

  @override
  void initState() {
    super.initState();
    final conn = ref.read(connectionProvider);
    _ip = TextEditingController(text: conn.device?.address ?? '');
    _error = conn.message;
    _ip.addListener(() => setState(() {})); // 찾은 기기 카드 선택 표시
    _code.addListener(_onCodeChanged);
    _codeFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ip.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    setState(() {});
    if (_code.text.length == _codeLength) _codeFocus.unfocus();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final device = PiDevice.tryParse(_ip.text);
    if (device == null) {
      setState(() => _error = 'IP 주소를 확인해 주세요. 예: 192.168.0.10');
      return;
    }
    if (_code.text.length != _codeLength) {
      setState(() => _error = '페어링 코드 6자리를 입력해 주세요.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(connectionProvider.notifier).pair(device, _code.text);
      if (mounted) context.go('/home');
    } on PairException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _messageFor(PairException e) {
    final cause = e.cause;
    final api = cause is PiApiException ? cause : null;
    return switch (e.step) {
      PairStep.info when api != null && api.isNetwork => '기기에 연결할 수 없어요. IP 주소와 Wi-Fi를 확인해 주세요.',
      PairStep.info => '도어 레이더 기기가 아닌 것 같아요. 주소를 확인해 주세요.',
      PairStep.pair when api != null && api.isUnauthorized => '페어링 코드가 맞지 않아요. 파이에 나온 코드를 다시 확인해 주세요.',
      PairStep.pair when api != null && api.isNetwork => '페어링 중에 연결이 끊겼어요. 다시 시도해 주세요.',
      PairStep.pair => '페어링하지 못했어요. 다시 시도해 주세요.',
      PairStep.save => '이 폰에 연결 정보를 저장하지 못했어요.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 56),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 28,
                  children: [
                    const _Header(),
                    const _Title(),
                    _FoundDevices(
                      selected: _ip.text,
                      onPick: (d) => setState(() {
                        _ip.text = d.device.address;
                        _error = null;
                      }),
                    ),
                    _IpField(controller: _ip, onSubmitted: (_) => _codeFocus.requestFocus()),
                    _PairCodeField(
                      controller: _code,
                      focusNode: _codeFocus,
                      length: _codeLength,
                      onSubmitted: (_) => _submit(),
                    ),
                    const Spacer(),
                    if (_error != null) _ErrorText(_error!),
                    _ConnectButton(busy: _busy, onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
          child: const Icon(Icons.sensors, size: 20, color: AppColors.surface),
        ),
        const SizedBox(width: 10),
        const Text('Door Radar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
        const Spacer(),
        const Text('v0.1', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          '현관 기기\n연결하기',
          style: TextStyle(fontSize: 36, height: 42 / 36, fontWeight: FontWeight.w600, letterSpacing: -1.2),
        ),
        Text(
          '레이더와 같은 Wi-Fi에 연결된 라즈베리파이를 골라 주세요.',
          style: TextStyle(fontSize: 14, height: 21 / 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// 같은 Wi-Fi에서 찾은 기기 (mDNS `_doorradar._tcp`). 고르면 IP 칸을 채운다.
/// 선택된 카드는 검정 1.5px 테두리, 아니면 흰 테두리(DESIGN.md). 못 찾으면 IP 직접 입력 안내.
class _FoundDevices extends ConsumerStatefulWidget {
  const _FoundDevices({required this.selected, required this.onPick});

  /// 지금 IP 칸의 주소 (같은 주소의 카드를 선택된 것으로 그린다)
  final String selected;
  final ValueChanged<FoundDevice> onPick;

  @override
  ConsumerState<_FoundDevices> createState() => _FoundDevicesState();
}

class _FoundDevicesState extends ConsumerState<_FoundDevices> {
  /// 이 시간 동안 하나도 못 찾으면 "못 찾았어요"
  static const _searchFor = Duration(seconds: 6);

  List<FoundDevice> _found = const [];
  bool _searching = true;
  StreamSubscription<List<FoundDevice>>? _sub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final discovery = ref.read(deviceDiscoveryProvider);
    _sub ??= discovery.devices.listen((list) {
      if (mounted) setState(() => _found = list);
    });
    setState(() => _searching = true);
    _timer?.cancel();
    _timer = Timer(_searchFor, () {
      if (mounted) setState(() => _searching = false);
    });
    try {
      await discovery.start();
    } catch (_) {
      // mDNS 를 못 쓰는 망(일부 에뮬레이터·공유기)도 있다 → 못 찾음으로 보여 주고 IP 입력
      _timer?.cancel();
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면에 있는 동안 찾기를 계속한다 (autoDispose)
    ref.watch(deviceDiscoveryProvider);
    final searching = _searching && _found.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          children: [
            const Expanded(child: Text('같은 Wi-Fi에서 찾은 기기', style: _sectionLabel)),
            if (searching || _found.isNotEmpty)
              const Row(
                spacing: 6,
                children: [
                  Icon(Icons.wifi, size: 14, color: AppColors.muted),
                  Text('찾는 중', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              )
            else
              InkWell(
                key: ConnectScreen.rescanKey,
                onTap: _start,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('다시 찾기', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ),
          ],
        ),
        if (_found.isEmpty)
          _DeviceCard(
            title: searching ? '기기를 찾는 중이에요' : '기기를 찾지 못했어요',
            subtitle: searching ? '같은 Wi-Fi의 도어 레이더를 찾고 있어요' : '아래에 IP를 직접 입력해 주세요',
            selected: false,
          )
        else
          for (final d in _found)
            _DeviceCard(
              title: d.title,
              subtitle: d.device.address,
              selected: d.device.address == widget.selected.trim(),
              onTap: () => widget.onPick(d),
            ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.title, required this.subtitle, required this.selected, this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.softCard),
          side: BorderSide(color: selected ? AppColors.ink : AppColors.surface, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              spacing: 14,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.door_front_door_outlined,
                      size: 22, color: selected ? AppColors.surface : AppColors.ink),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (onTap != null)
                  // 라디오 모양 (선택: 검정 테두리 + 검정 점)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? AppColors.ink : AppColors.field, width: 1.5),
                    ),
                    child: selected
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle))
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
const _sectionLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

class _IpField extends StatelessWidget {
  const _IpField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        const Text('IP 직접 입력', style: _sectionLabel),
        SizedBox(
          height: 52,
          child: TextField(
            key: ConnectScreen.ipFieldKey,
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15, color: AppColors.ink),
            decoration: const InputDecoration(
              hintText: '예: 192.168.0.10',
              hintStyle: TextStyle(fontSize: 15, color: AppColors.subtle),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}

/// 6칸 코드 입력. 실제 입력은 보이지 않는 TextField 하나가 받고(붙여넣기·지우기 자연스럽게), 칸은 그리기만 한다.
class _PairCodeField extends StatelessWidget {
  const _PairCodeField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final active = focusNode.hasFocus && text.length < length ? text.length : -1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        const Text('페어링 코드', style: _sectionLabel),
        SizedBox(
          height: 52,
          child: Stack(
            children: [
              Row(
                spacing: 8,
                children: [
                  for (var i = 0; i < length; i++)
                    Expanded(child: _CodeBox(char: i < text.length ? text[i] : '', active: i == active)),
                ],
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    key: ConnectScreen.codeFieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(length),
                    ],
                    onSubmitted: onSubmitted,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Text(
          '라즈베리파이 서버를 켜면 화면(또는 로그)에 6자리 코드가 나와요.',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.char, required this.active});

  final String char;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? AppColors.ink : AppColors.field, width: active ? 1.5 : 1),
      ),
      child: Text(char, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // 빨강은 이상 상황 전용이라 오류 안내는 검정 글자 + 아이콘으로
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, size: 16, color: AppColors.ink),
        ),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 19 / 13, color: AppColors.ink))),
      ],
    );
  }
}

/// 큰 검정 알약 + 오른쪽 흰 원 안 ↗ 화살표
class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '연결하기',
      excludeSemantics: true,
      child: Material(
        color: AppColors.ink,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ConnectScreen.submitKey,
          onTap: busy ? null : onPressed,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 8, 0),
              child: Row(
                children: [
                  Text(
                    busy ? '연결하는 중' : '연결하기',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.surface),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                          )
                        : const Icon(Icons.north_east, size: 20, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
