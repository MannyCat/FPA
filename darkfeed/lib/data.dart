import 'dart:convert';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
// МОДЕЛИ
// ═══════════════════════════════════════════

class Character {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String avatarColor;
  final String initials;
  final int followers;
  final int following;
  final List<Post> posts;
  final List<Story> stories;
  final List<ChatMessage> messages;
  final bool isVictim;
  final bool isHidden;

  const Character({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.avatarColor,
    required this.initials,
    required this.followers,
    required this.following,
    required this.posts,
    required this.stories,
    required this.messages,
    this.isVictim = false,
    this.isHidden = false,
  });
}

class Post {
  final String id;
  final String characterId;
  final String text;
  final String? imageData;
  final String time;
  final int likes;
  final int comments;
  final List<Comment> commentList;
  final int chapterUnlock;
  final bool isEvidence;
  final String? evidenceHint;

  const Post({
    required this.id,
    required this.characterId,
    required this.text,
    this.imageData,
    required this.time,
    required this.likes,
    required this.comments,
    required this.commentList,
    required this.chapterUnlock,
    this.isEvidence = false,
    this.evidenceHint,
  });
}

class Comment {
  final String characterId;
  final String text;
  final String time;

  const Comment({required this.characterId, required this.text, required this.time});
}

class Story {
  final String id;
  final String characterId;
  final List<StorySlide> slides;
  final int chapterUnlock;

  const Story({required this.id, required this.characterId, required this.slides, required this.chapterUnlock});
}

class StorySlide {
  final String text;
  final String? imageData;
  final String? gradientTop;
  final String? gradientBottom;

  const StorySlide({required this.text, this.imageData, this.gradientTop, this.gradientBottom});
}

class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final String time;
  final bool isDeleted;
  final int chapterUnlock;

  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.time,
    this.isDeleted = false,
    required this.chapterUnlock,
  });
}

class Chapter {
  final int number;
  final String title;
  final String subtitle;
  final String description;
  final String? characterFocus;
  final MiniGame? miniGame;

  const Chapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    this.characterFocus,
    this.miniGame,
  });
}

class MiniGame {
  final String type;
  final String title;
  final String instruction;
  final Map<String, dynamic> data;

  const MiniGame({required this.type, required this.title, required this.instruction, required this.data});
}

class Evidence {
  final String id;
  final String title;
  final String description;
  final String characterId;
  final int chapterFound;
  final IconData icon;

  const Evidence({required this.id, required this.title, required this.description, required this.characterId, required this.chapterFound, required this.icon});
}

// ═══════════════════════════════════════════
// СОСТОЯНИЕ ИГРЫ
// ═══════════════════════════════════════════

class GameState extends ChangeNotifier {
  int _currentChapter = 1;
  int _maxUnlockedChapter = 1;
  final Set<String> _collectedEvidence = {};
  final Set<String> _completedMiniGames = {};
  int _currentTab = 0;
  bool _splashDone = false;
  String? _viewingCharacterId;
  int? _viewingChatWith;
  int? _viewingStoryGroup;

  int get currentChapter => _currentChapter;
  int get maxUnlockedChapter => _maxUnlockedChapter;
  Set<String> get collectedEvidence => _collectedEvidence;
  Set<String> get completedMiniGames => _completedMiniGames;
  int get currentTab => _currentTab;
  bool get splashDone => _splashDone;
  String? get viewingCharacterId => _viewingCharacterId;
  int? get viewingChatWith => _viewingChatWith;
  int? get viewingStoryGroup => _viewingStoryGroup;

  void finishSplash() { _splashDone = true; notifyListeners(); }
  void setTab(int t) { _currentTab = t; notifyListeners(); }
  void viewCharacter(String? id) { _viewingCharacterId = id; notifyListeners(); }
  void viewChat(int? idx) { _viewingChatWith = idx; notifyListeners(); }
  void viewStory(int? idx) { _viewingStoryGroup = idx; notifyListeners(); }

  void advanceChapter(int ch) {
    if (ch > _maxUnlockedChapter) _maxUnlockedChapter = ch;
    _currentChapter = ch;
    notifyListeners();
  }

  void addEvidence(String id) { _collectedEvidence.add(id); notifyListeners(); }
  void completeMiniGame(String id) { _completedMiniGames.add(id); notifyListeners(); }
  bool hasEvidence(String id) => _collectedEvidence.contains(id);
  bool hasCompletedGame(String id) => _completedMiniGames.contains(id);
}

// ═══════════════════════════════════════════
// ДАННЫЕ ИГРЫ
// ═══════════════════════════════════════════

const alyonaId = 'alyona';
const dimaId = 'dima';
const marinaId = 'marina';
const victorId = 'victor';
const lenaId = 'lena';
const olegId = 'oleg';

