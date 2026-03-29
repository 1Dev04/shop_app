import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter_application_1/blocs/cat_chatbot/chatbot_bloc.dart';
import 'package:flutter_application_1/blocs/cat_chatbot/chatbot_event.dart';
import 'package:flutter_application_1/blocs/cat_chatbot/chatbot_state.dart';
import 'package:flutter_application_1/repositories/cat_memory_game.dart';
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatbotBloc(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  bool _showWelcome = true;
  bool _isDancing = false;
  bool _isHappy = false;
  bool _is8bit = false;
  bool _isCMD = false;
  bool _isScan = false;
  bool _isError = false;
  bool _showBotPopup = false;
  bool _isFight = false;
  bool _showGame = false;

  bool _isTapLocked = false;
  DateTime _lastTapTime = DateTime.now();
  int _tapCount = 0;

  String _userText = '';
  String _botPopup = '';

  AudioPlayer? _audioPlayer;

  String get _currentAnim {
    if (_isError) return 'lib/assets/CatError.json';
    if (_isFight) return 'lib/assets/CatTB.json';
    if (_isDancing) return 'lib/assets/CatDance.json';
    if (_isHappy) return 'lib/assets/CarLovePS.json';
    if (_is8bit) return 'lib/assets/Cat8Bit.json';
    if (_isCMD) return 'lib/assets/CatCMD.json';
    if (_isScan) return 'lib/assets/CatScan.json';
    return 'lib/assets/CatBot.json';
  }

  @override
  void initState() {
    super.initState();

    // ✅ setup shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showWelcome = false);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _audioPlayer?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playMeow() async {
    try {
      await _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setAsset('assets/meow_robot.ogg');
      await _audioPlayer!.play();
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isError) setState(() => _isError = false);
    if (_showWelcome) setState(() => _showWelcome = false);

    setState(() {
      _userText = text;
      _showBotPopup = false;
      _botPopup = '';
      _controller.clear();
    });

    context.read<ChatbotBloc>().add(ChatbotMessageSent(text));
  }

  void _onTapMaffin() {
    if (_isTapLocked || _isError) return;

    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 400) return;
    _lastTapTime = now;

    _tapCount++;

    _shakeController.forward(from: 0);
    _playMeow();

    if (_tapCount >= 5) {
      _tapCount = 0;
      _isTapLocked = true;

      setState(() {
        _isFight = true;
        _botPopup = 'จี๊ Maffin เยอะละนะ!! 😾🐾';
        _showBotPopup = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _isFight = false;
          _showBotPopup = false;
        });
        _isTapLocked = false;
      });
      return;
    }

    setState(() {
      _botPopup = _getMaffinReaction();
      _showBotPopup = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showBotPopup = false);
    });
  }

  void _catGame() {
    setState(() => _showGame = true);
  }

  String _getMaffinReaction() {
    final reactions = [
      'หืม~ มือซนอีกแล้วนะ! 😼',
      'อย่ามาแกล้งกันนะเมี้ยว! 🐾',
      'Maffin งอนแล้วนะ! 😾',
      'โดนจับได้แล้ววว! 😹',
      'แอบมาจิ้มอีก! 👀',
    ];
    reactions.shuffle();
    return reactions.first;
  }

  Widget _buildMaffin({double size = 40}) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _currentAnim,
        key: ValueKey(_currentAnim),
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }

  Widget _buildGameOverlay() {
    return CatMemoryGame(
      onWin: (int percent) {
        setState(() => _showGame = false);
        setState(() {
          _botPopup = '🎉 WON! คุณได้รับ Coupon ส่วนลด $percent% แล้วนะเมี้ยว~';
          _showBotPopup = true;
        });
        Future.delayed(const Duration(seconds: 8), () {
          if (!mounted) return;
          setState(() => _showBotPopup = false);
        });
      },
      onLose: () {
        setState(() => _showGame = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ChatbotBloc, ChatbotState>(
      listener: (context, state) {
        if (state is ChatbotSuccess) {
          setState(() {
            _botPopup = state.reply;
            _showBotPopup = true;
            _isError = false;
            _isDancing = false;
            _isHappy = false;
            _is8bit = false;
            _isCMD = false;
            _isScan = false;
          });

          if (state.action == 'dance') {
            setState(() => _isDancing = true);
            Future.delayed(const Duration(seconds: 10), () {
              if (!mounted) return;
              setState(() => _isDancing = false);
            });
          }
          if (state.action == 'happy') {
            setState(() => _isHappy = true);
            Future.delayed(const Duration(seconds: 8), () {
              if (!mounted) return;
              setState(() => _isHappy = false);
            });
          }
          if (state.action == '8bit') {
            setState(() => _is8bit = true);
            Future.delayed(const Duration(seconds: 8), () {
              if (!mounted) return;
              setState(() => _is8bit = false);
            });
          }
          if (state.action == 'command') {
            setState(() => _isCMD = true);
            Future.delayed(const Duration(seconds: 7), () {
              if (!mounted) return;
              setState(() => _isCMD = false);
            });
          }
          if (state.action == 'scan') {
            setState(() => _isScan = true);
            Future.delayed(const Duration(seconds: 7), () {
              if (!mounted) return;
              setState(() => _isScan = false);
            });
          }

          if (state.action == 'game') {
            _catGame();
          }

          Future.delayed(const Duration(seconds: 7), () {
            if (!mounted) return;
            setState(() {
              _showBotPopup = false;
              _userText = '';
            });
          });
        }

        if (state is ChatbotFailure) {
          setState(() {
            _isError = true;
            _botPopup = '😿 เชื่อมต่อไม่ได้ ลองใหม่อีกครั้งนะ!';
            _showBotPopup = true;
          });
          Future.delayed(const Duration(seconds: 10), () {
            if (!mounted) return;
            setState(() {
              _isError = false;
              _showBotPopup = false;
              _userText = '';
            });
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.network(
                'https://res.cloudinary.com/dag73dhpl/image/upload/v1741695020/cat3_thqyg3.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maffin',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('พร้อมช่วยเสมอ ~',
                      style: TextStyle(fontSize: 11, color: Colors.orange)),
                ],
              ),
            ],
          ),
          backgroundColor: isDark ? Colors.black : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0.5,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ✅ Maffin ใหญ่ + shake animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: _onTapMaffin,
                        child: _buildMaffin(size: 420),
                      ),
                    ),
                  ),
                  if (_showGame)
                    Positioned.fill(
                      child: _buildGameOverlay(),
                    ),
                  if (_showWelcome)
                    Positioned(
                      bottom: 20,
                      left: 24,
                      right: 24,
                      child: AnimatedOpacity(
                        opacity: _showWelcome ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.shade200, width: 1),
                          ),
                          child: Text(
                            'สวัสดี~ เมี้ยว! ฉันชื่อ Maffin 🐾\nจะถามเรื่องเสื้อแมว หรือแฟชั่นอะไรก็ถามได้นะ!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.orange[200]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      ),
                    ),

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    top: _showBotPopup ? 16 : -100,
                    left: 16,
                    right: 16,
                    child: AnimatedOpacity(
                      opacity: _showBotPopup ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isError
                              ? Colors.red.shade50
                              : (isDark ? Colors.grey[800] : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isError
                                ? Colors.red.shade200
                                : Colors.orange.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildMaffin(size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _botPopup,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isError
                                      ? Colors.red.shade700
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  BlocBuilder<ChatbotBloc, ChatbotState>(
                    builder: (context, state) {
                      if (state is! ChatbotLoading)
                        return const SizedBox.shrink();
                      return Positioned(
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.shade200, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange.shade400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Maffin กำลังคิด...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _userText.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16,
                              color:
                                  isDark ? Colors.white54 : Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _userText,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'พิมพ์ข้อความถาม Maffin...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[800] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color:
                                isDark ? Colors.grey[200] : Colors.grey[800]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
