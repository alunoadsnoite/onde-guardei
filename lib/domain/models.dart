// Models do catálogo: dados puros usados por toda a aplicação.
// Sem dependências de I/O ou UI.

import 'dart:math';

String newId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

const _foldings = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
  'š': 's',
  'ž': 'z',
  'ğ': 'g',
  'ı': 'i',
  'ł': 'l',
  'đ': 'd',
  'ð': 'd',
  'þ': 't',
  'æ': 'a',
  'œ': 'o',
  'ß': 'ss',
};

/// Tira acentos e caixa, para que a busca encontre "cabo" ao digitar "cábô".
String normalize(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    if (rune < 128) {
      buffer.writeCharCode(rune);
      continue;
    }
    final char = String.fromCharCodes([rune]);
    buffer.write(_foldings[char] ?? char);
  }
  return buffer.toString();
}

/// Texto sem acento em minúsculas, usado para ordenar e comparar.
String folded(String text) => normalize(text).trim().toLowerCase();

class Place {
  final String id, name;
  final String? parentId;
  const Place({required this.id, required this.name, this.parentId});
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
  };
  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id: j['id'] as String,
    name: j['name'] as String,
    parentId: j['parentId'] as String?,
  );
}

class Move {
  final String from, to;
  final DateTime at;
  const Move(this.from, this.to, this.at);
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'at': at.toIso8601String(),
  };
  factory Move.fromJson(Map<String, dynamic> j) => Move(
    j['from'] as String,
    j['to'] as String,
    DateTime.parse(j['at'] as String),
  );
}

