/// The app's version and build number, as in `pubspec.yaml` (a test keeps
/// them equal). Shown on Profile so each device's build is known (cloud sync
/// S7 Decision 5). Bump both together for every release.
const appVersion = '1.3.0';
const appBuild = 5;

/// For example `Version 1.2.1 (4)`.
const appVersionText = 'Version $appVersion ($appBuild)';
