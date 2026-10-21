// Models do catálogo: dados puros usados por toda a aplicação.
// Sem dependências de I/O ou UI.

import 'dart:math';

String newId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
String normalize(String text) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  var result = text.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result;
}

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
  String path(String? id) {
    if (id == null) return 'Sem local definido';
    final names = <String>[];
    final visited = <String>{};
    while (id != null && visited.add(id)) {
      final p = places.where((p) => p.id == id).firstOrNull;
      if (p == null) break;
      names.insert(0, p.name);
      id = p.parentId;
    }
    return names.join(' › ');
  }

  List<StoredItem> search(String query, {String? placeId}) {
    final words = normalize(
      query,
    ).trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final found = items.where((i) {
      if (placeId != null) {
        var current = i.placeId;
        final visited = <String>{};
        while (current != null && current != placeId && visited.add(current)) {
          current = places.where((p) => p.id == current).firstOrNull?.parentId;
        }
        if (current != placeId) return false;
      }
      final hay = normalize(
        '${i.name} ${i.notes} ${i.keywords} ${path(i.placeId)}',
      );
      return words.every(hay.contains);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return found;
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
    for (final p in places) {
      var parent = p.parentId;
      final visited = {p.id};
      while (parent != null) {
        if (!ids.contains(parent) || !visited.add(parent)) {
          throw const FormatException(
            'A organização dos locais contém um ciclo ou local ausente.',
          );
        }
        parent = places.firstWhere((p) => p.id == parent).parentId;
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
