import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => GameState(), child: const ShadowChatApp()));
}

// ═══════════════════════════════════════════════════════════════
// THEME & APP
// ═══════════════════════════════════════════════════════════════

class ShadowChatApp extends StatelessWidget {
  const ShadowChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHADOWCHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFFFF3366),
          surface: Color(0xFF12121C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E0E16),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161622),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0C0C14),
          selectedItemColor: Color(0xFF00D4AA),
          unselectedItemColor: Color(0xFF3A3A4A),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerColor: const Color(0xFF1A1A28),
      ),
      home: const AppShell(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// APP SHELL — Main Navigation
// ═══════════════════════════════════════════════════════════════

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (!gs.splashDone) return const SplashScreen();
    if (gs.showingChapterIntro != null) return ChapterIntroScreen(chapterNum: gs.showingChapterIntro!);
    if (gs.activeChatId != null) return ChatScreen(charId: gs.activeChatId!);
    if (gs.activeMiniGame != null) {
      final mg = getMiniGames().firstWhere((g) => g.type == gs.activeMiniGame);
      return MiniGameScreen(game: mg);
    }
    return Scaffold(
      body: IndexedStack(
        index: gs.currentTab,
        children: const [
          ChatsListScreen(),
          EvidenceBoardScreen(),
          CallsScreen(),
          ChaptersScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1A1A28), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: gs.currentTab,
          onTap: (i) => gs.setTab(i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Чаты'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Улики'),
            BottomNavigationBarItem(icon: Icon(Icons.phone_outlined), activeIcon: Icon(Icons.phone), label: 'Звонки'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Сюжет'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPLASH SCREEN — Atmospheric with glitch effect
// ═══════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _glitchCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _glitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _mainCtrl.forward().then((_) {
      if (mounted) {
        context.read<GameState>().finishSplash();
        context.read<GameState>().showChapterIntro(1);
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _glitchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Stack(
        children: [
          // Background particles
          ...List.generate(20, (i) => Positioned(
            left: (i * 47.3) % 360.0,
            top: (i * 73.7) % 700.0,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1 + 0.1 * sin(_pulseCtrl.value * 2 * pi + i)),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          )),
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (ctx, child) {
                final t = _mainCtrl.value;
                final fadeIn = Curves.easeInOut.transform(t < 0.2 ? t / 0.2 : 1.0);
                final scaleIn = 0.7 + 0.3 * Curves.easeOutBack.transform(t < 0.35 ? t / 0.35 : 1.0);
                final fadeOut = t > 0.85 ? (1.0 - t) / 0.15 : 1.0;
                return Opacity(
                  opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
                  child: Transform.scale(scale: scaleIn, child: child),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00D4AA), Color(0xFF0088CC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.15 + 0.1 * _pulseCtrl.value),
                            blurRadius: 40 + 10 * _pulseCtrl.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title with glitch
                  AnimatedBuilder(
                    animation: _glitchCtrl,
                    builder: (_, __) {
                      final offset = _glitchCtrl.value * 2 - 1;
                      return Stack(
                        children: [
                          Text(
                            'SHADOWCHAT',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: const Color(0xFF00D4AA),
                              shadows: [
                                Shadow(color: Colors.red.withOpacity(0.3), offset: Offset(offset, 0), blurRadius: 0),
                                Shadow(color: Colors.cyan.withOpacity(0.3), offset: Offset(-offset, 0), blurRadius: 0),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Неизвестный написал тебе...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A4A5A),
                      letterSpacing: 2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 80),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: const Color(0xFF00D4AA).withOpacity(0.4),
                      backgroundColor: Colors.transparent,
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

// ═══════════════════════════════════════════════════════════════
// CHAPTER INTRO SCREEN
// ═══════════════════════════════════════════════════════════════

class ChapterIntroScreen extends StatefulWidget {
  final int chapterNum;
  const ChapterIntroScreen({super.key, required this.chapterNum});
  @override
  State<ChapterIntroScreen> createState() => _ChapterIntroScreenState();
}

class _ChapterIntroScreenState extends State<ChapterIntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _ctrl.forward().then((_) {
      if (mounted) context.read<GameState>().dismissChapterIntro();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final chapters = getChapters();
    final ch = chapters.firstWhere((c) => c.number == widget.chapterNum);
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, child) {
          final t = _ctrl.value;
          final fadeIn = Curves.easeIn.transform(t < 0.2 ? t / 0.2 : 1.0);
          final fadeOut = t > 0.8 ? (1.0 - t) / 0.2 : 1.0;
          final slideUp = (1.0 - Curves.easeOut.transform((t - 0.15).clamp(0.0, 0.3) / 0.3)).clamp(0.0, 1.0) * 30;
          return Opacity(
            opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: slideUp),
                child: child,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ГЛАВА ${widget.chapterNum}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: Color(0xFF00D4AA),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              child: Text(
                ch.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 260,
              child: Text(
                ch.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6A6A7A),
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHATS LIST SCREEN — WhatsApp-style
// ═══════════════════════════════════════════════════════════════

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final chars = getCharacters();
    final visible = chars.where((c) => !c.isHidden || gs.isCharUnlocked(c.id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHADOWCHAT', style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: Color(0xFF00D4AA),
          letterSpacing: 4,
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1A1A28),
              child: Text('?', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1A1A28), width: 0.5)),
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF12121C)),
          itemBuilder: (ctx, i) {
            final c = visible[i];
            final msgs = getMessagesFor(c.id).where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem).toList();
            final lastMsg = msgs.isNotEmpty ? msgs.last : null;
            final hasNew = msgs.any((m) => !gs.hasSeen(m.id) && m.fromId != 'player');
            return _ChatTile(character: c, lastMsg: lastMsg, hasNew: hasNew, onTap: () => gs.openChat(c.id));
          },
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatCharacter character;
  final ChatMsg? lastMsg;
  final bool hasNew;
  final VoidCallback onTap;

  const _ChatTile({required this.character, required this.lastMsg, required this.hasNew, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF00D4AA).withOpacity(0.05),
      highlightColor: const Color(0xFF00D4AA).withOpacity(0.03),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: character.avatarColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: character.avatarColor.withOpacity(0.2), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      character.avatarEmoji,
                      style: TextStyle(fontSize: 22, color: character.avatarColor),
                    ),
                  ),
                ),
                if (character.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0A0A10), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          style: TextStyle(
                            fontWeight: hasNew ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                            color: hasNew ? Colors.white : const Color(0xFFBBBBCC),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasNew ? const Color(0xFF00D4AA) : const Color(0xFF3A3A4A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasNew)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4AA),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          lastMsg?.text ?? 'Начните расследование...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasNew ? const Color(0xFF8888AA) : const Color(0xFF3A3A4A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHAT SCREEN — Duskwood-style messaging
// ═══════════════════════════════════════════════════════════════

class ChatScreen extends StatefulWidget {
  final String charId;
  const ChatScreen({super.key, required this.charId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMsg> _visibleMsgs = [];
  final ScrollController _scrollCtrl = ScrollController();
  bool _showChoices = false;
  ChatMsg? _pendingChoiceMsg;
  Timer? _msgTimer;
  String _selectedChoiceText = '';

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    _visibleMsgs = getMessagesFor(widget.charId)
        .where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem)
        .toList();
    _scheduleMessages();
  }

  void _scheduleMessages() {
    final gs = context.read<GameState>();
    _msgTimer?.cancel();
    int delay = 400;
    for (final msg in _visibleMsgs) {
      final d = delay;
      delay += (msg.delayMs > 0 ? msg.delayMs : 800);
      if (msg.fromId != 'player' && !gs.hasSeen(msg.id)) {
        Future.delayed(Duration(milliseconds: d), () {
          if (!mounted) return;
          gs.setTyping(true);
          Future.delayed(Duration(milliseconds: 1200 + Random().nextInt(800)), () {
            if (!mounted) return;
            gs.setTyping(false);
            gs.markSeen(msg.id);
            _processSystemFor(msg, gs);
            setState(() {});
            _scrollToBottom();
            _checkForChoices(gs);
          });
        });
      }
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _checkForChoices(gs);
    });
  }

  void _processSystemFor(ChatMsg msg, GameState gs) {
    final allMsgs = getMessagesFor(widget.charId);
    final idx = allMsgs.indexOf(msg);
    for (int i = 0; i <= idx; i++) {
      final m = allMsgs[i];
      if (m.isSystem && m.chapter <= gs.maxUnlockedChapter) {
        if (m.text.startsWith('CONTACT_UNLOCK:')) {
          gs.unlockChar(m.text.split(':')[1]);
        } else if (m.text.startsWith('EVIDENCE:')) {
          gs.addEvidence(m.text.split(':')[1]);
        }
      }
    }
  }

  void _checkForChoices(GameState gs) {
    for (final msg in _visibleMsgs) {
      if (msg.playerChoices != null && msg.fromId == 'player' && !gs.hasSeen('choice_${msg.id}') && gs.hasSeen(_getPrevMsgId(msg))) {
        if (mounted) setState(() { _showChoices = true; _pendingChoiceMsg = msg; });
        return;
      }
    }
  }

  String _getPrevMsgId(ChatMsg msg) {
    final all = getMessagesFor(widget.charId);
    final idx = all.indexOf(msg);
    if (idx > 0) return all[idx - 1].id;
    return '';
  }

  void _onChoiceTap(String choice) {
    final gs = context.read<GameState>();
    gs.markSeen('choice_${_pendingChoiceMsg!.id}');
    gs.markSeen(_pendingChoiceMsg!.id);
    setState(() {
      _selectedChoiceText = choice;
      _showChoices = false;
      _pendingChoiceMsg = null;
    });
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _visibleMsgs = getMessagesFor(widget.charId)
            .where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem)
            .toList();
      });
      _scheduleMessages();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final char = getCharacters().firstWhere((c) => c.id == widget.charId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => gs.closeChat(),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: char.avatarColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: char.avatarColor.withOpacity(0.2), width: 0.5),
              ),
              child: Center(
                child: Text(char.avatarEmoji, style: TextStyle(fontSize: 15, color: char.avatarColor)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(char.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2)),
                Text(
                  char.isOnline ? 'в сети' : 'был(а) недавно',
                  style: TextStyle(
                    fontSize: 11,
                    color: char.isOnline ? const Color(0xFF00D4AA) : const Color(0xFF4A4A5A),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 20, color: Color(0xFF5A5A6A)),
            onPressed: () => _makeCall(char),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF5A5A6A)),
            onPressed: () => _showProfile(char),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A10),
        ),
        child: Column(
          children: [
            Expanded(
              child: gs.isTyping
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TypingIndicator(charColor: char.avatarColor),
                          const SizedBox(height: 16),
                          const Text(
                            'печатает',
                            style: TextStyle(color: Color(0xFF4A4A5A), fontSize: 12, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: _visibleMsgs.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return const SizedBox(height: 8);
                        final msg = _visibleMsgs[i - 1];
                        if (!gs.hasSeen(msg.id) && msg.fromId != 'player') {
                          return const SizedBox.shrink();
                        }
                        if (msg.fromId == 'player') {
                          if (msg.playerChoices != null && !gs.hasSeen('choice_${msg.id}')) {
                            return const SizedBox.shrink();
                          }
                          if (msg.playerChoices != null && gs.hasSeen('choice_${msg.id}')) {
                            return _MessageBubble(
                              msg: ChatMsg(
                                id: msg.id,
                                fromId: 'player',
                                text: _selectedChoiceText,
                                chapter: msg.chapter,
                              ),
                              character: char,
                              gs: gs,
                            );
                          }
                        }
                        return _MessageBubble(msg: msg, character: char, gs: gs);
                      },
                    ),
            ),
            if (_showChoices && _pendingChoiceMsg != null)
              _ChoicePanel(choices: _pendingChoiceMsg!.playerChoices!, onTap: _onChoiceTap),
          ],
        ),
      ),
    );
  }

  void _makeCall(ChatCharacter char) {
    final gs = context.read<GameState>();
    final call = getPhoneCalls().where((c) => c.callerId == char.id && c.chapter <= gs.maxUnlockedChapter).lastOrNull;
    if (call == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нет звонков от ${char.name}'),
          backgroundColor: const Color(0xFF1A1A28),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char)));
  }

  void _showProfile(ChatCharacter char) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E16),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileSheet(character: char),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TYPING INDICATOR — Animated dots
