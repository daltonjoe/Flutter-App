import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class SilhouetteController extends RiveAnimationController<RuntimeArtboard> {
  LinearAnimationInstance? _progress, _breath, _reveal;
  double _targetProgress = 0, _currentProgress = 0;
  bool _revealing = false;
  double _revealT = 0;

  double _dur(LinearAnimationInstance i) =>
      i.animation.duration / i.animation.fps;

  @override
  bool init(RuntimeArtboard artboard) {
    LinearAnimationInstance? make(String name) {
      for (final a in artboard.animations) {
        if (a is LinearAnimation && a.name == name) {
          return LinearAnimationInstance(a);
        }
      }
      return null;
    }

    _progress = make('Progress');
    _breath = make('Breath');
    _reveal = make('Reveal');
    isActive = true;
    return true;
  }

  void setProgress(double v) => _targetProgress = v.clamp(0.0, 1.0);

  void playReveal() {
    _revealing = true;
    _revealT = 0;
  }

  @override
  void apply(RuntimeArtboard artboard, double elapsedSeconds) {
    _currentProgress += (_targetProgress - _currentProgress) *
        (elapsedSeconds * 4).clamp(0.0, 1.0);
    if (_progress != null) {
      _progress!.time = _currentProgress * _dur(_progress!);
      _progress!.animation
          .apply(_progress!.time, coreContext: artboard, mix: 1);
    }

    if (_breath != null) {
      _breath!.advance(elapsedSeconds);
      _breath!.animation
          .apply(_breath!.time, coreContext: artboard, mix: 1);
    }

    if (_reveal != null && _revealing) {
      _revealT += elapsedSeconds;
      final d = _dur(_reveal!);
      if (_revealT >= d) _revealing = false;
      _reveal!.time = _revealT.clamp(0.0, d);
      _reveal!.animation.apply(_reveal!.time, coreContext: artboard, mix: 1);
    }
  }

  @override
  void dispose() {
    _progress?.dispose();
    _breath?.dispose();
    _reveal?.dispose();
    super.dispose();
  }
}

class SilhouetteRiveView extends StatefulWidget {
  final int step;
  final int totalSteps;
  final bool reveal;

  const SilhouetteRiveView({
    super.key,
    required this.step,
    this.totalSteps = 6,
    this.reveal = false,
  });

  @override
  State<SilhouetteRiveView> createState() => _SilhouetteRiveViewState();
}

class _SilhouetteRiveViewState extends State<SilhouetteRiveView> {
  final _c = SilhouetteController();
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _c.setProgress(widget.step / widget.totalSteps);
  }

  @override
  void didUpdateWidget(covariant SilhouetteRiveView old) {
    super.didUpdateWidget(old);
    _c.setProgress(widget.step / widget.totalSteps);
    if (widget.reveal && !_revealed) {
      _revealed = true;
      _c.playReveal();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/animations/silhouette.riv',
      artboard: 'Silhouette',
      controllers: [_c],
      fit: BoxFit.cover,
      onInit: (_) => debugPrint('Silhouette riv yüklendi'),
    );
  }
}