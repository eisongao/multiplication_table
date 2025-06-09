import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'app_configs.dart';
import 'utils.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _player = AudioPlayer();
  double? _usableWidth, _usableHeight;

  @override
  void initState() {
    super.initState();
    // Set initial volume based on AppSettings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AppConfigs>(context, listen: false);
      _player.setVolume(settings.audioVolume);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSound(int i, int j, AppConfigs settings, BuildContext context) async {
    if (!settings.isAudioEnabled) return; // Skip if audio is disabled
    try {
      // Determine language-specific audio path
      final langPrefix = settings.language == 'Chinese' ? 'zh' : 'en';
      final assetPath = 'audio/$langPrefix/${i}x${j}.mp3';
      await _player.setVolume(settings.audioVolume); // Update volume
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      logger.e('Failed to play audio for $i × $j: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'Chinese'
                  ? '无法播放音频: $i × $j'
                  : 'Cannot play audio: $i × $j',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppConfigs>(context); // Access AppSettings
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth * 0.02;
          _usableWidth = constraints.maxWidth - padding * 2;
          _usableHeight = constraints.maxHeight - padding * 2;
          final cellWidth = _usableWidth! / 10; // 9 cells + 1 header
          final cellHeight = _usableHeight! / 10; // 9 cells + 1 header

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[50]!.withOpacity(0.1),
                  Colors.grey[200]!.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: SizedBox(
                  width: _usableWidth,
                  height: _usableHeight,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: Map.fromIterables(
                      List.generate(10, (i) => i),
                      List.generate(10, (_) => FixedColumnWidth(cellWidth)),
                    ),
                    children: [
                      // Header row
                      TableRow(
                        children: [
                          _buildHeaderCell('', cellWidth, cellHeight),
                          for (int j = 1; j <= 9; j++)
                            _buildHeaderCell(
                              '$j',
                              cellWidth,
                              cellHeight,
                              color: j.isEven ? Colors.orange : Colors.green,
                            ),
                        ],
                      ),
                      // Data rows
                      for (int i = 1; i <= 9; i++)
                        TableRow(
                          children: [
                            _buildHeaderCell(
                              '$i',
                              cellWidth,
                              cellHeight,
                              color: i.isEven ? Colors.orange : Colors.green,
                            ),
                            for (int j = 1; j <= 9; j++)
                              _buildDataCell(
                                i,
                                j,
                                settings.language == 'Chinese' ? '$i×$j=${i * j}' : '$i × $j = ${i * j}',
                                cellWidth,
                                cellHeight,
                                settings,
                                context,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(
      String text, double width, double height,
      {Color? color}) {
    return Container(
      width: width,
      height: height,
      color: color ?? Colors.transparent,
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: min(width, height) * 0.3,
          fontWeight: FontWeight.w700,
          color: color != null ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataCell(
      int i, int j, String text, double width, double height, AppConfigs settings, BuildContext context) {
    return GestureDetector(
      onTap: () => _playSound(i, j, settings, context),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            settings.language == 'Chinese' ? '$i×$j=${i * j}' : '$i×$j=${i * j}', // Unified format
            style: GoogleFonts.notoSans(
              fontSize: min(width, height) * (settings.language == 'Chinese' ? 0.25 : 0.22),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}