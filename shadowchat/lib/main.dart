import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => GameState(), child: const ShadowChatApp()));
}

// ═══════════════════════════════════════════
// TELEGRAM DARK THEME
// ═══════════════════════════════════════════

const _bg = Color(0xFF17212B);
const _surface = Color(0xFF182533);
const _outBubble = Color(0xFF2B5278);
const _accent = Color(0xFF64B5F6);
const _green = Color(0xFF4DCD5E);
const _text1 = Color(0xFFFFFFFF);
const _text2 = Color(0xFF6C7883);
const _text3 = Color(0xFF546E7A);
const _divider = Color(0xFF0F1921);
const _header = Color(0xFF17212B);
const _inputBg = Color(0xFF182533);
const _unreadBadge = Color(0xFF64B5F6);

class ShadowChatApp extends StatelessWidget {
  const ShadowChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        primaryColor: _accent,
        appBarTheme: const AppBarTheme(backgroundColor: _header, foregroundColor: _text1, elevation: 0),
        cardColor: _surface,
        dividerColor: _divider,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
          onPrimary: _text1,
          secondary: _text2,
        ),
        iconTheme: const IconThemeData(color: _accent),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _text1, fontSize: 15),
          bodySmall: TextStyle(color: _text2, fontSize: 13),
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ═══════════════════════════════════════════
// APP SHELL
// ═══════════════════════════════════════════

class AppShell extends StatelessWidget {
  const AppShell({super.key});
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
      bottomNavigationBar: _TGBottomNav(currentIndex: gs.currentTab, onTap: (i) => gs.setTab(i)),
    );
  }
}

