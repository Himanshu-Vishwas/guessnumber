# Number Master - Guess The Number

A professional, high-quality "Guess the Number" game built with Flutter. Featuring a modern UI, multiple difficulty levels, haptic feedback, and persistent high scores.

## ✨ Features

- **Responsive Design:** Works flawlessly on phones and tablets.
- **Multiple Difficulties:** 
  - **Easy:** Range 1-20, 6 attempts.
  - **Medium:** Range 1-100, 8 attempts.
  - **Hard:** Range 1-500, 12 attempts.
- **Persistent High Scores:** Saves your best performance for each level using `shared_preferences`.
- **Haptic Feedback:** Physical response for every guess (vibration).
- **Narrowing Range:** Dynamically tracks the possible range based on your previous guesses.
- **Guess History:** Keep track of your path to victory.
- **Victory Effects:** Celebratory confetti when you win!
- **Modern UI:** Built with Google Fonts (Lexend), Animate_do, and a sleek dark-theme aesthetic.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / VS Code

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Run the app using `flutter run`.

## 📦 Publishing Checklist

This project is configured for publishing. To finalize:

1. **Icons:** Replace `assets/icon/icon.png` with your own app icon.
2. **Splash Screen:** Run the splash screen generator:
   ```bash
   dart run flutter_native_splash:create
   ```
3. **App Icons:** Run the icon generator:
   ```bash
   dart run flutter_launcher_icons:main
   ```
4. **Build:**
   - **Android:** `flutter build apk --split-per-abi` or `flutter build appbundle`.
   - **iOS:** `flutter build ios`.

## 🧩 Open Source / Publish Notes

- This repository is intended to be open source.
- Do not commit secrets or local signing files to the repository.
- Keep `android/key.properties` and `kotlin/new.properties` local and private.
- Do not publish any keystore passwords, API keys, or private configuration files.
- If you need an explicit open-source license, add a `LICENSE` file (for example MIT or Apache 2.0).

## 🛠 Tech Stack
- **Framework:** Flutter
- **State Management:** StatefulWidget
- **Persistence:** shared_preferences
- **Animations:** animate_do, confetti
- **Typography:** google_fonts
- **Feedback:** vibration
