<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# HSS Lock Screen

A Flutter package that provides a conditional lock screen widget for web applications in debug mode. The lock screen uses secure storage to remember authentication for up to 20 days and includes a beautiful blurred overlay interface.

## Features

- 🔒 **Conditional Lock Screen**: Only displays on web in debug mode (`kIsWeb && isEnabled`)
- 🔐 **Secure Authentication**: Uses `flutter_secure_storage` to remember authentication
- ⏰ **Auto Expiry**: Authentication expires after 20 days maximum
- 🎨 **Beautiful UI**: Blurred background with centered password input
- 🏗️ **State Management**: Built with flutter_bloc for clean state management
- 🧪 **Well Tested**: Includes comprehensive unit tests

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  hss_lock_screen: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

Wrap your main app widget with `HssLockScreen`:

```dart
import 'package:flutter/material.dart';
import 'package:hss_lock_screen/hss_lockscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: HssLockScreen(
        password: 'your_secure_password_here',
        child: const MyHomePage(),
      ),
    );
  }
}
```

## Parameters

- `password` (String, required): The password required to unlock the screen
- `child` (Widget, required): The widget to display when unlocked
- `backgroundColor` (Color?, optional): Custom background color for the lock screen overlay
- `blurIntensity` (double, optional): Blur intensity for the background (default: 10.0)

## Behavior

### When Lock Screen is Shown
- Platform: Web only (`kIsWeb` is true)
- Mode: Debug mode only (`isEnabled` is true)
- Authentication: When no valid authentication exists or it has expired

### When Lock Screen is Hidden
- Platform: Any platform other than web
- Mode: Release mode
- Authentication: Valid authentication exists and hasn't expired

### Authentication Storage
- Uses `flutter_secure_storage` to securely store authentication timestamps
- Authentication expires after 20 days
- Timestamp is updated on successful authentication

## Advanced Usage

### Custom Styling

```dart
HssLockScreen(
  password: 'my_password',
  backgroundColor: Colors.black.withOpacity(0.5),
  blurIntensity: 15.0,
  child: MyApp(),
)
```

### Programmatic Authentication Control

You can access the `AuthCubit` for advanced control:

```dart
// Clear authentication (logout)
context.read<AuthCubit>().clearAuth();

// Check current auth status
context.read<AuthCubit>().checkAuthStatus();
```

## Security Considerations

1. **Debug Mode Only**: The lock screen only appears in debug mode, so it won't affect production builds
2. **Secure Storage**: Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
3. **Password in Code**: Remember that the password is stored in your source code, so use appropriate security measures
4. **Web Only**: Only functions on web platform as intended

## Development

### Running Tests

```bash
flutter test
```

### Running the Example

```bash
cd example
flutter run -d chrome
```

## Dependencies

- `flutter_bloc: ^8.1.3` - State management
- `flutter_secure_storage: ^9.0.0` - Secure storage for authentication timestamps

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
