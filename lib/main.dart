import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GuessNumberApp());
}

class GuessNumberApp extends StatelessWidget {
  const GuessNumberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
      ),
      home: const GameHomeScreen(),
    );
  }
}

enum Difficulty {
  easy(20, 6, 'Easy', Colors.green),
  medium(100, 8, 'Medium', Colors.orange),
  hard(500, 12, 'Hard', Colors.red);

  final int maxNumber;
  final int maxAttempts;
  final String label;
  final Color color;
  const Difficulty(this.maxNumber, this.maxAttempts, this.label, this.color);
}

enum GameMode {
  classic('Classic', Icons.sports_esports),
  timeAttack('Time Attack', Icons.timer),
  hardcore('Hardcore', Icons.whatshot),
  zen('Zen', Icons.self_improvement);

  final String label;
  final IconData icon;
  const GameMode(this.label, this.icon);
}

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  Difficulty _difficulty = Difficulty.easy;
  int? _highScore;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _gamesPlayed = 0;
  int _totalWins = 0;
  int _coins = 0;
  int _xp = 0;
  int _level = 1;
  int _extraLives = 0;
  int _rangeFinders = 0;
  GameMode _gameMode = GameMode.classic;
  int _rateStatus = 0; // 0: None, 1: Rated, 2: Never


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore_${_difficulty.name}_${_gameMode.name}');
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
      _totalWins = prefs.getInt('totalWins') ?? 0;
      _coins = prefs.getInt('coins') ?? 0;
      _xp = prefs.getInt('xp') ?? 0;
      _level = prefs.getInt('level') ?? 1;
      _extraLives = prefs.getInt('extraLives') ?? 0;
      _rangeFinders = prefs.getInt('rangeFinders') ?? 0;
      _rateStatus = prefs.getInt('rate_status') ?? 0;
    });
  }

  Future<void> _updateDifficulty(Difficulty d) async {
    if (_vibrationEnabled) Vibration.vibrate(duration: 30);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _difficulty = d;
      _highScore = prefs.getInt('highScore_${d.name}_${_gameMode.name}');
    });
  }

  Future<void> _updateMode(GameMode m) async {
    if (_vibrationEnabled) Vibration.vibrate(duration: 30);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameMode = m;
      _highScore = prefs.getInt('highScore_${_difficulty.name}_${m.name}');
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _loadSettings();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: Text('HOW TO PLAY', style: GoogleFonts.bungee(color: Colors.amber, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.help_outline, 'Guess the secret number within the given attempts.'),
            _infoRow(Icons.trending_up, '"HIGHER" means the secret number is larger.'),
            _infoRow(Icons.trending_down, '"LOWER" means the secret number is smaller.'),
            _infoRow(Icons.lightbulb_outline, 'Use "HINT" to reveal if the number is Even or Odd (costs 1 attempt).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: Text('STATISTICS', style: GoogleFonts.bungee(color: Colors.blueAccent, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow('Games Played', '$_gamesPlayed'),
            const SizedBox(height: 10),
            _statRow('Total Wins', '$_totalWins'),
            const SizedBox(height: 10),
            _statRow('Win Rate', '${_gamesPlayed == 0 ? 0 : ((_totalWins / _gamesPlayed) * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildProfileHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? size.width * 0.2 : 30.0,
                          vertical: 10.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: Hero(
                                tag: 'logo',
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Icon(Icons.bolt, size: 60, color: Colors.amber),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildModeSelection(),
                            const SizedBox(height: 30),
                            _buildDifficultySection(),
                            const SizedBox(height: 30),
                            if (_highScore != null && _gameMode != GameMode.zen)
                              FadeInUp(
                                delay: const Duration(milliseconds: 500),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _gameMode == GameMode.timeAttack 
                                      ? 'Best Score: $_highScore correct'
                                      : 'Best Score: $_highScore attempts',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 40),
                            FadeInUp(
                              delay: const Duration(milliseconds: 600),
                              child: _buildStartButton(),
                            ),
                            const SizedBox(height: 30),
                            FadeInUp(
                              delay: const Duration(milliseconds: 700),
                              child: _buildSettingsRow(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    int xpToNextLevel = _level * 100;
    double progress = (_xp / xpToNextLevel).clamp(0.0, 1.0);

    Color statusColor = _rateStatus == 1 ? Colors.greenAccent : (_rateStatus == 2 ? Colors.redAccent : Colors.blueAccent);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor,
            child: Text('L$_level', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PLAYER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Text('$_xp / $xpToNextLevel XP', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 5),
                Text('$_coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 2.2,
      children: GameMode.values.map((mode) {
        bool isSelected = _gameMode == mode;
        return GestureDetector(
          onTap: () => _updateMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
              boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mode.icon, size: 20, color: isSelected ? Colors.white : Colors.white54),
                const SizedBox(width: 10),
                Text(
                  mode.label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      children: [
        const Text(
          'SELECT LEVEL',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300, color: Colors.white70),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: Difficulty.values.map((d) {
            bool isSelected = _difficulty == d;
            return GestureDetector(
              onTap: () => _updateDifficulty(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? d.color : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: d.color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] 
                    : [],
                ),
                child: Text(
                  d.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black87 : Colors.white60,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: () {
        if (_vibrationEnabled) Vibration.vibrate(duration: 50);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => GamePlayScreen(
              difficulty: _difficulty,
              gameMode: _gameMode,
              soundEnabled: _soundEnabled,
              vibrationEnabled: _vibrationEnabled,
              extraLives: _extraLives,
              rangeFinders: _rangeFinders,
              onOpenShop: () => _showShopDialog(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ).then((_) => _loadSettings());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(220, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
      ),
      child: const Text('BATTLE START', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 15,
      runSpacing: 10,
      children: [
        IconButton(
          onPressed: () => _toggleSetting('soundEnabled', !_soundEnabled),
          icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white54),
        ),
        IconButton(
          onPressed: () => _toggleSetting('vibrationEnabled', !_vibrationEnabled),
          icon: Icon(_vibrationEnabled ? Icons.vibration : Icons.mobile_off, color: Colors.white54),
        ),
        IconButton(
          onPressed: _showInfoDialog,
          icon: const Icon(Icons.info_outline, color: Colors.white54),
        ),
        IconButton(
          onPressed: _showStatsDialog,
          icon: const Icon(Icons.bar_chart, color: Colors.white54),
        ),
        IconButton(
          onPressed: _showShopDialog,
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white54),
        ),
      ],
    );
  }

  Future<void> _showShopDialog() async {
    await _loadSettings();
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SHOP', style: GoogleFonts.bungee(color: Colors.greenAccent, fontSize: 24)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('$_coins', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _shopItem('Extra Life', 'Add 3 attempts in Classic mode', 100, _extraLives, Icons.favorite, () async {
                  await _buyItem('extraLives', 100);
                  setDialogState(() {});
                }),
                const SizedBox(height: 15),
                _shopItem('Range Finder', 'See which half the number is in', 50, _rangeFinders, Icons.radar, () async {
                  await _buyItem('rangeFinders', 50);
                  setDialogState(() {});
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _shopItem(String name, String desc, int price, int ownedCount, IconData icon, VoidCallback onBuy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                Text('OWNED: $ownedCount', style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: Text('$price', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _buyItem(String key, int price) async {
    if (_coins < price) {
      _showToast('Not enough coins!');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins - price);
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
    _loadSettings();
    _showToast('Purchase successful!');
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }
}

class GamePlayScreen extends StatefulWidget {
  final Difficulty difficulty;
  final GameMode gameMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int extraLives;
  final int rangeFinders;

  const GamePlayScreen({
    super.key, 
    required this.difficulty,
    required this.gameMode,
    required this.soundEnabled,
    required this.vibrationEnabled,
    this.extraLives = 0,
    this.rangeFinders = 0,
    this.onOpenShop,
  });

  final VoidCallback? onOpenShop;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late int _targetNumber;
  late int _attemptsRemaining;
  int _attemptsCount = 0;
  int _minPossible = 1;
  late int _maxPossible;
  
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _hintMessage = '';
  bool _isGameOver = false;
  bool _isWin = false;
  bool _isTimerPaused = false;
  bool _rangeFinderUsedForCurrentRange = false;
  double _sliderValue = 1.0;
  
  late ConfettiController _confettiController;
  final List<int> _guessHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Advanced Features
  Timer? _timer;
  int _timeRemaining = 60;
  int _score = 0;
  late int _extraLivesRemaining;
  late int _rangeFindersRemaining;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _maxPossible = widget.difficulty.maxNumber;
    _extraLivesRemaining = widget.extraLives;
    _rangeFindersRemaining = widget.rangeFinders;
    _startNewGame();
    _incrementGamesPlayed();
    if (widget.gameMode == GameMode.timeAttack) _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _syncPowerUps();
  }

  Future<void> _syncPowerUps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _extraLivesRemaining = prefs.getInt('extraLives') ?? 0;
      _rangeFindersRemaining = prefs.getInt('rangeFinders') ?? 0;
    });
  }

  void _startTimer() {
    _timeRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerPaused) return;
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _endGameByTimeout();
      }
    });
  }

  void _endGameByTimeout() {
    setState(() {
      _isGameOver = true;
      _hintMessage = 'TIME IS UP!';
    });
  }

  void _startNewGame() {
    bool wasGameOver = _isGameOver;
    setState(() {
      _targetNumber = Random().nextInt(widget.difficulty.maxNumber) + 1;
      _attemptsRemaining = widget.gameMode == GameMode.hardcore 
          ? 1 
          : (widget.gameMode == GameMode.zen ? 999 : widget.difficulty.maxAttempts);
      _attemptsCount = 0;
      _minPossible = 1;
      _maxPossible = widget.difficulty.maxNumber;
      _hintMessage = 'Range: 1 to $_maxPossible';
      _isGameOver = false;
      _isWin = false;
      _rangeFinderUsedForCurrentRange = false;
      _sliderValue = _minPossible.toDouble();
      _guessHistory.clear();
      _controller.clear();
      _confettiController.stop();
      
      if (wasGameOver && widget.gameMode == GameMode.timeAttack) {
        _score = 0;
        _timeRemaining = 60;
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _playWinSound() async {
    if (widget.soundEnabled) {
      try {
        await _audioPlayer.setVolume(0.4); // Lower volume as requested
        await _audioPlayer.play(AssetSource('audio/success.mp3'));
      } catch (e) {
        debugPrint('Audio play error: $e');
      }
    }
  }

  void _showHint() {
    if (_isGameOver || _attemptsRemaining <= 1) {
      _showToast('Not enough attempts for a hint!');
      return;
    }

    if (widget.vibrationEnabled) Vibration.vibrate(duration: 50);

    setState(() {
      _attemptsRemaining--;
      _attemptsCount++;
      bool isEven = _targetNumber % 2 == 0;
      _hintMessage = 'HINT: IT IS AN ${isEven ? 'EVEN' : 'ODD'} NUMBER';
    });
  }

  void _useExtraLife() {
    if (_isGameOver) return;
    if (_extraLivesRemaining <= 0) {
      _showNoItemsDialog('EXTRA LIVES', 'Adds +3 attempts to your current game.');
      return;
    }
    setState(() {
      _extraLivesRemaining--;
      _attemptsRemaining += 3;
      _hintMessage = '+3 ATTEMPTS ADDED!';
    });
    _updatePowerUpCount('extraLives');
  }

  void _useRangeFinder() {
    if (_isGameOver) return;
    
    int mid = ((_minPossible + _maxPossible) / 2).floor();
    bool inLower = _targetNumber <= mid;
    String message = 'HINT: IT IS IN THE ${inLower ? 'LOWER' : 'UPPER'} HALF';

    if (_rangeFinderUsedForCurrentRange) {
      setState(() {
        _hintMessage = message;
      });
      _showToast('Range already revealed!');
      return;
    }

    if (_rangeFindersRemaining <= 0) {
      _showNoItemsDialog('RANGE FINDER', 'Reveals which half the number is in.');
      return;
    }

    setState(() {
      _rangeFindersRemaining--;
      _hintMessage = message;
      _rangeFinderUsedForCurrentRange = true;
    });
    _updatePowerUpCount('rangeFinders');
  }

  void _showNoItemsDialog(String name, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.blueAccent, width: 2)),
        title: Text('NO $name LEFT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'You have run out of $name. Would you like to purchase more from the shop?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (widget.onOpenShop != null) {
                await (widget.onOpenShop!() as Future);
                _syncPowerUps();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('PURCHASE NOW'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePowerUpCount(String key) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(key) ?? 0;
    if (current > 0) await prefs.setInt(key, current - 1);
  }

  Widget _buildPowerUpsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _powerUpButton(Icons.favorite, '$_extraLivesRemaining', Colors.redAccent, _useExtraLife),
        const SizedBox(width: 20),
        _powerUpButton(Icons.radar, '$_rangeFindersRemaining', Colors.amber, _useRangeFinder),
      ],
    );
  }

  Widget _powerUpButton(IconData icon, String count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 5),
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  void _processGuess() {
    final input = _controller.text;
    final guess = int.tryParse(input);

    if (guess == null || guess < 1 || guess > widget.difficulty.maxNumber) {
      _showToast('Enter valid number (1-${widget.difficulty.maxNumber})');
      return;
    }

    if (_guessHistory.contains(guess)) {
      _showToast('You already tried $guess!');
      return;
    }

    if (widget.vibrationEnabled) Vibration.vibrate(duration: 40);

    setState(() {
      _attemptsCount++;
      _attemptsRemaining--;
      _guessHistory.insert(0, guess);
      _rangeFinderUsedForCurrentRange = false;

      if (guess == _targetNumber) {
        _isWin = true;
        if (_attemptsCount <= 3) {
          _checkRateUs();
        }
        if (widget.gameMode != GameMode.timeAttack) {
          _isGameOver = true;
          _hintMessage = 'EPIC WIN!';
          _confettiController.play();
          _playWinSound();
          _saveHighScore();
          _awardRewards();
        } else {
          // Time Attack Mode
          _score++;
          _timeRemaining += 10; // Bonus time
          _hintMessage = 'CORRECT! +10s';
          _playWinSound();
          _confettiController.play();
          
          setState(() {
            _isTimerPaused = true;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isTimerPaused = false;
                _startNewGame();
              });
            }
          });
        }
      } else if (widget.gameMode != GameMode.timeAttack && widget.gameMode != GameMode.zen && _attemptsRemaining == 0) {
        _isGameOver = true;
        _hintMessage = 'THE NUMBER WAS $_targetNumber';
      } else {
        if (guess < _targetNumber) {
          _hintMessage = 'HIGHER!';
          _minPossible = max(_minPossible, guess + 1);
        } else {
          _hintMessage = 'LOWER!';
          _maxPossible = min(_maxPossible, guess - 1);
        }
      }
      _controller.clear();
      _sliderValue = _minPossible.toDouble();
      if (_minPossible == _maxPossible) {
        _controller.text = _minPossible.toString();
      }
      _focusNode.requestFocus();
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'highScore_${widget.difficulty.name}_${widget.gameMode.name}';
    final currentHigh = prefs.getInt(key);
    
    if (widget.gameMode == GameMode.timeAttack) {
      if (currentHigh == null || _score > currentHigh) {
        await prefs.setInt(key, _score);
      }
    } else {
      if (currentHigh == null || _attemptsCount < currentHigh) {
        await prefs.setInt(key, _attemptsCount);
      }
    }
    
    // Increment total wins
    int currentWins = prefs.getInt('totalWins') ?? 0;
    await prefs.setInt('totalWins', currentWins + 1);
  }

  Future<void> _incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    int currentGames = prefs.getInt('gamesPlayed') ?? 0;
    await prefs.setInt('gamesPlayed', currentGames + 1);
  }

  Future<void> _awardRewards() async {
    final prefs = await SharedPreferences.getInstance();
    int earnedCoins = (widget.difficulty.maxAttempts - _attemptsCount + 1) * 10;
    int earnedXP = (widget.difficulty.maxAttempts - _attemptsCount + 1) * 20;

    if (widget.gameMode == GameMode.hardcore) {
      earnedCoins *= 5;
      earnedXP *= 5;
    } else if (widget.gameMode == GameMode.zen) {
      earnedCoins = 5;
      earnedXP = 10;
    }

    int currentCoins = prefs.getInt('coins') ?? 0;
    int currentXP = prefs.getInt('xp') ?? 0;
    int currentLevel = prefs.getInt('level') ?? 1;

    currentXP += earnedXP;
    int xpToNext = currentLevel * 100;
    if (currentXP >= xpToNext) {
      currentXP -= xpToNext;
      currentLevel++;
      _showToast('LEVEL UP! Level $currentLevel');
    }

    await prefs.setInt('coins', currentCoins + earnedCoins);
    await prefs.setInt('xp', currentXP);
    await prefs.setInt('level', currentLevel);
  }

  Future<void> _checkRateUs() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasInteracted = prefs.getBool('rate_interacted') ?? false;
    if (!hasInteracted) {
      _showRateDialog();
    }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.blueAccent, width: 2)),
        title: const Text('ENJOYING THE GAME?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'You are doing great! Would you mind rating us on the Play Store? It helps us a lot!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => _handleRateInteraction(false),
            child: const Text('NEVER', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => _handleRateInteraction(null),
            child: const Text('LATER', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => _handleRateInteraction(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('RATE NOW'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRateInteraction(bool? isPositive) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPositive != null) {
      await prefs.setBool('rate_interacted', true);
      await prefs.setInt('rate_status', isPositive ? 1 : 2);
    }
    if (mounted) Navigator.pop(context);
    if (isPositive == true) {
      final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=mm.marsman.guessnumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Could not open Play Store');
      }
    }
  }

  void _onKeypadTap(String val) {
    if (_isGameOver) return;
    if (widget.vibrationEnabled) Vibration.vibrate(duration: 20);
    setState(() {
      if (val == 'BACK') {
        if (_controller.text.isNotEmpty) {
          _controller.text = _controller.text.substring(0, _controller.text.length - 1);
        }
      } else {
        if (_controller.text.length < 5) {
          _controller.text += val;
        }
      }
      _sliderValue = double.tryParse(_controller.text)?.clamp(_minPossible.toDouble(), _maxPossible.toDouble()) ?? _minPossible.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: Text('${widget.difficulty.label} Mode'.toUpperCase(), style: const TextStyle(fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.amber, Colors.blue, Colors.pink, Colors.green],
            numberOfParticles: 50,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeaderStats(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 5 : 15),
                        _buildRangeIndicator(),
                        const SizedBox(height: 10),
                        _buildMainDisplay(),
                        const SizedBox(height: 10),
                        _buildPowerUpsRow(),
                        const SizedBox(height: 10),
                        if (!_isGameOver) ...[
                          _buildInputSection(),
                          const SizedBox(height: 20),
                          _buildHintButton(),
                        ],
                        if (_isGameOver) _buildGameOverSection(),
                        const SizedBox(height: 30),
                        _buildGuessHistory(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile('ATTEMPTS', '$_attemptsCount', Colors.blue),
          _statTile('REMAINING', '$_attemptsRemaining', _attemptsRemaining < 3 ? Colors.red : Colors.amber),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    if (widget.gameMode == GameMode.timeAttack && label == 'REMAINING') {
      label = 'TIME';
      value = '$_timeRemaining';
    }
    if (widget.gameMode == GameMode.timeAttack && label == 'ATTEMPTS') {
      label = 'SCORE';
      value = '$_score';
    }
    if (widget.gameMode == GameMode.zen && label == 'REMAINING') {
      value = '∞';
    }
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildRangeIndicator() {
    return Column(
      children: [
        const Text('CURRENT RANGE', style: TextStyle(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _rangeBox('$_minPossible'),
            Container(width: 40, height: 2, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 10)),
            _rangeBox('$_maxPossible'),
          ],
        ),
      ],
    );
  }

  Widget _rangeBox(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildMainDisplay() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            _hintMessage,
            key: ValueKey(_hintMessage),
            textAlign: TextAlign.center,
            style: GoogleFonts.bungee(
              fontSize: 28,
              color: _isWin ? Colors.greenAccent : (_isGameOver ? Colors.redAccent : Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        // Slider for quick selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.amber,
              overlayColor: Colors.amber.withOpacity(0.2),
              trackHeight: 2,
            ),
            child: Slider(
              value: _sliderValue.clamp(_minPossible.toDouble(), max(_minPossible.toDouble() + 1.0, _maxPossible.toDouble())),
              min: _minPossible.toDouble(),
              max: _maxPossible == _minPossible ? _minPossible + 1.0 : _maxPossible.toDouble(),
              divisions: max(1, _maxPossible - _minPossible),
              onChanged: _maxPossible == _minPossible ? null : (val) {
                setState(() {
                  _sliderValue = val;
                  _controller.text = val.toInt().toString();
                });
              },
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _controller,
                      readOnly: true,
                      showCursor: true,
                      textAlign: TextAlign.center,
                      cursorColor: Colors.amber,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
                      decoration: const InputDecoration(hintText: '?', border: InputBorder.none),
                    ),
                  ),
                  _buildCustomKeypad(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: _buildRightActionColumn(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightActionColumn() {
    return Column(
      children: [
        _actionButton(Icons.backspace_outlined, Colors.redAccent, () => _onKeypadTap('BACK')),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _processGuess,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8)],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
                SizedBox(height: 5),
                Text('GUESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildCustomKeypad() {
    return Column(
      children: [
        _keypadRow(['1', '2', '3', '4', '5']),
        _keypadRow(['6', '7', '8', '9', '0']),
      ],
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _keypadButton(key)).toList(),
      ),
    );
  }

  Widget _keypadButton(String label) {
    bool isAction = label == 'BACK' || label == '✓';
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == '✓') {
            _processGuess();
          } else {
            _onKeypadTap(label);
          }
        },
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isAction ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Center(
            child: label == 'BACK' 
              ? const Icon(Icons.backspace_outlined, color: Colors.redAccent, size: 20)
              : label == '✓'
                ? const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24)
                : Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessHistory() {
    if (_guessHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const Text('HISTORY', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: _guessHistory.length,
            itemBuilder: (context, index) {
              int guess = _guessHistory[index];
              bool isCorrect = guess == _targetNumber;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isCorrect ? Colors.greenAccent : Colors.white10),
                ),
                child: Text(
                  '$guess',
                  style: TextStyle(
                    color: isCorrect ? Colors.greenAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverSection() {
    return Column(
      children: [
        FadeInUp(
          child: Text(
            _isWin ? 'CONGRATULATIONS!' : 'BETTER LUCK NEXT TIME!',
            style: const TextStyle(color: Colors.white70, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _startNewGame,
              icon: const Icon(Icons.replay),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            const SizedBox(width: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('EXIT', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildHintButton() {
    return TextButton.icon(
      onPressed: _showHint,
      icon: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
      label: const Text('USE HINT (COSTS 1 ATTEMPT)', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.amber.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
