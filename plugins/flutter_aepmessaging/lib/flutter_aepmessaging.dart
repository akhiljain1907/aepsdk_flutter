/// Copyright 2023 Adobe. All rights reserved.
/// This file is licensed to you under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License. You may obtain a copy
/// of the License at http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software distributed under
/// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
/// OF ANY KIND, either express or implied. See the License for the specific language
/// governing permissions and limitations under the License.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_message.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_messaging_delegate.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_surface.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_proposition.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_message.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_messaging_edge_event_type.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_messaging_delegate.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_showable.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_surface.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_proposition.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_proposition_item.dart';
export 'package:flutter_aepmessaging/src/aepmessaging_content_card_schema_data.dart';

/// Adobe Experience Platform Messaging
class Messaging {
  static const MethodChannel _channel = MethodChannel('flutter_aepmessaging');

  static MessagingDelegate? _delegate;

  static Future<dynamic> Function(MethodCall)? _methodCallHandler =
      (MethodCall call) async {
    Map<dynamic, dynamic> arguments = call.arguments;
    switch (call.method) {
      case 'onDismiss':
        _delegate?.onDismiss(Message.fromMap(arguments['message']));
        return null;
      case 'onShow':
        _delegate?.onShow(Message.fromMap(arguments['message']));
        return null;
      case 'shouldSaveMessage':
        return _delegate
                ?.shouldSaveMessage(Message.fromMap(arguments['message'])) ??
            false;
      case 'shouldShowMessage':
        return _delegate
                ?.shouldShowMessage(Message.fromMap(arguments['message'])) ??
            true;
      case 'urlLoaded':
        if (Platform.isIOS) {
          _delegate?.urlLoaded(
              arguments['url'], Message.fromMap(arguments['message']));
        }
        return null;
      case 'onContentLoaded':
        if (Platform.isAndroid) {
          _delegate?.onContentLoaded(Message.fromMap(arguments['message']));
        }
        return null;
      default:
        throw UnimplementedError('${call.method} has not been implemented');
    }
  };

  /// Returns the version of the Messaging extension
  static Future<String> get extensionVersion =>
      _channel.invokeMethod('extensionVersion').then((value) => value!);

  /// Returns a list of messages currently cached in-memory
  static Future<List<Message>> getCachedMessages() =>
      _channel.invokeListMethod('getCachedMessages').then((result) =>
          (result ?? []).map((val) => Message.fromMap(val)).toList());

  /// Initiates a network call to retrieve remote In-App Message definitions.
  static void refreshInAppMessages() =>
      _channel.invokeMethod('refreshInAppMessages');

  /// Fetches propositions (e.g. Content Cards) for the given [surfaces] from
  /// Adobe Journey Optimizer over the Experience Edge network and caches them
  /// in the SDK. This is an asynchronous network call every time it is invoked;
  /// throttle it on the app side (e.g. once per launch/foreground).
  ///
  /// Use [getPropositionsForSurfaces] afterwards to read the cached results.
  static void updatePropositionsForSurfaces(List<Surface> surfaces) =>
      _channel.invokeMethod('updatePropositionsForSurfaces',
          {'surfaces': surfaces.map((s) => s.toMap()).toList()});

  /// Retrieves the previously fetched (cached) propositions for the given
  /// [surfaces]. This is a cache-only read — it does not make a network call.
  /// Surfaces that were never fetched via [updatePropositionsForSurfaces] are
  /// absent from the result.
  ///
  /// Note: Content Card propositions are held in memory only and are not
  /// available after an app restart until fetched again.
  ///
  /// Returns a map keyed by surface URI to the list of [Proposition]s for it.
  static Future<Map<String, List<Proposition>>> getPropositionsForSurfaces(
    List<Surface> surfaces,
  ) {
    return _channel.invokeMapMethod<String, dynamic>(
        'getPropositionsForSurfaces',
        {'surfaces': surfaces.map((s) => s.toMap()).toList()}).then((result) {
      final decoded = <String, List<Proposition>>{};
      (result ?? {}).forEach((uri, propositions) {
        decoded[uri] = (propositions as List<dynamic>)
            .map((p) => Proposition.fromMap(Map<dynamic, dynamic>.from(p as Map)))
            .toList();
      });
      return decoded;
    });
  }

  static void setMessagingDelegate(MessagingDelegate? delegate) {
    _delegate = delegate;
    _channel.setMethodCallHandler(_methodCallHandler);
  }
}
