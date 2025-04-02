# SplitWise - Smart Expense Sharing App

[![Flutter](https://img.shields.io/badge/Flutter-3.6.2-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0.0-blue.svg)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-green.svg)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<div align="center">
  <h3>Split expenses effortlessly with friends and groups</h3>
</div>

## 📱 Overview

SplitWise is a modern, feature-rich Flutter application designed to revolutionize how people manage shared expenses. Built with cutting-edge technologies and a focus on user experience, it provides a seamless platform for tracking, splitting, and settling expenses among friends, family, and groups.

### 🌟 Key Highlights

- **Intelligent Expense Management**: Smart algorithms for fair expense distribution
- **Real-time Synchronization**: Instant updates across all devices
- **Secure Authentication**: Enterprise-grade security with Firebase
- **Beautiful UI/UX**: Modern neumorphic design with smooth animations
- **Cross-platform Support**: Works seamlessly on iOS, Android, and macOS

## ✨ Features

### 🔐 Authentication & Security
- **Multi-factor Authentication**
  - Firebase Authentication integration
  - Google Sign-in support
  - Secure user authentication flow
  - Biometric authentication support
  - Session management

### 💰 Expense Management
- **Smart Group Management**
  - Create and manage expense groups
  - Add individual and group expenses
  - Split expenses equally or custom amounts
  - Track balances between users
  - Export expense reports
  - Receipt scanning and storage

### 🎨 User Interface
- **Modern Design Elements**
  - Neumorphic design system
  - Smooth animations and transitions
  - Responsive layout
  - Dark/Light theme support
  - Custom widgets and components
  - Accessibility features

### 🔄 Real-time Features
- **Live Updates**
  - Firebase Cloud Firestore integration
  - Real-time expense tracking
  - Instant notifications
  - Live balance updates
  - Offline support with sync
  - Multi-device synchronization

### 📱 Additional Features
- **Advanced Capabilities**
  - PDF generation for expense reports
  - Image upload for expense receipts
  - Push notifications
  - Offline support
  - Multi-platform support
  - Expense analytics and insights
  - Currency conversion
  - Budget tracking

## 🛠 Technical Stack

### Core Technologies
- **Framework**: Flutter (SDK ^3.6.2)
- **Language**: Dart
- **State Management**: Flutter Riverpod
- **Architecture**: Clean Architecture with MVVM pattern

### Backend Services
- **Firebase**
  - Authentication
  - Cloud Firestore
  - Cloud Messaging
  - Cloud Storage
  - Analytics
- **Supabase**
  - Real-time Database
  - Authentication
  - Storage
  - Edge Functions

### UI/UX Components
- Material Design
- Neumorphic Design
- Custom animations
- Charts and graphs
- Responsive layouts
- Custom widgets

## 📁 Project Structure

```
lib/
├── Home screen/         # Main app screens and features
├── Profile/            # User profile management
├── login signup/       # Authentication screens
├── split/             # Expense splitting logic
├── Search/            # Search functionality
├── Helper/            # Utility functions and helpers
├── main.dart          # App entry point
└── bottom_bar.dart    # Bottom navigation bar
```

## 📦 Dependencies

### Core Dependencies
- `firebase_core`: Firebase core functionality
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database services
- `flutter_riverpod`: State management
- `google_sign_in`: Google authentication

### UI Dependencies
- `flutter_neumorphic`: Neumorphic design elements
- `fl_chart`: Data visualization
- `animate_do`: Animation effects
- `flutter_animate`: Advanced animations
- `shimmer`: Loading effects

### Utility Dependencies
- `image_picker`: Image selection
- `pdf`: PDF generation
- `flutter_local_notifications`: Local notifications
- `supabase_flutter`: Supabase integration
- `shared_preferences`: Local storage
- `intl`: Internationalization

## 🚀 Getting Started

### Prerequisites
- Flutter SDK: ^3.6.2
- Dart SDK: Compatible with Flutter SDK
- Android Studio / VS Code
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/split_wise.git
   cd split_wise
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android and iOS apps
   - Download and add configuration files
   - Enable required services

4. **Supabase Setup**
   - Create a Supabase project
   - Add credentials to environment variables
   - Configure database schema

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Environment Setup

### Required Tools
- Flutter SDK: ^3.6.2
- Dart SDK: Compatible with Flutter SDK
- Android Studio / VS Code
- Git

### Configuration Files
- `google-services.json` for Android
- `GoogleService-Info.plist` for iOS
- `.env` for environment variables
- `firebase_options.dart` for Firebase configuration

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Supabase for additional backend features
- All contributors and maintainers
- Open source community

## 📞 Support

For support, email support@splitwise.com or join our Slack channel.

---

<div align="center">
  Made with ❤️ by the SplitWise Team
</div>