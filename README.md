# HISP Mobile Tracker

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-6DB33F?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![DHIS2](https://img.shields.io/badge/DHIS2-4285F4?style=for-the-badge&logo=DHIS2&logoColor=white)](https://dhis2.org)

**HISP Mobile Tracker** is a cross-platform mobile data entry application built with Flutter, purpose-built for **DHIS2** (District Health Information System 2). It enables health workers and field data collectors to capture, validate, and synchronize program data with DHIS2 instances — reliably, even in low-connectivity environments.

Developed and maintained by **HISP Ethiopia**.

## Features

- **Secure Authentication** — Token-based login with credentials encrypted via secure local storage.
- **DHIS2 Integration** — Seamless synchronization with DHIS2 DataSets, Data Elements, Programs, and Events (API v40).
- **Offline-First** — Built for field conditions; local data persistence ensures uninterrupted data entry when connectivity is unavailable.
- **Dynamic Forms** — Auto-generated data entry forms driven by DHIS2 metadata configuration.
- **Client-Side Validation** — Real-time data validation for accuracy before submission.
- **Material Design 3** — Modern, intuitive interface with a consistent design language.
- **Ethiopian Calendar Support** — Native Ethiopian-to-Gregorian calendar conversion with DHIS2-compatible period generation.
- **Multi-Platform** — Runs on Android, iOS, Web, Linux, macOS, and Windows.

## Tech Stack

| Concern | Library |
|---|---|
| **Framework** | Flutter (Dart SDK >=3.0.0) |
| **State Management** | flutter_bloc 8.x (BLoC pattern) |
| **Routing** | go_router 14.x (declarative, URL-based) |
| **Networking** | dio 5.x with auth & logging interceptors |
| **Dependency Injection** | get_it + injectable (code-generated) |
| **Local Storage** | flutter_secure_storage (credentials), shared_preferences (settings) |
| **Serialization** | freezed + json_serializable (code-generated) |
| **Utilities** | intl (i18n), equatable, logger |

## Architecture

The project follows **Clean Architecture** with a **feature-first** module structure, ensuring separation of concerns, testability, and maintainability across the codebase.

```
lib/
├── core/                          # Cross-cutting infrastructure
│   ├── constants/                 # API endpoints & app constants
│   ├── errors/                    # Exceptions (data) & Failures (domain)
│   ├── network/                   # Dio client, auth & logging interceptors
│   ├── router/                    # GoRouter configuration
│   ├── storage/                   # Secure storage wrapper
│   └── utils/                     # Ethiopian calendar utilities
├── features/                      # Feature modules (domain-driven)
│   ├── auth/                      # Authentication
│   │   ├── data/                  #   Datasources, models, repository impl
│   │   ├── domain/                #   Entities, repository interfaces, use cases
│   │   └── presentation/          #   BLoC, pages, widgets
│   ├── data_entry/                # Data entry forms
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dataset_detail/            # Dataset detail & record list
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── home/                      # Dashboard
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/                        # Shared UI & utilities
│   ├── theme/                     # AppColors, AppTextStyles, AppTheme
│   └── widgets/                   # AppButton, AppTextField, AppLoader
└── main.dart                      # App entry point
```

### Layered Design

Each feature is split into three distinct layers:

| Layer | Responsibility | Dependencies |
|---|---|---|
| **Domain** (innermost) | Business logic — entities, use cases, repository interfaces | Pure Dart, no Flutter dependency |
| **Data** | Repository implementations, data sources (remote API), models | Domain layer, Dio |
| **Presentation** | UI — BLoC state management, pages, reusable widgets | Domain layer, Flutter/BLoC |

Data flows **inward** (Presentation → Domain → Data) via dependency inversion: the presentation layer depends on domain abstractions, while the data layer implements those abstractions.

## Getting Started

### Prerequisites

- Flutter SDK: `>=3.0.0`
- Dart SDK: `>=3.0.0`
- Android Studio, VS Code, or IntelliJ IDEA with Flutter extension

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/hisp_mobile_tracker.git
cd hisp_mobile_tracker

# Install dependencies
flutter pub get

# Run code generation (freezed, json_serializable, injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# Launch the app
flutter run
```

### Configuration

Before running the app, configure your DHIS2 instance base URL and credentials through the application's login screen or via environment configuration.

## Testing

```bash
flutter test
```

## Project Status

This project is under active development by **HISP Ethiopia**. Features and improvements are continuously being added to support DHIS2-based health data collection workflows.

## License

This project is proprietary software of HISP Ethiopia. All rights reserved.

---

*Powered by HISP Ethiopia*
