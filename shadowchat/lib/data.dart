import 'dart:convert';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
// МОДЕЛИ
// ═══════════════════════════════════════════

class ChatCharacter {
  final String id;
  final String name;
  final String avatarEmoji;
  final Color avatarColor;
  final String bio;
  final String phone;
  final bool isHidden;
  final bool isOnline;

  const ChatCharacter({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    required this.bio,
    required this.phone,
    this.isHidden = false,
    this.isOnline = false,
  });
}

class ChatMsg {
  final String id;
  final String fromId;
  final String text;
  final String? imageUrl;
  final String? voiceNoteText;
  final bool isDeleted;
  final int chapter;
  final int delayMs;
  final List<String>? playerChoices;
  final bool isSystem;

  const ChatMsg({
    required this.id,
    required this.fromId,
    required this.text,
    this.imageUrl,
    this.voiceNoteText,
    this.isDeleted = false,
    required this.chapter,
    this.delayMs = 0,
    this.playerChoices,
    this.isSystem = false,
  });
}

class PhoneCall {
  final String id;
  final String callerId;
  final String transcript;
  final int durationSec;
  final int chapter;
  final bool isIncoming;

  const PhoneCall({
    required this.id,
    required this.callerId,
    required this.transcript,
    required this.durationSec,
    required this.chapter,
    this.isIncoming = true,
  });
}

class Evidence {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int chapterFound;
  final IconData icon;

  const Evidence({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.chapterFound,
    required this.icon,
  });
}

class ChapterInfo {
  final int number;
  final String title;
  final String description;
  final String? characterUnlock;

  const ChapterInfo({
    required this.number,
    required this.title,
    required this.description,
    this.characterUnlock,
  });
}

class MiniGameData {
  final String type;
  final String title;
  final String instruction;
  final Map<String, dynamic> data;

  const MiniGameData({
    required this.type,
    required this.title,
    required this.instruction,
    required this.data,
  });
}

// ═══════════════════════════════════════════
// СОСТОЯНИЕ ИГРЫ
// ═══════════════════════════════════════════

class GameState extends ChangeNotifier {
  int _currentChapter = 1;
  int _maxUnlockedChapter = 1;
  final Set<String> _seenMessages = {};
  final Set<String> _collectedEvidence = {};
  final Set<String> _completedMinigames = {};
  final Set<String> _unlockedCharacters = {};
  bool _splashDone = false;
  int _currentTab = 0;
  String? _activeChatId;
  bool _isTyping = false;

  int get currentChapter => _currentChapter;
  int get maxUnlockedChapter => _maxUnlockedChapter;
  bool get splashDone => _splashDone;
  int get currentTab => _currentTab;
  String? get activeChatId => _activeChatId;
  bool get isTyping => _isTyping;

  void finishSplash() { _splashDone = true; notifyListeners(); }
  void setTab(int t) { _currentTab = t; notifyListeners(); }
  void openChat(String id) { _activeChatId = id; notifyListeners(); }
  void closeChat() { _activeChatId = null; notifyListeners(); }
  void setTyping(bool v) { _isTyping = v; notifyListeners(); }

  bool hasSeen(String msgId) => _seenMessages.contains(msgId);
  void markSeen(String msgId) { _seenMessages.add(msgId); notifyListeners(); }

  bool isCharUnlocked(String charId) => _unlockedCharacters.contains(charId) || charId == 'unknown';
  void unlockChar(String id) { _unlockedCharacters.add(id); notifyListeners(); }

  void advanceChapter(int ch) {
    if (ch > _maxUnlockedChapter) _maxUnlockedChapter = ch;
    _currentChapter = ch;
    if (ch <= 10) {
      final chars = getCharacters();
      for (final c in chars) {
        if (c.isHidden && ch >= _charUnlockChapter(c.id)) {
          unlockChar(c.id);
        }
      }
    }
    notifyListeners();
  }

  int _charUnlockChapter(String charId) {
    const map = {'darya': 1, 'max': 2, 'andrey': 3, 'victor': 4, 'natasha': 5, 'kira': 8};
    return map[charId] ?? 99;
  }

  void addEvidence(String id) { _collectedEvidence.add(id); notifyListeners(); }
  bool hasEvidence(String id) => _collectedEvidence.contains(id);
  void completeMinigame(String id) { _completedMinigames.add(id); notifyListeners(); }
  bool hasMinigameDone(String id) => _completedMinigames.contains(id);
}

// ═══════════════════════════════════════════
// ВСЕ ДАННЫЕ ИГРЫ
// ═══════════════════════════════════════════

const _unknown = 'unknown';
const _darya = 'darya';
const _max = 'max';
const _andrey = 'andrey';
const _victor = 'victor';
const _natasha = 'natasha';
const _kira = 'kira';

