import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_configs.dart';
import 'utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppConfigs>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isChinese = settings.language == 'Chinese';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: SingleChildScrollView(
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 400),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Semantics(
                      label: isChinese ? '语言设置' : 'Language Settings',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isChinese ? '语言设置' : 'Language Settings',
                          style: GoogleFonts.notoSans(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: DropdownButton<String>(
                          value: settings.language,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                              value: 'Chinese',
                              child: Text(
                                isChinese ? '中文' : 'Chinese',
                                style: GoogleFonts.notoSans(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'English',
                              child: Text(
                                isChinese ? '英文' : 'English',
                                style: GoogleFonts.notoSans(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settings.setLanguage(value);
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Semantics(
                      label: isChinese ? '语音设置' : 'Audio Settings',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isChinese ? '语音设置' : 'Audio Settings',
                          style: GoogleFonts.notoSans(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isChinese ? '启用语音' : 'Enable Audio',
                            style: GoogleFonts.notoSans(
                              fontSize: screenWidth * 0.045,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        value: settings.isAudioEnabled,
                        onChanged: (value) => settings.setAudioEnabled(value),
                        activeColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isChinese ? '音量' : 'Volume',
                            style: GoogleFonts.notoSans(
                              fontSize: screenWidth * 0.045,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        subtitle: Slider(
                          value: settings.audioVolume,
                          onChanged: (value) => settings.setAudioVolume(value),
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: settings.audioVolume.toStringAsFixed(1),
                          activeColor: Colors.blue[700],
                          inactiveColor: Colors.blue[200],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Semantics(
                      label: isChinese ? '重置记录' : 'Reset Records',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isChinese ? '重置记录' : 'Reset Records',
                          style: GoogleFonts.notoSans(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isChinese ? '重置所有记录' : 'Reset All Records',
                            style: GoogleFonts.notoSans(
                              fontSize: screenWidth * 0.045,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        trailing: Icon(Icons.delete, color: Colors.red[700]),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                isChinese ? '确认重置' : 'Confirm Reset',
                                style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                isChinese
                                    ? '您确定要重置所有记录吗？此操作无法撤销。'
                                    : 'Are you sure you want to reset all records? This action cannot be undone.',
                                style: GoogleFonts.notoSans(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(isChinese ? '取消' : 'Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    isChinese ? '确认' : 'Confirm',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await settings.resetRecords();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isChinese ? '记录已重置' : 'Records reset successfully',
                                  ),
                                  backgroundColor: Colors.blue[700],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}