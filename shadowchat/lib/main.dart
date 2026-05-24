import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => GameState(), child: const ShadowChatApp()));
}

class ShadowChatApp extends StatelessWidget {
  const ShadowChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHADOWCHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00D4AA), secondary: Color(0xFFFF3366), surface: Color(0xFF14141C)),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0B0B0F), foregroundColor: Colors.white, elevation: 0),
        cardTheme: CardThemeData(color: const Color(0xFF1A1A26), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF0F0F16), selectedItemColor: Color(0xFF00D4AA), unselectedItemColor: Color(0xFF444455)),
      ),
      home: const AppShell(),
    );
  }
}

// ═══════════════════════════════════════════
// APP SHELL
// ═══════════════════════════════════════════

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
    if (gs.activeChatId != null) {
      return ChatScreen(charId: gs.activeChatId!);
    }
    return Scaffold(
      body: IndexedStack(index: gs.currentTab, children: const [
        ChatsListScreen(),
        CallsScreen(),
        EvidenceBoardScreen(),
        ChaptersScreen(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: gs.currentTab,
        onTap: (i) => gs.setTab(i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(Icons.phone_in_talk), label: 'Звонки'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Улики'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Сюжет'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SPLASH SCREEN
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _ctrl.forward().then((_) { if (mounted) context.read<GameState>().finishSplash(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, child) {
            final t = _ctrl.value;
            final fadeIn = Curves.easeInOut.transform(t < 0.3 ? t / 0.3 : 1.0);
            final scaleIn = 0.8 + 0.2 * Curves.easeOutBack.transform(t < 0.4 ? t / 0.4 : 1.0);
            final fadeOut = t > 0.85 ? (1.0 - t) / 0.15 : 1.0;
            return Opacity(
              opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
              child: Transform.scale(scale: scaleIn, child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF0088FF)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.3), blurRadius: 30)],
                ),
                child: const Icon(Icons.shield, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('SHADOWCHAT', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFF00D4AA))),
              const SizedBox(height: 10),
              const Text('Неизвестный написал тебе.', style: TextStyle(fontSize: 14, color: Color(0xFF555566), letterSpacing: 1)),
              const SizedBox(height: 60),
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF00D4AA).withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CHAT LIST
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
        title: const Text('SHADOWCHAT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF00D4AA), letterSpacing: 4)),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: visible.length,
        itemBuilder: (ctx, i) {
          final c = visible[i];
          final msgs = getMessagesFor(c.id).where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem).toList();
          final lastMsg = msgs.isNotEmpty ? msgs.last : null;
          final hasNew = msgs.any((m) => !gs.hasSeen(m.id) && m.fromId != 'player');
          return _ChatTile(character: c, lastMsg: lastMsg, hasNew: hasNew, onTap: () => gs.openChat(c.id));
        },
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 26, backgroundColor: character.avatarColor.withOpacity(0.2),
                  child: Text(character.avatarEmoji, style: TextStyle(fontSize: 20, color: character.avatarColor))),
                if (character.isOnline) Positioned(right: 0, bottom: 0,
                  child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF00D4AA), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0B0B0F), width: 2)))),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(character.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (lastMsg != null) Text('Глава ${lastMsg!.chapter}', style: const TextStyle(fontSize: 11, color: Color(0xFF555566))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasNew) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(color: Color(0xFF00D4AA), shape: BoxShape.circle)),
                      Expanded(
                        child: Text(
                          lastMsg?.text ?? 'Начните расследование...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: hasNew ? const Color(0xFFAAAACC) : const Color(0xFF555566)),
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

// ═══════════════════════════════════════════
// CHAT SCREEN (Duskwood-style)
// ═══════════════════════════════════════════

class ChatScreen extends StatefulWidget {
  final String charId;
  const ChatScreen({super.key, required this.charId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<ChatMsg> _visibleMsgs;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showChoices = false;
  ChatMsg? _pendingChoiceMsg;
  Timer? _msgTimer;

  @override
  void initState() {
    super.initState();
    final gs = context.read<GameState>();
    final char = getCharacters().firstWhere((c) => c.id == widget.charId);
    _visibleMsgs = getMessagesFor(widget.charId)
        .where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem)
        .toList();
    _scheduleMessages();
  }

  void _scheduleMessages() {
    final gs = context.read<GameState>();
    _msgTimer?.cancel();
    int delay = 600;
    for (final msg in _visibleMsgs) {
      final d = delay;
      delay += (msg.delayMs > 0 ? msg.delayMs : 800);
      if (msg.fromId != 'player' && !gs.hasSeen(msg.id)) {
        Future.delayed(Duration(milliseconds: d), () {
          if (mounted) {
            gs.setTyping(true);
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) {
                gs.setTyping(false);
                gs.markSeen(msg.id);
                // Process system events from preceding system messages
                _processSystemFor(msg, gs);
                setState(() {});
                _scrollToBottom();
                // Check if next message is a player choice
                _checkForChoices(gs);
              }
            });
          }
        });
      }
    }
    // Initial check for already-seen choices
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _checkForChoices(gs);
    });
  }

  void _processSystemFor(ChatMsg msg, GameState gs) {
    final allMsgs = getMessagesFor(widget.charId);
    final idx = allMsgs.indexOf(msg);
    // Check previous messages for system events
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
      _showChoices = false;
      _pendingChoiceMsg = null;
    });
    _scrollToBottom();
    // Continue message chain
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _visibleMsgs = getMessagesFor(widget.charId)
            .where((m) => m.chapter <= gs.maxUnlockedChapter && !m.isSystem)
            .toList();
        _scheduleMessages();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
    final isPlayer = false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => gs.closeChat()),
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: char.avatarColor.withOpacity(0.2),
              child: Text(char.avatarEmoji, style: TextStyle(fontSize: 13, color: char.avatarColor))),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(char.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(char.isOnline ? 'в сети' : 'был(а) недавно', style: const TextStyle(fontSize: 11, color: Color(0xFF555566))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined, color: Color(0xFF00D4AA)), onPressed: () => _makeCall(char)),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showProfile(char)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: gs.isTyping
                ? const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4AA))),
                      SizedBox(height: 12),
                      Text('печатает...', style: TextStyle(color: Color(0xFF555566), fontSize: 13)),
                    ],
                  ))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _visibleMsgs.length,
                    itemBuilder: (ctx, i) {
                      final msg = _visibleMsgs[i];
                      if (!gs.hasSeen(msg.id) && msg.fromId != 'player') {
                        if (msg.playerChoices == null) return const SizedBox.shrink();
                        return const SizedBox.shrink();
                      }
                      if (msg.fromId == 'player') {
                        if (msg.playerChoices != null && !gs.hasSeen('choice_${msg.id}')) {
                          return const SizedBox.shrink();
                        }
                        if (msg.playerChoices != null && gs.hasSeen('choice_${msg.id}')) {
                          // Show as player sent message (placeholder)
                          return const SizedBox.shrink();
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
    );
  }

  void _makeCall(ChatCharacter char) {
    final gs = context.read<GameState>();
    final call = getPhoneCalls().where((c) => c.callerId == char.id && c.chapter <= gs.maxUnlockedChapter).lastOrNull;
    if (call == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Нет доступных звонков от ${char.name}'), backgroundColor: const Color(0xFF1A1A26)));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char)));
  }

  void _showProfile(ChatCharacter char) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: const Color(0xFF14141C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundColor: char.avatarColor.withOpacity(0.2),
              child: Text(char.avatarEmoji, style: TextStyle(fontSize: 32, color: char.avatarColor))),
            const SizedBox(height: 16),
            Text(char.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(char.phone, style: const TextStyle(fontSize: 13, color: Color(0xFF666677))),
            const SizedBox(height: 12),
            Text(char.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF999999), height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), foregroundColor: Colors.black),
              child: const Text('Закрыть', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    ));
  }
}

