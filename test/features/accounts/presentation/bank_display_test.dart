import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/bank.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';
import 'package:fundly/features/accounts/presentation/bank_display.dart';

// docs/BANKS_PLAN.md, B-1, B-2, B-4, B-5.

CustomBank custom(String id, String name) =>
    CustomBank(id: id, name: name, createdAt: DateTime.utc(2026, 11, 25));

Account account({String? bankKey, String? customBankId}) => Account(
  id: '1',
  name: 'Savings',
  type: AccountType.savingsCash,
  openingBalance: const Money.zero('PHP'),
  createdAt: DateTime.utc(2026, 11, 25),
  bankKey: bankKey,
  customBankId: customBankId,
);

/// WCAG contrast ratio of white text on [background].
double contrastWithWhite(Color background) {
  final luminance = background.computeLuminance();
  return 1.05 / (luminance + 0.05);
}

void main() {
  group('built-in badges', () {
    test('every built-in bank has a distinct 2-3 letter monogram', () {
      final monograms = [
        for (final bank in builtInBanks) builtInBankBadge(bank).monogram,
      ];
      for (final monogram in monograms) {
        expect(monogram, matches(RegExp(r'^[A-Z]{2,3}$')));
      }
      expect(monograms.toSet(), hasLength(builtInBanks.length));
    });

    test('white initials are readable on every colour (4.5:1)', () {
      final colors = {
        for (final bank in builtInBanks) builtInBankBadge(bank).color,
        for (final name in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
          customBankBadge(custom('1', name)).color,
      };
      for (final color in colors) {
        expect(
          contrastWithWhite(color),
          greaterThanOrEqualTo(4.5),
          reason: color.toString(),
        );
      }
    });
  });

  group('custom badges', () {
    test('monograms come from the first two words or letters', () {
      expect(monogramFor('Town Coop'), 'TC');
      expect(monogramFor('rural bank of iba'), 'RB');
      expect(monogramFor('Pag-IBIG'), 'PA');
      expect(monogramFor('  x  '), 'X');
      expect(monogramFor('ñandu bank'), 'ÑB');
    });

    test('the colour depends only on the name, ignoring case', () {
      final a = customBankBadge(custom('1', 'Town Coop'));
      final b = customBankBadge(custom('2', 'TOWN COOP'));
      expect(a.color, b.color);
      expect(a.name, 'Town Coop');
    });

    test('names spread over several colours', () {
      final colors = {
        for (var i = 0; i < 40; i++)
          customBankBadge(custom('$i', 'Bank ${String.fromCharCode(65 + i)}'))
              .color,
      };
      expect(colors, hasLength(8), reason: 'the whole palette is used');
    });
  });

  group("an account's badge", () {
    final coop = custom('30', 'Town Coop');

    test('a built-in bank, a custom bank, or none', () {
      expect(accountBankBadge(account(bankKey: 'bdo'), {})?.name, 'BDO');
      expect(
        accountBankBadge(account(customBankId: '30'), {'30': coop})?.name,
        'Town Coop',
      );
      expect(accountBankBadge(account(), {'30': coop}), isNull);
    });

    test('an unknown key or a bank not downloaded yet shows as none', () {
      expect(accountBankBadge(account(bankKey: 'komo'), {}), isNull);
      expect(
        accountBankBadge(account(customBankId: '31'), {'30': coop}),
        isNull,
      );
    });
  });

  group('logo files', () {
    test('every built-in bank has a 192 px square PNG logo', () {
      for (final bank in builtInBanks) {
        final file = File(bankLogoAsset(bank.key));
        expect(file.existsSync(), isTrue, reason: file.path);
        final bytes = file.readAsBytesSync();
        // PNG signature, then the IHDR width and height (big-endian).
        expect(bytes.sublist(1, 4), 'PNG'.codeUnits, reason: file.path);
        final header = ByteData.sublistView(bytes, 16, 24);
        expect(
          (header.getUint32(0), header.getUint32(4)),
          (192, 192),
          reason: file.path,
        );
      }
    });

    test('the logo folder is bundled', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/images/banks/'),
      );
    });
  });

  group('BankAvatar', () {
    Future<void> pumpAvatars(WidgetTester tester, List<Widget> avatars) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Column(children: avatars)),
          ),
        );

    testWidgets('a built-in bank shows its logo image', (tester) async {
      final bdo = builtInBankBadge(builtInBankByKey('bdo')!);
      await pumpAvatars(tester, [BankAvatar(badge: bdo)]);

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/banks/bdo.png',
      );
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('BDO logo'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a custom bank shows its monogram; no bank shows the icon', (
      tester,
    ) async {
      await pumpAvatars(tester, [
        BankAvatar(badge: customBankBadge(custom('30', 'Town Coop'))),
        BankAvatar(
          badge: null,
          fallbackIcon: accountTypeIcon(AccountType.credit),
        ),
      ]);

      expect(find.text('TC'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('a logo that fails to load falls back to the monogram', (
      tester,
    ) async {
      const missing = (
        name: 'Gone Bank',
        logoAsset: 'assets/images/banks/missing.png',
        monogram: 'GB',
        color: Color(0xFF00695C),
      );
      await tester.runAsync(() async {
        await pumpAvatars(tester, [const BankAvatar(badge: missing)]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('GB'), findsOneWidget);
    });
  });
}
