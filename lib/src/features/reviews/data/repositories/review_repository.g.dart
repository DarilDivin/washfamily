// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewRepositoryHash() => r'2a34175cf3319039cd14d5c4d9244bb0300c646c';

/// See also [reviewRepository].
@ProviderFor(reviewRepository)
final reviewRepositoryProvider = Provider<ReviewRepository>.internal(
  reviewRepository,
  name: r'reviewRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReviewRepositoryRef = ProviderRef<ReviewRepository>;
String _$reviewsStreamHash() => r'b114742cc444efc1271057ff9ff537fcc73f7069';

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

/// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
///
/// Copied from [reviewsStream].
@ProviderFor(reviewsStream)
const reviewsStreamProvider = ReviewsStreamFamily();

/// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
///
/// Copied from [reviewsStream].
class ReviewsStreamFamily extends Family<AsyncValue<List<ReviewModel>>> {
  /// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
  ///
  /// Copied from [reviewsStream].
  const ReviewsStreamFamily();

  /// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
  ///
  /// Copied from [reviewsStream].
  ReviewsStreamProvider call(
    String machineId,
  ) {
    return ReviewsStreamProvider(
      machineId,
    );
  }

  @override
  ReviewsStreamProvider getProviderOverride(
    covariant ReviewsStreamProvider provider,
  ) {
    return call(
      provider.machineId,
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
  String? get name => r'reviewsStreamProvider';
}

/// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
///
/// Copied from [reviewsStream].
class ReviewsStreamProvider
    extends AutoDisposeStreamProvider<List<ReviewModel>> {
  /// Provider de stream d'avis pour une machine — consommé dans MachineDetailScreen.
  ///
  /// Copied from [reviewsStream].
  ReviewsStreamProvider(
    String machineId,
  ) : this._internal(
          (ref) => reviewsStream(
            ref as ReviewsStreamRef,
            machineId,
          ),
          from: reviewsStreamProvider,
          name: r'reviewsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reviewsStreamHash,
          dependencies: ReviewsStreamFamily._dependencies,
          allTransitiveDependencies:
              ReviewsStreamFamily._allTransitiveDependencies,
          machineId: machineId,
        );

  ReviewsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.machineId,
  }) : super.internal();

  final String machineId;

  @override
  Override overrideWith(
    Stream<List<ReviewModel>> Function(ReviewsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReviewsStreamProvider._internal(
        (ref) => create(ref as ReviewsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        machineId: machineId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ReviewModel>> createElement() {
    return _ReviewsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewsStreamProvider && other.machineId == machineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, machineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReviewsStreamRef on AutoDisposeStreamProviderRef<List<ReviewModel>> {
  /// The parameter `machineId` of this provider.
  String get machineId;
}

class _ReviewsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ReviewModel>>
    with ReviewsStreamRef {
  _ReviewsStreamProviderElement(super.provider);

  @override
  String get machineId => (origin as ReviewsStreamProvider).machineId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