List<ChatCharacter> getCharacters() => [
  const ChatCharacter(id: _unknown, name: 'Неизвестный', avatarEmoji: '?', avatarColor: Color(0xFF555555),
    bio: 'Номер не определён. Статус: аноним.', phone: '+7 (999) ***-**-03', isOnline: true),
  const ChatCharacter(id: _darya, name: 'Даша', avatarEmoji: 'D', avatarColor: Color(0xFF9C27B0),
    bio: 'Дарья Литвинова. Лучшая подруга Киры. 22 года. Официантка.', phone: '+7 (916) 445-12-07', isHidden: true),
  const ChatCharacter(id: _max, name: 'Макс', avatarEmoji: 'M', avatarColor: Color(0xFF2196F3),
    bio: 'Максим Волков. Парень Киры. 24 года. Студент-юрист.', phone: '+7 (903) 778-33-41', isHidden: true),
  const ChatCharacter(id: _andrey, name: 'Андрей', avatarEmoji: 'A', avatarColor: Color(0xFF4CAF50),
    bio: 'Андрей Смирнов. Следователь. 35 лет. 8 лет в отделе.', phone: '+7 (495) 221-88-50', isHidden: true),
  const ChatCharacter(id: _victor, name: 'Виктор', avatarEmoji: 'V', avatarColor: Color(0xFFFF9800),
    bio: 'Виктор Петров. Владелец кафе «Уголёк». 45 лет.', phone: '+7 (926) 112-90-65', isHidden: true),
  const ChatCharacter(id: _natasha, name: 'Наташа', avatarEmoji: 'N', avatarColor: Color(0xFFE91E63),
    bio: 'Наташа Козлова. Соседка Киры. 28 лет. Фотограф.', phone: '+7 (977) 334-56-12', isHidden: true),
  const ChatCharacter(id: _kira, name: 'Кира', avatarEmoji: 'K', avatarColor: Color(0xFF607D8B),
    bio: 'Кира Белова. 21 год. Исчезла 3 дня назад. Студентка.', phone: '+7 (915) 667-88-23', isHidden: true),
];

List<ChapterInfo> getChapters() => const [
  ChapterInfo(number: 1, title: 'Неизвестный номер', description: 'Вам пишет незнакомец. Кому-то нужна помощь, но не всем можно доверять.'),
  ChapterInfo(number: 2, title: 'Последний вечер', description: 'Кто-то видел Киру в последний вечер. Но показания расходятся.'),
  ChapterInfo(number: 3, title: 'Сыск', description: 'Следователь Смирнов ведёт дело. Но его интерес к вам подозрителен.'),
  ChapterInfo(number: 4, title: 'Уголёк', description: 'Кафе «Уголёк» — последнее рабочее место Киры. Что скрывает владелец?'),
  ChapterInfo(number: 5, title: 'Соседка', description: 'Наташа — соседка Киры — слышала то, чего не должна была слышать.'),
  ChapterInfo(number: 6, title: 'Записи', description: 'Обнаружены записи с камер наблюдения. Кто-то их удалил.'),
  ChapterInfo(number: 7, title: 'Двойное дно', description: 'У каждого есть секрет. Но один секрет опаснее всех.'),
  ChapterInfo(number: 8, title: 'Призрак', description: 'Сообщение от Киры. Но Кира пропала 5 дней назад. Кто держит её телефон?'),
  ChapterInfo(number: 9, title: 'Раскрытие', description: 'Все фрагменты складываются в картину. И она пугает.'),
  ChapterInfo(number: 10, title: 'Ответ', description: 'Вы знаете правду. Но правда может стоить слишком дорого.'),
];

// СООБЩЕНИЯ ДЛЯ КАЖДОГО КОНТАКТА
List<ChatMsg> getMessagesFor(String charId) {
  switch (charId) {
    case _unknown: return _unknownMsgs;
    case _darya: return _daryaMsgs;
    case _max: return _maxMsgs;
    case _andrey: return _andreyMsgs;
    case _victor: return _victorMsgs;
    case _natasha: return _natashaMsgs;
    case _kira: return _kiraMsgs;
    default: return [];
  }
}

