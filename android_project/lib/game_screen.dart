import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Image loading via built-in Image.network
import 'game_state.dart';

class GameScreen extends StatefulWidget {
  final Quest quest;
  const GameScreen({super.key, required this.quest});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _showInventory = false;
  bool _showAchievements = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().startQuest(widget.quest);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quest.titleRu,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _showExitConfirm(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Назад',
            onPressed: () {
              final gs = context.read<GameState>();
              if (gs.canGoBack()) {
                gs.goBack();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Некуда возвращаться'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Инвентарь',
            onPressed: () => setState(() => _showInventory = !_showInventory),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Достижения',
            onPressed: () =>
                setState(() => _showAchievements = !_showAchievements),
          ),
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          final scene = gameState.currentScene;
          if (scene == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A0E17), Color(0xFF141A2A)],
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      children: [
                        // Заголовок сцены
                        _SceneTitle(title: scene.title),
                        const SizedBox(height: 12),

                        // Изображение сцены
                        if (scene.imageUrl != null && scene.imageUrl!.isNotEmpty)
                          _SceneImage(imageUrl: scene.imageUrl!),
                        if (scene.imageUrl != null && scene.imageUrl!.isNotEmpty)
                          const SizedBox(height: 16),

                        // Текст сцены
                        _SceneText(paragraphs: scene.paragraphs),
                        const SizedBox(height: 8),

                        // Индикатор конца
                        if (scene.isEnd) ...[
                          const SizedBox(height: 16),
                          _EndBanner(
                            questCompleted: gameState.questCompleted,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _restartQuest(context),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Начать заново'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.list_rounded),
                            label: const Text('К списку квестов'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A2A4A),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          _ChoicesList(
                            choices: scene.choices,
                            inventory: gameState.inventory,
                            onChoice: (choice) {
                              gameState.goToScene(choice.gotoSceneId, choice);
                              _scrollToBottom();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Инвентарь снизу
                  if (_showInventory && gameState.inventory.isNotEmpty)
                    _InventoryBar(inventory: gameState.inventory),
                ],
              ),

              // Достижения — оверлей
              if (_showAchievements)
                _AchievementsOverlay(
                  achievements: widget.quest.achievements,
                  unlocked: gameState.unlockedAchievements,
                  onClose: () =>
                      setState(() => _showAchievements = false),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showExitConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A2A),
        title: const Text('Выйти из квеста?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Прогресс текущего прохождения будет потерян.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Выйти',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _restartQuest(BuildContext context) {
    context.read<GameState>().startQuest(widget.quest);
    _scrollToBottom();
  }
}

/// Заголовок сцены
class _SceneTitle extends StatelessWidget {
  final String title;
  const _SceneTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded,
              size: 18, color: const Color(0xFF6C63FF).withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Изображение сцены
class _SceneImage extends StatelessWidget {
  final String imageUrl;
  const _SceneImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A1F30),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 180,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded,
                    size: 36, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 8),
                Text(
                  'Изображение недоступно',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Текст сцены
class _SceneText extends StatelessWidget {
  final List<String> paragraphs;
  const _SceneText({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            p,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFFD0D0D0),
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Баннер конца квеста
class _EndBanner extends StatelessWidget {
  final bool questCompleted;
  const _EndBanner({required this.questCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF00D4AA).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: questCompleted
                ? const Color(0xFF00D4AA)
                : const Color(0xFFFF5252)),
      ),
      child: Row(
        children: [
          Icon(
            questCompleted
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: questCompleted
                ? const Color(0xFF00D4AA)
                : const Color(0xFFFF5252),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              questCompleted
                  ? 'Квест завершён!'
                  : 'Квест закончен.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: questCompleted
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFFFF5252),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Список выборов
class _ChoicesList extends StatelessWidget {
  final List<Choice> choices;
  final Set<String> inventory;
  final ValueChanged<Choice> onChoice;

  const _ChoicesList({
    required this.choices,
    required this.inventory,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    final availableChoices =
        choices.where((c) => c.isAvailable(inventory)).toList();
    final lockedChoices =
        choices.where((c) => !c.isAvailable(inventory)).toList();

    if (availableChoices.isEmpty && lockedChoices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Что вы решите?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...availableChoices.map((choice) => _ChoiceButton(
              choice: choice,
              available: true,
              onTap: () => onChoice(choice),
            )),
        if (lockedChoices.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...lockedChoices.map((choice) => _ChoiceButton(
                choice: choice,
                available: false,
                inventory: inventory,
              )),
        ],
      ],
    );
  }
}

/// Кнопка выбора
class _ChoiceButton extends StatelessWidget {
  final Choice choice;
  final bool available;
  final VoidCallback? onTap;
  final Set<String>? inventory;

  const _ChoiceButton({
    required this.choice,
    required this.available,
    this.onTap,
    this.inventory,
  });

  String _getRequirementText() {
    final parts = <String>[];
    if (choice.requireAll.isNotEmpty) {
      parts.add('Нужны: ${choice.requireAll.join(", ")}');
    }
    if (choice.requireAny.isNotEmpty) {
      parts.add('Нужно одно из: ${choice.requireAny.join(", ")}');
    }
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (available) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2440),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_right_rounded,
                      size: 20, color: const Color(0xFF6C63FF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      choice.label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (choice.addItems.isNotEmpty)
                    Icon(Icons.add_circle_outline_rounded,
                        size: 16, color: const Color(0xFF00D4AA).withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Недоступный выбор
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    choice.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.35),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                _getRequirementText(),
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFFF5252).withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Панель инвентаря снизу
class _InventoryBar extends StatelessWidget {
  final Set<String> inventory;
  const _InventoryBar({required this.inventory});

  String _itemName(String id) {
    final map = {
      'plasma_cutter': 'Плазморез',
      'bioscanner': 'Биосканер',
      'translator': 'Транслатор',
      'stealth_module': 'Маскировка',
      'fuel_cell': 'Топливная ячейка',
      'medkit': 'Аптечка',
      'spacesuit': 'Скафандр',
      'datacore': 'Датакор',
      'access_card': 'Карта доступа',
      'mag_token': 'Магнитный жетон',
      'hairpin': 'Шпилька',
      'rusty_key': 'Ржавый ключ',
      'photo_half': 'Половинка фото',
      'photo_half2': 'Вторая половинка фото',
      'mirror_shard': 'Осколок зеркала',
      'courage': 'Смелость',
      'gloves': 'Перчатки',
      'evidence_bags': 'Пакеты для улик',
      'victim_phone': 'Телефон жертвы',
      'victim_watch': 'Часы жертвы',
      'suspect_glove': 'Перчатка подозреваемого',
      'murder_weapon': 'Орудие убийства',
      'coworking_address': 'Адрес коворкинга',
      'logi_badge': 'Бейдж логистики',
      'gym_card': 'Абонемент',
      'logi_card': 'Визитка',
      'gym_logs': 'Журнал клуба',
      'warrant_requested': 'Ордер запрошен',
      'neighbor_statement': 'Показания соседа',
      'key_red': 'Красная карта',
      'key_blue': 'Синяя карта',
      'key_green': 'Зелёная карта',
      'club_phone': 'Телефон клуба',
      'fake_invoices': 'Фиктивные накладные',
      'lightning_keyfob': 'Брелок-молния',
      'cash_bundle': 'Наличные',
      'locker_phone': 'Запасной телефон',
      'chat_logs': 'Переписка',
      'journalist_informer': 'Журналист-информатор',
      'sting_at_warehouse': 'Операция у складов',
      'sting_at_coworking': 'Операция у коворкинга',
      'bait_active': 'Приманка активна',
      'crew_rescued': 'Пилот спасён',
      'reactor_fixed': 'Реактор починен',
      'engine_fixed': 'Двигатель починен',
      'crew_marked': 'Экипаж помечен',
      'alien_artifact': 'Инопланетный артефакт',
      'artifact_decoded': 'Артефакт декодирован',
      'eva_pattern': 'EVA-паттерн',
      'reactor_key': 'Модуль реактора',
    };
    return map[id] ?? id.replaceAll('_', ' ');
  }

  IconData _itemIcon(String id) {
    if (id.contains('key') || id.contains('card') || id.contains('token'))
      return Icons.key_rounded;
    if (id.contains('phone'))
      return Icons.phone_android_rounded;
    if (id.contains('weapon') || id.contains('knife') || id.contains('scalpel'))
      return Icons.warning_rounded;
    if (id.contains('med') || id.contains('first_aid'))
      return Icons.medical_services_rounded;
    if (id.contains('log') || id.contains('doc') || id.contains('note'))
      return Icons.description_rounded;
    if (id.contains('badge') || id.contains('id'))
      return Icons.badge_rounded;
    return Icons.inventory_2_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1220),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A4A), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 14, color: Color(0xFF00D4AA)),
              const SizedBox(width: 6),
              const Text(
                'Инвентарь',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00D4AA)),
              ),
              const Spacer(),
              Text(
                '${inventory.length} предмет(ов)',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: inventory.map((item) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2440),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_itemIcon(item),
                          size: 14, color: const Color(0xFF00D4AA)),
                      const SizedBox(width: 4),
                      Text(
                        _itemName(item),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Оверлей достижений
class _AchievementsOverlay extends StatelessWidget {
  final List<Achievement> achievements;
  final List<String> unlocked;
  final VoidCallback onClose;

  const _AchievementsOverlay({
    required this.achievements,
    required this.unlocked,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Достижения',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${unlocked.length}/${achievements.length}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  final isUnlocked = unlocked.contains(ach.code);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF1E2440)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUnlocked
                              ? const Color(0xFFFFD700).withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUnlocked
                                ? Icons.emoji_events_rounded
                                : Icons.lock_outline_rounded,
                            color: isUnlocked
                                ? const Color(0xFFFFD700)
                                : Colors.white.withOpacity(0.2),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ach.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnlocked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isUnlocked
                                    ? const Color(0xFFFFD700)
                                    : Colors.white.withOpacity(0.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
