import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/mind_orb.dart';
import '../../viewmodels/orb_provider.dart';
import '../widgets/orb_detail_dialog.dart';
import '../widgets/orb_painter.dart';
import 'create_orb_screen.dart';
import 'my_vault_screen.dart';

class PersonalOrbitScreen extends StatefulWidget {
  const PersonalOrbitScreen({super.key});

  @override
  State<PersonalOrbitScreen> createState() => _PersonalOrbitScreenState();
}

class _PersonalOrbitScreenState extends State<PersonalOrbitScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Map<String, _OrbBody> _bodies = {};
  final math.Random _random = math.Random();

  Rect? _playfield;
  Duration? _lastStamp;
  double _time = 0;
  bool? _tickerWanted;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final field = _playfield;
    if (!mounted || field == null || _bodies.isEmpty) return;
    final previous = _lastStamp;
    _lastStamp = elapsed;
    if (previous == null) return;

    var dt = (elapsed - previous).inMicroseconds / 1000000;
    if (dt <= 0) return;
    if (dt > 0.032) dt = 0.032;

    for (final body in _bodies.values) {
      var dx = body.position.dx + body.velocity.dx * dt;
      var dy = body.position.dy + body.velocity.dy * dt;
      var vx = body.velocity.dx;
      var vy = body.velocity.dy;

      final minX = field.left + body.radius;
      final maxX = field.right - body.radius;
      final minY = field.top + body.radius;
      final maxY = field.bottom - body.radius;

      if (dx < minX) {
        dx = minX;
        vx = vx.abs();
      } else if (dx > maxX) {
        dx = maxX;
        vx = -vx.abs();
      }
      if (dy < minY) {
        dy = minY;
        vy = vy.abs();
      } else if (dy > maxY) {
        dy = maxY;
        vy = -vy.abs();
      }

      body.position = Offset(dx, dy);
      body.velocity = Offset(vx, vy);
      body.phase += dt;
    }

    setState(() => _time += dt);
  }

  void _syncBodies(List<MindOrb> orbs, Rect field) {
    if (field.width < 48 || field.height < 48) return;
    _playfield = field;
    final alive = orbs.map((orb) => orb.id).toSet();
    _bodies.removeWhere((id, _) => !alive.contains(id));
    for (final orb in orbs) {
      _bodies.putIfAbsent(orb.id, () => _createBody(orb, field));
    }
  }

  _OrbBody _createBody(MindOrb orb, Rect field) {
    final radius = _radiusFor(orb, field);
    final angle = _random.nextDouble() * math.pi * 2;
    const speed = _slowestSpeed;
    return _OrbBody(
      position: _spawn(field, radius),
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      radius: radius,
      phase: _random.nextDouble() * math.pi * 2,
    );
  }

  Offset _spawn(Rect field, double radius) {
    final minX = field.left + radius;
    final maxX = field.right - radius;
    final minY = field.top + radius;
    final maxY = field.bottom - radius;
    if (maxX <= minX || maxY <= minY) return field.center;
    return Offset(
      minX + _random.nextDouble() * (maxX - minX),
      minY + _random.nextDouble() * (maxY - minY),
    );
  }

  double _radiusFor(MindOrb orb, Rect field) {
    final weight = (orb.title.length + orb.content.length).clamp(0, 120);
    final preferred = 26 + weight / 120 * 20;
    final limit = math.min(field.width, field.height) / 5;
    if (limit.isFinite && limit > 18) return math.min(preferred, limit);
    return preferred;
  }

  static const _slowestSpeed = 26.0;

  Rect _playfieldFor(Size size, EdgeInsets padding) {
    const topChrome = 96.0;
    const bottomChrome = 112.0;
    final left = math.max(12.0, padding.left + 8);
    final right = size.width - math.max(12.0, padding.right + 8);
    final top = padding.top + topChrome;
    final bottom = size.height - padding.bottom - bottomChrome;
    if (right - left < 48 || bottom - top < 48) {
      return Offset.zero & size;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _scheduleTicker(bool run) {
    if (_tickerWanted == run) return;
    _tickerWanted = run;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tickerWanted != run) return;
      if (run && !_ticker.isActive) {
        _lastStamp = null;
        _ticker.start();
      } else if (!run && _ticker.isActive) {
        _ticker.stop();
      }
    });
  }

  List<OrbPaintData> _paintData(List<MindOrb> orbs) {
    final data = <OrbPaintData>[];
    for (final orb in orbs.reversed) {
      final body = _bodies[orb.id];
      if (body == null) continue;
      data.add(
        OrbPaintData(
          emotion: orb.emotion,
          position: body.position,
          radius: body.radius,
          phase: body.phase,
        ),
      );
    }
    return data;
  }

  void _handleTap(TapUpDetails details, List<MindOrb> orbs) {
    final point = details.localPosition;
    for (final orb in orbs) {
      final body = _bodies[orb.id];
      if (body == null) continue;
      if ((point - body.position).distance <= body.radius + 12) {
        showOrbDetailDialog(context, orb);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrbProvider>();
    if (!provider.isReady) {
      return const ColoredBox(
        color: AppColors.spaceBlack,
        child: Center(
          child: Text(
            '正在打開星海…',
            style: TextStyle(color: AppColors.starlightWhite),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final padding = MediaQuery.paddingOf(context);
          _syncBodies(provider.orbs, _playfieldFor(size, padding));
          final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
          _scheduleTicker(provider.orbs.isNotEmpty && isCurrent);

          return Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: StarfieldPainter())),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details, provider.orbs),
                  child: CustomPaint(
                    painter: OrbPainter(
                      orbs: _paintData(provider.orbs),
                      time: _time,
                    ),
                  ),
                ),
              ),
              _centerMessage(provider),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '個人星系',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                _OrbitCaption(),
                              ],
                            ),
                          ),
                          TextButton(
                            key: const Key('open-vault'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MyVaultScreen(),
                                ),
                              );
                            },
                            child: const Text('記憶庫'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('open-create'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.starlightWhite,
                          foregroundColor: AppColors.spaceBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CreateOrbScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('發射心情'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _centerMessage(OrbProvider provider) {
    if (provider.errorMessage != null && provider.orbs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: provider.load, child: const Text('再試一次')),
            ],
          ),
        ),
      );
    }
    if (provider.orbs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '星海還是空的',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                '從下方把心情發射出去，它會留在這台裝置裡。',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.starlightWhite, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _OrbitCaption extends StatelessWidget {
  const _OrbitCaption();

  @override
  Widget build(BuildContext context) {
    final hasOrbs = context.watch<OrbProvider>().orbs.isNotEmpty;
    return Text(
      hasOrbs ? '點一顆心球，讀它留下的話' : '心情會留在這台裝置',
      style: TextStyle(color: AppColors.starlightWhite.withValues(alpha: 0.8)),
    );
  }
}

class _OrbBody {
  _OrbBody({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.phase,
  });

  Offset position;
  Offset velocity;
  final double radius;
  double phase;
}