// ═══ НЕИЗВЕСТНЫЙ ═══
const _unknownMsgs = [
  ChatMsg(id: 'u1', fromId: _unknown, text: 'Привет. Мне нужна помощь. Пожалуйста, прочитай это.', chapter: 1, delayMs: 500),
  ChatMsg(id: 'u2', fromId: _unknown, text: 'Мою подругу Киру не нашли уже третий день. Полиция говорит — «уехала voluntarily». Но это ложь.', chapter: 1, delayMs: 2000),
  ChatMsg(id: 'u3', fromId: _unknown, text: 'Я не могу идти в полицию. Меня видят с ней — и я стану подозреваемой. Мне нужен кто-то со стороны. Кто-то, кто сможет узнать правду.', chapter: 1, delayMs: 2500),
  ChatMsg(id: 'u4', fromId: 'player', text: '', chapter: 1, playerChoices: [
    'Кто ты? Почему пишешь именно мне?',
    'Я помогу. Расскажи подробнее.',
    'Это какая-то шутка?',
  ]),
  ChatMsg(id: 'u5a', fromId: _unknown, text: 'Меня зовут... неважно. Пока неважно. Я нашла твой номер в записях Киры. Ты был в её контактах под пометкой «если что-то случится».', chapter: 1, delayMs: 1500),
  ChatMsg(id: 'u5b', fromId: _unknown, text: 'Кира Белова, 21 год. Студентка, работает официанткой в кафе «Уголёк». Три дня назад после смены она не вернулась домой.', chapter: 1, delayMs: 1500),
  ChatMsg(id: 'u6', fromId: _unknown, text: 'Её телефон выключен. Друзья в панике. Парень говорит, что они поругались. Но я знаю — она бы не ушла просто так. Она боялась.', chapter: 1, delayMs: 3000),
  ChatMsg(id: 'u7', fromId: _unknown, text: 'У неё были проблемы на работе. Она говорила, что нашла что-то в документах кафе. Что-то, чего не должна была видеть.', chapter: 1, delayMs: 2000),
  ChatMsg(id: 'u8', fromId: _unknown, text: 'Я даю тебе номер её подруги Даши. Она первая, кому нужно позвонить. Не говори ей, что от меня. Скажи — просто знаешь Киру.', chapter: 1, delayMs: 2500),
  ChatMsg(id: 'u9', fromId: 'system', text: 'CONTACT_UNLOCK:darya', isSystem: true, chapter: 1),

  // Глава 3
  ChatMsg(id: 'u10', fromId: _unknown, text: 'Следователь Смирнов — не тот, кем кажется. Будь осторожен.', chapter: 3, delayMs: 1500),
  ChatMsg(id: 'u11', fromId: 'player', text: '', chapter: 3, playerChoices: [
    'Откуда ты знаешь про следователя?',
    'Почему я должен тебе верить?',
  ]),
  ChatMsg(id: 'u12', fromId: _unknown, text: 'Потому что я знаю больше, чем показываю. Просто... доверься мне. Пока. Если я ошибаюсь — ты ничего не теряешь. А если прав — ты спасёшь жизнь.', chapter: 3, delayMs: 2000),

  // Глава 5
  ChatMsg(id: 'u13', fromId: _unknown, text: 'Наташа — ключ. Она видела то, что происходит по вечерам в доме напротив. Она слишком боится говорить.', chapter: 5, delayMs: 1000),

  // Глава 7
  ChatMsg(id: 'u14', fromId: _unknown, text: 'Я должна тебе кое-что сказать. Я не просто подруга Киры. Мы были ближе, чем ты думаешь.', chapter: 7, delayMs: 2000),
  ChatMsg(id: 'u15', fromId: _unknown, text: 'Кира нашла финансовые махинации в «Уголёке». Налоговые схемы. И она собиралась сообщить об этом. Виктор — не просто владелец кафе.', chapter: 7, delayMs: 3000),
  ChatMsg(id: 'u16', fromId: 'player', text: '', chapter: 7, playerChoices: [
    'Кто ты на самом деле?',
    'Зачем Виктору её убивать?',
  ]),
  ChatMsg(id: 'u17', fromId: _unknown, text: 'Виктор отмывает деньги. Через кафе. Кира увидела records — миллионы рублей. Она записала всё на флешку и спрятала. Виктор это узнал.', chapter: 7, delayMs: 2500),
  ChatMsg(id: 'u18', fromId: _unknown, text: 'А я... я Наташа. Соседка Киры. Я использовала анонимный номер, потому что боюсь. Виктор следит за всеми, кто близок к Кире.', chapter: 7, delayMs: 3000),
  ChatMsg(id: 'u19', fromId: _unknown, text: 'Теперь ты знаешь. Будь осторожен. Пожалуйста.', chapter: 7, delayMs: 1500),

  // Глава 9
  ChatMsg(id: 'u20', fromId: _unknown, text: 'Кира жива. Она у Виктора в подвале. Я слышала голос через стену. Но я не могу доказать это полиции — Смирнов его прикрывает.', chapter: 9, delayMs: 1000),
  ChatMsg(id: 'u21', fromId: 'player', text: '', chapter: 9, playerChoices: [
    'Надо звонить в полицию. Не в местную — в федеральную.',
    'Я сам поеду к кафе.',
  ]),
  ChatMsg(id: 'u22', fromId: _unknown, text: 'Нет. Смирнов перехватит вызов. У него связи. Нужен план. Я отправлю тебе адрес склада за кафе. Там держат Киру.', chapter: 9, delayMs: 2000),
  ChatMsg(id: 'u23', fromId: _unknown, text: 'Вот: переулок Тенистый, 12. Подвал. Код от двери — 1984. торопись. Не говори никому.', chapter: 9, delayMs: 1500),

  // Глава 10
  ChatMsg(id: 'u24', fromId: _unknown, text: 'Ты её нашёл? Пожалуйста, ответь...', chapter: 10, delayMs: 500),
  ChatMsg(id: 'u25', fromId: _unknown, text: 'Если ты не ответишь через 5 минут, я сама еду туда. Неважно, что будет со мной.', chapter: 10, delayMs: 3000),
  ChatMsg(id: 'u26', fromId: _unknown, text: 'Спасибо. Спасибо, что не сдался. Кира в безопасности. А Виктор — в руках полиции. Реальной полиции.', chapter: 10, delayMs: 2000),
  ChatMsg(id: 'u27', fromId: _unknown, text: 'Это я, Наташа. Моё настоящее имя. Ты спас мою лучшую подругу. Я не знаю, как тебя благодарить. Если когда-нибудь понадобится — ты знаешь мой номер.', chapter: 10, delayMs: 3000),
];

