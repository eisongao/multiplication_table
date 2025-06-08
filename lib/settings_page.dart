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

    return Scaffold(

      body:  SafeArea(
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
                        label: settings.language == 'Chinese' ? '语言设置' : 'Language Settings',
                        child: Text(
                          settings.language == 'Chinese' ? '语言设置' : 'Language Settings',
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
                            items: ['Chinese', 'English']
                                .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(
                                lang,
                                style: GoogleFonts.notoSans(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ))
                                .toList(),
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
                        label: settings.language == 'Chinese' ? '语音设置' : 'Audio Settings',
                        child: Text(
                          settings.language == 'Chinese' ? '语音设置' : 'Audio Settings',
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
                      SizedBox(height: screenHeight * 0.02),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            settings.language == 'Chinese' ? '启用语音' : 'Enable Audio',
                            style: GoogleFonts.notoSans(
                              fontSize: screenWidth * 0.045,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
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
                          title: Text(
                            settings.language == 'Chinese' ? '音量' : 'Volume',
                            style: GoogleFonts.notoSans(
                              fontSize: screenWidth * 0.045,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
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