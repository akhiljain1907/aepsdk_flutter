/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import 'package:flutter/services.dart';
import 'package:flutter_aepmessaging/flutter_aepmessaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_aepmessaging');

  TestWidgetsFlutterBinding.ensureInitialized();

  group('extensionVersion', () {
    final String testVersion = "2.0.0";
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return testVersion;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('invokes correct method', () async {
      await Messaging.extensionVersion;

      expect(log, <Matcher>[
        isMethodCall(
          'extensionVersion',
          arguments: null,
        ),
      ]);
    });

    test('returns correct result', () async {
      expect(await Messaging.extensionVersion, testVersion);
    });
  });

  group('refreshInAppMessages', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('invokes correct method', () async {
      Messaging.refreshInAppMessages();

      expect(log, <Matcher>[
        isMethodCall(
          'refreshInAppMessages',
          arguments: null,
        ),
      ]);
    });
  });

  group('Surface', () {
    test('toMap serializes path', () {
      expect(Surface('homepage/banner').toMap(),
          {'path': 'homepage/banner', 'uri': ''});
    });

    test('fromMap reads uri', () {
      final s = Surface.fromMap({'uri': 'mobileapp://com.app/homepage/banner'});
      expect(s.uri, 'mobileapp://com.app/homepage/banner');
    });

    test('equality by uri then path', () {
      expect(Surface('a'), Surface('a'));
      expect(Surface('a') == Surface('b'), false);
      expect(Surface.fromUri('u1'), Surface.fromUri('u1'));
    });
  });

  group('PropositionItem', () {
    final itemMap = {
      'itemId': 'item-1',
      'schema': 'https://ns.adobe.com/personalization/message/content-card',
      'data': {
        'content': {'title': 'Hello', 'body': 'World'},
        'contentType': 'application/json',
        'publishedDate': 1700000000,
        'expiryDate': 1800000000,
        'meta': {'surface': 'homepage'},
      },
    };

    test('fromMap parses fields', () {
      final item = PropositionItem.fromMap(itemMap);
      expect(item.itemId, 'item-1');
      expect(item.schema.contains('content-card'), true);
      expect(item.data['contentType'], 'application/json');
    });

    test('contentCardSchemaData exposes card fields', () {
      final card = PropositionItem.fromMap(itemMap).contentCardSchemaData;
      expect(card, isNotNull);
      expect((card!.content as Map)['title'], 'Hello');
      expect(card.contentType, 'application/json');
      expect(card.publishedDate, 1700000000);
      expect(card.expiryDate, 1800000000);
      expect(card.meta, {'surface': 'homepage'});
    });

    test('contentCardSchemaData is null without content', () {
      final item = PropositionItem.fromMap({'itemId': 'x', 'data': {}});
      expect(item.contentCardSchemaData, isNull);
    });

    group('tracking', () {
      final List<MethodCall> log = <MethodCall>[];
      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return methodCall.method == 'generatePropositionInteractionXdm'
              ? {'eventType': 'decisioning.propositionInteract'}
              : null;
        });
      });
      tearDown(() {
        log.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('track invokes trackPropositionInteraction with itemId', () async {
        await PropositionItem.fromMap(itemMap)
            .track('click', MessagingEdgeEventType.INTERACT, tokens: ['t1']);
        expect(log.length, 1);
        expect(log[0].method, 'trackPropositionInteraction');
        final args = log[0].arguments as Map;
        expect(args['itemId'], 'item-1');
        expect(args['eventType'], MessagingEdgeEventType.INTERACT.value);
        expect(args['interaction'], 'click');
        expect(args['tokens'], ['t1']);
      });

      test('generateInteractionXdm returns xdm map', () async {
        final xdm = await PropositionItem.fromMap(itemMap)
            .generateInteractionXdm(null, MessagingEdgeEventType.DISPLAY);
        expect(log[0].method, 'generatePropositionInteractionXdm');
        expect(xdm!['eventType'], 'decisioning.propositionInteract');
      });

      test('ContentCardSchemaData.track routes via parent itemId', () async {
        await PropositionItem.fromMap(itemMap)
            .contentCardSchemaData!
            .track(null, MessagingEdgeEventType.DISPLAY);
        expect(log[0].method, 'trackPropositionInteraction');
        expect((log[0].arguments as Map)['itemId'], 'item-1');
      });
    });
  });

  group('Proposition', () {
    test('fromMap parses items', () {
      final prop = Proposition.fromMap({
        'id': 'prop-1',
        'scope': 'mobileapp://com.app/homepage',
        'scopeDetails': {'activity': {'id': 'act-1'}},
        'items': [
          {'itemId': 'i1', 'schema': 's', 'data': {'content': {}}},
          {'itemId': 'i2', 'schema': 's', 'data': {'content': {}}},
        ],
      });
      expect(prop.id, 'prop-1');
      expect(prop.scope, 'mobileapp://com.app/homepage');
      expect(prop.scopeDetails['activity'], {'id': 'act-1'});
      expect(prop.items.length, 2);
      expect(prop.items[0].itemId, 'i1');
    });

    test('fromMap handles missing items', () {
      final prop = Proposition.fromMap({'id': 'p', 'scope': 's'});
      expect(prop.items, isEmpty);
      expect(prop.scopeDetails, isEmpty);
    });
  });

  group('updatePropositionsForSurfaces', () {
    final List<MethodCall> log = <MethodCall>[];
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });
    tearDown(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokes correct method with serialized surfaces', () async {
      Messaging.updatePropositionsForSurfaces(
          [Surface('homepage/banner'), Surface('homepage/feed')]);
      await Future<void>.delayed(Duration.zero);
      expect(log.length, 1);
      expect(log[0].method, 'updatePropositionsForSurfaces');
      final surfaces = (log[0].arguments as Map)['surfaces'] as List;
      expect(surfaces.length, 2);
      expect((surfaces[0] as Map)['path'], 'homepage/banner');
    });
  });

  group('getPropositionsForSurfaces', () {
    final List<MethodCall> log = <MethodCall>[];
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return {
          'mobileapp://com.app/homepage/banner': [
            {
              'id': 'prop-1',
              'scope': 'mobileapp://com.app/homepage/banner',
              'scopeDetails': {},
              'items': [
                {
                  'itemId': 'item-1',
                  'schema': 'content-card',
                  'data': {
                    'content': {'title': 'Card'}
                  }
                }
              ],
            }
          ]
        };
      });
    });
    tearDown(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokes correct method and decodes propositions', () async {
      final result = await Messaging.getPropositionsForSurfaces(
          [Surface('homepage/banner')]);
      expect(log[0].method, 'getPropositionsForSurfaces');
      expect(result.length, 1);
      final props = result['mobileapp://com.app/homepage/banner']!;
      expect(props.length, 1);
      expect(props[0].id, 'prop-1');
      expect(props[0].items[0].contentCardSchemaData, isNotNull);
    });
  });
}
