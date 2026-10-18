import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/api_service.dart';
import 'providers/player_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/playlist_provider.dart';
import 'core/router.dart';

late MyAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Audio Handler chạy nền cho Người 1
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musicapp.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const MusicAppRoot());
}

class MusicAppRoot extends StatelessWidget {
  const MusicAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final playerProv = PlayerProvider(_audioHandler);
            // Hook tự động gọi API POST /api/history khi nghe > 30s theo hợp đồng mục 8
            playerProv.onTrackListenedOver30s = (songId) {
              apiService.logHistory(songId).catchError((_) {});
            };
            return playerProv;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: MaterialApp.router(
        title: 'Music App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Colors.greenAccent,
            surface: Color(0xFF1E1E1E),
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}