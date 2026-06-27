# 🏫 SRIWAAP — School Good Deed Monitor

A Flutter desktop application for managing and tracking student good deeds, teacher self-evaluations, and annual school performance records.

## 📱 Features

### 👨‍💼 Admin
- Manage students and teachers (add, edit, delete)
- Auto-generate student IDs and login credentials
- Share login credentials via WhatsApp or email
- Run annual class promotion and reset points

### 👩‍🏫 Teacher
- Set annual goals by category
- Submit monthly self-evaluations
- View progress charts throughout the year
- Access student good deed reporting

### 🎓 Student
- View class leaderboard
- View class summary (top & bottom performers)

## 🏛️ Class Structure

7 classes per year level using gem names:

| Year | Classes |
|------|---------|
| Year 1–6 | Aman, Ruby, Sapphire, Emerald, Topaz, Opal, Pearl |

## 🛠️ Tech Stack

- **Frontend:** Flutter (Windows desktop)
- **Backend:** Firebase (Firestore + Authentication)
- **State Management:** Riverpod
- **Navigation:** GoRouter

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project set up
- Windows development environment

### Installation

1. Clone the repo
```bash
   git clone https://github.com/iqramdollah/school-good-deed-monitor.git
   cd school-good-deed-monitor
```

2. Install dependencies
```bash
   flutter pub get
```

3. Add your Firebase config
   - Place `google-services.json` in `android/app/`
   - Place `firebase_options.dart` in `lib/`

4. Run the app
```bash
   flutter run -d windows
```

### Build for release
```bash
flutter build windows --release
```
Output will be in `build/windows/x64/runner/Release/`

## 🔐 Default Credentials

| Role | Default Password |
|------|-----------------|
| Teacher | Set by admin on creation |
| Student | `123456` |

> ⚠️ Users should change their password after first login.

## 📁 Project Structure