// ═══════════════════════════════════════════
// SPLASH — Telegram style
// ═══════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _ctrl.forward().then((_) {
      if (mounted) {
        context.read<GameState>().finishSplash();
        context.read<GameState>().showChapterIntro(1);
      }
    });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final t = Curves.easeOut.transform(_ctrl.value.clamp(0, 1));
            final fadeOut = _ctrl.value > 0.85 ? 1 - (_ctrl.value - 0.85) / 0.15 : 1.0;
            return Opacity(opacity: fadeOut, child: Transform.scale(scale: 0.8 + 0.2 * t, child: child));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.send_rounded, size: 42, color: _accent),
              ),
              const SizedBox(height: 24),
              const Text('ShadowChat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _text1, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              const Text('Неизвестный написал вам', style: TextStyle(fontSize: 13, color: _text2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CHAPTER INTRO
// ═══════════════════════════════════════════

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _ctrl.forward().then((_) { if (mounted) context.read<GameState>().dismissChapterIntro(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ch = getChapters().firstWhere((c) => c.number == widget.chapterNum);
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final fi = Curves.easeIn.transform((_ctrl.value / 0.2).clamp(0, 1));
          final fo = _ctrl.value > 0.75 ? 1 - (_ctrl.value - 0.75) / 0.25 : 1.0;
          return Opacity(
            opacity: (fi * fo).clamp(0, 1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                    child: Text('ГЛАВА ${widget.chapterNum}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent, letterSpacing: 3)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(ch.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _text1, height: 1.2)),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(ch.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _text2, height: 1.5)),
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

// ═══════════════════════════════════════════
// BOTTOM NAVIGATION — Telegram style
// ═══════════════════════════════════════════

class _TGBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _TGBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labels = ['Чаты', 'Улики', 'Звонки', 'Ещё'];
    final icons = [Icons.chat_bubble_outline, Icons.fact_check, Icons.phone_outlined, Icons.more_horiz];
    return Container(
      decoration: const BoxDecoration(color: _header, border: Border(top: BorderSide(color: _divider, width: 0.5))),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(4, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[i], size: 22, color: active ? _accent : _text2),
                        const SizedBox(height: 2),
                        Text(labels[i], style: TextStyle(fontSize: 10, color: active ? _accent : _text2, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CHAT LIST — Telegram style
// ═══════════════════════════════════════════

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final chars = getCharacters();
    final visible = chars.where((c) => !c.isHidden || gs.isCharUnlocked(c.id)).toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: _TGSearchField()),
              const SizedBox(width: 8),
              _TGHamburgerButton(),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: visible.length,
        itemBuilder: (ctx, i) {
          final c = visible[i];
          final msgs = getMessagesFor(c.id).where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem).toList();
          final last = msgs.isNotEmpty ? msgs.last : null;
          final hasNew = msgs.any((m) => !gs.hasSeen(m.id) && m.fromId != 'player');
          final unreadCount = msgs.where((m) => !gs.hasSeen(m.id) && m.fromId != 'player').length;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => gs.openChat(c.id),
              child: Column(
                children: [
                  _TGChatListItem(character: c, lastMsg: last, hasNew: hasNew, unreadCount: unreadCount),
                  const Divider(height: 1, color: _divider, indent: 76, endIndent: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TGSearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: const [
          SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: _text2),
          SizedBox(width: 8),
          Text('Поиск', style: TextStyle(fontSize: 15, color: _text2)),
        ],
      ),
    );
  }
}

class _TGHamburgerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(22)),
      child: const Icon(Icons.menu, size: 20, color: _text1),
    );
  }
}

class _TGChatListItem extends StatelessWidget {
  final ChatCharacter character;
  final ChatMsg? lastMsg;
  final bool hasNew;
  final int unreadCount;

  const _TGChatListItem({required this.character, required this.lastMsg, required this.hasNew, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              _TGAvatar(emoji: character.avatarEmoji, color: character.avatarColor),
              if (character.isOnline)
                Positioned(right: 1, bottom: 1,
                  child: Container(width: 14, height: 14,
                    decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                    child: Center(
                      child: Container(width: 10, height: 10,
                        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: Name + Time
                Row(
                  children: [
                    Expanded(
                      child: Text(character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hasNew ? _text1 : _text1)),
                    ),
                    Text(timeStr, style: TextStyle(fontSize: 12, color: hasNew ? _accent : _text3)),
                  ],
                ),
                const SizedBox(height: 2),
                // Row: Message preview + Badge
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (lastMsg != null && lastMsg!.fromId == 'player')
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.done_all, size: 14, color: hasNew ? _accent : _text3),
                            ),
                          Expanded(
                            child: Text(
                              lastMsg?.text ?? 'Начните расследование...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: hasNew ? _text1 : _text2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasNew && unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: _unreadBadge, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('$unreadCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TG AVATAR
// ═══════════════════════════════════════════

class _TGAvatar extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;

  const _TGAvatar({required this.emoji, required this.color, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: _surface, shape: BoxShape.circle),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.38, color: color))),
    );
  }
}

// ═══════════════════════════════════════════
// CHAT SCREEN — Telegram style
// ═══════════════════════════════════════════

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
    _loadMessages();
  }

  void _loadMessages() {
    final gs = context.read<GameState>();
    _visibleMsgs = getMessagesFor(widget.charId)
        .where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem)
        .toList();
    _scheduleMessages();
  }

  void _scheduleMessages() {
    final gs = context.read<GameState>();
    _msgTimer?.cancel();
    int delay = 300;
    for (final msg in _visibleMsgs) {
      final d = delay;
      delay += (msg.delayMs > 0 ? msg.delayMs : 900);
      if (msg.fromId != 'player' && !gs.hasSeen(msg.id)) {
        Future.delayed(Duration(milliseconds: d), () {
          if (!mounted) return;
          gs.setTyping(true);
          Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(600)), () {
            if (!mounted) return;
            gs.setTyping(false);
            gs.markSeen(msg.id);
            _processSystemFor(msg, gs);
            setState(() {});
            _scrollBottom();
            _checkChoices(gs);
          });
        });
      }
    }
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _checkChoices(gs); });
  }

  void _processSystemFor(ChatMsg msg, GameState gs) {
    final all = getMessagesFor(widget.charId);
    final idx = all.indexOf(msg);
    for (int i = 0; i <= idx; i++) {
      final m = all[i];
      if (m.isSystem && m.chapter <= gs.maxUnlockedChapter) {
        if (m.text.startsWith('CONTACT_UNLOCK:')) gs.unlockChar(m.text.split(':')[1]);
        else if (m.text.startsWith('EVIDENCE:')) gs.addEvidence(m.text.split(':')[1]);
      }
    }
  }

  void _checkChoices(GameState gs) {
    for (final msg in _visibleMsgs) {
      if (msg.playerChoices != null && msg.fromId == 'player' && !gs.hasSeen('choice_${msg.id}') && gs.hasSeen(_prevId(msg))) {
        if (mounted) setState(() { _showChoices = true; _pendingChoiceMsg = msg; });
        return;
      }
    }
  }

  String _prevId(ChatMsg msg) {
    final all = getMessagesFor(widget.charId);
    final idx = all.indexOf(msg);
    return idx > 0 ? all[idx - 1].id : '';
  }

  void _onChoiceTap(String choice) {
    final gs = context.read<GameState>();
    gs.markSeen('choice_${_pendingChoiceMsg!.id}');
    gs.markSeen(_pendingChoiceMsg!.id);
    setState(() { _selectedChoiceText = choice; _showChoices = false; _pendingChoiceMsg = null; });
    _scrollBottom();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() { _visibleMsgs = getMessagesFor(widget.charId).where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem).toList(); });
      _scheduleMessages();
    });
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _msgTimer?.cancel(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final char = getCharacters().firstWhere((c) => c.id == widget.charId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 22), onPressed: () => gs.closeChat()),
        titleSpacing: 4,
        title: InkWell(
          onTap: () => _showProfile(char),
          child: Row(
            children: [
              _TGAvatar(emoji: char.avatarEmoji, color: char.avatarColor, size: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(char.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2)),
                  if (gs.isTyping)
                    const Text('печатает...', style: TextStyle(fontSize: 12, color: _accent, height: 1.2))
                  else
                    Text(char.isOnline ? 'в сети' : 'был(а) недавно', style: TextStyle(fontSize: 12, color: char.isOnline ? _green : _text2, height: 1.2)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined, size: 21), onPressed: () => _makeCall(char)),
          IconButton(icon: const Icon(Icons.more_vert, size: 21), onPressed: () => _showProfile(char)),
        ],
      ),
      body: Container(
        color: const Color(0xFF0E1621),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: _visibleMsgs.length,
                itemBuilder: (ctx, i) {
                  final msg = _visibleMsgs[i];
                  if (!gs.hasSeen(msg.id) && msg.fromId != 'player') return const SizedBox.shrink();
                  if (msg.fromId == 'player' && msg.playerChoices != null && !gs.hasSeen('choice_${msg.id}')) return const SizedBox.shrink();
                  if (msg.fromId == 'player' && msg.playerChoices != null && gs.hasSeen('choice_${msg.id}')) {
                    return _TGBubble(msg: ChatMsg(id: msg.id, fromId: 'player', text: _selectedChoiceText, chapter: msg.chapter), charColor: char.avatarColor);
                  }
                  return _TGBubble(msg: msg, charColor: char.avatarColor);
                },
              ),
            ),
            if (_showChoices && _pendingChoiceMsg != null)
              _TGChoicePanel(choices: _pendingChoiceMsg!.playerChoices!, onTap: _onChoiceTap),
          ],
        ),
      ),
    );
  }

  void _makeCall(ChatCharacter char) {
    final gs = context.read<GameState>();
    final call = getPhoneCalls().where((c) => c.callerId == char.id && c.chapter <= gs.maxUnlockedChapter).lastOrNull;
    if (call == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Нет доступных звонков'), backgroundColor: _surface,
        behavior: SnackBarBehavior.floating, shape: StadiumBorder(),
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char)));
  }

  void _showProfile(ChatCharacter char) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _TGProfileSheet(character: char),
    );
  }
}

