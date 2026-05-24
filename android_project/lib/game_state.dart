import 'dart:convert';
import 'package:flutter/material.dart';

/// Модель квеста
class Quest {
  final String id;
  final String titleRu;
  final String titleEn;
  final String startSceneId;
  final List<Achievement> achievements;
  final Map<String, SceneNode> nodes;
  String? imageStyle;

  Quest({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.startSceneId,
    required this.achievements,
    required this.nodes,
    this.imageStyle,
  });

  factory Quest.fromJson(Map<String, dynamic> json, String fileName) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final titleMap = meta['title'] as Map<String, dynamic>? ?? {};
    final achList = (meta['achievements'] as List<dynamic>?)
            ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final nodesMap = <String, SceneNode>{};
    final raw = json['nodes'] as Map<String, dynamic>? ?? {};
    raw.forEach((key, value) {
      nodesMap[key] = SceneNode.fromJson(key, value as Map<String, dynamic>);
    });

    return Quest(
      id: fileName.replaceAll('.json', ''),
      titleRu: (titleMap['ru'] as String?) ?? titleMap['en'] ?? fileName,
      titleEn: (titleMap['en'] as String?) ?? fileName,
      startSceneId: json['start'] as String? ?? '',
      achievements: achList,
      nodes: nodesMap,
      imageStyle: meta['imageStyle'] as String?,
    );
  }
}

/// Достижение
class Achievement {
  final String code;
  final String title;
  final Map<String, dynamic>? when;

  Achievement({required this.code, required this.title, this.when});

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      when: json['when'] as Map<String, dynamic>?,
    );
  }
}

/// Сцена квеста
class SceneNode {
  final String id;
  final String title;
  final List<String> paragraphs;
  final String? imageUrl;
  final String? imgPrompt;
  final List<Choice> choices;
  final bool isEnd;

  SceneNode({
    required this.id,
    required this.title,
    required this.paragraphs,
    this.imageUrl,
    this.imgPrompt,
    required this.choices,
    this.isEnd = false,
  });

  factory SceneNode.fromJson(String id, Map<String, dynamic> json) {
    final textRaw = json['text'];
    List<String> paragraphs;
    if (textRaw is List) {
      paragraphs = textRaw.map((e) => e.toString()).toList();
    } else {
      paragraphs = (textRaw as String?)?.isNotEmpty == true
          ? [(textRaw as String)]
          : [];
    }

    final choicesList = (json['choices'] as List<dynamic>?)
            ?.map((e) => Choice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    String? imageUrl = json['image'] as String?;
    if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;

    return SceneNode(
      id: id,
      title: json['title'] as String? ?? '',
      paragraphs: paragraphs,
      imageUrl: imageUrl,
      imgPrompt: json['imgPrompt'] as String?,
      choices: choicesList,
      isEnd: json['end'] == true,
    );
  }
}

/// Выбор в сцене
class Choice {
  final String label;
  final String gotoSceneId;
  final List<String> addItems;
  final List<String> removeItems;
  final List<String> requireAll;
  final List<String> requireAny;