List<Chapter> getChapters() => const [
  Chapter(number: 1, title: 'Необычное молчание', subtitle: 'Глава 1',
    description: 'Популярная блогерша Алёна Волкова не выходит на связь второй день. Её подписчики в панике. Вы — кибер-детектив, и ваше расследование начинается с ленты.',
    characterFocus: alyonaId),
  Chapter(number: 2, title: 'Последний пост', subtitle: 'Глава 2',
    description: 'Последняя публикация Алёны выглядит как крик о помощи. С comments раскрывается картина напряжённых отношений.',
    characterFocus: alyonaId,
    miniGame: MiniGame(type: 'photo_search', title: 'Фото-анализ',
      instruction: 'Нажмите на 5 подозрительных фрагментов на последнем фото Алёны.',
      data: {'grid': '5x4', 'clues': [2,6,9,13,17], 'label': 'photo_ch2'})),
  Chapter(number: 3, title: 'Два лица', subtitle: 'Глава 3',
    description: 'Профиль Димы скрывает больше, чем показывает. Удалённые посты и агрессивные комментарии — первый звоночек.',
    characterFocus: dimaId,
    miniGame: MiniGame(type: 'cipher', title: 'Расшифруй сообщение',
      instruction: 'Дима зашифровал сообщение шифром Цезаря (сдвиг 3). Расшифруйте его.',
      data: {'encrypted': 'ОХКЛБ ЦЮЪХЛ ЪВЛЭЛБО — ДП ЕЦСВЛХ', 'answer': 'ЛЮБЛЮ ДЕНЬГИ — ВСЁ ПРОДАМ', 'shift': 3})),
  Chapter(number: 4, title: 'Скрытые переписки', subtitle: 'Глава 4',
    description: 'С ордером на цифровую экспертизу вы получаете доступ к личным сообщениям Алёны. Переписки с подозревающими раскрывают мотивы.',
    characterFocus: alyonaId,
    miniGame: MiniGame(type: 'word_puzzle', title: 'Восстанови сообщение',
      instruction: 'Сообщение Алёны было уничтожено. Соберите правильный порядок слов.',
      data: {'words': ['Он', 'знает', 'о', 'сделке', 'и', 'угрожает', 'мне'], 'answer': 'Он знает о сделке и угрожает мне'})),
  Chapter(number: 5, title: 'Тень PR', subtitle: 'Глава 5',
    description: 'Виктор Орлов — глава PR-агентства, где работала Алёна. Его профиль пестрит корпоративным сиянием, но в тени скрываются угрозы.',
    characterFocus: victorId,
    miniGame: MiniGame(type: 'match', title: 'Свяжи улики',
      instruction: 'Соедините каждую улику с правильным подозреваемым.',
      data: {'pairs': [
        {'clue': 'Угрозы увольнения', 'suspect': 'Виктор Орлов'},
        {'clue': 'Застрахована жизнь', 'suspect': 'Дима Кравцов'},
        {'clue': 'Фейковые аккаунты', 'suspect': 'Лена Морозова'},
        {'clue': 'Компрометирующие фото', 'suspect': 'Олег Тимошенко'},
      ]})),
  Chapter(number: 6, title: 'Подделка', subtitle: 'Глава 6',
    description: 'Лена Морозова — соперница Алёны. Её посты suspiciously совпадают по времени с исчезновением. Фейковые аккаунты травили Алёну месяцами.',
    characterFocus: lenaId,
    miniGame: MiniGame(type: 'spot_fake', title: 'Найди фейк',
      instruction: 'Среди 4 профилей найдите фейковый аккаунт по признакам.',
      data: {'profiles': [
        {'name': 'anastasia_true', 'followers': '12.4K', 'posts': 234, 'joined': '2019', 'fake': false},
        {'name': 'masha_style88', 'followers': '892', 'posts': 5, 'joined': '2024', 'fake': true},
        {'name': 'katya_kreativ', 'followers': '8.1K', 'posts': 156, 'joined': '2020', 'fake': false},
        {'name': 'sveta_beauty_x', 'followers': '1.2K', 'posts': 3, 'joined': '2024', 'fake': true},
      ], 'fake_indices': [1, 3]})),
  Chapter(number: 7, title: 'Объектив', subtitle: 'Глава 7',
    description: 'Олег Тимошенко — фотограф с тёмной репутацией. Его снимки с последней вечеринки могут стать ключом к разгадке.',
    characterFocus: olegId,
    miniGame: MiniGame(type: 'photo_search', title: 'Найди улики на фото',
      instruction: 'На снимке вечеринки спрятаны 4 важные детали. Нажмите на них.',
      data: {'grid': '4x4', 'clues': [1,5,10,14], 'label': 'party_ch7'})),
  Chapter(number: 8, title: 'Паутина', subtitle: 'Глава 8',
    description: 'Все нити сходятся. Финансовые махинации, страховой контракт, шантаж и ревность — каждый имел мотив.',
    characterFocus: null,
    miniGame: MiniGame(type: 'timeline', title: 'Хронология',
      instruction: 'Расставьте события в правильном хронологическом порядке.',
      data: {'events': [
        'Алёна узнаёт о махинациях Виктора',
        'Дима оформляет страховку на 5 млн',
        'Лена создаёт фейковые аккаунты',
        'Олег фотографирует тайную встречу',
        'Алёна получает угрозы от Виктора',
        'Алёна пишет Marina о страхе',
        'Вечеринка — последняя встреча всех',
        'Алёна не выходит на связь',
      ], 'answer': [0,1,2,3,4,5,6,7]})),
  Chapter(number: 9, title: 'Тот вечер', subtitle: 'Глава 9',
    description: 'Восстановленные сторис показывают вечер перед исчезновением. Каждый рассказывает свою версию. Но кто-то лжёт.',
    characterFocus: null,
    miniGame: MiniGame(type: 'deduction', title: 'Анализ показаний',
      instruction: 'Определите, кто лжёт. У каждого есть мотив, но только у одного — возможность.',
      data: {
        'suspects': ['Дима Кравцов', 'Виктор Орлов', 'Лена Морозова'],
        'clues': [
          'Камера у подъезда: Дима ушёл в 22:15',
          'Лена была на стриме с 21:00 до 23:30',
          'Виктор не подозревал камеры',
          'Олег видел Виктора у дома в 23:00',
        ],
        'answer': 'Виктор Орлов'
      })),
  Chapter(number: 10, title: 'Истина', subtitle: 'Финал',
    description: 'Все улики собраны. Ключевой свидетель готов дать показания. Настало время назвать имя убийцы.',
    characterFocus: null,
    miniGame: MiniGame(type: 'final_choice', title: 'Вердикт',
      instruction: 'Кто убил Алёну Волкову? Выберите, основываясь на собранных уликах.',
      data: {
        'options': ['Дима Кравцов', 'Виктор Орлов', 'Лена Морозова'],
        'correct': 'Виктор Орлов',
        'explanation': 'Виктор Орлов убил Алёну, чтобы скрыть корпоративные махинации. Угрозы, зафиксированные в переписке, и свидетель Олега — ключевые улики.'
      })),
];

