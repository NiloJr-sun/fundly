// The invite secret a web page was opened with (shared spaces C3, Decision
// C3-1). Platform-specific: only the web app opens `/join#<secret>` links.
export 'invite_page_native.dart'
    if (dart.library.js_interop) 'invite_page_web.dart';