// ═══ ДАША ═══
const _daryaMsgs = [
  ChatMsg(id: 'd1', fromId: _darya, text: 'Алло? Кто это? Откуда у вас мой номер?', chapter: 1, delayMs: 800),
  ChatMsg(id: 'd2', fromId: 'player', text: '', chapter: 1, playerChoices: [
    'Мы общий знакомый прислал. Я знаю Киру.',
    'Я ищу Киру. Она пропала. Ты Даша, да?',
  ]),
  ChatMsg(id: 'd3', fromId: _darya, text: 'Кира... да, это я, Даша. Её подруга. Ты знаешь что-то о ней?', chapter: 1, delayMs: 1500),
  ChatMsg(id: 'd4', fromId: _darya, text: 'Три дня. ТРИ ДНЯ она не выходит на связь. Мобильный выключен. Макс говорит — поругались и она уехала к маме. Но мама говорит — Киры у неё нет.', chapter: 1, delayMs: 2500),
  ChatMsg(id: 'd5', fromId: _darya, text: 'Кира не такая. Она бы написала мне. Она бы написала КАЖДОМУ. Она не могла просто исчезнуть.', chapter: 1, delayMs: 2000),
  ChatMsg(id: 'd6', fromId: _darya, text: 'В последний раз я видела её в кафе «Уголёк». Она работала вечернюю смену. Уходила около 23:00. Была... напряжённая. Что-то её тревожило.', chapter: 1, delayMs: 2500),
  ChatMsg(id: 'd7', fromId: _darya, text: 'Она сказала мне: «Даш, если со мной что-то случится — проверь документы Виктора. В его кабинете. Верхняя полка. Серая папка.»', chapter: 1, delayMs: 3000),
  ChatMsg(id: 'd8', fromId: _darya, text: 'Я не поняла тогда. Думала, драма. Но теперь... может, это важно? Я не могу туда пойти. Виктор страшный. Он всех уволил, кто задавал вопросы.', chapter: 1, delayMs: 2500),
  ChatMsg(id: 'd9', fromId: 'player', text: '', chapter: 1, playerChoices: [
    'Что за кафе? Кто такой Виктор?',
    'Ты сможешь описать, что было в тот вечер?',
  ]),
  ChatMsg(id: 'd10', fromId: _darya, text: '«Уголёк» — кафе на окраине. Виктор Петров — владелец. Кажется, нормальный. Но персонал часто меняется. Кира говорила, что он кричит на официантов и следит за каждым.', chapter: 1, delayMs: 2000),

  // Глава 2
  ChatMsg(id: 'd11', fromId: _darya, text: 'Я спросила Макса — что было вечером перед исчезновением. Он сказал, что они поругались из-за её работы. Что она «слишком много работает и не уделяет ему время».', chapter: 2, delayMs: 1500),
  ChatMsg(id: 'd12', fromId: _darya, text: 'Типичный Макс. Всё revolves вокруг него. Но знаешь что? Кира рассказывала, что Макс был в кафе ВОТ ВОТ тот вечер. Пришёл без предупреждения. Поссорился с Виктором.', chapter: 2, delayMs: 2500),
  ChatMsg(id: 'd13', fromId: _darya, text: 'Макс не рассказывает, почему он туда пришёл. Говорит — «заехал за Кирой». Но в кафе он был в 22:30, а Кира ушла в 23:00. Полчаса он там был один. Без Киры.', chapter: 2, delayMs: 2000),
  ChatMsg(id: 'd14', fromId: _darya, text: 'Тебе дать его номер? Он не будет рад. Но если Кира в беде — он должен помочь, а не прятаться.', chapter: 2, delayMs: 1500),
  ChatMsg(id: 'd15', fromId: 'system', text: 'CONTACT_UNLOCK:max', isSystem: true, chapter: 2),

  // Глава 4
  ChatMsg(id: 'd16', fromId: _darya, text: 'Я попробовала зайти в кафе как клиентка. Виктор был там. Посмотрел на меня так, будто я — проблема. Попросил «не лезть не в своё дело».', chapter: 4, delayMs: 1000),
  ChatMsg(id: 'd17', fromId: _darya, text: 'Кассирша шёпотом сказала: «Серая папка в кабинете Виктора — он её забрал домой после того, как Кира пропала. Но он не знает, что я сделала копию.»', chapter: 4, delayMs: 2500),
  ChatMsg(id: 'd18', fromId: _darya, text: 'Она дала мне фотку документов. Похоже на налоговые отчеты. Но цифры не сходятся. Тыги рублей проходят через кафе без накладных.', chapter: 4, delayMs: 2000),
  ChatMsg(id: 'd19', fromId: _darya, text: 'IMAGE:tax_docs', imageUrl: 'tax_docs', chapter: 4, delayMs: 1500),
  ChatMsg(id: 'd20', fromId: 'system', text: 'EVIDENCE:ev_tax_docs', isSystem: true, chapter: 4),

  // Глава 8
  ChatMsg(id: 'd21', fromId: _darya, text: 'Только что получила сообщение от номера Киры. Но она пропала! Кто-то написал с её телефона!', chapter: 8, delayMs: 500),
  ChatMsg(id: 'd22', fromId: _darya, text: 'Сообщение: «Всё хорошо. Уехала подумать. Не ищите.» Но это НЕ её стиль. Кира так не пишет.', chapter: 8, delayMs: 2000),
  ChatMsg(id: 'd23', fromId: 'darya', text: 'Кира ВСЕГДА ставит смайлики. И пишет с заглавной. И называет меня «Даш». А в сообщении — «не ищите». Ни одной личной детали. Это не она.', chapter: 8, delayMs: 1500),
];