// ═══════════════════════════════════════════════════════════════

class TypingIndicator extends StatefulWidget {
  final Color charColor;
  const TypingIndicator({super.key, required this.charColor});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final delay = i * 0.2;
              final t = (_ctrl.value - delay) % 1.0;
              final scale = 0.6 + 0.4 * sin(t * pi * 2);
              final opacity = 0.3 + 0.7 * sin(t * pi * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: scale.clamp(0.5, 1.2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.charColor.withOpacity(opacity.clamp(0.2, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MESSAGE BUBBLE — Polished
// ═══════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMsg msg;
  final ChatCharacter character;
  final GameState gs;

  const _MessageBubble({required this.msg, required this.character, required this.gs});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.fromId == 'player';
    final hour = 22 + (msg.chapter - 1);
    final minute = 15 + (msg.id.hashCode % 45);
    final timeLabel = '${hour.clamp(0, 23)}:${minute.toString().padLeft(2, '0')}';

    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161622).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Сообщение удалено',
              style: TextStyle(color: Color(0xFF3A3A4A), fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: EdgeInsets.only(
            left: isMe ? 40 : 4,
            right: isMe ? 4 : 40,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: msg.imageUrl != null || msg.voiceNoteText != null ? 8 : 4,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00D4AA).withOpacity(0.18),
                            const Color(0xFF0088CC).withOpacity(0.12),
                          ],
                        )
                      : null,
                  color: isMe ? null : const Color(0xFF161622),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe
                      ? Border.all(color: const Color(0xFF00D4AA).withOpacity(0.1), width: 0.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imageUrl != null) ...[
                      _buildImage(msg.imageUrl!),
                      if (msg.text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (msg.voiceNoteText != null) ...[
                      _buildVoiceNote(msg.voiceNoteText!),
                      if (msg.text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (msg.text.isNotEmpty)
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isMe ? const Color(0xFFCCFFE8) : const Color(0xFFDDDDEE),
                          height: 1.4,
                          letterSpacing: 0.1,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          timeLabel,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF4A4A5A)),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.done_all, size: 14, color: const Color(0xFF00D4AA).withOpacity(0.6)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    final configs = {
      'tax_docs': const _ImgConfig(
        icon: Icons.description_outlined,
        gradient: [Color(0xFF1A237E), Color(0xFF0D0D1A)],
        label: 'Налоговые документы "Уголёк"',
        sublabel: 'Фотокопия • 2 страницы',
      ),
      'cafe_night': const _ImgConfig(
        icon: Icons.night_shelter,
        gradient: [Color(0xFF1A1A2E), Color(0xFF000000)],
        label: 'Кафе "Уголёк". 23:00',
        sublabel: 'Свет в офисе Виктора',
      ),
      'smirnov_threat': const _ImgConfig(
        icon: Icons.mic_outlined,
        gradient: [Color(0xFF2A0A0A), Color(0xFF0D0D0D)],
        label: 'Запись разговора',
        sublabel: 'Аудиофайл • 28 сек',
      ),
      'ally_view': const _ImgConfig(
        icon: Icons.location_city,
        gradient: [Color(0xFF0D1B0D), Color(0xFF050505)],
        label: 'Вид из окна Наташи',
        sublabel: 'Переулок за кафе',
      ),
    };
    final cfg = configs[url] ?? _ImgConfig(
      icon: Icons.image_outlined,
      gradient: const [Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
      label: url,
      sublabel: '',
    );

    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cfg.gradient),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
      ),
      child: Stack(
        children: [
          // Decorative grid overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Center(
            child: Icon(cfg.icon, size: 52, color: Colors.white.withOpacity(0.08)),
          ),
          // Photo frame corners
          Positioned(top: 8, left: 8, child: _corner(true, true)),
          Positioned(top: 8, right: 8, child: _corner(true, false)),
          Positioned(bottom: 8, left: 8, child: _corner(false, true)),
          Positioned(bottom: 8, right: 8, child: _corner(false, false)),
          // Label
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cfg.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (cfg.sublabel.isNotEmpty)
                    Text(cfg.sublabel, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(bool top, bool left) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF00D4AA), width: 1.5) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF00D4AA), width: 1.5) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF00D4AA), width: 1.5) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF00D4AA), width: 1.5) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildVoiceNote(String text) {
    final secs = text.length * 2;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Color(0xFF00D4AA), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 16,
                  child: CustomPaint(
                    painter: _WaveformPainter(),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '0:${secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4A4A5A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImgConfig {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String sublabel;
  const _ImgConfig({required this.icon, required this.gradient, required this.label, required this.sublabel});
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00D4AA)..strokeWidth = 1.5;
    final path = Path();
    final rng = Random(42);
    for (double x = 0; x < size.width; x += 3) {
      final h = (rng.nextDouble() * 0.7 + 0.3) * size.height;
      final y = (size.height - h) / 2;
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      path.lineTo(x, y + h);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// CHOICE PANEL — Response options
// ═══════════════════════════════════════════════════════════════

class _ChoicePanel extends StatelessWidget {
  final List<String> choices;
  final Function(String) onTap;

  _ChoicePanel({required this.choices, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C14),
        border: Border(top: BorderSide(color: Color(0xFF1A1A28), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.reply, size: 14, color: const Color(0xFF00D4AA).withOpacity(0.5)),
                const SizedBox(width: 6),
                const Text(
                  'Выберите ответ',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A4A5A), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          ...choices.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(c),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161622),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2A38), width: 0.5),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCEE), height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

class _ProfileSheet extends StatelessWidget {
  final ChatCharacter character;
  const _ProfileSheet({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF3A3A4A), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: character.avatarColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: character.avatarColor.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: character.avatarColor.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Center(
              child: Text(character.avatarEmoji, style: TextStyle(fontSize: 34, color: character.avatarColor)),
            ),
          ),
          const SizedBox(height: 16),
          Text(character.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(character.phone, style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A6A))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: character.isOnline ? const Color(0xFF00D4AA).withOpacity(0.1) : const Color(0xFF1A1A28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              character.isOnline ? 'В сети' : 'Не в сети',
              style: TextStyle(
                fontSize: 11,
                color: character.isOnline ? const Color(0xFF00D4AA) : const Color(0xFF4A4A5A),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              character.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8888AA), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: const Color(0xFF050508),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Закрыть', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EVIDENCE BOARD — Card grid
// ═══════════════════════════════════════════════════════════════

class EvidenceBoardScreen extends StatelessWidget {
  const EvidenceBoardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final all = getEvidenceItems();
    final found = all.where((e) => e.chapterFound <= gs.maxUnlockedChapter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доска улик', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Progress header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00D4AA).withOpacity(0.08),
                    const Color(0xFF0088CC).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fingerprint, color: Color(0xFF00D4AA), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Собрано улик', style: TextStyle(color: Color(0xFF5A5A6A), fontSize: 12, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          '${found.length} из ${all.length}',
                          style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: all.isEmpty ? 0 : found.length / all.length,
                          strokeWidth: 4,
                          backgroundColor: const Color(0xFF1A1A28),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
                        ),
                        Center(
                          child: Text(
                            '${all.isEmpty ? 0 : (found.length * 100 ~/ all.length)}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00D4AA)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Evidence cards
          if (found.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Color(0xFF2A2A38)),
                      SizedBox(height: 16),
                      Text('Улики пока не найдены', style: TextStyle(color: Color(0xFF3A3A4A), fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Продолжайте расследование', style: TextStyle(color: Color(0xFF2A2A38), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final ev = found[i];
                return _EvidenceCard(evidence: ev);
              }, childCount: found.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final Evidence evidence;
  const _EvidenceCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'ev_tax_docs': const Color(0xFF2196F3),
      'ev_cafe_night': const Color(0xFF9C27B0),
      'ev_smirnov': const Color(0xFFFF3366),
      'ev_scream': const Color(0xFFFF9800),
      'ev_victor_threat': const Color(0xFFF44336),
      'ev_kira_msg': const Color(0xFF00D4AA),
    };
    final cardColor = colors[evidence.id] ?? const Color(0xFFFF9800);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.15), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(evidence.icon, color: cardColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              evidence.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              evidence.description,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6A6A7A), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Глава ${evidence.chapterFound}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF4A4A5A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CALLS SCREEN
// ═══════════════════════════════════════════════════════════════

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final calls = getPhoneCalls().where((c) => c.chapter <= gs.maxUnlockedChapter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Звонки', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: calls.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_disabled, size: 48, color: Color(0xFF2A2A38)),
                  SizedBox(height: 16),
                  Text('Пока нет звонков', style: TextStyle(color: Color(0xFF3A3A4A), fontSize: 14)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF12121C)),
              itemCount: calls.length,
              itemBuilder: (ctx, i) {
                final call = calls[i];
                final char = getCharacters().firstWhere((c) => c.id == call.callerId);
                return InkWell(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: char.avatarColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(child: Text(char.avatarEmoji, style: TextStyle(color: char.avatarColor, fontSize: 18))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(char.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                '${call.durationSec} сек • Глава ${call.chapter}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5A6A)),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          call.isIncoming ? Icons.call_received : Icons.call_made,
                          color: const Color(0xFF00D4AA),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CALL SCREEN — Improved
// ═══════════════════════════════════════════════════════════════

class CallScreen extends StatefulWidget {
  final PhoneCall call;
  final ChatCharacter character;
  const CallScreen({super.key, required this.call, required this.character});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) { _timer?.cancel(); return; }
        setState(() {
          _progress += 0.1 / widget.call.durationSec;
          if (_progress >= 1.0) { _progress = 1.0; _isPlaying = false; _timer?.cancel(); }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060609),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with pulse
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.character.avatarColor.withOpacity(0.08 + 0.04 * _pulseCtrl.value),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: widget.character.avatarColor.withOpacity(0.15 + 0.1 * _pulseCtrl.value),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.character.avatarColor.withOpacity(0.08 * _pulseCtrl.value),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.character.avatarEmoji,
                      style: TextStyle(fontSize: 48, color: widget.character.avatarColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(widget.character.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.call.isIncoming
                      ? const Color(0xFF00D4AA).withOpacity(0.1)
                      : const Color(0xFF1A1A28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.call.isIncoming ? 'Входящий звонок' : 'Исходящий звонок',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.call.isIncoming ? const Color(0xFF00D4AA) : const Color(0xFF5A5A6A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${widget.call.durationSec} сек', style: const TextStyle(color: Color(0xFF3A3A4A), fontSize: 12)),
              const SizedBox(height: 40),
              // Transcript
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1A1A28), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.transcribe, size: 16, color: Color(0xFF5A5A6A)),
                        const SizedBox(width: 8),
                        const Text('Транскрипция', style: TextStyle(fontSize: 12, color: Color(0xFF5A5A6A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.call.transcript,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFFAAAACC), height: 1.6, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color(0xFF1A1A28),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 56,
                  color: const Color(0xFF00D4AA),
                ),
                onPressed: _togglePlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHAPTERS SCREEN — Story progress
// ═══════════════════════════════════════════════════════════════

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final chapters = getChapters();
    return Scaffold(
      appBar: AppBar(title: const Text('Сюжет', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chapters.length,
        itemBuilder: (ctx, i) {
          final ch = chapters[i];
          final unlocked = ch.number <= gs.maxUnlockedChapter;
          final current = ch.number == gs.currentChapter;
          final completed = ch.number < gs.maxUnlockedChapter;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: unlocked ? const Color(0xFF161622) : const Color(0xFF0E0E16),
                borderRadius: BorderRadius.circular(16),
                border: current ? Border.all(color: const Color(0xFF00D4AA), width: 1.5) : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: unlocked ? () => _openChapter(ctx, ch, gs) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Chapter number
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: completed
                                ? const Color(0xFF00D4AA)
                                : (current ? const Color(0xFF00D4AA).withOpacity(0.15) : const Color(0xFF1A1A28)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: completed
                                ? const Icon(Icons.check, color: Color(0xFF050508), size: 22)
                                : Text(
                                    '${ch.number}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: unlocked ? const Color(0xFF00D4AA) : const Color(0xFF3A3A4A),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ch.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: unlocked ? Colors.white : const Color(0xFF3A3A4A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ch.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unlocked ? const Color(0xFF6A6A7A) : const Color(0xFF2A2A38),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!unlocked)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock, color: Color(0xFF2A2A38), size: 16),
                          )
                        else if (current)
                          const Icon(Icons.chevron_right, color: Color(0xFF00D4AA), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openChapter(BuildContext ctx, ChapterInfo ch, GameState gs) {
    if (ch.characterUnlock != null) gs.unlockChar(ch.characterUnlock!);
    if (ch.number == gs.maxUnlockedChapter) gs.advanceChapter(ch.number);
    final charMap = {1: 'unknown', 2: 'darya', 3: 'unknown', 4: 'victor', 5: 'natasha', 6: 'andrey', 7: 'unknown', 8: 'kira', 9: 'max', 10: 'unknown'};
    final targetChar = charMap[ch.number] ?? 'unknown';
    gs.showChapterIntro(ch.number);
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI-GAMES SCREEN
// ═══════════════════════════════════════════════════════════════

class MiniGameScreen extends StatefulWidget {
  final MiniGameData game;
  const MiniGameScreen({super.key, required this.game});
  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  String? _result;
  bool _solved = false;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => gs.closeMiniGame(),
        ),
        title: Text(widget.game.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Instruction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF00D4AA), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.game.instruction,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFAAAACC), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildGameContent()),
            if (_result != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _solved ? const Color(0xFF00D4AA).withOpacity(0.1) : const Color(0xFFFF3366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _solved ? const Color(0xFF00D4AA).withOpacity(0.3) : const Color(0xFFFF3366).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    fontSize: 14,
                    color: _solved ? const Color(0xFF00D4AA) : const Color(0xFFFF3366),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (widget.game.type) {
      case 'cipher':
        return _buildCipher();
      case 'logic':
        return _buildTimeline();
      case 'final_choice':
        return _buildFinalChoice();
      default:
        return const Center(child: Text('Мини-игра в разработке', style: TextStyle(color: Color(0xFF4A4A5A))));
    }
  }

  Widget _buildCipher() {
    final encrypted = widget.game.data['encrypted'] as String;
    final answer = widget.game.data['answer'] as String;
    final shift = widget.game.data['shift'] as int;
    final controller = TextEditingController();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A38)),
          ),
          child: Column(
            children: [
              const Text('Зашифрованное сообщение', style: TextStyle(fontSize: 12, color: Color(0xFF5A5A6A))),
              const SizedBox(height: 8),
              Text(encrypted, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4, color: Color(0xFFFF9800))),
              const SizedBox(height: 8),
              Text('Шифр Цезаря, сдвиг: $shift', style: const TextStyle(fontSize: 11, color: Color(0xFF4A4A5A))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Введите расшифровку...',
            hintStyle: const TextStyle(color: Color(0xFF3A3A4A)),
            filled: true,
            fillColor: const Color(0xFF161622),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2A2A38)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2A2A38)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == answer.toUpperCase()) {
                setState(() {
                  _solved = true;
                  _result = 'Верно! Номер машины расшифрован.';
                });
              } else {
                setState(() {
                  _solved = false;
                  _result = 'Неверно. Попробуйте ещё раз.';
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: const Color(0xFF050508),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Проверить', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final events = List<String>.from(widget.game.data['events'] as List);
    events.shuffle(Random(42));
    final order = List<int>.generate(events.length, (i) => i);
    return Column(
      children: [
        const Text('Расставьте события в правильном порядке', style: TextStyle(color: Color(0xFF6A6A7A), fontSize: 12)),
        const SizedBox(height: 12),
        ...List.generate(events.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A38), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(events[i], style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCEE), height: 1.3)),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _solved = true;
                _result = 'Хронология восстановлена! События происходили именно в этом порядке.';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: const Color(0xFF050508),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Подтвердить порядок', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalChoice() {
    final options = List<String>.from(widget.game.data['options'] as List);
    final correct = widget.game.data['correct'] as String;
    final explanation = widget.game.data['explanation'] as String;

    return Column(
      children: [
        const Icon(Icons.gavel, size: 48, color: Color(0xFFFF3366)),
        const SizedBox(height: 16),
        const Text('Кто виновен?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Выберите на основе собранных улик', style: TextStyle(color: Color(0xFF6A6A7A), fontSize: 12)),
        const SizedBox(height: 24),
        ...options.map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (opt == correct) {
                  setState(() {
                    _solved = true;
                    _result = 'Верно! $explanation';
                  });
                } else {
                  setState(() {
                    _solved = false;
                    _result = 'Неверно. Пересмотрите улики и подумайте ещё раз.';
                  });
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A38), width: 0.5),
                ),
                child: Text(opt, style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCEE), fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        )),
      ],
    );
  }
}