// ═══════════════════════════════════════════
// WALLPAPER PATTERN
// ═══════════════════════════════════════════

class _WallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF131C26);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    final p2 = Paint()..color = const Color(0xFF0E1621);
    for (int x = 0; x < size.width; x += 40) {
      for (int y = 0; y < size.height; y += 40) {
        canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, 38, 38), p2);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// TG MESSAGE BUBBLE — Pixel perfect Telegram
// ═══════════════════════════════════════════

class _TGBubble extends StatelessWidget {
  final ChatMsg msg;
  final Color charColor;

  const _TGBubble({required this.msg, required this.charColor});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.fromId == 'player';
    final hour = (22 + msg.chapter - 1).clamp(0, 23);
    final minute = 15 + (msg.id.hashCode % 45);
    final time = '$hour:${minute.toString().padLeft(2, '0')}';

    if (msg.isDeleted) {
      return Padding(
        padding: EdgeInsets.only(
          left: isMe ? 48 : 8, right: isMe ? 8 : 48, top: 1, bottom: 1,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text('Сообщение удалено', style: TextStyle(color: _text2, fontStyle: FontStyle.italic, fontSize: 14)),
          ),
        ),
      );
    }

    // Check if this message has an image or voice
    final hasMedia = msg.imageUrl != null || msg.voiceNoteText != null;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 8, right: isMe ? 8 : 64, top: 1, bottom: 1,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: CustomPaint(
          painter: _BubblePainter(isMe: isMe),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75 - 40),
            padding: EdgeInsets.fromLTRB(
              isMe ? 12 : 10,
              hasMedia ? 4 : 7,
              isMe ? 8 : 10,
              hasMedia ? 4 : 7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (msg.imageUrl != null) ...[
                  _TGPhotoBlock(imageUrl: msg.imageUrl!),
                  if (msg.text.isNotEmpty) const SizedBox(height: 4),
                ],
                // Voice
                if (msg.voiceNoteText != null) ...[
                  _TGVoiceBlock(),
                  if (msg.text.isNotEmpty) const SizedBox(height: 4),
                ],
                // Text
                if (msg.text.isNotEmpty)
                  Text(msg.text, style: const TextStyle(fontSize: 15, color: _text1, height: 1.35)),
                // Time + checks
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(time, style: TextStyle(fontSize: 11, color: isMe ? const Color(0xFF8EACBB) : _text2)),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF4FAE4E)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// BUBBLE PAINTER — Telegram bubble shape
// ═══════════════════════════════════════════

