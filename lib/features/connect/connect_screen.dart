import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../data/api/pi_api.dart';
import '../../state/connection.dart';

/// 1 연결 (docs/wireframe/Main.dc.html)
/// 파이에 나온 6자리 페어링 코드 → 클라우드 /api/pair → 토큰으로 /api/info → 토큰 저장 → /home (SPEC 9.1)
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  static const codeFieldKey = Key('connect.code');
  static const submitKey = Key('connect.submit');

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _busy = false;
  String? _error;

  static const _codeLength = 6;

  @override
  void initState() {
    super.initState();
    _error = ref.read(connectionProvider).message;
    _code.addListener(_onCodeChanged);
    _codeFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
      await ref.read(connectionProvider.notifier).pair(_code.text);
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
      PairStep.pair when api != null && api.isNetwork => '서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.',
      PairStep.pair when api != null && api.isUnauthorized =>
        '페어링 코드가 맞지 않아요. 기기가 인터넷에 연결돼 있는지, 파이에 나온 코드가 맞는지 확인해 주세요.',
      PairStep.pair => '페어링하지 못했어요. 다시 시도해 주세요.',
      PairStep.info when api != null && api.isNetwork => '연결 중에 인터넷이 끊겼어요. 다시 시도해 주세요.',
      PairStep.info => '기기 정보를 받지 못했어요. 다시 시도해 주세요.',
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
          '라즈베리파이에 나온 6자리 코드로 이 폰을 현관 기기와 연결해요.',
          style: TextStyle(fontSize: 14, height: 21 / 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

const _sectionLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

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
          '라즈베리파이 서버를 켜면 화면(또는 로그)에 6자리 코드가 나와요. 기기가 인터넷에 연결돼 있어야 해요.',
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
