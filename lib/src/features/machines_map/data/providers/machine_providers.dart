import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/machine_repository.dart';
import '../../domain/models/machine_model.dart';

part 'machine_providers.g.dart';

@Riverpod(keepAlive: true)
MachineRepository machineRepository(MachineRepositoryRef ref) =>
    MachineRepository();

@riverpod
Stream<List<MachineModel>> machines(MachinesRef ref, String laundryId) =>
    ref.watch(machineRepositoryProvider).streamMachines(laundryId);
