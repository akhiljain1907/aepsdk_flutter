/// Copyright 2026 Adobe. All rights reserved.
/// This file is licensed to you under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License. You may obtain a copy
/// of the License at http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software distributed under
/// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
/// OF ANY KIND, either express or implied. See the License for the specific language
/// governing permissions and limitations under the License.

import 'package:flutter/services.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_content_card_schema_data.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_messaging_edge_event_type.dart';

/// A single decision option within a [Proposition]. Mirrors the native
/// `PropositionItem` type. For Content Cards, the card data is available via
/// [contentCardSchemaData].
class PropositionItem {
  static const MethodChannel _channel =
      const MethodChannel('flutter_aepmessaging');

  /// Unique identifier for this proposition item.
  final String itemId;

  /// The schema string describing the item's content
  /// (e.g. a content-card schema URI).
  final String schema;

  /// The raw item data map as returned by the SDK.
  final Map<String, dynamic> data;

  PropositionItem({
    required this.itemId,
    this.schema = '',
    this.data = const {},
  });

  /// Creates a proposition item from a platform channel [map].
  factory PropositionItem.fromMap(Map<dynamic, dynamic> map) {
    return PropositionItem(
      itemId: map['itemId'] as String? ?? '',
      schema: map['schema'] as String? ?? '',
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : <String, dynamic>{},
    );
  }

  /// The content-card schema data for this item, or null if it is not a content card.
  ContentCardSchemaData? get contentCardSchemaData =>
      ContentCardSchemaData.fromItemData(itemId, data);

  /// Tracks an interaction with this proposition item. Produces the same XDM the
  /// native SDK would send. [tokens] are optional sub-item tokens.
  Future<void> track(
    String? interaction,
    MessagingEdgeEventType eventType, {
    List<String>? tokens,
  }) {
    return _channel.invokeMethod('trackPropositionInteraction', {
      'itemId': itemId,
      'eventType': eventType.value,
      'interaction': interaction,
      'tokens': tokens,
    });
  }

  /// Generates the XDM interaction map for this proposition item without dispatching it.
  Future<Map<String, dynamic>?> generateInteractionXdm(
    String? interaction,
    MessagingEdgeEventType eventType, {
    List<String>? tokens,
  }) {
    return _channel.invokeMapMethod<String, dynamic>(
        'generatePropositionInteractionXdm', {
      'itemId': itemId,
      'eventType': eventType.value,
      'interaction': interaction,
      'tokens': tokens,
    });
  }
}
