import 'package:flutter/material.dart';

import '../domain/account.dart';
import '../domain/account_type.dart';
import '../domain/bank.dart';
import '../domain/custom_bank.dart';

/// How a bank looks: its name, its logo image when the app bundles one, and
/// otherwise the initials on its monogram and the monogram's colour
/// (docs/BANKS_PLAN.md, B-1, B-2, B-5).
typedef BankBadge = ({
  String name,
  String? logoAsset,
  String monogram,
  Color color,
});

/// The logo of built-in bank [key]: a 192 px square PNG, already padded to
/// fit a circle. Every built-in bank has one; a test checks it.
String bankLogoAsset(String key) => 'assets/images/banks/$key.png';

/// Monogram and colour of each built-in bank, by key, shown if its logo
/// image cannot be loaded. White initials stay readable on every colour
/// (contrast 4.5:1 or more).
const Map<String, ({String monogram, Color color})> _builtInBadges = {
  'bdo': (monogram: 'BDO', color: Color(0xFF003087)),
  'bpi': (monogram: 'BPI', color: Color(0xFFA6192E)),
  'metrobank': (monogram: 'MB', color: Color(0xFF0B3C8C)),
  'landbank': (monogram: 'LBP', color: Color(0xFF00703C)),
  'pnb': (monogram: 'PNB', color: Color(0xFF13306B)),
  'securitybank': (monogram: 'SB', color: Color(0xFF0A5A9C)),
  'unionbank': (monogram: 'UB', color: Color(0xFFB34700)),
  'rcbc': (monogram: 'RC', color: Color(0xFF1C3F94)),
  'chinabank': (monogram: 'CBC', color: Color(0xFFB0171F)),
  'eastwest': (monogram: 'EW', color: Color(0xFF7A1F5C)),
  'gcash': (monogram: 'GC', color: Color(0xFF0057C2)),
  'maya': (monogram: 'MY', color: Color(0xFF00754A)),
  'gotyme': (monogram: 'GT', color: Color(0xFF00696B)),
  'seabank': (monogram: 'SEA', color: Color(0xFFB4441A)),
  'cimb': (monogram: 'CIM', color: Color(0xFF9E0B0F)),
  'tonik': (monogram: 'TK', color: Color(0xFF5B2A86)),
};

/// Colours for custom bank monograms, picked by name (B-5).
const List<Color> _customPalette = [
  Color(0xFF00695C),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
  Color(0xFF37474F),
  Color(0xFF2E7D32),
  Color(0xFFBF360C),
];

/// The badge of built-in bank [bank].
BankBadge builtInBankBadge(Bank bank) {
  final badge = _builtInBadges[bank.key];
  return (
    name: bank.name,
    logoAsset: bankLogoAsset(bank.key),
    monogram: badge?.monogram ?? monogramFor(bank.name),
    color: badge?.color ?? _customPalette.first,
  );
}

/// The badge of custom bank [bank]: initials from its name, and a colour
/// that depends only on the name ignoring case, so it is the same on every
/// device.
BankBadge customBankBadge(CustomBank bank) => (
  name: bank.name,
  logoAsset: null,
  monogram: monogramFor(bank.name),
  color: _customPalette[_nameCode(bank.name) % _customPalette.length],
);

/// Up to two initials: the first letters of the first two words, or the
/// first two characters of a single word, upper-cased.
String monogramFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final initials = words.length == 1
      ? words.first.characters.take(2).toString()
      : words.take(2).map((word) => word.characters.first).join();
  return initials.toUpperCase();
}

int _nameCode(String name) =>
    name.toLowerCase().codeUnits.fold(0, (sum, unit) => sum + unit);

/// The badge for [account]'s bank, or `null` for no bank. See [bankBadgeFor].
BankBadge? accountBankBadge(
  Account account,
  Map<String, CustomBank> customBanks,
) => bankBadgeFor(account.bank, customBanks);

/// The badge for [bank], or `null` for no bank. A built-in key this app does
/// not know (from a later version) and a custom bank not in [customBanks]
/// (not downloaded yet) also show as no bank.
BankBadge? bankBadgeFor(AccountBank bank, Map<String, CustomBank> customBanks) {
  if (bank.bankKey case final key?) {
    final builtIn = builtInBankByKey(key);
    return builtIn == null ? null : builtInBankBadge(builtIn);
  }
  if (bank.customBankId case final id?) {
    final custom = customBanks[id];
    return custom == null ? null : customBankBadge(custom);
  }
  return null;
}

/// The icon shown for an account without a bank (B-4), by its built-in base
/// type, so custom types use their base type's icon.
IconData accountTypeIcon(AccountType type) => switch (type) {
  AccountType.savingsCash => Icons.account_balance_wallet_outlined,
  AccountType.credit => Icons.credit_card,
  AccountType.loan => Icons.request_quote_outlined,
};

/// A round bank logo: [badge]'s logo image, or its monogram on its colour,
/// or, without a bank, [fallbackIcon] on a neutral circle.
class BankAvatar extends StatelessWidget {
  const BankAvatar({
    super.key,
    required this.badge,
    this.fallbackIcon = Icons.account_balance_outlined,
    this.size = 40,
  });

  final BankBadge? badge;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    if (badge == null) {
      final colors = Theme.of(context).colorScheme;
      return ExcludeSemantics(
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurfaceVariant,
          child: Icon(fallbackIcon, size: size * 0.55),
        ),
      );
    }
    final monogram = _Monogram(badge: badge, size: size);
    final logoAsset = badge.logoAsset;
    return Semantics(
      label: '${badge.name} logo',
      excludeSemantics: true,
      child: logoAsset == null
          ? monogram
          : _Logo(asset: logoAsset, size: size, fallback: monogram),
    );
  }
}

/// A logo image clipped to a circle, with a hairline so a white logo stays
/// visible on a white surface. Shows [fallback] if the image fails to load.
class _Logo extends StatelessWidget {
  const _Logo({
    required this.asset,
    required this.size,
    required this.fallback,
  });

  final String asset;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

/// Initials on the bank's colour.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.badge, required this.size});

  final BankBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: badge.color,
      foregroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: FittedBox(
          child: Text(
            badge.monogram,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