// ═══ MESSAGE BUBBLE ═══

class _MessageBubble extends StatelessWidget {
  final ChatMsg msg;
  final ChatCharacter character;
  final GameState gs;

  const _MessageBubble({required this.msg, required this.character, required this.gs});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.fromId == 'player';
    final timeLabel = '22:${(msg.chapter * 3 + 15).toString().padLeft(2, '0')}';

    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A1A26).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
            child: const Text('Сообщение удалено', style: TextStyle(color: Color(0xFF444455), fontStyle: FontStyle.italic, fontSize: 13)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: msg.imageUrl != null ? 4 : 6),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF00D4AA).withOpacity(0.15) : const Color(0xFF1A1A26),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: isMe ? Border.all(color: const Color(0xFF00D4AA).withOpacity(0.2)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null) ...[
                _buildImage(msg.imageUrl!),
                const SizedBox(height: 6),
              ],
              if (msg.voiceNoteText != null) ...[
                _buildVoiceNote(msg.voiceNoteText!),
                const SizedBox(height: 6),
              ],
              if (msg.text.isNotEmpty) Text(msg.text, style: TextStyle(fontSize: 14, color: isMe ? const Color(0xFFCCFFE8) : const Color(0xFFDDDDEE), height: 1.35)),
              const SizedBox(height: 4),
              Text(timeLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF555566))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    final labels = {
      'tax_docs': {'icon': Icons.description, 'bg1': Color(0xFF1A237E), 'bg2': Color(0xFF0D0D1A), 'label': 'Налоговые документы «Уголёк»'},
      'cafe_night': {'icon': Icons.night_shelter, 'bg1': Color(0xFF1A1A2E), 'bg2': Color(0xFF000000), 'label': 'Кафе «Уголёк». 23:00. Свет в офисе.'},
      'smirnov_threat': {'icon': Icons.mic, 'bg1': Color(0xFF1B0000), 'bg2': Color(0xFF0D0D0D), 'label': 'Запись разговора со следователем'},
      'ally_view': {'icon': Icons.location_city, 'bg1': Color(0xFF0D1B0D), 'bg2': Color(0xFF050505), 'label': 'Вид из окна Наташи на переулок'},
    };
    final info = labels[url] ?? {'icon': Icons.image, 'bg1': const Color(0xFF1A1A2E), 'bg2': const Color(0xFF0D0D0D), 'label': url};
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [info['bg1'] as Color, info['bg2'] as Color]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(child: Icon(info['icon'] as IconData, size: 48, color: Colors.white.withOpacity(0.12))),
          Positioned(bottom: 10, left: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
              child: Text(info['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNote(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.play_circle_filled, color: Color(0xFF00D4AA), size: 32),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 2, decoration: BoxDecoration(color: const Color(0xFF333344), borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 4),
              Text('0:${text.length.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10, color: Color(0xFF666677))),
            ],
          )),
        ],
      ),
    );
  }
}

