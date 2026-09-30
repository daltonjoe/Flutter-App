import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'silhouette_controller.dart';

class SilhouetteRiveView extends StatefulWidget {
  const SilhouetteRiveView({super.key});

  @override
  State<SilhouetteRiveView> createState() => _SilhouetteRiveViewState();
}

class _SilhouetteRiveViewState extends State<SilhouetteRiveView> {
  StateMachineController? _smController;
  SMINumber? _progressInput;
  SMITrigger? _revealInput;
  SMITrigger? _pulseInput;

  int _lastRevealTick = 0;
  int _lastPulseTick = 0;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'OnboardingProgress',
    );
    if (controller == null) return;

    artboard.addController(controller);
    _smController = controller;

    _progressInput = controller.findInput<double>('progress') as SMINumber?;
    _revealInput = controller.findInput<bool>('reveal') as SMITrigger?;
    _pulseInput = controller.findInput<bool>('pulseOnce') as SMITrigger?;

    // Başlangıç değerini hemen uygula
    _progressInput?.value = silhouette.progress;

    silhouette.addListener(_syncFromController);
  }

  void _syncFromController() {
    _progressInput?.value = silhouette.progress;

    if (silhouette.revealTick != _lastRevealTick) {
      _lastRevealTick = silhouette.revealTick;
      _revealInput?.fire();
    }

    if (silhouette.pulseTick != _lastPulseTick) {
      _lastPulseTick = silhouette.pulseTick;
      _pulseInput?.fire();
    }
  }

  @override
  void dispose() {
    silhouette.removeListener(_syncFromController);
    _smController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/rive/silhouette.riv',
      onInit: _onRiveInit,
      fit: BoxFit.contain,
    );
  }
}