import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
import 'game_state.dart' as gs;
import 'game_screen.dart';

class QuestListScreen extends StatelessWidget {
  final List<Quest> quests;
  const QuestListScreen({super.key, required this.quests});

  IconData _getQuestIcon(String questId) {
    if (questId.contains('orbit') || questId.contains('deep')) {
      return Icons.rocket_launch_rounded;
    }
    if (questId.contains('dockside') || questId.contains('shadow')) {
      return Icons.search_rounded;
    }
    if (questId.contains('flat') || questId.contains('psych')) {
      return Icons.psychology_rounded;
    }
    return Icons.menu_book_rounded;
  }

  Color _getQuestColor(String questId) {
    if (questId.contains('orbit') || questId.contains('deep')) {
      return const Color(0xFF00BCD4);
    }
    if (questId.contains('dockside') || questId.contains('shadow')) {
      return const Color(0xFFFF9800);
    }
    if (questId.contains('flat') || questId.contains('psych')) {
      return const Color(0xFFE91E63);
    }
    return const Color(0xFF6C63FF);
  }

  String _getQuestDescription(String questId) {
    if (questId.contains('orbit') || questId.contains('deep')) {
      return 'Научно-фантастический квест на борту повреждённого грузового корабля в Туманности Ят. Почините реактор, спасите экипаж и найдите путь домой.';
    }
    if (questId.contains('dockside') || questId.contains('shadow')) {
      return 'Нуар-детектив. Тело на набережной, подозреваемые в фитнес-клубе и складские тайны. Раскройте убийство и выведите на чистую воду преступную схему.';
    }
    if (questId.contains('flat') || questId.contains('psych')) {
      return 'Психологический хоррор. Вы просыпаетесь в тёмном коридоре без памяти. Лифт, зеркало и голоса в стенах — найдите выход, пока не потеряли себя.';
    }
    return 'Интерактивный квест с branching-сюжетом.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FPA — Квест-Плеер',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E17), Color(0xFF141A2A)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            final color = _getQuestColor(quest.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _QuestCard(
                quest: quest,
                icon: _getQuestIcon(quest.id),
                color: color,
                description: _getQuestDescription(quest.id),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A2A),
        title: const Text('О приложении',
            style: TextStyle(color: Color(0xFF6C63FF))),
        content: const Text(
          'FPA — интерактивный квест-плеер.\n\n'
          'Выбирайте квест, принимайте решения, собирайте предметы и раскрывайте тайны. '
          'Каждый квест имеет множество концовок — ваши решения определяют судьбу героя.\n\n'
          'Минимум подсказок — максимум погружения.',
          style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final IconData icon;
  final Color color;
  final String description;

  const _QuestCard({
    required this.quest,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final gameState = gs.GameState();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ChangeNotifierProvider<gs.GameState>.value(
                value: gameState,
                child: GameScreen(quest: quest),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.titleRu,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.room_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          '${quest.nodes.length} сцен',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.emoji_events_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          '${quest.achievements.length} достижений',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Color(0xFF444466)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
