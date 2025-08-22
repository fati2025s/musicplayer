import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../service/audio.dart';

class PlayerScreen extends StatefulWidget {
  final AudioService audioService;

  const PlayerScreen({Key? key, required this.audioService}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioService _audio;
  bool isShuffle = false;

  @override
  void initState() {
    super.initState();
    _audio = widget.audioService;
  }

  String formatTime(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: _audio.currentIndexStream, // گوش دادن به تغییر آهنگ
      builder: (context, snapshot) {
        final currentSong = _audio.currentSong;

        if (currentSong == null) {
          return const Scaffold(
            body: Center(child: Text("هیچ آهنگی در حال پخش نیست")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(currentSong.name)),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 100),
              Text(
                currentSong.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(currentSong.artist, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              StreamBuilder<Duration>(
                stream: _audio.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: _audio.durationStream,
                    builder: (context, snap) {
                      final duration = snap.data ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
                            onChanged: (val) {
                              _audio.seekTo(Duration(seconds: val.toInt()));
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatTime(position)),
                                Text(formatTime(duration)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // کنترل پخش
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 36,
                    onPressed: () => _audio.previous(),
                  ),

                  StreamBuilder<PlayerState>(
                    stream: _audio.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      final icon = playing ? Icons.pause : Icons.play_arrow;
                      final action = playing ? _audio.pause : _audio.play;
                      return IconButton(
                        icon: Icon(icon),
                        iconSize: 48,
                        onPressed: action,
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 36,
                    onPressed: () => _audio.next(),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              IconButton(
                icon: Icon(
                  isShuffle ? Icons.shuffle_on : Icons.shuffle,
                  color: isShuffle ? Colors.green : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    isShuffle = !isShuffle;
                    _audio.setShuffle(isShuffle);
                  });
                },
              ),
              const Text("Shuffle"),
            ],
          ),
        );
      },
    );
  }
}
