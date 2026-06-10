# QuickSlot ⚡ Flutter Client

This directory contains the Flutter mobile client for **QuickSlot**, a real-time sports slot booking application.

---

## 📱 App Key Features

*   **Google & Email Authentication**: Auth is managed securely using Supabase Auth.
*   **Real-time Slot Statuses**: Listens to database inserts/deletions on the `bookings` table via Supabase Realtime Channels. When any user books or cancels a slot, the status updates on all other devices immediately.
*   **Time-Aware Slot Filtering**: Today's past slots are hidden dynamically based on the current hour. If the day is past operating hours (after 9:00 PM), the current date is removed from the selection list automatically.
*   **Advanced Bookings Filter**: Dynamic filters on the "My Bookings" screen. You can filter your history by:
    *   **Date**: Using a calendar selector where dates with no bookings are disabled (`selectableDayPredicate`).
    *   **Time**: Custom bottom-sheet with 12-hour slots.
    *   **Sport Type**: Custom selection bottom-sheet (e.g., Badminton, Tennis).
*   **FCM Push & Local Notifications**: Dispatches confirmation alerts when booking is confirmed or cancelled.

---

## 🏗️ Folder Structure

```
app/
├── android/
├── assets/                  # Images and static assets
├── ios/
├── lib/
│   ├── models/              # Data parsing objects
│   │   ├── booking.dart
│   │   ├── slot.dart
│   │   └── venue.dart
│   ├── providers/           # Riverpod state providers & notification config
│   │   ├── api_config.dart  # Development IP configuration
│   │   ├── auth_provider.dart
│   │   ├── booking_provider.dart
│   │   ├── fcm_provider.dart
│   │   └── venue_provider.dart
│   ├── screens/             # UI View screens
│   │   ├── auth_screen.dart          # Sign In / Sign Up UI
│   │   ├── my_bookings_screen.dart   # Interactive booking list & filters
│   │   ├── venue_details_screen.dart # Interactive slots grid & details
│   │   └── venues_list_screen.dart   # Main dashboard
│   └── main.dart            # App entrypoint & theme setup
└── pubspec.yaml             # Dart packages config
```

---

## ⚙️ State Management & Providers

The app relies heavily on **Riverpod** for structured, decoupled state management:

1.  **`authProvider`**: Manages auth lifecycle and state transitions. Exposes `currentUserProvider` and `authSessionTokenProvider`.
2.  **`venueProvider`**: FutureProvider fetching the list of all available venues from `GET /venues`.
3.  **`slotsProvider(SlotArg)`**: Familiy FutureProvider fetching hourly slot availability for a specific venue on a target date. Subscribes to Supabase Postgres replication updates on the `bookings` table filtered by `venue_id`.
4.  **`bookingsFilterProvider`**: NotifierProvider managing the selected filter state (Date, Time, Sport Type) for the bookings screen.
5.  **`userBookingsProvider`**: FutureProvider fetching filtered user bookings from `GET /users/:id/bookings` with query parameters. Automatically subscribes to Supabase Realtime database changes for the active user's bookings.
6.  **`unfilteredUserBookingsProvider`**: Fetches all user bookings to populate the datepicker's enabled dates list.
7.  **`bookingActionsProvider`**: Notifier handling the network requests for `bookSlot` and `cancelBooking`, showing loading spinners and handling `409 Conflict` errors gracefully.

---

## 🛠️ Getting Started & Run Instructions

### 1. Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0.0 or higher recommended)
*   An Android or iOS Emulator, or a connected physical phone.

### 2. Configure Backend Server IP
For physical devices to talk to the local Express backend, they must access the server over Wi-Fi:
1.  Find your local machine's IP address (e.g., `192.168.1.15`).
2.  Open [api_config.dart](file:///Users/admin/Downloads/swades/app/lib/providers/api_config.dart) and modify the `_localHostIp` constant:
    ```dart
    const String _localHostIp = '192.168.1.15';
    ```
3.  Connect both the computer and testing phones to the **exact same Wi-Fi network**.

### 3. Add Dependencies & Run
```bash
flutter pub get
flutter run
```

### 💡 Android Emulator Tip
If testing on the Android Emulator and network requests fail, the emulator might not resolve the local IP address correctly. You can fall back to the Android internal loopback bridge:
*   Open [api_config.dart](file:///Users/admin/Downloads/swades/app/lib/providers/api_config.dart) and change the return statement to return `http://10.0.2.2:3000`.
