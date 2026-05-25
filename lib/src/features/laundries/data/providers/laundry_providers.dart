import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/laundry_repository.dart';
import '../../domain/models/laundry_model.dart';

part 'laundry_providers.g.dart';

@Riverpod(keepAlive: true)
LaundryRepository laundryRepository(LaundryRepositoryRef ref) =>
    LaundryRepository();

@riverpod
Stream<List<LaundryModel>> activeLaundries(ActiveLaundriesRef ref) =>
    ref.watch(laundryRepositoryProvider).streamActiveLaundries();

@riverpod
Stream<LaundryModel?> laundry(LaundryRef ref, String laundryId) =>
    ref.watch(laundryRepositoryProvider).streamLaundry(laundryId);