// ═══ МАКС ═══
const _maxMsgs = [
  ChatMsg(id: 'm1', fromId: _max, text: 'Кто это? Даша дала мой номер? Ей не стоило этого делать.', chapter: 2, delayMs: 1000),
  ChatMsg(id: 'm2', fromId: 'player', text: '', chapter: 2, playerChoices: [
    'Мне нужна помощь. Кира пропала.',
    'Расскажи про вечер в кафе.',
    'Почему ты поссорился с Виктором?',
  ]),
  ChatMsg(id: 'm3', fromId: _max, text: 'Кира не «пропала». Она ушла сама. Мы поругались. Она эмоциональная — уехала остывать. Это не первое время.', chapter: 2, delayMs: 2000),
  ChatMsg(id: 'm4', fromId: _max, text: 'Я ждал её у кафе. Мы должны были вместе пойти домой. Она вышла и сказала «мне нужно побыть одной». Я спросил «почему» — она промолчала.', chapter: 2, delayMs: 2500),
  ChatMsg(id: 'm5', fromId: _max, text: 'Виктор? Я не ссорился с ним. Мы... обсудили одну вещь. Но это личное.', chapter: 2, delayMs: 1500),
  ChatMsg(id: 'm6', fromId: _max, text: '...Ладно. Я пришёл в café поговорить с Виктором. Узнал, что Кира копалась в его документах. Я пытался её отговорить — не лезь, мол. А он... увидел.', chapter: 2, delayMs: 3000),
  ChatMsg(id: 'm7', fromId: _max, text: 'Виктор сказал мне: «Кира уволена. Забирай свои вещи». Я разозлился. Но Кира уже уходила. Я не знал, что это последний раз.', chapter: 2, delayMs: 2000),
  ChatMsg(id: 'm8', fromId: _max, text: 'Я виню себя. Если бы я не ушёл... Если бы я проводил её...', chapter: 2, delayMs: 2500),
  ChatMsg(id: 'm9', fromId: 'player', text: '', chapter: 2, playerChoices: [
    'Ты не виноват. Но нужно найти её. Помоги.',
    'Зачем Кира копалась в документах?',
  ]),
  ChatMsg(id: 'm10', fromId: _max, text: 'Она сказала, что нашла «что-то неправильное». Отчёты с поддельными подписями. Она думала, что Виктор обманывает налоговую. Я сказал ей — забей, не твоё дело.', chapter: 2, delayMs: 3000),

  // Глава 6
  ChatMsg(id: 'm11', fromId: _max, text: 'Я был у кафе сегодня ночью. Камеры наблюдения — одну из них кто-то удалил. Запись с 22:00 до 23:30 за 3 дня назад — пусто.', chapter: 6, delayMs: 1500),
  ChatMsg(id: 'm12', fromId: _max, text: 'Но я заметил: в офисе Виктора горел свет в 23:00. Кира ушла в 23:00. Виктор оставался. Мне кажется, он её догнал.', chapter: 6, delayMs: 2000),
  ChatMsg(id: 'm13', fromId: _max, text: 'IMAGE:cafe_night', imageUrl: 'cafe_night', chapter: 6, delayMs: 1500),
  ChatMsg(id: 'm14', fromId: 'system', text: 'EVIDENCE:ev_cafe_night', isSystem: true, chapter: 6),

  // Глава 9
  ChatMsg(id: 'm15', fromId: _max, text: 'Я знаю где она. Виктор держит её на складе за кафе. Я видел — он выходил туда ночью с едой. Кто ходит на склад в 2 часа ночи?', chapter: 9, delayMs: 1000),
  ChatMsg(id: 'm16', fromId: _max, text: 'Но я один. Не могу действовать. Мне нужна помощь. Ты со мной?', chapter: 9, delayMs: 1500),
];

