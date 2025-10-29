# Impostor AR - Application Blueprint

## Overview

"Impostor AR" is a mobile social deduction game that uses augmented reality to blend the classic "impostor" gameplay with the real world. Players complete tasks by scanning real-world objects, while trying to identify the impostor among them. The game is built with Flutter and leverages Firebase for backend services.

## Implemented Features & Design

This section documents the features, design, and architecture implemented in the application.

### V1 - Core Authentication & Navigation (Current)

*   **Architecture**:
    *   **State Management**: `flutter_riverpod` is used for dependency injection and managing application state.
    *   **Navigation**: `go_router` provides a declarative routing solution with authentication-based redirects.
    *   **Structure**: The project follows a feature-first structure (`/lib/`) with a core layer for shared logic (`/lib/core`).

*   **Features**:
    *   **Google Sign-In**: Users can authenticate using their Google account. The flow is handled by `firebase_auth` and `google_sign_in`.
    *   **Automatic Redirects**: The router automatically navigates users to the login screen if they are not authenticated, and to the home screen if they are.
    *   **User Model**: A `UserModel` class defines the data structure for users.
    *   **Authentication Repository**: An `AuthRepository` abstracts the Firebase authentication logic and provides a stream of the current authentication state.

*   **Design & UI**:
    *   **Theme**: A modern, dark theme (`ThemeData`) is implemented for a consistent, game-like feel.
    *   **Screens**:
        *   `LoginScreen`: A simple screen with a "Sign in with Google" button.
        *   `HomeScreen`: A basic home screen displayed after login, with a "Sign Out" button.

## Current Plan

This section outlines the plan for the currently requested change.

*There are no active changes being implemented. The last task was to set up the foundational authentication and navigation flow.*
