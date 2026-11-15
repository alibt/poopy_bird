import 'dart:convert';

import 'package:flutter/services.dart';

import 'level_definition.dart';

/// Where worlds and levels come from. Today: bundled JSON assets. Later a
/// backend implementation can deliver new or updated levels.
abstract interface class LevelRepository {
  Future<List<WorldDefinition>> loadWorlds();
  Future<LevelDefinition> loadLevel(String id);
}

/// Reads `assets/levels/worlds.json` and `assets/levels/<id>.json`.
class AssetLevelRepository implements LevelRepository {
  AssetLevelRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _directory = 'assets/levels';

  final AssetBundle _bundle;
  final Map<String, LevelDefinition> _cache = {};

  @override
  Future<List<WorldDefinition>> loadWorlds() async {
    final json = await _readJson('$_directory/worlds.json');
    return (json['worlds'] as List)
        .cast<Map<String, dynamic>>()
        .map(WorldDefinition.fromJson)
        .toList();
  }

  @override
  Future<LevelDefinition> loadLevel(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final level = LevelDefinition.fromJson(
      await _readJson('$_directory/$id.json'),
    );
    if (level.id != id) {
      throw FormatException('File $id.json declares id "${level.id}"');
    }
    return _cache[id] = level;
  }

  Future<Map<String, dynamic>> _readJson(String path) async =>
      jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
}
