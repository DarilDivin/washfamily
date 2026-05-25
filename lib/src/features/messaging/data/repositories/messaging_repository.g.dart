// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messagingRepositoryHash() =>
    r'7e5cf9607d170440e5bb80a06ea3e8c7d43637f9';

/// See also [messagingRepository].
@ProviderFor(messagingRepository)
final messagingRepositoryProvider = Provider<MessagingRepository>.internal(
  messagingRepository,
  name: r'messagingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MessagingRepositoryRef = ProviderRef<MessagingRepository>;
String _$conversationsStreamHash() =>
    r'886501e9794c52848dd6fa66889584aa0b48e3dc';

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

/// See also [conversationsStream].
@ProviderFor(conversationsStream)
const conversationsStreamProvider = ConversationsStreamFamily();

/// See also [conversationsStream].
class ConversationsStreamFamily
    extends Family<AsyncValue<List<ConversationModel>>> {
  /// See also [conversationsStream].
  const ConversationsStreamFamily();

  /// See also [conversationsStream].
  ConversationsStreamProvider call(
    String userId,
  ) {
    return ConversationsStreamProvider(
      userId,
    );
  }

  @override
  ConversationsStreamProvider getProviderOverride(
    covariant ConversationsStreamProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'conversationsStreamProvider';
}

/// See also [conversationsStream].
class ConversationsStreamProvider
    extends AutoDisposeStreamProvider<List<ConversationModel>> {
  /// See also [conversationsStream].
  ConversationsStreamProvider(
    String userId,
  ) : this._internal(
          (ref) => conversationsStream(
            ref as ConversationsStreamRef,
            userId,
          ),
          from: conversationsStreamProvider,
          name: r'conversationsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$conversationsStreamHash,
          dependencies: ConversationsStreamFamily._dependencies,
          allTransitiveDependencies:
              ConversationsStreamFamily._allTransitiveDependencies,
          userId: userId,
        );

  ConversationsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<ConversationModel>> Function(ConversationsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationsStreamProvider._internal(
        (ref) => create(ref as ConversationsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ConversationModel>> createElement() {
    return _ConversationsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationsStreamProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ConversationsStreamRef
    on AutoDisposeStreamProviderRef<List<ConversationModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ConversationsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ConversationModel>>
    with ConversationsStreamRef {
  _ConversationsStreamProviderElement(super.provider);

  @override
  String get userId => (origin as ConversationsStreamProvider).userId;
}

String _$messagesStreamHash() => r'da706252e91e98139ab4b97ad426847f52edba83';

/// See also [messagesStream].
@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily();

/// See also [messagesStream].
class MessagesStreamFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// See also [messagesStream].
  const MessagesStreamFamily();

  /// See also [messagesStream].
  MessagesStreamProvider call(
    String conversationId,
  ) {
    return MessagesStreamProvider(
      conversationId,
    );
  }

  @override
  MessagesStreamProvider getProviderOverride(
    covariant MessagesStreamProvider provider,
  ) {
    return call(
      provider.conversationId,
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
  String? get name => r'messagesStreamProvider';
}

/// See also [messagesStream].
class MessagesStreamProvider
    extends AutoDisposeStreamProvider<List<MessageModel>> {
  /// See also [messagesStream].
  MessagesStreamProvider(
    String conversationId,
  ) : this._internal(
          (ref) => messagesStream(
            ref as MessagesStreamRef,
            conversationId,
          ),
          from: messagesStreamProvider,
          name: r'messagesStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messagesStreamHash,
          dependencies: MessagesStreamFamily._dependencies,
          allTransitiveDependencies:
              MessagesStreamFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  MessagesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<MessageModel>> Function(MessagesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessagesStreamProvider._internal(
        (ref) => create(ref as MessagesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageModel>> createElement() {
    return _MessagesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MessagesStreamRef on AutoDisposeStreamProviderRef<List<MessageModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _MessagesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageModel>>
    with MessagesStreamRef {
  _MessagesStreamProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as MessagesStreamProvider).conversationId;
}

String _$totalUnreadCountHash() => r'8ba91e2f622831fe336414dbe26b3707e55049e0';

/// See also [totalUnreadCount].
@ProviderFor(totalUnreadCount)
const totalUnreadCountProvider = TotalUnreadCountFamily();

/// See also [totalUnreadCount].
class TotalUnreadCountFamily extends Family<AsyncValue<int>> {
  /// See also [totalUnreadCount].
  const TotalUnreadCountFamily();

  /// See also [totalUnreadCount].
  TotalUnreadCountProvider call(
    String userId,
  ) {
    return TotalUnreadCountProvider(
      userId,
    );
  }

  @override
  TotalUnreadCountProvider getProviderOverride(
    covariant TotalUnreadCountProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'totalUnreadCountProvider';
}

/// See also [totalUnreadCount].
class TotalUnreadCountProvider extends AutoDisposeStreamProvider<int> {
  /// See also [totalUnreadCount].
  TotalUnreadCountProvider(
    String userId,
  ) : this._internal(
          (ref) => totalUnreadCount(
            ref as TotalUnreadCountRef,
            userId,
          ),
          from: totalUnreadCountProvider,
          name: r'totalUnreadCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$totalUnreadCountHash,
          dependencies: TotalUnreadCountFamily._dependencies,
          allTransitiveDependencies:
              TotalUnreadCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  TotalUnreadCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<int> Function(TotalUnreadCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TotalUnreadCountProvider._internal(
        (ref) => create(ref as TotalUnreadCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _TotalUnreadCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TotalUnreadCountProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TotalUnreadCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _TotalUnreadCountProviderElement
    extends AutoDisposeStreamProviderElement<int> with TotalUnreadCountRef {
  _TotalUnreadCountProviderElement(super.provider);

  @override
  String get userId => (origin as TotalUnreadCountProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