// ═══ CHOICE PANEL ═══

class _ChoicePanel extends StatelessWidget {
  final List<String> choices;
  final Function(String) onTap;

  _ChoicePanel({required this.choices, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final btns = <Widget>[];
    for (final c in choices) {
      btns.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A26),
              foregroundColor: const Color(0xFFCCCCEE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => onTap(c),
            child: Text(c, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ),
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF0F0F16), border: const Border(top: BorderSide(color: Color(0xFF1A1A26)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Ваш ответ:', style: TextStyle(fontSize: 12, color: Color(0xFF555566), fontWeight: FontWeight.w600))),
          ...btns,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CALL SCREEN
// ═══════════════════════════════════════════

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final calls = getPhoneCalls().where((c) => c.chapter <= gs.maxUnlockedChapter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Звонки', style: TextStyle(fontWeight: FontWeight.bold))),
      body: calls.isEmpty
          ? const Center(child: Text('Пока нет звонков', style: TextStyle(color: Color(0xFF555566))))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: calls.length,
              itemBuilder: (ctx, i) {
                final call = calls[i];
                final char = getCharacters().firstWhere((c) => c.id == call.callerId);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: char.avatarColor.withOpacity(0.2),
                    child: Text(char.avatarEmoji, style: TextStyle(color: char.avatarColor))),
                  title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${call.durationSec} сек • Глава ${call.chapter}', style: const TextStyle(color: Color(0xFF666677))),
                  trailing: Icon(call.isIncoming ? Icons.call_received : Icons.call_made, color: const Color(0xFF00D4AA), size: 20),
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => CallScreen(call: call, character: char))),
                );
              },
            ),
    );
  }
}

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
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 60, backgroundColor: widget.character.avatarColor.withOpacity(0.15),
                child: Text(widget.character.avatarEmoji, style: TextStyle(fontSize: 48, color: widget.character.avatarColor))),
              const SizedBox(height: 20),
              Text(widget.character.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.call.isIncoming ? 'Входящий звонок' : 'Исходящий звонок', style: const TextStyle(color: Color(0xFF555566), fontSize: 14)),
              const SizedBox(height: 6),
              Text('${widget.call.durationSec} сек', style: const TextStyle(color: Color(0xFF444455), fontSize: 12)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(16)),
                child: Text(widget.call.transcript, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCDD), height: 1.5)),
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(value: _progress, backgroundColor: const Color(0xFF1A1A26), valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)), minHeight: 4),
              const SizedBox(height: 20),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 60, color: const Color(0xFF00D4AA)),
                onPressed: _togglePlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// EVIDENCE BOARD
