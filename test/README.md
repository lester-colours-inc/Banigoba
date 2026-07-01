# Test Structure

Tests are grouped by the part of the app they protect:

- `auth/` covers sign-in gates, permissions, and access-control helper logic.
- `services/` covers data and business logic that can run without a live UI.
- `ui/` covers widgets, screens, themes, and user-visible behavior.

Prefer service tests for pure logic and widget tests for UI behavior. Keep tests
runnable with `flutter test` without requiring Firebase emulators unless a test
file clearly says otherwise.
