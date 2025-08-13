// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sftp_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sftpNotifierHash() => r'819f80135b516bf1d8d3e7dd9022edf3b23a9e0c';

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

abstract class _$SftpNotifier extends BuildlessAutoDisposeNotifier<SftpState> {
  late final SftpWorker sftpWorker;

  SftpState build(SftpWorker sftpWorker);
}

/// See also [SftpNotifier].
@ProviderFor(SftpNotifier)
const sftpNotifierProvider = SftpNotifierFamily();

/// See also [SftpNotifier].
class SftpNotifierFamily extends Family<SftpState> {
  /// See also [SftpNotifier].
  const SftpNotifierFamily();

  /// See also [SftpNotifier].
  SftpNotifierProvider call(SftpWorker sftpWorker) {
    return SftpNotifierProvider(sftpWorker);
  }

  @override
  SftpNotifierProvider getProviderOverride(
    covariant SftpNotifierProvider provider,
  ) {
    return call(provider.sftpWorker);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sftpNotifierProvider';
}

/// See also [SftpNotifier].
class SftpNotifierProvider
    extends AutoDisposeNotifierProviderImpl<SftpNotifier, SftpState> {
  /// See also [SftpNotifier].
  SftpNotifierProvider(SftpWorker sftpWorker)
    : this._internal(
        () => SftpNotifier()..sftpWorker = sftpWorker,
        from: sftpNotifierProvider,
        name: r'sftpNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sftpNotifierHash,
        dependencies: SftpNotifierFamily._dependencies,
        allTransitiveDependencies:
            SftpNotifierFamily._allTransitiveDependencies,
        sftpWorker: sftpWorker,
      );

  SftpNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sftpWorker,
  }) : super.internal();

  final SftpWorker sftpWorker;

  @override
  SftpState runNotifierBuild(covariant SftpNotifier notifier) {
    return notifier.build(sftpWorker);
  }

  @override
  Override overrideWith(SftpNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SftpNotifierProvider._internal(
        () => create()..sftpWorker = sftpWorker,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sftpWorker: sftpWorker,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<SftpNotifier, SftpState> createElement() {
    return _SftpNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SftpNotifierProvider && other.sftpWorker == sftpWorker;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sftpWorker.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SftpNotifierRef on AutoDisposeNotifierProviderRef<SftpState> {
  /// The parameter `sftpWorker` of this provider.
  SftpWorker get sftpWorker;
}

class _SftpNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<SftpNotifier, SftpState>
    with SftpNotifierRef {
  _SftpNotifierProviderElement(super.provider);

  @override
  SftpWorker get sftpWorker => (origin as SftpNotifierProvider).sftpWorker;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
