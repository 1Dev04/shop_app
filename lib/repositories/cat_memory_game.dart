import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CatMemoryGame extends StatefulWidget {
  final void Function(int percent) onWin;
  final VoidCallback onLose;

  const CatMemoryGame ({required this.onWin, required this.onLose});

  @override
  State<CatMemoryGame> createState() => CatMemoryGameState();
}

class CatMemoryGameState extends State<CatMemoryGame> {
  static const List<String> _icons = [
    '🐱',
    '🐟',
    '🎀',
    '🌸',
    '🍪',
    '🦋',
    '🌙',
    '⭐'
  ];
  static const List<int> _coupons = [10, 20, 50, 100];

  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;

  int? _firstIndex;
  bool _checking = false;
  int _wrongCount = 0;
  int _timeLeft = 60;
  int _moves = 0;
  Timer? _timer;
  bool _gameOver = false;
  bool _won = false;
  int _wonCoupon = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final doubled = [..._icons, ..._icons];
    doubled.shuffle(Random());
    _cards = doubled;
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstIndex = null;
    _checking = false;
    _wrongCount = 0;
    _timeLeft = 60;
    _moves = 0;
    _gameOver = false;
    _won = false;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _triggerLose();
    });
  }

  void _triggerLose() {
    _timer?.cancel();
    setState(() => _gameOver = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onLose();
    });
  }

  void _triggerWin() {
    _timer?.cancel();
    final coupon = _coupons[Random().nextInt(_coupons.length)];
    setState(() {
      _won = true;
      _gameOver = true;
      _wonCoupon = coupon;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onWin(coupon);
    });
  }

  void _onTap(int index) {
    if (_checking || _flipped[index] || _matched[index] || _gameOver) return;

    setState(() => _flipped[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;
    _checking = true;
    _moves++;

    if (_cards[first] == _cards[index]) {
      // match!
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
        _checking = false;
      });
      if (_matched.every((m) => m)) _triggerWin();
    } else {
      // wrong
      _wrongCount++;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _flipped[first] = false;
          _flipped[index] = false;
          _checking = false;
        });
        if (_wrongCount >= 5) _triggerLose();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.black.withOpacity(0.92)
          : Colors.white.withOpacity(0.97),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memory Match 🐾',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'จับคู่ให้ครบก่อนหมดเวลา!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Timer
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${_timeLeft}s',
                        color: _timeLeft <= 10 ? Colors.red : _timeLeft <= 30 ? Colors.orange : Colors.green, 
                      ),
                      const SizedBox(width: 8),
                      // Wrong count
                      _StatChip(
                        icon: Icons.close_rounded,
                        label: '${_wrongCount}/5',
                        color: _wrongCount >= 4 ? Colors.red : _wrongCount >= 2 ? Colors.orange : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 16,
                  itemBuilder: (_, i) => _buildCard(i, isDark),
                ),
              ),
            ),

            // Moves
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'เปิดไปแล้ว $_moves ครั้ง',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
            ),

            // Result overlay
            if (_gameOver)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: _won ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _won ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _won ? '🎉 WON!' : '😿 Game Over',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            _won ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _won
                          ? 'ได้รับ Coupon ส่วนลด $_wonCoupon%! 🏷️'
                          : 'เสียใจด้วยนะเมี้ยว~ ลองใหม่ได้นะ',
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            _won ? Colors.green.shade800 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index, bool isDark) {
    final isFlipped = _flipped[index] || _matched[index];
    final isMatched = _matched[index];

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isMatched
              ? Colors.green.shade100
              : isFlipped
                  ? (isDark ? Colors.grey[700] : Colors.orange.shade50)
                  : (isDark ? Colors.grey[800] : Colors.orange.shade400),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? Colors.green.shade300
                : isFlipped
                    ? Colors.orange.shade300
                    : Colors.orange.shade600,
            width: 1.5,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isFlipped
                ? Text(
                    _cards[index],
                    key: ValueKey('f$index'),
                    style: const TextStyle(fontSize: 28),
                  )
                : Image.network(
                    "https://res.cloudinary.com/dag73dhpl/image/upload/v1741695020/cat3_thqyg3.png",
                    key: ValueKey('h$index'),
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
