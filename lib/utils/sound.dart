import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Sound {
  final AudioPlayer _player;
  final DeviceFileSource? _source;

  Sound._(this._player, this._source);

  static Future<Sound> loop(String? url) async {
    final player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.loop);
    final source = await Sound.cache(url);

    if (source == null) throw Exception('Failed to load sound source for loop.');
    
    return Sound._(player, source);
  }

  Future<void> dispose() async {
    await _player.dispose();
    log('Sound disposed');
  }

  Future<void> play() async {
    if (_source == null) {
      log('No sound source available to play');
      return;
    }
    await _player.play(_source);
    log('Sound playing from URL');
  }

  Future<void> stop() async {
    await _player.stop();
    log('Sound stopped');
  }

  Future<void> pause() async {
    await _player.pause();
    log('Sound paused');
  }

  Future<void> resume() async {
    if (_source == null) {
      log('No sound source available to play');
      return;
    }
    await _player.resume();
    log('Sound resumed');
  }

  static Future<DeviceFileSource?> cache(String? url) async {
    try {
      if (url == null || url.isEmpty) {
        log('Sound URL is null or empty');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final hash = md5.convert(utf8.encode(url)).toString();
      final file = '${dir.path}/$hash';

      final f = File(file);
      if (await f.exists()) {
        return DeviceFileSource(f.path);
      } else {
        log('Downloading sound from URL: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final f = await File(file).writeAsBytes(response.bodyBytes);
          return DeviceFileSource(f.path);
        } else {
          log('Failed to download sound: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('Error in cacheAndPlay: $e');
    }
    return null;
  }

  static Future<void> single(String? url) async {
    if (url == null || url.isEmpty) {
      log('No sound URL provided!');
      return;
    }

    final P = AudioPlayer();
    P.setReleaseMode(ReleaseMode.release);
    DeviceFileSource? source = await Sound.cache(url);

    if (source == null) {
      log('No sound source available to play');
      return;
    }
    await P.play(source);
    log('Sound playing');

    P.onPlayerComplete.listen((event) async {
      await P.dispose();
      log('Sound disposed after completion');
    });
  }
}