class _BubblePainter extends CustomPainter {
  final bool isMe;
  const _BubblePainter({required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isMe ? _outBubble : _surface;
    final r = 12.0;
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (isMe) {
      // Outgoing: tail bottom-right
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
      path.lineTo(w, h - r - 6);
      path.quadraticBezierTo(w, h - 2, w - 6, h - 2);
      path.lineTo(w - 10, h);
      path.quadraticBezierTo(w - 2, h - 2, w - 2, h - r);
      path.lineTo(w - r, h);
      path.arcToPoint(Offset(w - r - r, h), radius: Radius.circular(r), clockwise: false);
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    } else {
      // Incoming: tail bottom-left
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
      path.lineTo(w, h - r);
      path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
      path.lineTo(r + 2, h);
      path.arcToPoint(Offset(2, h - r), radius: Radius.circular(r));
      path.lineTo(2, h - r);
      path.quadraticBezierTo(2, h - 2, 10, h);
      path.lineTo(6, h - 2);
      path.quadraticBezierTo(0, h - 2, 0, h - r - 6);
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// TG PHOTO BLOCK
// ═══════════════════════════════════════════

class _TGPhotoBlock extends StatelessWidget {
  final String imageUrl;
  const _TGPhotoBlock({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.image_outlined;
    String label = imageUrl;
    if (imageUrl == 'tax_docs') { icon = Icons.description_outlined; label = 'Налоговые документы "Уголёк"'; }
    else if (imageUrl == 'cafe_night') { icon = Icons.night_shelter; label = 'Кафе "Уголёк". 23:00'; }
    else if (imageUrl == 'smirnov_threat') { icon = Icons.mic_outlined; label = 'Запись разговора'; }
    else if (imageUrl == 'ally_view') { icon = Icons.location_city; label = 'Вид из окна Наташи'; }
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2836),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Icon(icon, size: 40, color: _text2.withOpacity(0.3))),
          Positioned(
            left: 8, right: 8, bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TG VOICE BLOCK
// ═══════════════════════════════════════════

class _TGVoiceBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_filled, size: 36, color: _accent),
          const SizedBox(width: 8),
          SizedBox(width: 180, height: 24, child: _TGWaveform()),
          const SizedBox(width: 8),
          const Text('0:24', style: TextStyle(fontSize: 11, color: _text2)),
        ],
      ),
    );
  }
}

