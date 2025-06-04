import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _player = AudioPlayer();
  Duration? _duration, _position;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _isPlaying = false;
  int? _currentSongIndex;

  @override
  void initState() {
    super.initState();
    _player.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
    _player.positionStream.listen((duration) {
      setState(() {
        _position = duration;
      });
    });
    initAudioQuery();
  }

  initAudioQuery() async {
    var res = await [
      Permission.storage,
      Permission.mediaLibrary,
      Permission.accessMediaLocation,
    ].request();
    print(res.toString());
    if (await Permission.storage.isGranted) {
      final songs = await _audioQuery.querySongs();
      setState(() {
        _songs = songs;
      });
    } else {
      var state = await Permission.audio.request();
      if (state.isGranted) {
        initAudioQuery();
      } else {
        print("Failed to access Audio");
      }
    }
  }

  Future<void> playSong(String uri, int index) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    await _player.play();
    setState(() {
      _currentSongIndex = index;
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_songs.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_isPlaying) {
                        await _player.pause();
                        setState(() {
                          _isPlaying = false;
                        });
                      } else {
                        await _player.play();
                        setState(() {
                          _isPlaying = true;
                        });
                      }
                    },
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                  ),
                ],
              ),
            _songs.isEmpty
                ? Text("You Have No Songs")
                : Expanded(
                    child: ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (ctx, index) {
                        final song = _songs[index];
                        return ListTile(
                          title: Text(song.title),
                          onTap: () => playSong(song.uri!, index),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