// ═══ АНДРЕЙ (следователь) ═══
const _andreyMsgs = [
  ChatMsg(id: 'a1', fromId: _andrey, text: 'Здравствуйте. Смирнов, следователь ОВД. Мне сказали, что вы интересуетесь делом Беловой Киры.', chapter: 3, delayMs: 800),
  ChatMsg(id: 'a2', fromId: _andrey, text: 'Расследование ведётся. Не нужно любительского вмешательства. Девушка, вероятно, уехала по собственной инициативе.', chapter: 3, delayMs: 2000),
  ChatMsg(id: 'a3', fromId: 'player', text: '', chapter: 3, playerChoices: [
    'Вы проверили кафе «Уголёк»?',
    'Кира не уехала voluntarily. У неё есть записи.',
    'Почему вы так уверены, что она уехала сама?',
  ]),
  ChatMsg(id: 'a4', fromId: _andrey, text: 'Кафе проверено. Владелец — образцовый предприниматель. Жалоб от сотрудников нет. У Беловой были личные проблемы с молодым человеком. Это типичная ситуация.', chapter: 3, delayMs: 2500),
  ChatMsg(id: 'a5', fromId: _andrey, text: 'Посоветую вам заняться своими делами. Следствие под контролем.', chapter: 3, delayMs: 1500),

  // Глава 6
  ChatMsg(id: 'a6', fromId: _andrey, text: 'Я получил информацию, что вы связались с свидетелями по делу. Предупреждаю: мешать следствию — уголовное преступление. Статья 315 УК РФ.', chapter: 6, delayMs: 1000),
  ChatMsg(id: 'a7', fromId: _andrey, text: 'Если у вас есть информация — передайте официально. Не устраивайте самосуд.', chapter: 6, delayMs: 1500),
  ChatMsg(id: 'a8', fromId: 'player', text: '', chapter: 6, playerChoices: [
    'Почему вы защищаете Виктора Петрова?',
    'У меня есть доказательства налоговых махинаций.',
  ]),
  ChatMsg(id: 'a9', fromId: _andrey, text: 'Никого я не защищаю. Я выполняю свою работу. Какие «доказательства»? Покажите.', chapter: 6, delayMs: 2000),
  ChatMsg(id: 'a10', fromId: _andrey, text: 'IMAGE:smirnov_threat', imageUrl: 'smirnov_threat', chapter: 6, delayMs: 1500),
  ChatMsg(id: 'a11', fromId: 'system', text: 'EVIDENCE:ev_smirnov', isSystem: true, chapter: 6),

  // Глава 9
  ChatMsg(id: 'a12', fromId: _andrey, text: 'Хватит. Вы в опасности. Оставьте это дело. Я... не могу говорить. Но поверьте — вы не понимаете, с кем связались.', chapter: 9, delayMs: 500),
];

// ═══ ВИКТОР ═══
const _victorMsgs = [
  ChatMsg(id: 'v1', fromId: _victor, text: 'Здравствуйте. Виктор Петров. Мне сказали, что кто-то задает вопросы о моей сотруднице. Не понимаю, при чём тут вы.', chapter: 4, delayMs: 1000),
  ChatMsg(id: 'v2', fromId: 'player', text: '', chapter: 4, playerChoices: [
    'Кира пропала после смены у вас. Что вы знаете?',
    'Где вы были в ночь её исчезновения?',
    'Почему вы уволили Киру?',
  ]),
  ChatMsg(id: 'v3', fromId: _victor, text: 'Белова ушла сама. Я уволил её за то, что она рылась в моих личных документах. Нарушение. После этого она разозлилась и ушла.', chapter: 4, delayMs: 2000),
  ChatMsg(id: 'v4', fromId: _victor, text: 'Я закрыл кафе в 23:00 и поехал домой. Как и каждый вечер. Можете проверить камеры на парковке.', chapter: 4, delayMs: 1500),
  ChatMsg(id: 'v5', fromId: _victor, text: 'Больше мне не о чём говорить. Обращайтесь в полицию, если у вас есть вопросы. У меня бизнес, мне некогда на праздное любопытство.', chapter: 4, delayMs: 2000),

  // Глава 7
  ChatMsg(id: 'v6', fromId: _victor, text: 'Я знаю, что ты копаешься в моих делах. Послушай меня внимательно. Оставь это. Не тебе судить. Не тебе разбираться. Ты не знаешь, в какую игру играешь.', chapter: 7, delayMs: 500),
  ChatMsg(id: 'v7', fromId: 'victor', text: 'Один звонок — и ты будешь иметь проблемы. Серьёзные проблемы. Я не шучу.', chapter: 7, delayMs: 2000),
  ChatMsg(id: 'v8', fromId: 'system', text: 'EVIDENCE:ev_victor_threat', isSystem: true, chapter: 7),
];

