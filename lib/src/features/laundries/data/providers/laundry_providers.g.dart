// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laundry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$laundryRepositoryHash() => r'78112095c868d5abf9223a4d48d61e1395cce048';

/// See also [laundryRepository].
@ProviderFor(laundryRepository)
final laundryRepositoryProvider = Provider<LaundryRepository>.internal(
  laundryRepository,
  name: r'laundryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$laundryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LaundryRepositoryRef = ProviderRef<LaundryRepository>;
String _$activeLaundriesHash() => r'f9e5d2c09cbdc951254d1db2b48b54b77f9c69fa';

/// See also [activeLaundries].
@ProviderFor(activeLaundries)
final activeLaundriesProvider =
    AutoDisposeStreamProvider<List<LaundryModel>>.internal(
  activeLaundries,
  name: r'activeLaundriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeLaundriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveLaundriesRef = AutoDisposeStreamProviderRef<List<LaundryModel>>;
String _$laundryHash() => r'2b3389af85c49a768cff5b57aa4f72eda7fbf309';

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

/// See also [laundry].
@ProviderFor(laundry)
const laundryProvider = LaundryFamily();

/// See also [laundry].
class LaundryFamily extends Family<AsyncValue<LaundryModel?>> {
  /// See also [laundry].
  const LaundryFamily();

  /// See also [laundry].
  LaundryProvider call(
    String laundryId,
  ) {
    return LaundryProvider(
      laundryId,
    );
  }

  @override
  LaundryProvider getProviderOverride(
    covariant LaundryProvider provider,
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
  String? get name => r'laundryProvider';
}

/// See also [laundry].
class LaundryProvider extends AutoDisposeStreamProvider<LaundryModel?> {
  /// See also [laundry].
  LaundryProvider(
    String laundryId,
  ) : this._internal(
          (ref) => laundry(
            ref as LaundryRef,
            laundryId,
          ),
          from: laundryProvider,
          name: r'laundryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$laundryHash,
          dependencies: LaundryFamily._dependencies,
          allTransitiveDependencies: LaundryFamily._allTransitiveDependencies,
          laundryId: laundryId,
        );

  LaundryProvider._internal(
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
    Stream<LaundryModel?> Function(LaundryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LaundryProvider._internal(
        (ref) => create(ref as LaundryRef),
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
  AutoDisposeStreamProviderElement<LaundryModel?> createElement() {
    return _LaundryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LaundryProvider && other.laundryId == laundryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, laundryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LaundryRef on AutoDisposeStreamProviderRef<LaundryModel?> {
  /// The parameter `laundryId` of this provider.
  String get laundryId;
}

class _LaundryProviderElement
    extends AutoDisposeStreamProviderElement<LaundryModel?> with LaundryRef {
  _LaundryProviderElement(super.provider);

  @override
  String get laundryId => (origin as LaundryProvider).laundryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
