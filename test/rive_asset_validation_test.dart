import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads silhouette Rive asset and reports animations', () async {
    final file = await RiveFile.asset('assets/animations/silhouette.riv');
    final artboard = file.mainArtboard;

    for (final animation in artboard.animations.whereType<LinearAnimation>()) {
      debugPrint(
        'Rive animation: ${animation.name}, '
        'duration=${animation.duration}, fps=${animation.fps}',
      );
    }

    expect(artboard.animations.map((animation) => animation.name),
        containsAll(<String>['Progress', 'Breath', 'Reveal']));
  });
}