// ═══ НАТАША ═══
const _natashaMsgs = [
  ChatMsg(id: 'n1', fromId: _natasha, text: 'Привет... Даша сказала, что ты помогаешь найти Киру. Я — Наташа, её соседка.', chapter: 5, delayMs: 800),
  ChatMsg(id: 'n2', fromId: _natasha, text: 'Мне страшно говорить. Но я должна. В ту ночь я слышала крик. Из переулка за кафе «Уголёк». Около 23:15.', chapter: 5, delayMs: 2000),
  ChatMsg(id: 'n3', fromId: _natasha, text: 'Я выглянула в окно — но было темно. Только слышала... мужской голос. И звук открывающейся двери машины. Потом — тишина.', chapter: 5, delayMs: 2500),
  ChatMsg(id: 'n4', fromId: 'player', text: '', chapter: 5, playerChoices: [
    'Ты уверена, что это был крик?',
    'Ты не звонила в полицию?',
    'Что ещё ты видела/слышала?',
  ]),
  ChatMsg(id: 'n5', fromId: _natasha, text: 'Звонила. Приехал участковый. Сказал: «Может, пьяная ссора. Ничего страшного». И уехал. Я настаивала — он сказал: «Женщина, не выдумывайте».', chapter: 5, delayMs: 3000),
  ChatMsg(id: 'n6', fromId: _natasha, text: 'Но это был не просто крик. Это был... ужас. Я никогда не слышала такой звук. Как будто человек увидел смерть.', chapter: 5, delayMs: 2500),
  ChatMsg(id: 'n7', fromId: _natasha, text: 'IMAGE:ally_view', imageUrl: 'ally_view', chapter: 5, delayMs: 1500),
  ChatMsg(id: 'n8', fromId: 'system', text: 'EVIDENCE:ev_scream', isSystem: true, chapter: 5),

  // Глава 8
  ChatMsg(id: 'n9', fromId: _natasha, text: 'Я снимала видео со своего окна каждое утро для блога. В день исчезновения Киры — на записи видно, как чёрная машина стоит у переулка с 22:50 до 23:30.', chapter: 8, delayMs: 1500),
  ChatMsg(id: 'n10', fromId: _natasha, text: 'А потом машина уехала. Быстро. С проблесковыми огнями... или мне показалось.', chapter: 8, delayMs: 2000),
];

// ═══ КИРА (появляется в главе 8) ═══
const _kiraMsgs = [
  ChatMsg(id: 'k1', fromId: _kira, text: '...пожалуйста... помогите...', chapter: 8, delayMs: 2000),
  ChatMsg(id: 'k2', fromId: _kira, text: 'он держит меня... в подвале... кафе...переулок тенистый 12...', chapter: 8, delayMs: 3000),
  ChatMsg(id: 'k3', fromId: _kira, text: 'у него пистолет... я боюсь... он не знает что у меня есть телефон...', chapter: 8, delayMs: 4000),
  ChatMsg(id: 'k4', fromId: _kira, text: 'флешка... я спрятала её... в столе на работе... верхний ящик... под меню...', chapter: 8, delayMs: 2500),
  ChatMsg(id: 'k5', fromId: 'player', text: '', chapter: 8, playerChoices: [
    'Кира! Я иду. Держись!',
    'Как ты добралась до телефона?',
  ]),
  ChatMsg(id: 'k6', fromId: _kira, text: 'он не заметил... старый телефон... в углу... зарядка почти на нуле...', chapter: 8, delayMs: 2000),
  ChatMsg(id: 'k7', fromId: _kira, text: 'пожалуйста... я не хочу умирать...', chapter: 8, delayMs: 3000),
  ChatMsg(id: 'k8', fromId: _kira, text: '...он идёт... надо прятать телефон...', chapter: 8, delayMs: 5000),
  ChatMsg(id: 'k9', fromId: _kira, text: '█▓▒░ ░▒▓█', chapter: 8, delayMs: 1000),

  // Глава 10
  ChatMsg(id: 'k10', fromId: _kira, text: 'ты пришёл...', chapter: 10, delayMs: 2000),
  ChatMsg(id: 'k11', fromId: _kira, text: 'я не верила что кто-то придёт... спасибо тебе...', chapter: 10, delayMs: 2500),
  ChatMsg(id: 'k12', fromId: _kira, text: 'виктор арестован. настоящая полиция приехала. даша рядом. я в больнице. всё будет хорошо.', chapter: 10, delayMs: 3000),
  ChatMsg(id: 'k13', fromId: _kira, text: 'ты спас мне жизнь. запомни — не всегда нужно быть героем. иногда достаточно — просто не отвернуться.', chapter: 10, delayMs: 4000),
];

