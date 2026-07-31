/// Copyright 2026 Adobe. All rights reserved.
/// This file is licensed to you under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License. You may obtain a copy
/// of the License at http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software distributed under
/// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
/// OF ANY KIND, either express or implied. See the License for the specific language
/// governing permissions and limitations under the License.

/// Represents a Surface used to fetch personalization content (e.g. Content Cards)
/// from Adobe Journey Optimizer via the Experience Edge network.
///
/// A [Surface] is identified by a relative [path] (for example `"homepage/banner"`).
/// The native SDK expands it into a full surface URI of the form
/// `mobileapp://<app-bundle-id>/<path>`; that expanded [uri] is populated on
/// surfaces returned from [Messaging.getPropositionsForSurfaces].
class Surface {
  /// The relative path that identifies this surface (e.g. `"homepage/banner"`).
  final String path;

  /// The fully-qualified surface URI, when known (populated on surfaces returned
  /// from the SDK). Empty when a surface is constructed locally from a [path].
  final String uri;

  /// Creates a surface from a relative [path] (e.g. `"homepage/banner"`).
  const Surface(this.path) : uri = '';

  /// Creates a surface from an already-expanded surface [uri].
  const Surface.fromUri(this.uri) : path = '';

  /// Converts this surface into a map for the platform channel.
  Map<String, dynamic> toMap() => {'path': path, 'uri': uri};

  /// Creates a surface from a platform channel [map].
  factory Surface.fromMap(Map<dynamic, dynamic> map) {
    return Surface.fromUri(map['uri'] as String? ?? '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Surface &&
          runtimeType == other.runtimeType &&
          (uri.isNotEmpty ? uri == other.uri : path == other.path);

  @override
  int get hashCode => uri.isNotEmpty ? uri.hashCode : path.hashCode;

  @override
  String toString() => 'Surface(path: $path, uri: $uri)';
}
