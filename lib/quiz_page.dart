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
import 'dart:convert';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<QuizPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  int _currentLevel = 1;
  int _correctAnswersInLevel = 0;
  int _totalQuestionsInLevel = 0;
  int _totalQuestions = 0;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;
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

  String _getTitleForLevel(int level) {
    final settings = Provider.of<AppConfigs>(context, listen: false);
    final isChinese = settings.language == 'Chinese';
    if (level >= 90) return isChinese ? '至尊大师' : 'Supreme Master';
    if (level >= 75) return isChinese ? '宗师' : 'Grand Master';
    if (level >= 60) return isChinese ? '大师' : 'Master';
    if (level >= 45) return isChinese ? '专家' : 'Expert';
    if (level >= 30) return isChinese ? '高级' : 'Advanced';
    if (level >= 15) return isChinese ? '中级' : 'Intermediate';
    return isChinese ? '初学者' : 'Beginner';
  }

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
    _loadProgress();
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
      _totalQuestions = prefs.getInt('totalQuestions') ?? 0;
      _totalCorrect = prefs.getInt('totalCorrect') ?? 0;
      _totalIncorrect = prefs.getInt('totalIncorrect') ?? 0;
      final historyJson = prefs.getString('history');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history.clear();
        _history.addAll(decoded.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', _currentLevel);
    await prefs.setInt('correctAnswersInLevel', _correctAnswersInLevel);
    await prefs.setInt('totalQuestionsInLevel', _totalQuestionsInLevel);
    await prefs.setBool('hasMasterBadge', _hasMasterBadge);
    await prefs.setInt('totalQuestions', _totalQuestions);
    await prefs.setInt('totalCorrect', _totalCorrect);
    await prefs.setInt('totalIncorrect', _totalIncorrect);
    await prefs.setString('history', jsonEncode(_history));
  }

  Future<void> _clearHistory() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _history.clear();
      _totalQuestions = 0;
      _totalCorrect = 0;
      _totalIncorrect = 0;
    });
    await _saveProgress();
  }

  int _getQuestionsPerLevel(int level) {
    if (level <= 20) return 5;
    if (level <= 40) return 7;
    if (level <= 60) return 10;
    if (level <= 80) return 12;
    return 15;
  }

  void _generateQuestion() {
    setState(() {
      final availableQuestions = <String>[];
      final maxNumber = _currentLevel <= 20
          ? 9
          : _currentLevel <= 40
          ? 12
          : _currentLevel <= 60
          ? 15
          : _currentLevel <= 80
          ? 20
          : 25;
      for (int i = 1; i <= maxNumber; i++) {
        for (int j = 1; j <= maxNumber; j++) {
          final key = '${i}x$j';
          if (!_askedQuestionsInLevel.contains(key)) {
            availableQuestions.add(key);
          }
        }
      }
      if (availableQuestions.isEmpty) {
        _askedQuestionsInLevel.clear();
        for (int i = 1; i <= maxNumber; i++) {
          for (int j = 1; j <= maxNumber; j++) {
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
    });
  }

  Future<void> _checkAnswer(BuildContext context) async {
    if (_isLoading || _controller.text.isEmpty) return;
    final settings = Provider.of<AppConfigs>(context, listen: false);
    final answer = int.tryParse(_controller.text);
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    setState(() {
      _totalQuestionsInLevel++;
      _totalQuestions++;
      final correctAnswer = _first * _second;
      final userAnswer = answer ?? 0;
      if (answer == correctAnswer) {
        _correctAnswersInLevel++;
        _totalCorrect++;
        _feedback = settings.language == 'Chinese' ? '正确！' : 'Correct!';
        _isCorrect = true;
        _feedbackAnimationController.forward(from: 0);
        if (settings.isAudioEnabled) {
          _playAudio(settings, context);
        }
      } else {
        _totalIncorrect++;
        _feedback = settings.language == 'Chinese' ? '错误，请重试！' : 'Wrong, try again!';
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
        if (_currentLevel < 100) {
          _currentLevel++;
          _correctAnswersInLevel = 0;
          _totalQuestionsInLevel = 0;
          _askedQuestionsInLevel.clear();
          _feedback = settings.language == 'Chinese'
              ? '恭喜！进入第$_currentLevel级 (${_getTitleForLevel(_currentLevel)})'
              : 'Congratulations! Advanced to Level $_currentLevel (${_getTitleForLevel(_currentLevel)})';
        } else {
          _hasMasterBadge = true;
          _feedback = settings.language == 'Chinese'
              ? '无敌了！获得至尊大师认证徽章！'
              : 'Unstoppable! Earned the Supreme Master Badge!';
        }
        _saveProgress();
      } else {
        _saveProgress();
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
      _totalQuestions = 0;
      _totalCorrect = 0;
      _totalIncorrect = 0;
      _askedQuestionsInLevel.clear();
      _history.clear();
      _hasMasterBadge = false;
      _feedback = '';
      _isCorrect = false;
      _saveProgress();
      _generateQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppConfigs>(context);
    final isChinese = settings.language == 'Chinese';
    final question = '$_first × $_second = ?';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final progress = _getQuestionsPerLevel(_currentLevel) > 0
        ? _correctAnswersInLevel / _getQuestionsPerLevel(_currentLevel)
        : 0.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
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
                                child: Column(
                                  children: [
                                    Semantics(
                                      label: isChinese ? '等级' : 'Level',
                                      child: Text(
                                        isChinese
                                            ? '等级: $_currentLevel / 100'
                                            : 'Level: $_currentLevel / 100',
                                        style: GoogleFonts.notoSans(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.01),
                                    Text(
                                      isChinese
                                          ? '称号: ${_getTitleForLevel(_currentLevel)}'
                                          : 'Title: ${_getTitleForLevel(_currentLevel)}',
                                      style: GoogleFonts.notoSans(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: screenWidth * 0.01),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isChinese
                                                ? '总题: $_totalQuestions'
                                                : 'Total: $_totalQuestions',
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            isChinese
                                                ? '正确: $_totalCorrect'
                                                : 'Correct: $_totalCorrect',
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            isChinese
                                                ? '错误: $_totalIncorrect'
                                                : 'Incorrect: $_totalIncorrect',
                                            style: GoogleFonts.notoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_hasMasterBadge)
                                      Padding(
                                        padding: EdgeInsets.only(top: screenWidth * 0.01),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: screenWidth * 0.08,
                                        ),
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
                                    style: GoogleFonts.notoSans(
                                      fontSize: screenWidth * 0.06,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                      textAlign: TextAlign.center,
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isChinese ? '历史记录' : 'History',
                                          style: GoogleFonts.notoSans(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        if (_history.isNotEmpty)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: screenWidth * 0.05,
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                            onPressed: _clearHistory,
                                            tooltip: isChinese ? '清除历史记录' : 'Clear History',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            splashRadius: screenWidth * 0.05,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: screenWidth * 0.015),
                                    SizedBox(
                                      height: isLandscape ? screenWidth * 0.4 : screenWidth * 0.3,
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
                                            dense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                                            title: Text(
                                              '${record['question']} = ${record['userAnswer']}',
                                              style: GoogleFonts.notoSans(
                                                fontSize: screenWidth * 0.035,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildButton(double screenWidth, String text, VoidCallback onTap, Color color, bool isLoading) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isLoading
          ? null
          : () {
        FocusScope.of(context).unfocus();
        onTap();
      },
      child: Container(
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
        child: Text(
          text,
          style: GoogleFonts.notoSans(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
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