List<Evidence> getEvidenceItems() => const [
  Evidence(id: 'ev_last_post', title: 'Последний пост', description: 'Криптическое фото с подписью «Кто-то слишком много знает...»', characterId: alyonaId, chapterFound: 2, icon: Icons.photo_camera),
  Evidence(id: 'ev_dima_cipher', title: 'Зашифрованное сообщение', description: 'Дима зашифровал переписку с сообщником о деньгах.', characterId: dimaId, chapterFound: 3, icon: Icons.lock),
  Evidence(id: 'ev_alena_dm', title: 'Личные сообщения', description: 'Алёна писала о страхе и угрозах от начальника.', characterId: alyonaId, chapterFound: 4, icon: Icons.chat),
  Evidence(id: 'ev_victor_threat', title: 'Угрозы Орлова', description: 'В записанных сторис видны угрозы Виктора в адрес Алёны.', characterId: victorId, chapterFound: 5, icon: Icons.warning),
  Evidence(id: 'ev_fake_accounts', title: 'Фейковые аккаунты', description: 'Лена Морозова управляла травлей через фейковые профили.', characterId: lenaId, chapterFound: 6, icon: Icons.person_off),
  Evidence(id: 'ev_party_photo', title: 'Фото вечеринки', description: 'На фото — напряжённая беседа Виктора и Алёны.', characterId: olegId, chapterFound: 7, icon: Icons.image),
  Evidence(id: 'ev_insurance', title: 'Страховой полис', description: 'Дима застраховал жизнь Алёны на 5 млн за неделю до смерти.', characterId: dimaId, chapterFound: 8, icon: Icons.description),
  Evidence(id: 'ev_oleg_testimony', title: 'Показания Олега', description: 'Олег видел Виктора у дома Алёны в 23:00 — когда все думали, что он ушёл.', characterId: olegId, chapterFound: 9, icon: Icons.visibility),
];