// ═══════════════════════════════════════════

class EvidenceBoardScreen extends StatelessWidget {
  const EvidenceBoardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final all = getEvidenceItems();
    final found = all.where((e) => e.chapterFound <= gs.maxUnlockedChapter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Доска улик', style: TextStyle(fontWeight: FontWeight.bold))),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF00D4AA).withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.15))),
          child: Row(
            children: [
              const Icon(Icons.fingerprint, color: Color(0xFF00D4AA), size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Собрано улик', style: TextStyle(color: Color(0xFF666677), fontSize: 12)),
                  Text('${found.length} / ${all.length}', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              )),
              SizedBox(width: 56, height: 56, child: CircularProgressIndicator(
                value: all.isEmpty ? 0 : found.length / all.length, strokeWidth: 5,
                backgroundColor: const Color(0xFF1A1A26), valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)))),
            ],
          ),
        ))),
        SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
          final ev = found[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFF9800).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(ev.icon, color: const Color(0xFFFF9800), size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(ev.description, style: const TextStyle(fontSize: 12, color: Color(0xFF888899), height: 1.3)),
                        const SizedBox(height: 6),
                        Text('Глава ${ev.chapterFound}', style: const TextStyle(fontSize: 11, color: Color(0xFF555566))),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          );
        }, childCount: found.length)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════
// CHAPTERS SCREEN
// ═══════════════════════════════════════════

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final chapters = getChapters();
    return Scaffold(
      appBar: AppBar(title: const Text('Сюжет', style: TextStyle(fontWeight: FontWeight.bold))),
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
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: unlocked ? () => _openChapter(ctx, ch, gs) : null,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: current ? Border.all(color: const Color(0xFF00D4AA), width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: completed ? const Color(0xFF00D4AA) : (unlocked ? const Color(0xFF00D4AA).withOpacity(0.2) : const Color(0xFF1A1A26)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: completed
                              ? const Icon(Icons.check, color: Colors.black, size: 24)
                              : Text('${ch.number}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: unlocked ? const Color(0xFF00D4AA) : const Color(0xFF444455))),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: unlocked ? Colors.white : const Color(0xFF444455))),
                          const SizedBox(height: 3),
                          Text(ch.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: unlocked ? const Color(0xFF888899) : const Color(0xFF333344))),
                        ],
                      )),
                      if (!unlocked) const Icon(Icons.lock_outline, color: Color(0xFF333344), size: 20),
                    ],
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
    if (ch.characterUnlock != null) {
      gs.unlockChar(ch.characterUnlock!);
    }
    if (ch.number == gs.maxUnlockedChapter) {
      gs.advanceChapter(ch.number);
    }
    // Navigate to the relevant chat
    final charMap = {1: 'unknown', 2: 'darya', 3: 'unknown', 4: 'victor', 5: 'natasha', 6: 'andrey', 7: 'unknown', 8: 'kira', 9: 'max', 10: 'unknown'};
    final targetChar = charMap[ch.number] ?? 'unknown';
    gs.openChat(targetChar);
  }
}
