# Mc20 Music Player

**Mc20 Music Player** is a lightweight yet powerful music application developed to demonstrate proficiency in **Java (backend)** and **Flutter/Dart (frontend)**.

The system is built to manage and play music both **locally** and through a **server connection**, while allowing users to organize and categorize tracks into playlists with ease.

The main focus of Mc20 is to deliver a **modern, responsive mobile UI** built with Flutter, combined with a robust Java backend, showcasing how two different technologies can integrate seamlessly into a full-stack project.

---

## Features & Screenshots

### Welcome & Login / Signup Pages

![Welcome Page](assets/screenshots/WelcomePage.jpg)

![Login Page](assets/screenshots/Login.jpg)  ![Login Page](assets/screenshots/Login1.jpg)

![Signup Page](assets/screenshots/Signup.jpg)  ![Signup Page](assets/screenshots/Signup1.jpg)

### Home Page

![Home Page](assets/screenshots/HomePage.jpg)

### 📚 Music Library & Sorting

In this section, all available or user-added tracks are displayed. Using the **Sort by** option, tracks can be sorted by most popular, newest, or different categories (local / server). Additionally, a desired track can be found using the **Search** feature.

![Sort Options](assets/screenshots/Sort.jpg)  ![Add Music Options](assets/screenshots/AploadAptions.jpg)

Users can download songs from the server or from local files and add them to the app.

### Menu & Account Pages

![Menu Page](assets/screenshots/Menu.jpg)  ![Account Page](assets/screenshots/UserAccount.jpg)

Users can view and edit account information. Songs can also be shared or liked with friends.

### Playlist Page

![Playlist Page](assets/screenshots/Playlists.jpg)

Users can create playlists, add songs, share them with friends, and delete them if desired.

---

## Admin Panel

The manager can perform the following actions:
1. Show all users
2. Search user by name
3. Show all playlists
4. Show all tracks
5. Show most popular tracks

---

## Server Example

```java
public void start() {
    try (ServerSocket serverSocket = new ServerSocket(PORT)) {
        System.out.println("🚀 Server started on port " + PORT);
        while (true) {
            Socket socket = serverSocket.accept();
            System.out.println("📡 Client connected: " + socket.getInetAddress());
            new ClientHandler(socket).start();
        }
    } catch (IOException e) {
        System.err.println("❌ Server error: " + e.getMessage());
        e.printStackTrace();
    }
}
```

---

## 🛠️ Key Skills & Technologies

This project demonstrates proficiency in the following areas:

**Framework:** Flutter (Frontend), Java (Backend)

**Languages:** Dart (Frontend), Java (Backend)

**State Management & Architecture:**
- Using Provider (or other state management solutions) for reactive UI updates in Flutter.
- Structuring the backend with a clean, scalable, and maintainable folder structure.
- Implementing role-based logic to serve different functionalities and views to different users (e.g., regular user vs. admin).

**UI Design & Implementation:**
- Building complex, custom user interfaces from scratch.
- Implementing a fully responsive layout.
- Creating user-friendly pages: Welcome, Login/Signup, Home, Menu, Playlist, and Player screens.

**Backend & API:**
- Designing RESTful APIs for music management (play, add, sort, search).
- Handling local and server-based music sources.
- Managing playlists, favorites, and recently played tracks.

---

## 🚀 Getting Started

To run this project locally, follow these steps:

1. Clone the repository:
```bash
git clone https://github.com/fati2025s/musicplayer.git
```
2. Run the server:
```bash
# run main class in Java backend
```
3. Install Flutter dependencies:
```bash
flutter pub get
```
4. Run the app:
```bash
flutter run
```

---