// ═══ ЗВОНКИ ═══
List<PhoneCall> getPhoneCalls() => const [
  PhoneCall(id: 'pc1', callerId: _darya, transcript: '[Тревожный голос] Слушай, Кира пропала. Три дня. Полиция не ищет. Макс говорит — уехала. Но мама говорит — её нет. Я в панике. Пожалуйста, помоги.', durationSec: 42, chapter: 1, isIncoming: true),
  PhoneCall(id: 'pc2', callerId: _unknown, transcript: '[Изменённый голос] Я не могу говорить долго. Запомни: серая папка. Кабинет Виктора. Там доказательства. И будь осторожен со следователем — он не тот, за кого себя выдаёт.', durationSec: 28, chapter: 3, isIncoming: true),
  PhoneCall(id: 'pc3', callerId: _natasha, transcript: '[Шёпотом] Я боюсь. Но... в ту ночь я видела чёрный седан у переулка. Номер начинался на М 779. И водитель... похож на Виктора. Но я не уверена. Свет был плохой.', durationSec: 55, chapter: 5, isIncoming: true),
  PhoneCall(id: 'pc4', callerId: _kira, transcript: '[Слабый, дрожащий голос] Пожалуйста... кто-нибудь... Я в подвале... холодно... он ушёл на пару часов... дверь не заперта... но я не могу... нога... Уголёк... переулок... торопитесь...', durationSec: 35, chapter: 8, isIncoming: true),
  PhoneCall(id: 'pc5', callerId: _max, transcript: '[Возбуждённо] Слушай, я у кафе. Вижу — Виктор выходит с заднего двора, идёт к гаражу в переулке. Несёт еду. Кто носит еду в гараж в 2 ночи?! Она там! Я уверен!', durationSec: 30, chapter: 9, isIncoming: true),
];

// ═══ УЛИКИ ═══
List<Evidence> getEvidenceItems() => const [
  Evidence(id: 'ev_tax_docs', title: 'Налоговые документы', description: 'Даша получила копию: через «Уголёк» проходят миллионы без документов. Фальшивые подписи.', chapterFound: 4, icon: Icons.description),
  Evidence(id: 'ev_cafe_night', title: 'Фото кафе ночью', description: 'Макс сфотографировал горящий свет в офисе Виктора в 23:00 — когда Кира уже «ушла».', chapterFound: 6, icon: Icons.photo_camera),
  Evidence(id: 'ev_smirnov', title: 'Запись разговора', description: 'Смирнов угрожает «оставить дело». Звучит как человек, который защищает кого-то, а не ищет.', chapterFound: 6, icon: Icons.mic),
  Evidence(id: 'ev_scream', title: 'Показания Наташи', description: 'Крик из переулка в 23:15. Участковый проигнорировал. Мужской голос. Звук двери машины.', chapterFound: 5, icon: Icons.hearing),
  Evidence(id: 'ev_victor_threat', title: 'Угроза Виктора', description: 'Виктор прислал угрозу: «Один звонок — и ты будешь иметь проблемы».', chapterFound: 7, icon: Icons.warning),
  Evidence(id: 'ev_kira_msg', title: 'Сообщение Киры', description: 'Кира жива. Написала с чужого телефона из подвала. Указала адрес: переулок Тенистый, 12.', chapterFound: 8, icon: Icons.message),
];

// ═══ МИНИ-ИГРЫ ═══
List<MiniGameData> getMiniGames() => const [
  MiniGameData(type: 'photo_analysis', title: 'Фото-анализ', instruction: 'Найдите 4 подозрительных детали на фото документа.', data: {
    'grid': '4x3',
    'clues': [1, 5, 9, 11],
  }),
  MiniGameData(type: 'cipher', title: 'Расшифруй код', instruction: 'Наташа записала номер машины. Шифр Цезаря, сдвиг 3. Расшифруйте.', data: {
    'encrypted': 'П 779 НХУ',
    'answer': 'М 779 КНУ',
    'shift': 3,
  }),
  MiniGameData(type: 'logic', title: 'Хронология', instruction: 'Расставьте события в правильном порядке.', data: {
    'events': [
      'Кира находит махинации в документах',
      'Макс приходит в кафе и ссорится с Виктором',
      'Виктор увольняет Киру',
      'Кира уходит из кафе в 23:00',
      'Крик из переулка — 23:15',
      'Чёрная машина уезжает в 23:30',
      'Кира не выходит на связь',
      'Неизвестный пишет вам',
    ],
  }),
  MiniGameData(type: 'final_choice', title: 'Финальное решение', instruction: 'Кто главный виновник? Выберите на основе улик.', data: {
    'options': ['Максим Волков (парень)', 'Виктор Петров (владелец кафе)', 'Андрей Смирнов (следователь)'],
    'correct': 'Виктор Петров',
    'explanation': 'Виктор Петров — мозг операции. Он отмывал деньги через кафе, Кира узнала, он похитил её. Смирнов — его прикрытие в полиции.',
  }),
];
