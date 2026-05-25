// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$machineRepositoryHash() => r'263b85a0ac8e353b63541661de0a1229d1d5320f';

/// See also [machineRepository].
@ProviderFor(machineRepository)
final machineRepositoryProvider = Provider<MachineRepository>.internal(
  machineRepository,
  name: r'machineRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$machineRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MachineRepositoryRef = ProviderRef<MachineRepository>;
String _$machinesHash() => r'54876276eb28da843ad8f3c3f2f69f10f75c43a5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [machines].
@ProviderFor(machines)
const machinesProvider = MachinesFamily();

/// See also [machines].
class MachinesFamily extends Family<AsyncValue<List<MachineModel>>> {
  /// See also [machines].
  const MachinesFamily();

  /// See also [machines].
  MachinesProvider call(
    String laundryId,
  ) {
    return MachinesProvider(
      laundryId,
    );
  }

  @override
  MachinesProvider getProviderOverride(
    covariant MachinesProvider provider,
  ) {
    return call(
      provider.laundryId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'machinesProvider';
}

/// See also [machines].
class MachinesProvider extends AutoDisposeStreamProvider<List<MachineModel>> {
  /// See also [machines].
  MachinesProvider(
    String laundryId,
  ) : this._internal(
          (ref) => machines(
            ref as MachinesRef,
            laundryId,
          ),
          from: machinesProvider,
          name: r'machinesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$machinesHash,
          dependencies: MachinesFamily._dependencies,
          allTransitiveDependencies: MachinesFamily._allTransitiveDependencies,
          laundryId: laundryId,
        );

  MachinesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.laundryId,
  }) : super.internal();

  final String laundryId;

  @override
  Override overrideWith(
    Stream<List<MachineModel>> Function(MachinesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MachinesProvider._internal(
        (ref) => create(ref as MachinesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        laundryId: laundryId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MachineModel>> createElement() {
    return _MachinesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MachinesProvider && other.laundryId == laundryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, laundryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MachinesRef on AutoDisposeStreamProviderRef<List<MachineModel>> {
  /// The parameter `laundryId` of this provider.
  String get laundryId;
}

class _MachinesProviderElement
    extends AutoDisposeStreamProviderElement<List<MachineModel>>
    with MachinesRef {
  _MachinesProviderElement(super.provider);

  @override
  String get laundryId => (origin as MachinesProvider).laundryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
