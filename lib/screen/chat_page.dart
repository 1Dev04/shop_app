import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  bool _showWelcome = true;
  bool _isSearching = false;
  bool _isDancing = false;
  bool _showBotPopup = false;
  bool _isTapped = false; // แตะ Maffin

  String _userText = '';
  String _botPopup = '';

  // animation state
  String get _currentAnim {
    if (_isSearching) return 'lib/assets/CatSearch.json';
    if (_isDancing) return 'lib/assets/CatDance.json';
    return 'lib/assets/CatIDle.json';
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showWelcome = false);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_showWelcome) setState(() => _showWelcome = false);

    setState(() {
      _userText = text;
      _showBotPopup = false;
      _botPopup = '';
      _isSearching = true;
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _botPopup = _getBotReply(text);
        _showBotPopup = true;
        _isSearching = false;
      });

      Future.delayed(const Duration(seconds: 7), () {
        if (!mounted) return;
        setState(() {
          _showBotPopup = false;
          _userText = '';
        });
      });
    });
  }

  // ── ตอบตาม keyword ──────────────────────────────────────────
  String _getBotReply(String text) {
    final t = text.toLowerCase();

    if (t.contains('dance') || t.contains('เต้น')) {
      // ✅ trigger dance animation
      setState(() => _isDancing = true);
      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() => _isDancing = false);
      });
      return 'เมี้ยว~ ดูฉันเต้นสิ! 💃🐾🎵';
    }

    if (t.contains('happy') || t.contains('สุข')) {
      return 'เย้~ เมี้ยว! Maffin ดีใจด้วยนะ! 😸🎉';
    }
    if (t.contains('outfit') || t.contains('เสื้อ')) {
      return 'โอ้โห~ มีเสื้อสวยเยอะเลย! ลองดู Meow Size ได้นะ 👕';
    }
    if (t.contains('สวัสดี') || t.contains('hello') || t.contains('hi')) {
      return 'สวัสดี~ เมี้ยว! ยินดีที่ได้รู้จักนะ! 🐱';
    }
    if (t.contains('ราคา') || t.contains('price')) {
      return 'ราคาเสื้อเริ่มต้น ฿259 นะ ลองกดดูที่หน้าหลักได้เลย! 🏷️';
    }
    return 'เมี้ยว~ ได้รับแล้ว! 🐾 ถามเรื่องเสื้อแมวได้นะ!';
  }

  // ── แตะ Maffin → reaction ────────────────────────────────────
  void _onTapMaffin() {
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isTapped = false);
    });

    setState(() {
      _botPopup = _getMaffinReaction();
      _showBotPopup = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showBotPopup = false);
    });
  }

  String _getMaffinReaction() {
    final reactions = [
      'อย่ากดเลย~ เมี้ยว! 😾',
      'จี้ๆ ตัว Maffin อยู่นะ! 🐾',
      'เมี้ยวๆ~ หยิก! 😸',
      'ทำอะไรอยู่เนี่ย! 😹',
      'เมี้ยว! อย่ารบกวนตอน idle สิ~ 😼',
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildMaffin(size: 42),
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
          // ── Maffin กลางหน้า + popup ───────────────────────────
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Maffin ใหญ่ แตะได้
                Center(
                  child: GestureDetector(
                    onTap: _onTapMaffin,
                    child: AnimatedScale(
                      scale: _isTapped ? 0.92 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: _buildMaffin(size: 420),
                    ),
                  ),
                ),

                // welcome text ล่าง Maffin
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
                          color:
                              isDark ? Colors.grey[800] : Colors.orange.shade50,
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

                // bot popup ลอยบน
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
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.orange.shade200, width: 1),
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
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // searching indicator
                if (_isSearching)
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.orange.shade200, width: 1),
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
                  ),
              ],
            ),
          ),

          // ── ข้อความ user ──────────────────────────────────────
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
                            color: isDark ? Colors.white54 : Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _userText,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Input bar ─────────────────────────────────────────
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
                                isDark ? Colors.grey[200] : Colors.grey[800])),
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
    );
  }
}
