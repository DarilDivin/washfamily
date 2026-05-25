import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/machine_model.dart';

/// Les machines sont une sous-collection : laundries/{laundryId}/machines/{machineId}
class MachineRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _machines(String laundryId) =>
      _db.collection('laundries').doc(laundryId).collection('machines');

  /// Stream de toutes les machines d'une laverie
  Stream<List<MachineModel>> streamMachines(String laundryId) {
    return _machines(laundryId).snapshots().map((snap) => snap.docs
        .map((d) => MachineModel.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  /// Récupère une machine spécifique
  Future<MachineModel?> getMachine({
    required String laundryId,
    required String machineId,
  }) async {
    final doc = await _machines(laundryId).doc(machineId).get();
    if (!doc.exists) return null;
    return MachineModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Ajoute une machine à une laverie — retourne le machineId créé
  Future<String> addMachine({
    required String laundryId,
    required MachineModel machine,
  }) async {
    final data = machine.toJson()..['laundryId'] = laundryId;
    final ref = await _machines(laundryId).add(data);
    return ref.id;
  }

  /// Met à jour les champs d'une machine
  Future<void> updateMachine({
    required String laundryId,
    required String machineId,
    required Map<String, dynamic> fields,
  }) async {
    await _machines(laundryId).doc(machineId).update(fields);
  }

  /// Supprime une machine
  Future<void> deleteMachine({
    required String laundryId,
    required String machineId,
  }) async {
    await _machines(laundryId).doc(machineId).delete();
  }

  /// Change la disponibilité d'une machine
  Future<void> setMachineAvailable({
    required String laundryId,
    required String machineId,
    required bool isAvailable,
  }) async {
    await _machines(laundryId).doc(machineId).update({
      'isAvailable': isAvailable,
      'status': isAvailable ? 'AVAILABLE' : 'IN_USE',
    });
  }
}