List<Character> getCharacters() => [
  // АЛЁНА ВОЛКОВА — жертва
  Character(id: alyonaId, name: 'Алёна Волкова', username: '@alyona_v',
    bio: 'Lifestyle | Travel | ❤️ Москва\n2x Best Blogger Award\nPR-менеджер в Diamond Agency',
    avatarColor: '#FF6B9D', initials: 'АВ', followers: 215000, following: 342, isVictim: true,
    posts: [
      Post(id: 'p1', characterId: alyonaId, time: '15.05 • 09:12',
        text: 'Утро начинается с кофе и планирования ✨ Сегодня большой съёмочный день в Diamond Agency. Кто-то скажет — легко, но вы бы видели график 😅',
        likes: 4521, comments: 87, chapterUnlock: 1,
        commentList: [Comment(characterId: marinaId, text: 'Удачи на съёмках! 💕', time: '09:15'), Comment(characterId: lenaId, text: 'Опять реклама...', time: '09:20')]),
      Post(id: 'p2', characterId: alyonaId, time: '12.05 • 14:30',
        text: 'Когда план на день идёт не по плану 😅 Но мы справляемся! #bloggerlife #contentcreator',
        likes: 3201, comments: 54, chapterUnlock: 1,
        commentList: [Comment(characterId: dimaId, text: 'Красавуля ❤️', time: '14:32')]),
      Post(id: 'p3', characterId: alyonaId, time: '10.05 • 23:45',
        text: 'Последнее время чувствую, что за мной наблюдают. Может, паранойя... Но лучше проверю камеру в квартире.',
        likes: 1204, comments: 31, chapterUnlock: 1,
        commentList: [Comment(characterId: marinaId, text: 'Алёна, всё нормально?? Звонила тебе!', time: '23:50')]),
      Post(id: 'p4', characterId: alyonaId, time: '08.05 • 20:15',
        text: 'Иногда работа — это не блеск и камера. Иногда это тёмный офис и документы, которые лучше бы не видеть. Но молчать нельзя.',
        likes: 2876, comments: 62, chapterUnlock: 1,
        commentList: [
          Comment(characterId: victorId, text: 'Алёна, надо обсудить твои посты. Офис, завтра 10:00.', time: '20:30'),
          Comment(characterId: marinaId, text: 'Ты в порядке? Звоню — не берёшь', time: '21:00'),
          Comment(characterId: dimaId, text: 'Чего ты вечно драму создаёшь?', time: '21:15'),
        ]),
      Post(id: 'p5', characterId: alyonaId, time: '05.05 • 22:00',
        text: 'Кто-то слишком много знает... 📸',
        imageData: 'dark_street', likes: 987, comments: 45, chapterUnlock: 2, isEvidence: true, evidenceHint: 'Последний пост — кажется, фото сделано в спешке. Рассмотрите детали.',
        commentList: [
          Comment(characterId: marinaId, text: 'АЛЁНА!!! Что происходит???', time: '22:05'),
          Comment(characterId: dimaId, text: 'Опять эти загадки. Устал уже.', time: '22:10'),
          Comment(characterId: victorId, text: 'Рекомендую быть осторожнее со словами.', time: '22:20'),
          Comment(characterId: lenaId, text: 'Кричишь «внимание» как обычно 🙄', time: '22:25'),
          Comment(characterId: olegId, text: 'Красивый кадр, но атмосфера тревожная.', time: '22:30'),
        ]),
    ],
    stories: [
      Story(id: 's1', characterId: alyonaId, chapterUnlock: 1, slides: [
        StorySlide(text: 'Всем привет! Сегодня расскажу про мой обычный день ☀️', gradientTop: '#FF6B9D', gradientBottom: '#C44569'),
        StorySlide(text: 'Утром — coffee run ☕ Потом в офис Diamond Agency. Намечается интересный проект...', gradientTop: '#C44569', gradientBottom: '#6C63FF'),
        StorySlide(text: 'Вообще, последнее время в агентстве что-то происходит. Файлы, которые я не должна видеть. Документы без подписей.', gradientTop: '#6C63FF', gradientBottom: '#0D1220'),
        StorySlide(text: 'Может, показалось. Но если что — вы первые узнаете. 💙', gradientTop: '#0D1220', gradientBottom: '#FF6B9D'),
      ]),
      Story(id: 's2', characterId: alyonaId, chapterUnlock: 1, slides: [
        StorySlide(text: '😭 Случайно удалила сторис, но суть: я увидела что-то в офисе. Не могу молчать, но и сказать боюсь...', gradientTop: '#FF6B9D', gradientBottom: '#8B0000'),
        StorySlide(text: 'Виктор сказал: «Тебе лучше не лезть в то, что тебя не касается». Это была не просьба.', gradientTop: '#8B0000', gradientBottom: '#330000'),
      ]),
      Story(id: 's3', characterId: alyonaId, chapterUnlock: 1, slides: [
        StorySlide(text: 'Мне страшно. Три дня подряд кто-то стоит под окном. Дима говорит — паранойя. Но я видела силуэт.', gradientTop: '#1A0A2E', gradientBottom: '#0D0D0D'),
        StorySlide(text: 'Если со мной что-то случится — Marina знает всё. Записала ей голосовое 🎤', gradientTop: '#0D0D0D', gradientBottom: '#1A0A2E'),
      ]),
    ],
    messages: [
      ChatMessage(id: 'm1', fromId: marinaId, toId: alyonaId, time: '12.05 • 01:30', text: 'Алёна, ты спишь? Мне нужно рассказать. Нашла инфу по Diamond Agency.', chapterUnlock: 4),
      ChatMessage(id: 'm2', fromId: alyonaId, toId: marinaId, time: '12.05 • 08:15', text: 'Да, что там?', chapterUnlock: 4),
      ChatMessage(id: 'm3', fromId: marinaId, toId: alyonaId, time: '12.05 • 08:20', text: 'Виктор отмывает деньги через фиктивные контракты. Алёна, это серьёзно. Суммы — миллионы.', chapterUnlock: 4),
      ChatMessage(id: 'm4', fromId: alyonaId, toId: marinaId, time: '12.05 • 08:25', text: 'Я знаю. Я видела файлы. Виктор пригрозил, если скажу кому-то.', chapterUnlock: 4),
      ChatMessage(id: 'm5', fromId: marinaId, toId: alyonaId, time: '12.05 • 08:30', text: 'Тебе нужно уйти оттуда. Немедленно. Это опасно.', chapterUnlock: 4),
      ChatMessage(id: 'm6', fromId: victorId, toId: alyonaId, time: '13.05 • 22:00', text: 'Алёна, я знаю, что ты видела в бухгалтерии. Поговорим завтра. Без вариантов.', chapterUnlock: 4),
      ChatMessage(id: 'm7', fromId: alyonaId, toId: victorId, time: '13.05 • 22:05', text: 'Виктор, я не хочу проблем. Просто хочу работать.', chapterUnlock: 4),
      ChatMessage(id: 'm8', fromId: victorId, toId: alyonaId, time: '13.05 • 22:10', text: 'Тогда молчи. Иначе последствия будут для всех. Особенно для тебя.', chapterUnlock: 4),
      ChatMessage(id: 'm9', fromId: dimaId, toId: alyonaId, time: '08.05 • 23:00', text: 'Ты опять на работе допоздна? Надоело это.', chapterUnlock: 4),
      ChatMessage(id: 'm10', fromId: alyonaId, toId: dimaId, time: '08.05 • 23:05', text: 'Дима, не начинай. У меня проблемы на работе.', chapterUnlock: 4),
      ChatMessage(id: 'm11', fromId: dimaId, toId: alyonaId, time: '08.05 • 23:10', text: 'У тебя всегда проблемы. Заканчивай эти драмы, мне рано вставать.', chapterUnlock: 4, isDeleted: true),
    ],
  ),

  // ДИМА КРАВЦОВ — парень
  Character(id: dimaId, name: 'Дима Кравцов', username: '@dima_kr',
    bio: 'Entrepreneur | Crypto | 💎\nCEO @ Kravsov Digital\n«Успех — это когда тебе завидуют»',
    avatarColor: '#4A90D9', initials: 'ДК', followers: 89000, following: 124,
    posts: [
      Post(id: 'd1', characterId: dimaId, time: '10.05 • 12:00',
        text: 'Новый проект — новые горизонты 🚀 Крипта не ждёт,市場 растёт, а мы растём вместе с ним. Инвестируйте с умом.',
        likes: 1203, comments: 67, chapterUnlock: 3,
        commentList: [Comment(characterId: alyonaId, text: 'Гордюсь тобой ❤️', time: '12:05')]),
      Post(id: 'd2', characterId: dimaId, time: '08.05 • 21:00',
        text: '[УДАЛЕНО] — контент недоступен',
        likes: 0, comments: 0, chapterUnlock: 3,
        commentList: []),
      Post(id: 'd3', characterId: dimaId, time: '05.05 • 19:30',
        text: 'Вечер в ресторане с любимой 🍷 @alyona_v — ты лучшее, что случалось в моей жизни.',
        likes: 3402, comments: 112, chapterUnlock: 3,
        commentList: [
          Comment(characterId: marinaId, text: 'Хотя бы кто-то счастлив в этой истории 😔', time: '19:35'),
          Comment(characterId: olegId, text: 'Отличный кадр!', time: '19:40'),
        ]),
      Post(id: 'd4', characterId: dimaId, time: '15.05 • 10:00',
        text: 'Алёна не выходит на связь со вчерашнего дня. Если кто-то знает что-то — напишите в личку. Это серьёзно.',
        likes: 5621, comments: 234, chapterUnlock: 3, isEvidence: true, evidenceHint: 'Застрахованная жизнь Алёны...',
        commentList: [
          Comment(characterId: marinaId, text: 'Дима, я тоже пытаюсь дозвониться. Пойдём в полицию?', time: '10:05'),
          Comment(characterId: lenaId, text: 'Может, просто устала и отключила телефон?', time: '10:10'),
          Comment(characterId: victorId, text: 'Не паникуйте раньше времени.', time: '10:15'),
        ]),
    ],
    stories: [
      Story(id: 'sd1', characterId: dimaId, chapterUnlock: 3, slides: [
        StorySlide(text: 'Жизнь — это инвестиция. Каждый день — новая возможность. 💰', gradientTop: '#4A90D9', gradientBottom: '#1A3A5C'),
        StorySlide(text: '[УДАЛЕНО]', gradientTop: '#1A3A5C', gradientBottom: '#0D0D0D'),
        StorySlide(text: 'Иногда лучший шаг — тот, который другие считают рискованным. 🎲', gradientTop: '#1A3A5C', gradientBottom: '#4A90D9'),
      ]),
    ],
    messages: [
      ChatMessage(id: 'dm1', fromId: dimaId, toId: alyonaId, time: '05.05 • 18:00', text: 'Алёна, я оформил на тебя страховку. На всякий случай.', chapterUnlock: 3),
      ChatMessage(id: 'dm2', fromId: alyonaId, toId: dimaId, time: '05.05 • 18:05', text: 'Зачем страховка? Ты что, ожидаешь чего-то?', chapterUnlock: 3),
      ChatMessage(id: 'dm3', fromId: dimaId, toId: alyonaId, time: '05.05 • 18:10', text: 'Просто предосторожность. 5 миллионов. Ты для меня бесценна ❤️', chapterUnlock: 3),
      ChatMessage(id: 'dm4', fromId: dimaId, toId: olegId, time: '03.05 • 14:00', text: 'Олег, мне нужны те фото с вечеринки. Все.', chapterUnlock: 3),
      ChatMessage(id: 'dm5', fromId: olegId, toId: dimaId, time: '03.05 • 14:15', text: 'Какие именно? Там сотни кадров.', chapterUnlock: 3),
      ChatMessage(id: 'dm6', fromId: dimaId, toId: olegId, time: '03.05 • 14:20', text: 'Где Алёна с ним рядом. Удали. Все без исключения.', chapterUnlock: 3),
    ],
  ),

  // МАРИНА СОКОЛОВА — подруга-журналист
  Character(id: marinaId, name: 'Марина Соколова', username: '@marina_s',
    bio: 'Журналист | Investigative 📰\nИщу правду в тени spotlight\n«Перо сильнее меча»',
    avatarColor: '#7B2D8E', initials: 'МС', followers: 67000, following: 523,
    posts: [
      Post(id: 'mr1', characterId: marinaId, time: '13.05 • 16:00',
        text: 'Работаю над материалом о финансовых махинациях в одном известном PR-агентстве. Когда статья выйдет — будет громко. 🔍',
        likes: 1890, comments: 78, chapterUnlock: 4,
        commentList: [
          Comment(characterId: alyonaId, text: 'Марина, осторожно... эти люди опасны.', time: '16:05'),
          Comment(characterId: victorId, text: 'Очередные выдумки. Будьте готовы к суду.', time: '16:20'),
        ]),
      Post(id: 'mr2', characterId: marinaId, time: '15.05 • 07:00',
        text: 'МОЯ ПОДРУГА НЕ ВЫХОДИТ НА СВЯЗЬ ВТОРОЙ ДЕНЬ. Её телефон выключен. В её квартиру не отвечают. Если кто-нибудь что-то знает — ПОЖАЛУЙСТА, напишите мне.',
        likes: 12450, comments: 890, chapterUnlock: 1,
        commentList: [
          Comment(characterId: dimaId, text: 'Я в полиции. Жди.', time: '07:10'),
          Comment(characterId: olegId, text: 'Марина, держись. Я тоже ищу информацию.', time: '07:15'),
          Comment(characterId: lenaId, text: 'Мне жаль. Может, она просто хочет побыть одна?', time: '07:25'),
        ]),
    ],
    stories: [
      Story(id: 'sm1', characterId: marinaId, chapterUnlock: 4, slides: [
        StorySlide(text: '🔍 Следствие продолжается. Нашла связи между Diamond Agency и оффшорными компаниями.', gradientTop: '#7B2D8E', gradientBottom: '#2D0A3E'),
        StorySlide(text: 'Алёна передала мне файлы. Свидетельские показания. Записи. Всё зашифровано, но я работаю над этим.', gradientTop: '#2D0A3E', gradientBottom: '#7B2D8E'),
      ]),
    ],
    messages: [
      ChatMessage(id: 'mm1', fromId: marinaId, toId: olegId, time: '14.05 • 11:00', text: 'Олег, мне нужны фотографии с той вечеринки. Все, что у тебя есть.', chapterUnlock: 7),
      ChatMessage(id: 'mm2', fromId: olegId, toId: marinaId, time: '14.05 • 11:30', text: 'Не все. Но есть кое-что интересное. Виктор был рядом с её домом в ту ночь.', chapterUnlock: 7),
      ChatMessage(id: 'mm3', fromId: marinaId, toId: olegId, time: '14.05 • 11:35', text: 'Ты уверен?! Это может быть ключевой уликой!', chapterUnlock: 7),
      ChatMessage(id: 'mm4', fromId: olegId, toId: marinaId, time: '14.05 • 11:40', text: 'Уверён. Снял случайно на телефон. Время на фото — 23:02.', chapterUnlock: 7),
    ],
  ),

  // ВИКТОР ОРЛОВ — босс
  Character(id: victorId, name: 'Виктор Орлов', username: '@v_orlov',
    bio: 'CEO Diamond Agency 🏢\nPR • Branding • Strategy\n«Контроль — это всё»',
    avatarColor: '#2D2D2D', initials: 'ВО', followers: 45000, following: 89,
    posts: [
      Post(id: 'v1', characterId: victorId, time: '11.05 • 09:00',
        text: 'Diamond Agency — 10 лет на рынке! 🎉 Горд нашими результатами и командой. Спасибо всем, кто с нами. #DiamondDecade',
        likes: 6780, comments: 234, chapterUnlock: 5,
        commentList: [
          Comment(characterId: alyonaId, text: 'Поздравляю, Виктор! ❤️ 10 лет — это серьёзно.', time: '09:10'),
          Comment(characterId: marinaId, text: '10 лет тени и коррупции? Поздравляю.', time: '09:25'),
        ]),
      Post(id: 'v2', characterId: victorId, time: '06.05 • 17:00',
        text: 'Каждый в Diamond Agency знает: конфиденциальность — наш главный актив. Нарушителей ждут последствия.',
        likes: 2103, comments: 56, chapterUnlock: 5, isEvidence: true, evidenceHint: 'Угроза?',
        commentList: [
          Comment(characterId: olegId, text: 'Пугающе звучит...', time: '17:05'),
          Comment(characterId: dimaId, text: 'Правильно. Дисциплина — залог успеха.', time: '17:10'),
        ]),
      Post(id: 'v3', characterId: victorId, time: '15.05 • 11:00',
        text: 'Шокирующие новости об одной из наших сотрудниц.Diamond Agency полностью сотрудничает со следствием. Мы верим в правосудие.',
        likes: 3450, comments: 456, chapterUnlock: 5,
        commentList: [
          Comment(characterId: marinaId, text: 'Сотрудничаете? Или уничтожаете улики?', time: '11:10'),
          Comment(characterId: dimaId, text: 'Полиция уже у них?', time: '11:15'),
        ]),
    ],
    stories: [
      Story(id: 'sv1', characterId: victorId, chapterUnlock: 5, slides: [
        StorySlide(text: 'Diamond Agency — не просто компания. Это семья. И в семье все помогают друг другу. Даже когда не просят.', gradientTop: '#2D2D2D', gradientBottom: '#0D0D0D'),
        StorySlide(text: 'Кому-то кажется, что он умнее системы. Но система всегда побеждает. Всегда.', gradientTop: '#0D0D0D', gradientBottom: '#4A0000'),
      ]),
    ],
    messages: [
      ChatMessage(id: 'vm1', fromId: victorId, toId: dimaId, time: '04.05 • 15:00', text: 'Кравцов, ситуация усложняется. Алёна слишком много знает. Ты должен убедить её молчать.', chapterUnlock: 5),
      ChatMessage(id: 'vm2', fromId: dimaId, toId: victorId, time: '04.05 • 15:10', text: 'Я попробую. Но она упрямая.', chapterUnlock: 5),
      ChatMessage(id: 'vm3', fromId: victorId, toId: dimaId, time: '04.05 • 15:15', text: 'Попробуй как следует. Или я найду кого-то, кто справится лучше. Для всех будет лучше — поверь.', chapterUnlock: 5),
    ],
  ),

  // ЛЕНА МОРОЗОВА — соперница
  Character(id: lenaId, name: 'Лена Морозова', username: '@lena_beauty',
    bio: 'Beauty Blogger | 💄 Fashion\nКосметика, стиль и настоящая жизнь\n2x runner-up BlogAwards 🏆',
    avatarColor: '#E91E63', initials: 'ЛМ', followers: 178000, following: 456,
    posts: [
      Post(id: 'l1', characterId: lenaId, time: '06.05 • 20:00',
        text: 'Иногда лучший контент — это когда конкуренты проваливаются 😏 Но я не назову имён. Хотя все знают 🤫',
        likes: 8902, comments: 342, chapterUnlock: 6,
        commentList: [
          Comment(characterId: alyonaId, text: 'Лена, зачем ты это пишешь? Мы коллеги.', time: '20:10'),
          Comment(characterId: lenaId, text: 'Коллеги? Смешно. Мы конкуренты. Всегда были.', time: '20:15'),
        ]),
      Post(id: 'l2', characterId: lenaId, time: '05.05 • 21:00',
        text: 'Некоторые люди не заслуживают платформы. Но алгоритм справедлив — он повышает тех, кого читают. А кого-то — понижает. 📉',
        likes: 6234, comments: 567, chapterUnlock: 6, isEvidence: true, evidenceHint: 'Намёк на травлю?',
        commentList: [
          Comment(characterId: marinaId, text: 'Ты специально пишешь это, когда у Алёны проблемы?', time: '21:10'),
          Comment(characterId: lenaId, text: 'Я пишу то, что думаю. Не всё в мире про Алёну.', time: '21:15'),
        ]),
      Post(id: 'l3', characterId: lenaId, time: '15.05 • 09:00',
        text: 'Новости шокируют всех. Мои соболезнования семье. Я, конечно, не дружила с ней, но... Словно предупреждение. Мы все уязвимы.',
        likes: 7800, comments: 412, chapterUnlock: 6,
        commentList: [
          Comment(characterId: marinaId, text: '«Словно предупреждение»?? Ты серьёзно сейчас??', time: '09:05'),
        ]),
    ],
    stories: [
      Story(id: 'sl1', characterId: lenaId, chapterUnlock: 6, slides: [
        StorySlide(text: 'Make-up of the day 💄 Тёмные тона — сегодня в настроении.', gradientTop: '#E91E63', gradientBottom: '#880E4F'),
        StorySlide(text: 'Кстати, у меня есть info, которую все ищут. Но я пока не решаюсь... 💭', gradientTop: '#880E4F', gradientBottom: '#E91E63'),
      ]),
    ],
    messages: [
      ChatMessage(id: 'lm1', fromId: lenaId, toId: victorId, time: '02.05 • 13:00', text: 'Виктор, договорились? Я помогаю вам с Алёной, вы даёте мне эксклюзив на Diamond.', chapterUnlock: 6),
      ChatMessage(id: 'lm2', fromId: victorId, toId: lenaId, time: '02.05 • 13:05', text: 'Договорились. Травля через аккаунты — твоё дело. Я не хочу знать подробностей.', chapterUnlock: 6),
      ChatMessage(id: 'lm3', fromId: lenaId, toId: victorId, time: '02.05 • 13:10', text: 'И рекламный контракт на 2 года? Статья о кризис-PR?', chapterUnlock: 6),
      ChatMessage(id: 'lm4', fromId: victorId, toId: lenaId, time: '02.05 • 13:15', text: 'Когда Алёна перестанет быть проблемой — получите всё.', chapterUnlock: 6),
    ],
  ),

  // ОЛЕГ ТИМОШЕНКО — фотограф
  Character(id: olegId, name: 'Олег Тимошенко', username: '@oleg_photo',
    bio: 'Photographer 📸\nМосква | Events | Portraits\n«Камера не врёт — даже когда люди врут»',
    avatarColor: '#FF9800', initials: 'ОТ', followers: 34000, following: 278,
    posts: [
      Post(id: 'o1', characterId: olegId, time: '09.05 • 18:00',
        text: 'Новые кадры с corporate-party Diamond Agency. Фотография — это не искусство, это документация. Иногда — улика.',
        likes: 2105, comments: 56, chapterUnlock: 7,
        commentList: [
          Comment(characterId: victorId, text: 'Олег, удали некоторые кадры. Мы обсуждали это.', time: '18:30'),
          Comment(characterId: olegId, text: 'Я фотографирую реальность. Не продаю её.', time: '18:35'),
        ]),
      Post(id: 'o2', characterId: olegId, time: '15.05 • 08:00',
        text: 'Вау. Новости об Алёне. Я... не знаю что сказать. У меня есть кое-что, что может помочь. Напишу следователю.',
        likes: 8900, comments: 345, chapterUnlock: 7,
        commentList: [
          Comment(characterId: marinaId, text: 'Олег, мне тоже напиши. Пожалуйста.', time: '08:05'),
          Comment(characterId: dimaId, text: 'Ты лучше удали то, что у тебя есть.', time: '08:15'),
        ]),
      Post(id: 'o3', characterId: olegId, time: '07.05 • 22:00',
        text: 'Иногда камера видит то, чего не замечают глаза. Вечеринка 7 мая — тому пример. Реальность сложнее, чем кажется.',
        likes: 1450, comments: 32, chapterUnlock: 7, isEvidence: true, evidenceHint: 'Фотография с Виктором...',
        commentList: [
          Comment(characterId: marinaId, text: 'Что ты имеешь в виду?', time: '22:10'),
          Comment(characterId: olegId, text: 'Покажу когда придёт время.', time: '22:15'),
        ]),
    ],
    stories: [
      Story(id: 'so1', characterId: olegId, chapterUnlock: 7, slides: [
        StorySlide(text: 'Последняя вечеринка, которую я снимал. Было всё: смех, слёзы, тайны. Камера фиксирует всё.', gradientTop: '#FF9800', gradientBottom: '#4A2800'),
        StorySlide(text: 'Я видел, как Виктор подошёл к Алёне после полуночи. Она отстранилась. Он схватил её за руку. Я сфотографировал.', gradientTop: '#4A2800', gradientBottom: '#8B0000'),
        StorySlide(text: 'Сейчас я спрашиваю себя: если бы я тогда вмешался... Камера — не щит. Но она — свидетель.', gradientTop: '#8B0000', gradientBottom: '#0D0D0D'),
      ]),
    ],
    messages: [],
  ),
];
