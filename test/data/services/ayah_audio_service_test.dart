import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';

void main() {
  test('serialized operations do not overlap', () async {
    final queue = AudioOperationQueue();
    var concurrent = 0;
    var maxConcurrent = 0;
    final events = <String>[];

    Future<void> enqueue(String id, Duration delay) {
      return queue.run(() async {
        concurrent += 1;
        maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
        events.add('start:$id');
        await Future<void>.delayed(delay);
        events.add('end:$id');
        concurrent -= 1;
      });
    }

    final first = enqueue('1', const Duration(milliseconds: 80));
    final second = enqueue('2', const Duration(milliseconds: 20));
    final third = enqueue('3', const Duration(milliseconds: 5));
    await Future.wait(<Future<void>>[first, second, third]);

    expect(maxConcurrent, 1);
    expect(
      events,
      <String>[
        'start:1',
        'end:1',
        'start:2',
        'end:2',
        'start:3',
        'end:3',
      ],
    );
  });

  test('updateSource without stop policy does not invoke stop path', () async {
    final fake = _FakeSerializedAudioService();

    await fake.updateSource('new-reciter', stopPlayback: false);
    expect(fake.source, 'new-reciter');
    expect(fake.stopCalls, 0);

    await fake.updateSource('other-reciter', stopPlayback: true);
    expect(fake.source, 'other-reciter');
    expect(fake.stopCalls, 1);
  });
}

class _FakeSerializedAudioService {
  final AudioOperationQueue _queue = AudioOperationQueue();
  String source = 'default';
  int stopCalls = 0;

  Future<void> updateSource(
    String nextSource, {
    bool stopPlayback = true,
  }) {
    return _queue.run(() async {
      source = nextSource;
      if (stopPlayback) {
        await _stopInternal();
      }
    });
  }

  Future<void> _stopInternal() async {
    stopCalls += 1;
  }
}