class StoredItem {
  final String id, name, notes, keywords;
  final String? placeId, photo;
  final DateTime createdAt, updatedAt;
  final List<Move> moves;
  const StoredItem({
    required this.id,
    required this.name,
    this.notes = '',
    this.keywords = '',
    this.placeId,
    this.photo,
    required this.createdAt,
    required this.updatedAt,
    this.moves = const [],
  });
  String get title => name.isEmpty ? 'Objeto sem nome' : name;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'keywords': keywords,
    'placeId': placeId,
    'photo': photo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'moves': moves.map((m) => m.toJson()).toList(),
  };
  factory StoredItem.fromJson(Map<String, dynamic> j) => StoredItem(
    id: j['id'] as String,
    name: j['name'] as String,
    notes: j['notes'] as String,
    keywords: j['keywords'] as String,
    placeId: j['placeId'] as String?,
    photo: j['photo'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    moves: (j['moves'] as List)
        .map((m) => Move.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList(),
  );
}

class Catalog {
  final List<Place> places;
  final List<StoredItem> items;
  const Catalog({this.places = const [], this.items = const []});

  /// Índice dos locais por id, para não repetir buscas lineares.
  Map<String, Place> get placeIndex => {for (final p in places) p.id: p};

  /// Caminho do local em partes: ['Quarto', 'Armário', 'Caixa azul'].
  List<String> pathSegments(String? id) => _segments(id, placeIndex);

  List<String> _segments(String? id, Map<String, Place> byId) {
    if (id == null) return const [];
    final names = <String>[];
    final visited = <String>{};
    var current = id;
    while (true) {
      if (!visited.add(current)) break;
      final place = byId[current];
      if (place == null) break;
      names.insert(0, place.name);
      final parent = place.parentId;
      if (parent == null) break;
      current = parent;
    }
    return names;
  }

  /// Caminho legível do local: "Quarto › Armário › Caixa azul".
  String path(String? id) => _path(id, placeIndex);

  String _path(String? id, Map<String, Place> byId) {
    if (id == null) return 'Sem local definido';
    final names = _segments(id, byId);
    if (names.isEmpty) return 'Local desconhecido';
    return names.join(' › ');
  }

  /// Verdadeiro quando o local está dentro do ancestral informado.
  bool isInside(String? id, String? ancestorId) =>
      _isInside(id, ancestorId, placeIndex);

  bool _isInside(String? id, String? ancestorId, Map<String, Place> byId) {
    if (ancestorId == null) return true;
    if (id == null) return false;
    final visited = <String>{};
    var current = id;
    while (true) {
      if (!visited.add(current)) break;
      if (current == ancestorId) return true;
      final place = byId[current];
      if (place == null) break;
      final parent = place.parentId;
      if (parent == null) break;
      current = parent;
    }
    return false;
  }

  List<StoredItem> search(String query, {String? placeId}) {
    final words = normalize(
      query,
    ).trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final byId = placeIndex;
    final found = <StoredItem>[];
    for (final item in items) {
      if (placeId != null && !_isInside(item.placeId, placeId, byId)) continue;
      if (words.isEmpty) {
        found.add(item);
        continue;
      }
      final hay = normalize(
        '${item.name} ${item.notes} ${item.keywords} ${_path(item.placeId, byId)}',
      );
      if (words.every(hay.contains)) found.add(item);
    }
    found.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return found;
  }

  /// Quantos objetos ficam em cada local, contando os locais que estão dentro.
  Map<String, int> itemsByPlace() {
    final byId = placeIndex;
    final counts = <String, int>{for (final p in places) p.id: 0};
    for (final item in items) {
      final visited = <String>{};
      var current = item.placeId;
      while (current != null) {
        if (!visited.add(current)) break;
        counts[current] = (counts[current] ?? 0) + 1;
        current = byId[current]?.parentId;
      }
    }
    return counts;
  }

  /// Locais ordenados pela hierarquia, sem diferenciar acentos ou caixa.
  List<Place> sortedPlaces() {
    final byId = placeIndex;
    final segments = <String, List<String>>{
      for (final p in places) p.id: _segments(p.id, byId),
    };
    final list = [...places];
    list.sort((a, b) {
      final left = segments[a.id] ?? const <String>[];
      final right = segments[b.id] ?? const <String>[];
      final size = min(left.length, right.length);
      for (var i = 0; i < size; i++) {
        final result = folded(left[i]).compareTo(folded(right[i]));
        if (result != 0) return result;
      }
      return left.length.compareTo(right.length);
    });
    return list;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'places': places.map((p) => p.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
  };
  factory Catalog.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Versão de arquivo não suportada.');
    }
    final c = Catalog(
      places: (j['places'] as List)
          .map((p) => Place.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      items: (j['items'] as List)
          .map((i) => StoredItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
    c.validate();
    return c;
  }
  void validate() {
    final ids = <String>{};
    final validId = RegExp(r'^[a-f0-9]{32}$');
    for (final p in places) {
      if (!validId.hasMatch(p.id) ||
          !ids.add(p.id) ||
          p.name.trim().isEmpty ||
          p.name.length > 100) {
        throw const FormatException('Local inválido ou repetido.');
      }
    }
    final byId = placeIndex;
    for (final p in places) {
      final visited = {p.id};
      var parent = p.parentId;
      while (parent != null) {
        if (!ids.contains(parent) || !visited.add(parent)) {
          throw const FormatException(
            'A organização dos locais contém um ciclo ou local ausente.',
          );
        }
        final next = byId[parent]?.parentId;
        if (next == null) break;
        parent = next;
      }
    }
    final itemIds = <String>{};
    for (final i in items) {
      if (!validId.hasMatch(i.id) ||
          !itemIds.add(i.id) ||
          (i.name.trim().isEmpty && i.photo == null) ||
          i.name.length > 120 ||
          i.notes.length > 3000 ||
          i.keywords.length > 500 ||
          (i.placeId != null && !ids.contains(i.placeId)) ||
          (i.photo != null && !validPhoto(i.photo!))) {
        throw const FormatException('Cadastro de objeto inválido.');
      }
    }
  }

  static bool validPhoto(String name) =>
      RegExp(r'^[a-f0-9]{32}\.img$').hasMatch(name);
}
