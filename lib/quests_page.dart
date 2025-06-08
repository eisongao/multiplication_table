import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_configs.dart';
import 'utils.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<QuestsPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  int _currentLevel = 1;
  int _correctAnswersInLevel = 0;
  int _totalQuestionsInLevel = 0;
  int _first = 1;
  int _second = 1;
  String _feedback = '';
  bool _isLoading = false;
  bool _isCorrect = false;
  bool _hasMasterBadge = false;
  final List<String> _askedQuestionsInLevel = [];
  final List<Map<String, dynamic>> _history = [];
  late AnimationController _feedbackAnimationController;
  late AnimationController _shakeAnimationController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProgress(); // Load saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AppConfigs>(context, listen: false);
      _audioPlayer.setVolume(settings.audioVolume);
    });
    _generateQuestion();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLevel = prefs.getInt('currentLevel') ?? 1;
      _correctAnswersInLevel = prefs.getInt('correctAnswersInLevel') ?? 0;
      _totalQuestionsInLevel = prefs.getInt('totalQuestionsInLevel') ?? 0;
      _hasMasterBadge = prefs.getBool('hasMasterBadge') ?? false;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', _currentLevel);
    await prefs.setInt('correctAnswersInLevel', _correctAnswersInLevel);
    await prefs.setInt('totalQuestionsInLevel', _totalQuestionsInLevel);
    await prefs.setBool('hasMasterBadge', _hasMasterBadge);
  }

  int _getQuestionsPerLevel(int level) {
    if (level <= 4) return 5;
    if (level <= 8) return 7;
    return 10;
  }

  void _generateQuestion() {
    setState(() {
      final availableQuestions = <String>[];
      for (int i = 1; i <= 9; i++) {
        for (int j = 1; j <= i; j++) {
          final key = '${i}x$j';
          if (!_askedQuestionsInLevel.contains(key)) {
            availableQuestions.add(key);
          }
        }
      }
      if (availableQuestions.isEmpty) {
        _askedQuestionsInLevel.clear();
        for (int i = 1; i <= 9; i++) {
          for (int j = 1; j <= 9; j++) {
            availableQuestions.add('${i}x$j');
          }
        }
      }
      final question = availableQuestions[_random.nextInt(availableQuestions.length)];
      _askedQuestionsInLevel.add(question);
      _first = int.parse(question.split('x')[0]);
      _second = int.parse(question.split('x')[1]);
      _controller.clear();
      _feedback = '';
      _isLoading = false;
      _isCorrect = false;
      _focusNode.requestFocus();
    });
  }

  Future<void> _checkAnswer(BuildContext context) async {
    if (_isLoading || _controller.text.isEmpty) return;

    final settings = Provider.of<AppConfigs>(context, listen: false);
    final answer = int.tryParse(_controller.text);

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    setState(() {
      _totalQuestionsInLevel++;
      final correctAnswer = _first * _second;
      final userAnswer = answer ?? 0;
      if (answer == correctAnswer) {
        _correctAnswersInLevel++;
        _feedback = settings.language == 'Chinese' ? '正确！' : 'Correct!';
        _isCorrect = true;
        _feedbackAnimationController.forward(from: 0);
        if (settings.isAudioEnabled) {
          _playAudio(settings, context);
        }
      } else {
        _feedback = settings.language == 'Chinese'
            ? '错误，请重试！正确答案是 $correctAnswer'
            : 'Wrong, try again! Correct answer is $correctAnswer';
        _isCorrect = false;
        _shakeAnimationController.forward(from: 0);
      }
      _history.add({
        'question': '$_first × $_second',
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': answer == correctAnswer,
        'timestamp': DateTime.now().toString(),
        'level': _currentLevel,
      });

      if (_correctAnswersInLevel >= _getQuestionsPerLevel(_currentLevel)) {
        if (_currentLevel < 12) {
          _currentLevel++;
          _correctAnswersInLevel = 0;
          _totalQuestionsInLevel = 0;
          _askedQuestionsInLevel.clear();
          _feedback = settings.language == 'Chinese'
              ? '恭喜！进入第$_currentLevel级'
              : 'Congratulations! Advanced to Level $_currentLevel';
        } else {
          _hasMasterBadge = true;
          _feedback = settings.language == 'Chinese'
              ? '太棒了！获得大师级认证徽章！'
              : 'Awesome! Earned the Master Certification Badge!';
        }
        _saveProgress(); // Save progress after level up or badge
      }
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (_isCorrect || _hasMasterBadge) {
      _generateQuestion();
    } else {
      setState(() {
        _isLoading = false;
        _controller.clear();
        _focusNode.requestFocus();
      });
    }
  }

  Future<void> _playAudio(AppConfigs settings, BuildContext context) async {
    try {
      final langPrefix = settings.language == 'Chinese' ? 'zh' : 'en';
      final assetPath = 'audio/$langPrefix/${_first}x$_second.mp3';
      await _audioPlayer.setVolume(settings.audioVolume);
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      logger.e('Failed to play audio for $_first × $_second: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'Chinese'
                  ? '无法播放音频: $_first × $_second'
                  : 'Cannot play audio: $_first × $_second',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _resetGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentLevel = 1;
      _correctAnswersInLevel = 0;
      _totalQuestionsInLevel = 0;
      _askedQuestionsInLevel.clear();
      _history.clear();
      _hasMasterBadge = false;
      _feedback = '';
      _isCorrect = false;
      _saveProgress(); // Save reset state
      _generateQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppConfigs>(context);
    final isChinese = settings.language == 'Chinese';
    final question = '$_first × $_second = ?';
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = _getQuestionsPerLevel(_currentLevel) > 0
        ? _correctAnswersInLevel / _getQuestionsPerLevel(_currentLevel)
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: AnimationLimiter(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 400),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 20.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isChinese ? '等级: $_currentLevel / 12' : 'Level: $_currentLevel / 12',
                                    style: GoogleFonts.notoSans(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  if (_hasMasterBadge)
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: screenWidth * 0.08,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Semantics(
                                label: isChinese
                                    ? '$_first 乘 $_second 等于多少'
                                    : 'What is $_first times $_second',
                                child: Text(
                                  question,
                                  style: GoogleFonts.notoSans(
                                    fontSize: screenWidth * 0.07,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          AnimatedBuilder(
                            animation: _shakeAnimationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _isCorrect ? 0 : sin(_shakeAnimationController.value * 4 * pi) * 4,
                                  0,
                                ),
                                child: child,
                              );
                            },
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _focusNode.hasFocus
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenWidth * 0.02,
                                ),
                                child: TextFormField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: isChinese ? '输入答案' : 'Enter answer',
                                    hintStyle: GoogleFonts.notoSans(
                                      color: Colors.grey[600],
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: GoogleFonts.notoSans(fontSize: screenWidth * 0.06),
                                  enabled: !_isLoading,
                                  textAlign: TextAlign.center,
                                  onFieldSubmitted: (_) => _checkAnswer(context),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildButton(
                                screenWidth,
                                isChinese ? '提交' : 'Submit',
                                    () => _checkAnswer(context),
                                Theme.of(context).colorScheme.primary,
                                _isLoading,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              _buildButton(
                                screenWidth,
                                isChinese ? '重置' : 'Reset',
                                _resetGame,
                                Theme.of(context).colorScheme.error,
                                _isLoading,
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _feedbackAnimationController,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: Text(
                              _feedback,
                              style: GoogleFonts.notoSans(
                                fontSize: screenWidth * 0.045,
                                color: _isCorrect || _hasMasterBadge
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Column(
                                children: [
                                  Text(
                                    isChinese
                                        ? '本级进度: $_correctAnswersInLevel / ${_getQuestionsPerLevel(_currentLevel)}'
                                        : 'Level Progress: $_correctAnswersInLevel / ${_getQuestionsPerLevel(_currentLevel)}',
                                    style: GoogleFonts.notoSans(
                                      fontSize: screenWidth * 0.045,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: screenWidth * 0.015),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Theme.of(context).colorScheme.primary,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isChinese ? '历史记录' : 'History',
                                    style: GoogleFonts.notoSans(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: screenWidth * 0.015),
                                  Container(
                                    height: screenWidth * 0.3,
                                    child: _history.isEmpty
                                        ? Center(
                                      child: Text(
                                        isChinese ? '暂无记录' : 'No records yet',
                                        style: GoogleFonts.notoSans(
                                          fontSize: screenWidth * 0.035,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                        : ListView.builder(
                                      itemCount: _history.length,
                                      itemBuilder: (context, index) {
                                        final record = _history[index];
                                        return ListTile(
                                          title: Text(
                                            '${record['question']} = ${record['userAnswer']}',
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          subtitle: Text(
                                            isChinese
                                                ? '正确答案: ${record['correctAnswer']} (${record['isCorrect'] ? '正确' : '错误'}) - 等级 ${record['level']}'
                                                : 'Correct: ${record['correctAnswer']} (${record['isCorrect'] ? 'Correct' : 'Wrong'}) - Level ${record['level']}',
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.03,
                                              color: record['isCorrect']
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                          trailing: Text(
                                            record['timestamp'].split('.')[0],
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.025,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildButton(double screenWidth, String text, VoidCallback onTap, Color color, bool isLoading) {
    return AnimatedScale(
      scale: isLoading ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.02,
          ),
          child: isLoading
              ? SizedBox(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
              : Text(
            text,
            style: GoogleFonts.notoSans(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _feedbackAnimationController.dispose();
    _shakeAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}