/// The app's version and build number, as in `pubspec.yaml` (a test keeps
/// them equal). Shown on Profile so each device's build is known (cloud sync
/// S7 Decision 5). Bump both together for every release.
const appVersion = '1.1.0';
const appBuild = 2;

/// For example `Version 1.1.0 (2)`.
const appVersionText = 'Version $appVersion ($appBuild)';
