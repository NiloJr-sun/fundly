# Fundly

A personal finance and budgeting app for tracking accounts, transactions and
spending. It works offline and keeps all data on the device.

- Product direction and engineering rules: [CLAUDE.md](CLAUDE.md)
- Delivery plan and open decisions: [docs/ROADMAP.md](docs/ROADMAP.md)

**Status:** Phase 0 (project foundation). The app has three placeholder tabs:
Spending, Plans and Account.

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.47.9 (stable) |
| Dart | 3.13.7 (bundled with Flutter) |
| Xcode | Needed for iOS. iOS is the main target device. |
| Android Studio / SDK | Optional, for Android |

Check your setup:

```bash
flutter --version
flutter doctor
```

## Setup

```bash
git clone git@github.com:NiloJr-sun/fundly.git
cd fundly
flutter pub get
```

## Run

```bash
open -a Simulator        # start an iOS simulator
flutter devices          # list available devices
flutter run              # run on the only device, or pick one with -d <id>
```

## Before each commit

Run all three. Each must finish with no issues and no failures.

```bash
dart format .            # format code
flutter analyze          # static analysis (rules in analysis_options.yaml)
flutter test             # run all tests
```

The analyzer uses `flutter_lints`, strict type checks (`strict-casts`,
`strict-inference`, `strict-raw-types`) and a few extra rules. See
[analysis_options.yaml](analysis_options.yaml).

## Project structure

```text
lib/
  main.dart                 # entry point
  app/
    app.dart                # MaterialApp and theme setup
    home_shell.dart         # bottom navigation: Spending, Plans, Account
    theme/                  # AppTheme (light/dark), Spacing
  features/
    spending/presentation/
    plans/presentation/
    accounts/presentation/
test/                       # mirrors lib/
```

Code is organised by feature. Folders for `data/` and `domain/` are added
when a feature needs them.

## Conventions

- Colours and text styles come from `Theme.of(context)`. Don't hard-code
  them in widgets.
- Use `Spacing` constants (`xs`–`xl`) for padding and gaps.
- Keep business rules out of widgets.
- Money is stored as integer minor units (centavos for PHP), never `double`.
