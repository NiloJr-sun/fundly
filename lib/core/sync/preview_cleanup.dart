// Deletes the S4 preview database that the synchronized store replaces
// (S4 Decision 1). Platform-specific: a file on native, browser storage on web.
export 'preview_cleanup_native.dart'
    if (dart.library.js_interop) 'preview_cleanup_web.dart';
