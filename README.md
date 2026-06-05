# HISP Mobile Tracker 🚀

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-green?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

A professional, high-performance DHIS2-based mobile data entry application built with Flutter. **HISP Mobile Tracker** is designed to streamline field data collection, ensuring reliability and seamless integration with DHIS2 instances.

## ✨ Features

- **Secure Authentication**: OAuth2/Token-based login with secure local storage.
- **DHIS2 Integration**: Direct synchronization with DHIS2 DataSets and Data Elements.
- **Offline First**: Robust local caching for data entry in low-connectivity areas.
- **Dynamic Forms**: Auto-generated forms based on DHIS2 metadata configuration.
- **Real-time Validation**: Client-side validation for data accuracy.
- **Modern UI/UX**: Clean, intuitive interface built with Material Design 3.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.0.0+)
- **State Management**: [BLoC](https://pub.dev/packages/flutter_bloc) for predictable state transitions.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.
- **Networking**: [Dio](https://pub.dev/packages/dio) with interceptors for auth and logging.
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) & [Injectable](https://pub.dev/packages/injectable).
- **Local Storage**: [Secure Storage](https://pub.dev/packages/flutter_secure_storage) for credentials and [Shared Preferences](https://pub.dev/packages/shared_preferences) for settings.
- **Serialization**: [Freezed](https://pub.dev/packages/freezed) & [JSON Serializable](https://pub.dev/packages/json_serializable).

## 🏗 Architecture

The project follows **Clean Architecture** principles to ensure scalability, maintainability, and testability:

- **Core**: Cross-cutting concerns like constants, themes, and network utilities.
- **Features**: Domain-driven modules (e.g., Auth, Home).
  - `data`: Repositories, Data Sources, and Models.
  - `domain`: Entities, Use Cases, and Repository Interfaces.
  - `presentation`: BLoCs and UI Components.
- **Shared**: Common widgets and utility functions used across features.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: `>=3.0.0`
- Dart SDK: `>=3.0.0`
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/hisp_mobile_trucker.git
   cd hisp_mobile_trucker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Testing

To run the test suite:

```bash
flutter test
```


Powered by HISP ETHIOPIA
