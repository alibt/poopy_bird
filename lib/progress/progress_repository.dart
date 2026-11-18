import 'dart:async';
import 'dart:convert';

import '../economy/catalog.dart';
import '../economy/rewards.dart';
import '../storage/key_value_store.dart';
import 'level_result.dart';
import 'player_progress.dart';

/// A run that has been stored, with the coins it paid.
class RecordedRun {
  const RecordedRun(this.progress, this.reward);

  final PlayerProgress progress;
  final RunReward reward;
}

/// Where player progress lives and how it changes. The local implementation
/// stores it on the device; a backend-synced one can replace it later
/// without touching the game or the screens.
///
/// Every operation is a named action rather than "save this progress", so
/// a server can validate coin changes instead of trusting the client.
abstract interface class ProgressRepository {
  Future<PlayerProgress> load();

  /// Stores [result], pays its reward and returns both.
  Future<RecordedRun> record(LevelResult result);

  /// Throws [ShopException] if the upgrade can't be bought.
  Future<PlayerProgress> buyUpgrade(UpgradeId id);

  /// Buys and equips a cosmetic. Throws [ShopException] on failure.
  Future<PlayerProgress> buyCosmetic(String cosmeticId);

  Future<PlayerProgress> equip(String cosmeticId);

  /// Grants coins from outside a run, e.g. a rewarded ad or a purchase.
  /// [reason] is recorded so a backend can verify the grant.
  Future<PlayerProgress> grantCoins(int amount, {required String reason});

  /// Marks achievements as unlocked and pays their rewards. Ids that are
  /// unknown or already unlocked are ignored.
  Future<PlayerProgress> unlockAchievements(List<String> ids);

  /// Applies a verified IAP: coins, optional cosmetic, optional remove-ads.
  Future<PlayerProgress> fulfillIap({
    required String productId,
    required String orderId,
    required int coins,
    String? cosmeticId,
    bool removeAds = false,
  });
}

/// Keeps progress in a [KeyValueStore] as JSON, and logs every action to an
/// outbox that a future sync service can upload.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this.store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final KeyValueStore store;
  final DateTime Function() _clock;

  static const String progressKey = 'progress';
  static const String corruptKey = 'progress.corrupt';
  static const String outboxKey = 'outbox';

  /// Oldest actions are dropped beyond this, so the log can't grow forever
  /// on a device that never syncs.
  static const int maxOutbox = 500;

  PlayerProgress? _progress;
  List<Map<String, dynamic>>? _outbox;

  /// Serialises operations so two quick taps can't both spend the same
  /// coins.
  Future<void> _queue = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<PlayerProgress> load() => _locked(_load);

  Future<PlayerProgress> _load() async {
    if (_progress case final progress?) return progress;
    final raw = await store.read(progressKey);
    var progress = const PlayerProgress();
    if (raw != null) {
      try {
        progress =
            PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // Keep the unreadable data for support instead of losing it, and
        // start fresh rather than crash on launch.
        await store.write(corruptKey, raw);
      }
    }
    return _progress = progress;
  }

  Future<List<Map<String, dynamic>>> _loadOutbox() async {
    if (_outbox case final outbox?) return outbox;
    final raw = await store.read(outboxKey);
    try {
      return _outbox = raw == null
          ? []
          : (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } on Object {
      return _outbox = [];
    }
  }

  /// Actions not yet sent to a backend, oldest first.
  Future<List<Map<String, dynamic>>> pendingActions() =>
      _locked(() async => List.unmodifiable(await _loadOutbox()));

  Future<PlayerProgress> _apply(
    String action,
    Map<String, dynamic> payload,
    PlayerProgress Function(PlayerProgress) change,
  ) async {
    final updated = change(await _load());
    final outbox = await _loadOutbox();
    outbox.add({
      'action': action,
      'at': _clock().toUtc().toIso8601String(),
      ...payload,
    });
    if (outbox.length > maxOutbox) {
      outbox.removeRange(0, outbox.length - maxOutbox);
    }
    await store.write(progressKey, jsonEncode(updated.toJson()));
    await store.write(outboxKey, jsonEncode(outbox));
    return _progress = updated;
  }

  @override
  Future<RecordedRun> record(LevelResult result) => _locked(() async {
        final reward = RewardRules.forResult(result, await _load());
        final progress = await _apply(
          'run',
          {'result': result.toJson(), 'coins': reward.total},
          (p) => p.withResult(result),
        );
        return RecordedRun(progress, reward);
      });

  @override
  Future<PlayerProgress> buyUpgrade(UpgradeId id) => _locked(
      () => _apply('buyUpgrade', {'id': id.id}, (p) => p.buyUpgrade(id)));

  @override
  Future<PlayerProgress> buyCosmetic(String cosmeticId) => _locked(() => _apply(
      'buyCosmetic', {'id': cosmeticId}, (p) => p.buyCosmetic(cosmeticId)));

  @override
  Future<PlayerProgress> equip(String cosmeticId) => _locked(
      () => _apply('equip', {'id': cosmeticId}, (p) => p.equip(cosmeticId)));

  @override
  Future<PlayerProgress> grantCoins(int amount, {required String reason}) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    return _locked(() => _apply(
          'grantCoins',
          {'amount': amount, 'reason': reason},
          (p) => p.withCoins(amount),
        ));
  }

  @override
  Future<PlayerProgress> unlockAchievements(List<String> ids) =>
      _locked(() async {
        final current = await _load();
        if (ids.every(current.hasAchievement)) return current;
        return _apply(
          'unlockAchievements',
          {'ids': ids},
          (p) => p.unlockAchievements(ids, _clock()),
        );
      });

  @override
  Future<PlayerProgress> fulfillIap({
    required String productId,
    required String orderId,
    required int coins,
    String? cosmeticId,
    bool removeAds = false,
  }) =>
      _locked(() => _apply(
            'iap',
            {
              'productId': productId,
              'orderId': orderId,
              'coins': coins,
              if (cosmeticId != null) 'cosmeticId': cosmeticId,
              'removeAds': removeAds,
            },
            (p) {
              var next = p;
              if (coins > 0) next = next.withCoins(coins);
              if (cosmeticId != null) next = next.grantCosmetic(cosmeticId);
              if (removeAds) next = next.withRemoveAds();
              return next;
            },
          ));
}

/// A [LocalProgressRepository] that forgets everything when the app closes.
/// For tests and previews.
class InMemoryProgressRepository extends LocalProgressRepository {
  InMemoryProgressRepository([PlayerProgress? initial])
      : super(MemoryKeyValueStore({
          if (initial != null)
            LocalProgressRepository.progressKey: jsonEncode(initial.toJson()),
        }));
}
