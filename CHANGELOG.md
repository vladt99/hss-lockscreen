# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-07-23

### Added
- Initial release of HSS Lock Screen package
- Conditional lock screen widget that only displays on web in debug mode
- AuthCubit with flutter_bloc for state management
- Secure storage integration with flutter_secure_storage
- 20-day authentication expiry system
- Beautiful blurred lock screen UI with centered password input
- Password validation and authentication persistence
- Comprehensive unit tests
- Example application demonstrating usage
- Full documentation and README

### Features
- Wraps any child widget with conditional authentication
- Only shows on web platform in debug mode (kIsWeb && kDebugMode)
- Secure timestamp storage with automatic expiry
- Customizable blur intensity and background color
- Material Design lock screen interface
- Error handling and loading states
- Clear authentication method for testing

### Dependencies
- flutter_bloc: ^8.1.3 for state management
- flutter_secure_storage: ^9.0.0 for secure authentication storage
