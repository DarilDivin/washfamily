import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/laundry_product_repository.dart';
import '../../domain/models/laundry_product_model.dart';

part 'laundry_product_providers.g.dart';

@Riverpod(keepAlive: true)
LaundryProductRepository laundryProductRepository(
        LaundryProductRepositoryRef ref) =>
    LaundryProductRepository();

@riverpod
Stream<List<LaundryProductModel>> laundryProducts(
  LaundryProductsRef ref,
  String laundryId,
) =>
    ref.watch(laundryProductRepositoryProvider).streamProducts(laundryId);

@riverpod
Stream<List<LaundryProductModel>> allLaundryProducts(
  AllLaundryProductsRef ref,
  String laundryId,
) =>
    ref.watch(laundryProductRepositoryProvider).streamAllProducts(laundryId);