  Choice({
    required this.label,
    required this.gotoSceneId,
    required this.addItems,
    required this.removeItems,
    required this.requireAll,
    required this.requireAny,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    final effects = json['effects'] as Map<String, dynamic>? ?? {};
    final add = (effects['add'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final remove = (effects['remove'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final require = json['require'] as Map<String, dynamic>? ?? {};
    final hasAll = (require['hasAll'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final hasAny = (require['hasAny'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Choice(
      label: json['label'] as String? ?? '',
      gotoSceneId: json['goto'] as String? ?? '',
      addItems: add,
      removeItems: remove,
      requireAll: hasAll,
      requireAny: hasAny,
    );
  }

  bool isAvailable(Set<String> inventory) {
    if (requireAll.isNotEmpty) {
      for (final item in requireAll) {
        if (!inventory.contains(item)) return false;
      }
    }
    if (requireAny.isNotEmpty) {
      bool found = false;
      for (final item in requireAny) {
        if (inventory.contains(item)) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }
}

/// Состояние игры
class GameState extends ChangeNotifier {
  Quest? _currentQuest;
  String _currentSceneId = '';
  final Set<String> _inventory = {};
  final Set<String> _visitedScenes = {};
  final List<String> _unlockedAchievements = [];
  final List<String> _sceneHistory = [];
  bool _questStarted = false;
  bool _questCompleted = false;

  Quest? get currentQuest => _currentQuest;
  String get currentSceneId => _currentSceneId;
  Set<String> get inventory => Set.unmodifiable(_inventory);
  List<String> get unlockedAchievements =>
      List.unmodifiable(_unlockedAchievements);
  List<String> get sceneHistory => List.unmodifiable(_sceneHistory);
  bool get questStarted => _questStarted;
  bool get questCompleted => _questCompleted;

  SceneNode? get currentScene {
    if (_currentQuest == null || _currentSceneId.isEmpty) return null;
    return _currentQuest!.nodes[_currentSceneId];
  }

  void startQuest(Quest quest) {
    _currentQuest = quest;
    _currentSceneId = quest.startSceneId;
    _inventory.clear();
    _visitedScenes.clear();
    _unlockedAchievements.clear();
    _sceneHistory.clear();
    _questStarted = true;
    _questCompleted = false;
    _visitedScenes.add(quest.startSceneId);
    _sceneHistory.add(quest.startSceneId);
    _checkAchievements();
    notifyListeners();
  }

  void goToScene(String sceneId, Choice choice) {
    if (sceneId.isEmpty) return;

    _sceneHistory.add(sceneId);
    _currentSceneId = sceneId;
    _visitedScenes.add(sceneId);

    for (final item in choice.addItems) {
      _inventory.add(item);
    }
    for (final item in choice.removeItems) {
      _inventory.remove(item);
    }

    final scene = currentScene;
    if (scene != null && scene.isEnd) {
      _questCompleted = true;
    }

    _checkAchievements();
    notifyListeners();
  }

  bool canGoBack() => _sceneHistory.length > 1;

  void goBack() {
    if (!canGoBack()) return;
    _sceneHistory.removeLast();
    _currentSceneId = _sceneHistory.last;
    notifyListeners();
  }

  void _checkAchievements() {
    if (_currentQuest == null) return;

    for (final ach in _currentQuest!.achievements) {
      if (_unlockedAchievements.contains(ach.code)) continue;
      if (_checkAchievementCondition(ach)) {
        _unlockedAchievements.add(ach.code);
      }
    }
  }

  bool _checkAchievementCondition(Achievement ach) {
    final when = ach.when;
    if (when == null) return false;
    final type = when['type'] as String?;

    switch (type) {
      case 'quest_started':
        return _questStarted;
      case 'quest_completed':
        return _questCompleted;
      case 'reach_scene':
        final sceneId = when['sceneId'] as String?;
        return sceneId != null && _visitedScenes.contains(sceneId);
      case 'have_items_all':
        final items = (when['items'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        for (final item in items) {
          if (!_inventory.contains(item)) return false;
        }
        return true;
    }
    return false;
  }

  /// Сериализация для сохранения
  Map<String, dynamic> toJson(String questId) {
    return {
      'questId': questId,
      'currentSceneId': _currentSceneId,
      'inventory': _inventory.toList(),
      'visitedScenes': _visitedScenes.toList(),
      'unlockedAchievements': _unlockedAchievements,
      'sceneHistory': _sceneHistory,
      'questStarted': _questStarted,
      'questCompleted': _questCompleted,
    };
  }

  /// Восстановление из сохранения
  bool restoreFromJson(Map<String, dynamic> json, Quest quest) {
    if (json['questId'] != quest.id) return false;

    _currentQuest = quest;
    _currentSceneId = json['currentSceneId'] as String? ?? '';
    _inventory.clear();
    _inventory.addAll((json['inventory'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        []);
    _visitedScenes.clear();
    _visitedScenes.addAll((json['visitedScenes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        []);
    _unlockedAchievements.clear();
    _unlockedAchievements.addAll((json['unlockedAchievements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        []);
    _sceneHistory.clear();
    _sceneHistory.addAll((json['sceneHistory'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        []);
    _questStarted = json['questStarted'] as bool? ?? false;
    _questCompleted = json['questCompleted'] as bool? ?? false;
    notifyListeners();
    return true;
  }

  String? getQuestSaveJson() {
    if (_currentQuest == null) return null;
    return jsonEncode(toJson(_currentQuest!.id));
  }
}
