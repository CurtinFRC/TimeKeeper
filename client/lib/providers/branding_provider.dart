import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:time_keeper/colors.dart';
import 'package:time_keeper/generated/api/settings.pbgrpc.dart';
import 'package:time_keeper/helpers/grpc_call_wrapper.dart';
import 'package:time_keeper/providers/settings_provider.dart';
import 'package:time_keeper/utils/grpc_result.dart';

part 'branding_provider.g.dart';

const _defaultPrimaryColor = Color(0xFF009485);
const _defaultSecondaryColor = Color(0xFF005994);

class Branding {
  final MaterialColor primaryColor;
  final MaterialColor secondaryColor;
  final Uint8List? logoBytes;

  const Branding({
    required this.primaryColor,
    required this.secondaryColor,
    this.logoBytes,
  });
}

Color? _parseHexColor(String hex) {
  if (hex.isEmpty) return null;
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}

@Riverpod(keepAlive: true)
class BrandingNotifier extends _$BrandingNotifier {
  @override
  Branding build() {
    _fetchBranding();
    return Branding(
      primaryColor: createMaterialColor(_defaultPrimaryColor),
      secondaryColor: createMaterialColor(_defaultSecondaryColor),
    );
  }

  Future<void> _fetchBranding() async {
    final client = ref.read(settingsServiceProvider);

    final settingsResult = await callGrpcEndpoint(
      () => client.getSettings(GetSettingsRequest()),
    );

    final logoResult = await callGrpcEndpoint(
      () => client.getLogo(GetLogoRequest()),
    );

    final primary = settingsResult is GrpcSuccess<GetSettingsResponse>
        ? _parseHexColor(settingsResult.data.settings.primaryColor)
        : null;

    final secondary = settingsResult is GrpcSuccess<GetSettingsResponse>
        ? _parseHexColor(settingsResult.data.settings.secondaryColor)
        : null;

    Uint8List? logoBytes;
    if (logoResult is GrpcSuccess<GetLogoResponse> &&
        logoResult.data.logo.isNotEmpty) {
      logoBytes = Uint8List.fromList(logoResult.data.logo);
    }

    state = Branding(
      primaryColor: createMaterialColor(primary ?? _defaultPrimaryColor),
      secondaryColor: createMaterialColor(secondary ?? _defaultSecondaryColor),
      logoBytes: logoBytes,
    );
  }

  Future<void> refresh() async {
    await _fetchBranding();
  }
}
