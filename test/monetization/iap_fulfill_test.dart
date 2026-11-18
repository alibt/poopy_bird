import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/economy/catalog.dart';
import 'package:poopy_bird/monetization/iap.dart';
import 'package:poopy_bird/progress/progress_repository.dart';

void main() {
  test('DebugIapStore fulfills coin packs into progress', () async {
    final repo = InMemoryProgressRepository();
    final store = DebugIapStore();
    await store.init();

    final result = await store.purchase(IapProduct.coinsSmall);
    expect(result, isNotNull);
    expect(result!.ok, isTrue);

    final progress = await repo.fulfillIap(
      productId: result.product.id,
      orderId: result.orderId,
      coins: result.product.coins,
    );
    expect(progress.coins, 1000);
  });

  test('remove ads IAP sets the flag and grants no coins', () async {
    final repo = InMemoryProgressRepository();
    final progress = await repo.fulfillIap(
      productId: IapProduct.removeAds.id,
      orderId: 'order-1',
      coins: 0,
      removeAds: true,
    );
    expect(progress.removeAds, isTrue);
    expect(progress.coins, 0);
  });

  test('starter pack grants coins and golden poop', () async {
    final repo = InMemoryProgressRepository();
    final product = IapProduct.starterPack;
    final progress = await repo.fulfillIap(
      productId: product.id,
      orderId: 'order-2',
      coins: product.coins,
      cosmeticId: product.cosmeticId,
    );
    expect(progress.coins, 2000);
    expect(progress.owns('poop_gold'), isTrue);
    expect(progress.equippedIn(CosmeticSlot.poop), 'poop_gold');
  });
}
