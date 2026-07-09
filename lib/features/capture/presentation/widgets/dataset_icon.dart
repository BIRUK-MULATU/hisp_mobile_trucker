import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/auth/app_session.dart';
import '../../domain/entities/dataset_entity.dart';
import 'dataset_icon_helper.dart';

/// Icon badge for a dataset card.
///
/// When the dataset has an icon assigned on the DHIS2 server
/// (`style.icon`, carried as [DataSetEntity.iconType]), that SVG is
/// downloaded and shown, tinted to match the card design. While it
/// loads — and whenever it is missing, fails, or the device is
/// offline — the keyword-based Material icon is shown instead.
class DataSetIcon extends StatelessWidget {
  final DataSetEntity dataSet;
  final double size;

  const DataSetIcon({super.key, required this.dataSet, required this.size});

  // Icons repeat across cards and rebuilds; one fetch per key per run.
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> _fetch(String iconKey) {
    return _cache.putIfAbsent(iconKey, () async {
      try {
        // The per-session client carries the auth; logged out (or
        // session not attached yet) just means the fallback icon.
        final api = AppSession.instance.api;
        if (api == null) return null;
        final response = await api.get(
          '/api/icons/$iconKey/icon.svg',
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data is List<int>) {
          return Uint8List.fromList(response.data as List<int>);
        }
      } catch (_) {
        // Fall through — a failed icon must never break the card.
        _cache.remove(iconKey); // retry on a later rebuild
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = DataSetIconHelper.getColor(dataSet.name);
    final fallback = Icon(
      DataSetIconHelper.getIcon(dataSet.name),
      color: color,
      size: size,
    );

    final iconKey = dataSet.iconType;
    if (iconKey == null || iconKey.isEmpty) return fallback;

    return FutureBuilder<Uint8List?>(
      future: _fetch(iconKey),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return SvgPicture.memory(
          bytes,
          width: size,
          height: size,
          // DHIS2 library icons are plain glyphs — tint them so they
          // match the badge color like the Material fallbacks do.
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      },
    );
  }
}
