// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laundry_product_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$laundryProductRepositoryHash() =>
    r'f1d99efc8bae5c7e5fa04ef3b5d9c0cea6da69c9';

/// See also [laundryProductRepository].
@ProviderFor(laundryProductRepository)
final laundryProductRepositoryProvider =
    Provider<LaundryProductRepository>.internal(
  laundryProductRepository,
  name: r'laundryProductRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$laundryProductRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LaundryProductRepositoryRef = ProviderRef<LaundryProductRepository>;
String _$laundryProductsHash() => r'7629d3dd6f68f2927aa391bb84fb69328ce59372';

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

/// See also [laundryProducts].
@ProviderFor(laundryProducts)
const laundryProductsProvider = LaundryProductsFamily();

/// See also [laundryProducts].
class LaundryProductsFamily
    extends Family<AsyncValue<List<LaundryProductModel>>> {
  /// See also [laundryProducts].
  const LaundryProductsFamily();

  /// See also [laundryProducts].
  LaundryProductsProvider call(
    String laundryId,
  ) {
    return LaundryProductsProvider(
      laundryId,
    );
  }

  @override
  LaundryProductsProvider getProviderOverride(
    covariant LaundryProductsProvider provider,
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
  String? get name => r'laundryProductsProvider';
}

/// See also [laundryProducts].
class LaundryProductsProvider
    extends AutoDisposeStreamProvider<List<LaundryProductModel>> {
  /// See also [laundryProducts].
  LaundryProductsProvider(
    String laundryId,
  ) : this._internal(
          (ref) => laundryProducts(
            ref as LaundryProductsRef,
            laundryId,
          ),
          from: laundryProductsProvider,
          name: r'laundryProductsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$laundryProductsHash,
          dependencies: LaundryProductsFamily._dependencies,
          allTransitiveDependencies:
              LaundryProductsFamily._allTransitiveDependencies,
          laundryId: laundryId,
        );

  LaundryProductsProvider._internal(
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
    Stream<List<LaundryProductModel>> Function(LaundryProductsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LaundryProductsProvider._internal(
        (ref) => create(ref as LaundryProductsRef),
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
  AutoDisposeStreamProviderElement<List<LaundryProductModel>> createElement() {
    return _LaundryProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LaundryProductsProvider && other.laundryId == laundryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, laundryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LaundryProductsRef
    on AutoDisposeStreamProviderRef<List<LaundryProductModel>> {
  /// The parameter `laundryId` of this provider.
  String get laundryId;
}

class _LaundryProductsProviderElement
    extends AutoDisposeStreamProviderElement<List<LaundryProductModel>>
    with LaundryProductsRef {
  _LaundryProductsProviderElement(super.provider);

  @override
  String get laundryId => (origin as LaundryProductsProvider).laundryId;
}

String _$allLaundryProductsHash() =>
    r'afe48a9feaaddce74954e68267737b1f161758fe';

/// See also [allLaundryProducts].
@ProviderFor(allLaundryProducts)
const allLaundryProductsProvider = AllLaundryProductsFamily();

/// See also [allLaundryProducts].
class AllLaundryProductsFamily
    extends Family<AsyncValue<List<LaundryProductModel>>> {
  /// See also [allLaundryProducts].
  const AllLaundryProductsFamily();

  /// See also [allLaundryProducts].
  AllLaundryProductsProvider call(
    String laundryId,
  ) {
    return AllLaundryProductsProvider(
      laundryId,
    );
  }

  @override
  AllLaundryProductsProvider getProviderOverride(
    covariant AllLaundryProductsProvider provider,
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
  String? get name => r'allLaundryProductsProvider';
}

/// See also [allLaundryProducts].
class AllLaundryProductsProvider
    extends AutoDisposeStreamProvider<List<LaundryProductModel>> {
  /// See also [allLaundryProducts].
  AllLaundryProductsProvider(
    String laundryId,
  ) : this._internal(
          (ref) => allLaundryProducts(
            ref as AllLaundryProductsRef,
            laundryId,
          ),
          from: allLaundryProductsProvider,
          name: r'allLaundryProductsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$allLaundryProductsHash,
          dependencies: AllLaundryProductsFamily._dependencies,
          allTransitiveDependencies:
              AllLaundryProductsFamily._allTransitiveDependencies,
          laundryId: laundryId,
        );

  AllLaundryProductsProvider._internal(
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
    Stream<List<LaundryProductModel>> Function(AllLaundryProductsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllLaundryProductsProvider._internal(
        (ref) => create(ref as AllLaundryProductsRef),
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
  AutoDisposeStreamProviderElement<List<LaundryProductModel>> createElement() {
    return _AllLaundryProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllLaundryProductsProvider && other.laundryId == laundryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, laundryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AllLaundryProductsRef
    on AutoDisposeStreamProviderRef<List<LaundryProductModel>> {
  /// The parameter `laundryId` of this provider.
  String get laundryId;
}

class _AllLaundryProductsProviderElement
    extends AutoDisposeStreamProviderElement<List<LaundryProductModel>>
    with AllLaundryProductsRef {
  _AllLaundryProductsProviderElement(super.provider);

  @override
  String get laundryId => (origin as AllLaundryProductsProvider).laundryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
