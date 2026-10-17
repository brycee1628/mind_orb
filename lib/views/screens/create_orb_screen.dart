import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../models/mind_orb.dart';
import '../../viewmodels/orb_provider.dart';

class CreateOrbScreen extends StatefulWidget {
  const CreateOrbScreen({super.key});

  @override
  State<CreateOrbScreen> createState() => _CreateOrbScreenState();
}

class _CreateOrbScreenState extends State<CreateOrbScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  late final AnimationController _launch;

  EmotionType _emotion = EmotionType.joy;
  bool _releaseToCosmos = false;
  bool _submitting = false;
  bool _launching = false;

  bool get _busy => _submitting || _launching;

  @override
  void initState() {
    super.initState();
    _launch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _launch.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      _showMessage('請寫下這顆心球的標題');
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<OrbProvider>().createOrb(
        title: title,
        content: _content.text,
        emotion: _emotion,
        isPublic: _releaseToCosmos,
      );
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _submitting = false;
        _launching = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _launch.forward(from: 0).whenComplete(() {
          if (mounted) Navigator.of(context).pop();
        });
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('沒能把心球留下來：$error');
      setState(() {
        _submitting = false;
        _launching = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cloudEnabled = context.watch<OrbProvider>().cloudEnabled;
    final color = _emotion.color;

    return PopScope(
      canPop: !_busy,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.spaceBlack,
            appBar: AppBar(title: const Text('心情發射台')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const Text('這份心情比較像'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final emotion in EmotionType.values)
                      Expanded(
                        child: _EmotionChoice(
                          emotion: emotion,
                          selected: emotion == _emotion,
                          onTap: _busy
                              ? null
                              : () => setState(() => _emotion = emotion),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_emotion.body} · ${_emotion.texture}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color),
                ),
                const SizedBox(height: 22),
                TextField(
                  key: const Key('orb-title'),
                  controller: _title,
                  enabled: !_busy,
                  maxLength: AppConstants.maxTitleLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '標題'),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('orb-content'),
                  controller: _content,
                  enabled: !_busy,
                  maxLength: AppConstants.maxContentLength,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: '內文',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _releaseToCosmos,
                  activeThumbColor: color,
                  activeTrackColor: color.withValues(alpha: 0.35),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _releaseToCosmos = value),
                  title: const Text('放流至大眾星海'),
                  subtitle: Text(
                    cloudEnabled
                        ? '會同步寫入雲端，其他人看得到這顆心球。'
                        : '先記在這台裝置。雲端接通後，已標記的心球會自動放流。',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('submit-orb'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: _emotion.onColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: Text(_submitting && !_launching ? '留下中…' : '發射'),
                ),
              ],
            ),
          ),
          if (_launching)
            Positioned.fill(
              child: _LaunchFlight(animation: _launch, color: color),
            ),
        ],
      ),
    );
  }
}

class _EmotionChoice extends StatelessWidget {
  const _EmotionChoice({
    required this.emotion,
    required this.selected,
    required this.onTap,
  });

  final EmotionType emotion;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = emotion.color;
    return Semantics(
      button: true,
      selected: selected,
      label: emotion.label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 52 : 40,
              height: selected ? 52 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.85),
                      blurRadius: 16,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emotion.label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white
                    : AppColors.starlightWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchFlight extends StatelessWidget {
  const _LaunchFlight({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInCubic.transform(animation.value);
        return IgnorePointer(
          child: ColoredBox(
            color: AppColors.spaceBlack.withValues(alpha: 0.28 * t),
            child: Align(
              alignment: Alignment(0, 0.72 - 1.7 * t),
              child: Opacity(
                opacity: (1 - t * 0.85).clamp(0, 1),
                child: Transform.scale(
                  scale: 1.15 - 0.85 * t,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          color,
                          color.withValues(alpha: 0.15),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.75),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
