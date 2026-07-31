/// Copyright 2026 Adobe. All rights reserved.
/// This file is licensed to you under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License. You may obtain a copy
/// of the License at http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software distributed under
/// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
/// OF ANY KIND, either express or implied. See the License for the specific language
/// governing permissions and limitations under the License.

import 'package:flutter/services.dart';
import 'package:flutter_aepmessaging/src/aepmessaging_messaging_edge_event_type.dart';

/// Represents the content-card schema data carried by a `PropositionItem` whose
/// schema is a Content Card. Mirrors the native `ContentCardSchemaData` type.
///
/// The visual fields of a card (title, body, image URL, action URL, buttons)
/// live inside [content] exactly as the native SDK returns them; the app renders
/// them as Flutter widgets.
class ContentCardSchemaData {
  static const MethodChannel _channel =
      const MethodChannel('flutter_aepmessaging');

  /// The `itemId` of the parent `PropositionItem`, used for tracking.
  final String _itemId;

  /// The card content. For a Content Card this is a map of the card's fields
  /// (title, body, image, buttons, action URL, etc.); may also be a string.
  final dynamic content;

  /// The content type of [content] (e.g. `application/json`), when provided.
  final String? contentType;

  /// The timestamp (seconds since epoch) when the card was published, if provided.
  final int? publishedDate;

  /// The timestamp (seconds since epoch) when the card expires, if provided.
  /// The SDK does not filter expired cards out of the results — honor this in the app.
  final int? expiryDate;

  /// Optional metadata associated with the card.
  final Map<String, dynamic>? meta;

  ContentCardSchemaData._({
    required String itemId,
    this.content,
    this.contentType,
    this.publishedDate,
    this.expiryDate,
    this.meta,
  }) : _itemId = itemId;

  /// Builds content-card schema data from a parent `PropositionItem`'s [itemId]
  /// and its `data` map, or returns null if the data is not a content card.
  static ContentCardSchemaData? fromItemData(
      String itemId, Map<dynamic, dynamic>? data) {
    if (data == null || data['content'] == null) return null;
    return ContentCardSchemaData._(
      itemId: itemId,
      content: data['content'],
      contentType: data['contentType'] as String?,
      publishedDate: (data['publishedDate'] as num?)?.toInt(),
      expiryDate: (data['expiryDate'] as num?)?.toInt(),
      meta: data['meta'] != null
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : null,
    );
  }

  /// Tracks an interaction with this content card. Reuses the parent proposition
  /// item's native tracking, producing the same XDM the native SDK would send.
  Future<void> track(String? interaction, MessagingEdgeEventType eventType) {
    return _channel.invokeMethod('trackPropositionInteraction', {
      'itemId': _itemId,
      'eventType': eventType.value,
      'interaction': interaction,
    });
  }
}