class _TGWaveform extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(),
      size: const Size(180, 24),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (double x = 0; x < size.width; x += 3) {
      final h = (rng.nextDouble() * 0.6 + 0.2) * size.height;
      final y = (size.height - h) / 2;
      final paint = Paint()
        ..color = (x < size.width * 0.35) ? _accent : _text2.withOpacity(0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), Offset(x, y + h), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════
// TG CHOICE PANEL — Quick reply bubbles
// ═══════════════════════════════════════════

class _TGChoicePanel extends StatelessWidget {
  final List<String> choices;
  final Function(String) onTap;
  const _TGChoicePanel({required this.choices, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      decoration: const BoxDecoration(color: _header, border: Border(top: BorderSide(color: _divider))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: choices.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(c),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _accent, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(c, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TG PROFILE SHEET
// ═══════════════════════════════════════════

class _TGProfileSheet extends StatelessWidget {
  final ChatCharacter character;
  const _TGProfileSheet({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 36, height: 4, decoration: BoxDecoration(color: _text2.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _TGAvatar(emoji: character.avatarEmoji, color: character.avatarColor, size: 80),
          const SizedBox(height: 14),
          Text(character.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(character.isOnline ? 'в сети' : 'был(а) недавно', style: TextStyle(fontSize: 13, color: character.isOnline ? _green : _text2)),
          const SizedBox(height: 16),
          _TGProfileRow(icon: Icons.info_outline, label: 'Био', value: character.bio),
          _TGProfileRow(icon: Icons.phone_outlined, label: 'Телефон', value: character.phone),
          _TGProfileRow(icon: Icons.alternate_email, label: 'Имя пользователя', value: '@${character.id}user'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TGProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _TGProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _text2),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: _accent)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 15, color: _text1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// EVIDENCE BOARD — Telegram style
// ═══════════════════════════════════════════

class EvidenceBoardScreen extends StatelessWidget {
  const EvidenceBoardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final all = getEvidenceItems();
    final found = all.where((e) => e.chapterFound <= gs.maxUnlockedChapter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Доска улик', style: TextStyle(fontWeight: FontWeight.w600))),
      body: found.isEmpty
          ? const Center(child: Text('Улики пока не найдены', style: TextStyle(color: _text2, fontSize: 14)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) => const Divider(height: 1, color: _divider, indent: 72),
              itemCount: found.length,
              itemBuilder: (ctx, i) {
                final ev = found[i];
                return InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(24)),
                            child: Icon(ev.icon, size: 22, color: _accent),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(ev.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _text2, height: 1.3)),
                              const SizedBox(height: 4),
                              Text('Глава ${ev.chapterFound}', style: const TextStyle(fontSize: 12, color: _text3)),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.chevron_right, size: 20, color: _text3),
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

// ═══════════════════════════════════════════
// CALLS — Telegram style
// ═══════════════════════════════════════════

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final calls = getPhoneCalls().where((c) => c.chapter <= gs.maxUnlockedChapter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Звонки', style: TextStyle(fontWeight: FontWeight.w600))),
      body: calls.isEmpty
          ? const Center(child: Text('Пока нет звонков', style: TextStyle(color: _text2, fontSize: 14)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              separatorBuilder: (_, __) => const Divider(height: 1, color: _divider, indent: 72),
              itemCount: calls.length,
              itemBuilder: (ctx, i) {
                final call = calls[i];
                final char = getCharacters().firstWhere((c) => c.id == call.callerId);
                return InkWell(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _TGAvatar(emoji: char.avatarEmoji, color: char.avatarColor, size: 54),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(char.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(call.isIncoming ? Icons.call_received : Icons.call_made, size: 16, color: call.isIncoming ? _green : _accent),
                                  const SizedBox(width: 4),
                                  Text('${call.durationSec} сек', style: const TextStyle(fontSize: 13, color: _text2)),
                                  Text(' • ', style: TextStyle(fontSize: 13, color: _text2.withOpacity(0.5))),
                                  Text('Сегодня', style: const TextStyle(fontSize: 13, color: _text2)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.call_outlined, size: 20, color: _accent), onPressed: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════
// CALL SCREEN — Telegram style
// ═══════════════════════════════════════════

class CallScreen extends StatefulWidget {
  final PhoneCall call;
  final ChatCharacter character;
  const CallScreen({super.key, required this.call, required this.character});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isPlaying = false;
  double _progress = 0;
  Timer? _timer;

  void _toggle() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) { _timer?.cancel(); return; }
        setState(() { _progress += 0.1 / widget.call.durationSec; if (_progress >= 1) { _progress = 1; _isPlaying = false; _timer?.cancel(); } });
      });
    } else { _timer?.cancel(); }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back, size: 22), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TGAvatar(emoji: widget.character.avatarEmoji, color: widget.character.avatarColor, size: 100),
              const SizedBox(height: 20),
              Text(widget.character.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.call.isIncoming ? 'Входящий' : 'Исходящий', style: const TextStyle(fontSize: 14, color: _text2)),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Транскрипция', style: TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text(widget.call.transcript, style: const TextStyle(fontSize: 14, color: _text1, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: _progress, backgroundColor: _surface, valueColor: const AlwaysStoppedAnimation(_accent), minHeight: 3)),
              const SizedBox(height: 24),
              IconButton(icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 56, color: _accent), onPressed: _toggle),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CHAPTERS — Telegram settings style
// ═══════════════════════════════════════════

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final chapters = getChapters();
    return Scaffold(
      appBar: AppBar(title: const Text('Сюжет', style: TextStyle(fontWeight: FontWeight.w600))),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (_, __) => const Divider(height: 1, color: _divider, indent: 72),
        itemCount: chapters.length,
        itemBuilder: (ctx, i) {
          final ch = chapters[i];
          final unlocked = ch.number <= gs.maxUnlockedChapter;
          final current = ch.number == gs.currentChapter;
          final completed = ch.number < gs.maxUnlockedChapter;
          return InkWell(
            onTap: unlocked ? () => _openChapter(ctx, ch, gs) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _TGAvatar(
                    emoji: completed ? '✓' : '${ch.number}',
                    color: completed ? _green : (current ? _accent : _text3),
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: unlocked ? _text1 : _text3)),
                        const SizedBox(height: 2),
                        Text(ch.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: unlocked ? _text2 : _text3)),
                      ],
                    ),
                  ),
                  if (!unlocked)
                    const Icon(Icons.lock_outline, size: 18, color: _text3)
                  else if (current)
                    const Icon(Icons.chevron_right, size: 20, color: _text3),
                ],
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
    final map = {1: 'unknown', 2: 'darya', 3: 'unknown', 4: 'victor', 5: 'natasha', 6: 'andrey', 7: 'unknown', 8: 'kira', 9: 'max', 10: 'unknown'};
    gs.showChapterIntro(ch.number);
  }
}

// ═══════════════════════════════════════════
// MINI-GAMES
// ═══════════════════════════════════════════

class MiniGameScreen extends StatefulWidget {
  final MiniGameData game;
  const MiniGameScreen({super.key, required this.game});
  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  String? _result;
  bool _solved = false;
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 22), onPressed: () => gs.closeMiniGame()),
        title: Text(widget.game.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline, size: 20, color: _accent),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.game.instruction, style: const TextStyle(fontSize: 14, color: _text2))),
              ]),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildGame()),
            if (_result != null)
              Container(
                width: double.infinity, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _solved ? _green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_result!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _solved ? _green : Colors.redAccent, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    switch (widget.game.type) {
      case 'cipher': return _buildCipher();
      case 'logic': return _buildTimeline();
      case 'final_choice': return _buildFinalChoice();
      default: return const Center(child: Text('В разработке', style: TextStyle(color: _text2)));
    }
  }

  Widget _buildCipher() {
    final encrypted = widget.game.data['encrypted'] as String;
    final answer = widget.game.data['answer'] as String;
    final shift = widget.game.data['shift'] as int;
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            const Text('Зашифрованное сообщение', style: TextStyle(fontSize: 12, color: _text2)),
            const SizedBox(height: 8),
            Text(encrypted, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 4, color: _accent)),
            const SizedBox(height: 6),
            Text('Шифр Цезаря, сдвиг $shift', style: const TextStyle(fontSize: 11, color: _text3)),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: _text1, fontSize: 16, letterSpacing: 2),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Введите ответ...',
            hintStyle: const TextStyle(color: _text3),
            filled: true, fillColor: _surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 46, child: _TGButton(text: 'Проверить', onPressed: () {
          if (_ctrl.text.trim().toUpperCase() == answer.toUpperCase()) {
            setState(() { _solved = true; _result = 'Верно! Номер расшифрован.'; });
          } else { setState(() { _solved = false; _result = 'Неверно. Попробуйте ещё.'; }); }
        })),
      ],
    );
  }

  Widget _buildTimeline() {
    final events = List<String>.from(widget.game.data['events'] as List)..shuffle(Random(42));
    return Column(
      children: [
        ...List.generate(events.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent)))),
              const SizedBox(width: 10),
              Expanded(child: Text(events[i], style: const TextStyle(fontSize: 13, color: _text1))),
            ]),
          ),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 46, child: _TGButton(text: 'Подтвердить', onPressed: () {
          setState(() { _solved = true; _result = 'Хронология восстановлена!'; });
        })),
      ],
    );
  }

  Widget _buildFinalChoice() {
    final options = List<String>.from(widget.game.data['options'] as List);
    final correct = widget.game.data['correct'] as String;
    final explanation = widget.game.data['explanation'] as String;
    return Column(
      children: [
        const Icon(Icons.gavel, size: 44, color: _accent),
        const SizedBox(height: 14),
        const Text('Кто виновен?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...options.map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(width: double.infinity, height: 46, child: _TGButton(text: opt, onPressed: () {
            if (opt == correct) { setState(() { _solved = true; _result = 'Верно! $explanation'; }); }
            else { setState(() { _solved = false; _result = 'Неверно. Пересмотрите улики.'; }); }
          })),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// TG BUTTON
// ═══════════════════════════════════════════

class _TGButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _TGButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
  }
}
