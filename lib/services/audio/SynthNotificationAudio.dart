import 'dart:math';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

enum SynthSoundType {
  ringtone,
  message,
  system,
}

class SynthNotificationAudio {
  static final SynthNotificationAudio _instance =
      SynthNotificationAudio._internal();
  factory SynthNotificationAudio() => _instance;
  SynthNotificationAudio._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  static const int _sampleRate = 44100;

  /* ================= AUDIO SESSION ================= */

  Future<void> _configureSession(SynthSoundType type) async {
    final session = await AudioSession.instance;

    switch (type) {
      case SynthSoundType.ringtone:
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionMode: AVAudioSessionMode.voiceChat,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.defaultToSpeaker,
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.notificationRingtone,
              contentType: AndroidAudioContentType.sonification,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransient,
          ),
        );
        break;

      case SynthSoundType.message:
        await session.configure(
          const AudioSessionConfiguration(
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.notification,
              contentType: AndroidAudioContentType.sonification,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientMayDuck,
          ),
        );
        break;

      case SynthSoundType.system:
        await session.configure(
          const AudioSessionConfiguration(
            androidAudioAttributes: AndroidAudioAttributes(
              usage: AndroidAudioUsage.assistanceSonification,
              contentType: AndroidAudioContentType.sonification,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientMayDuck,
          ),
        );
        break;
    }
  }

  /* ================= PUBLIC API ================= */

  Future<void> play(SynthSoundType type) async {
    if (_isPlaying) return;
    _isPlaying = true;

    await _configureSession(type);

    final wav = _generateSound(type);
    await _player.setAudioSource(_MemorySource(wav));
    await _player.setLoopMode(
        type == SynthSoundType.ringtone ? LoopMode.one : LoopMode.off);
    await _player.play();
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    await _player.stop();
    _isPlaying = false;
  }

  /* ================= SYNTH ENGINE ================= */

  Uint8List _generateSound(SynthSoundType type) {
    switch (type) {
      case SynthSoundType.ringtone:
        return _ringtone();
      case SynthSoundType.message:
        return _message();
      case SynthSoundType.system:
        return _system();
    }
  }

  Uint8List _ringtone() {
    final bells = [523, 659, 784, 1047, 784, 659]
        .map((f) => _osc(f.toDouble(), 0.4, 0.08))
        .toList();

    final pad = _osc(261.5, 1.6, 0.03);
    final sparkle = _osc(2093, 0.3, 0.04);

    return _toWav(_mix([...bells, pad, sparkle]));
  }

  Uint8List _message() {
    final ping1 = _osc(880, 0.12, 0.08);
    final ping2 = _osc(1320, 0.10, 0.06);
    return _toWav(_mix([ping1, ping2]));
  }

  Uint8List _system() {
    final tone = _osc(440, 0.08, 0.05);
    return _toWav(tone);
  }

  /* ================= DSP ================= */

  Int16List _osc(double freq, double duration, double volume) {
    final samples = (duration * _sampleRate).toInt();
    final pcm = Int16List(samples);

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final env = _adsr(t, 0.02, 0.05, duration - 0.12, 0.05, 0.6);
      pcm[i] =
          (sin(2 * pi * freq * t) * env * volume * 32767).toInt();
    }
    return pcm;
  }

  double _adsr(double t, double a, double d, double s, double r, double sl) {
    if (t < a) return t / a;
    t -= a;
    if (t < d) return 1 - (1 - sl) * (t / d);
    t -= d;
    if (t < s) return sl;
    t -= s;
    if (t < r) return sl * (1 - t / r);
    return 0;
  }

  Int16List _mix(List<Int16List> tracks) {
    final len = tracks.map((e) => e.length).reduce(max);
    final out = Int16List(len);
    for (final t in tracks) {
      for (int i = 0; i < t.length; i++) {
        out[i] = (out[i] + t[i]).clamp(-32768, 32767);
      }
    }
    return out;
  }

  Uint8List _toWav(Int16List pcm) {
    final bd = ByteData(44 + pcm.lengthInBytes);
    bd
      ..setUint32(0, 0x52494646, Endian.big)
      ..setUint32(4, 36 + pcm.lengthInBytes, Endian.little)
      ..setUint32(8, 0x57415645, Endian.big)
      ..setUint32(12, 0x666d7420, Endian.big)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, _sampleRate, Endian.little)
      ..setUint32(28, _sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461, Endian.big)
      ..setUint32(40, pcm.lengthInBytes, Endian.little);

    bd.buffer
        .asUint8List()
        .setRange(44, bd.lengthInBytes, pcm.buffer.asUint8List());

    return bd.buffer.asUint8List();
  }
}

/* ================= MEMORY SOURCE ================= */

class _MemorySource extends StreamAudioSource {
  final Uint8List bytes;
  _MemorySource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: bytes.length,
      offset: 0,
      stream: Stream.value(bytes),
      contentType: 'audio/wav',
    );
  }
}
