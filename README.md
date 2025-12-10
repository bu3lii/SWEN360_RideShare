# RideShare


## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Required Tools](#required-tools)
- [Installation & Setup](#installation--setup)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Environment Variables](#environment-variables)
- [Running the Application](#running-the-application)
- [Android Development Setup](#android-development-setup)
- [Troubleshooting](#troubleshooting)

##  Overview

RideShare is a full-stack carpooling application that enables university students to:
- **Share rides** as drivers or passengers
- **Find rides** based on location, time, and preferences
- **Manage bookings** with real-time updates
- **Rate and review** other users
- **Communicate** through in-app messaging
- **Navigate** using integrated maps and routing

##  Features

### Core Features
- **User Authentication**: Secure registration with email verification, JWT tokens, and optional 2FA
- **Ride Management**: Create, search, book, and manage rides with smart matching
- **Real-time Updates**: Socket.IO for live notifications and messaging
- **Smart Routing**: OpenStreetMap (OSRM) integration for route calculation
- **Content Moderation**: AI-powered toxicity detection using Google Perspective API
- **Rating System**: Two-way reviews for drivers and riders
- **In-App Messaging**: Real-time chat between users
- **Location Services**: Geocoding, reverse geocoding, and route optimization
- **Safe Ride Codes**: QR code-based verification for passenger pickup
- **Payment Tracking**: Mark payments and track earnings

### User Roles
- **Passengers**: Search and book rides, manage bookings, rate drivers
- **Drivers**: Create rides, manage passengers, track earnings, navigate routes

##  Project Structure

```
full/
├── backend/          # Node.js/Express API
│   ├── src/
│   │   ├── app.js            # Application entry point
│   │   ├── config/           # Configuration files
│   │   ├── controllers/      # Request handlers
│   │   ├── middleware/       # Express middleware
│   │   ├── models/           # Mongoose schemas
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic services
│   │   └── utils/            # Utility functions
│   ├── package.json
│   └── .env                  # Environment variables (create this)
│
└── frontend/         # Flutter mobile app
    ├── lib/
    │   ├── config/           # API configuration
    │   ├── models/           # Data models
    │   ├── screens/          # UI screens
    │   ├── services/         # API services
    │   ├── widgets/          # Reusable widgets
    │   └── main.dart         # App entry point
    ├── pubspec.yaml
    └── .env                  # Environment variables (if needed)
```

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** ([Download](https://nodejs.org/))
- **MongoDB**  ([Download](https://www.mongodb.com/try/download/community))
- **Flutter**  ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Git** ([Download](https://git-scm.com/downloads))
- **Android Studio** ([Download](https://developer.android.com/studio))

## Required Tools

### Backend Tools
- **Node.js** & **npm**: JavaScript runtime and package manager
- **MongoDB**: NoSQL database
- **MongoDB Compass** (optional): GUI for MongoDB

### Frontend Tools
- **Flutter SDK**: Cross-platform mobile framework
- **Dart**: Programming language for Flutter
- **Android Studio**: IDE for Android development
- **Android SDK**: Required for building Android apps
- **Android Virtual Device (AVD)**: Android emulator for testing

### Development Tools
- **VS Code** or **Android Studio**: Code editors
- **Postman** or **Insomnia** (optional): API testing tools

## Installation & Setup

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```
   This will install all required Node.js packages listed in `package.json`.

3. **Create environment file**
   ```bash
   # Create .env file in backend directory
   touch .env
   ```

4. **Configure environment variables** (see [Environment Variables](#environment-variables) section below)

5. **Start MongoDB**
   ```bash
   # On macOS/Linux
   mongod

   # On Windows
   # MongoDB usually runs as a service, or start it manually
   ```

6. **Seed database (optional)**
   ```bash
   npm run seed
   ```
   This creates test users and sample rides for development.

7. **Start the backend server**
   ```bash
   # Development mode (with auto-reload)
   npm run dev

   # Production mode
   npm start
   ```

   The backend API will be available at `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```
   This will install all required Flutter packages listed in `pubspec.yaml`.

3. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```
   This will check your Flutter setup and display any issues that need to be resolved.

4. **Update API configuration** (if needed)
   - Open `lib/config/api_config.dart`
   - Update the `baseUrl` if your backend is running on a different address
   - For Android emulator, use `http://10.0.2.2:3000`
   - For physical device, use your computer's IP address

5. **Run the Flutter app**
   ```bash
   # List available devices
   flutter devices

   # Run on Android emulator or connected device
   flutter run
   ```

##  Environment Variables

### Backend (.env file)

Create a `.env` file in the `backend` directory with the following variables:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database (Required)
MONGODB_URI=mongodb://localhost:27017/uniride
MONGODB_URI_TEST=mongodb://localhost:27017/uniride_test

# JWT Authentication (Required - Change in production!)
JWT_SECRET=your_super_secret_key_change_this_in_production
JWT_EXPIRES_IN=7d
JWT_COOKIE_EXPIRES_IN=7

# Email Configuration (Optional but recommended)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
EMAIL_FROM=UniRide <noreply@uniride.com>

# University Email Domain
UNIVERSITY_EMAIL_DOMAIN=aubh.edu.bh

# Google Perspective API (Optional - for content moderation)
PERSPECTIVE_API_KEY=your_google_perspective_api_key

# Two-Factor Authentication
TWO_FA_APP_NAME=UniRide

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# OpenStreetMap / OSRM (Optional - uses public servers by default)
OSRM_SERVER_URL=https://router.project-osrm.org
NOMINATIM_URL=https://nominatim.openstreetmap.org

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:5173
SOCKET_CORS_ORIGIN=http://localhost:5173
```

**Important Notes:**
- **MONGODB_URI**: Required. Make sure MongoDB is running.
- **JWT_SECRET**: Required. Use a strong, random secret in production.
- **EMAIL_***: Optional but recommended for email verification and notifications.
- **PERSPECTIVE_API_KEY**: Optional. Only needed if you want content moderation features.

### Frontend Configuration

The frontend API configuration is in `frontend/lib/config/api_config.dart`. Update the `baseUrl` based on your setup:

- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Physical Device**: `http://<your-computer-ip>:3000` (e.g., `http://192.168.1.100:3000`)

## Running the Application

### Step 1: Start MongoDB

Make sure MongoDB is running on your system:

```bash
# Check if MongoDB is running
# On macOS/Linux
mongod

# On Windows, MongoDB usually runs as a service
# Or start it from Services
```

### Step 2: Start the Backend

```bash
cd backend
npm install          # If not already done
npm run dev          # Development mode with auto-reload
```

The backend should now be running at `http://localhost:3000`

### Step 3: Start the Frontend

1. **Open Android Studio** and ensure you have:
   - Android SDK installed
   - An Android Virtual Device (AVD) created
   - Flutter plugin installed

2. **Start an Android Emulator** or connect a physical device

3. **Run the Flutter app**:
   ```bash
   cd frontend
   flutter pub get    # If not already done
   flutter run
   ```

##  Android Development Setup

### Installing Android Studio

1. **Download Android Studio**
   - Visit [https://developer.android.com/studio](https://developer.android.com/studio)
   - Download and install Android Studio

2. **Install Android SDK**
   - Open Android Studio
   - Go to **Tools then SDK Manager**
   - Install the latest Android SDK (API 33 or higher recommended)
   - Install Android SDK Platform-Tools and Build-Tools


### Creating an Android Virtual Device (AVD)

1. **Open AVD Manager**
   - In Android Studio, go to **Tools then Device Manager**
   - Or click the device manager icon in the toolbar

2. **Create Virtual Device**
   - Click **Create Device**
   - Select a device
   - Click **Next**

3. **Select System Image**
   - Choose a system image
   - Click **Download** if the image is not installed
   - Click **Next**

4. **Configure AVD**
   - Review settings and click **Finish**

5. **Start the Emulator**
   - Click the play button next to your AVD
   - Wait for the emulator to boot up

### Verifying Setup

Run Flutter doctor to verify everything is set up correctly:

```bash
flutter doctor
```

You should see checkmarks (✓) for:
- Flutter
- Android toolchain
- Android Studio
- Connected device (when emulator is running)

## Troubleshooting

### Backend Issues

**MongoDB Connection Error**
- Ensure MongoDB is running: `mongod` or check Windows Services
- Verify `MONGODB_URI` in `.env` is correct
- Check MongoDB logs for errors

**Port Already in Use**
- Change `PORT` in `.env` to a different port (e.g., 3001)
- Or stop the process using port 3000

**Module Not Found Errors**
- Run `npm install` again in `backend` directory
- Delete `node_modules` and `package-lock.json`, then run `npm install`

### Frontend Issues

**Flutter Doctor Shows Issues**
- Follow the suggestions from `flutter doctor`

**Build Errors**
- Run `flutter clean` then `flutter pub get`
- Ensure Android SDK is properly installed


**App Can't Connect to Backend**
- Verify backend is running on the correct port
- Check `api_config.dart` has the correct `baseUrl`
- For Android emulator, use `http://10.0.2.2:3000`
- For physical device, use your computer's local IP address

**Android Emulator Not Starting**
- Check that virtualization is enabled in BIOS

-----

*Made with Love by AUBH Students*
