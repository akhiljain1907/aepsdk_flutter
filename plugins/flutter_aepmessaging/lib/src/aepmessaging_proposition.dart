/// Copyright 2026 Adobe. All rights reserved.
/// This file is licensed to you under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License. You may obtain a copy
/// of the License at http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software distributed under
/// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
/// OF ANY KIND, either express or implied. See the License for the specific language
/// governing permissions and limitations under the License.

import 'package:flutter_aepmessaging/src/aepmessaging_proposition_item.dart';

/// Represents the propositions returned from Adobe Journey Optimizer for a given
/// surface. Mirrors the native `Proposition` type. A proposition contains one or
/// more [items] (for Content Cards, each item carries a card).
class Proposition {
  /// Unique identifier for this proposition.
  final String id;

  /// The surface scope (URI) this proposition was returned for.
  final String scope;

  /// Scope details used for tracking this proposition.
  final Map<String, dynamic> scopeDetails;

  /// The proposition items contained in this proposition.
  final List<PropositionItem> items;

  Proposition({
    required this.id,
    required this.scope,
    this.scopeDetails = const {},
    this.items = const [],
  });

  /// Creates a proposition from a platform channel [map].
  factory Proposition.fromMap(Map<dynamic, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) =>
                PropositionItem.fromMap(Map<dynamic, dynamic>.from(i as Map)))
            .toList() ??
        <PropositionItem>[];
    return Proposition(
      id: map['id'] as String? ?? '',
      scope: map['scope'] as String? ?? '',
      scopeDetails: map['scopeDetails'] != null
          ? Map<String, dynamic>.from(map['scopeDetails'] as Map)
          : <String, dynamic>{},
      items: itemsList,
    );
  }

  @override
  String toString() =>
      'Proposition(id: $id, scope: $scope, items: ${items.length})';
}
