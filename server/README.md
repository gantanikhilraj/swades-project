# QuickSlot ⚡ Express REST API Server

This directory contains the Node.js Express server backend for the **QuickSlot** sports slot booking application. The server manages business logic, enforces past-booking prevention, handles database transactions via Supabase, and dispatches FCM notifications.

---

## 🛠️ Tech Stack & Dependencies

*   **Node.js & Express**: Core REST web application framework.
*   **Supabase JS SDK**: Data interface mapping.
*   **Firebase Admin SDK**: Accessing Google Cloud messaging services to trigger user push notifications.
*   **Cors & Dotenv**: Cross-Origin resource sharing and environment management.

---

## ⚙️ Environment Configuration

Create a `.env` file in the root of the `server/` directory:

```env
PORT=3000
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-anon-key
```

### 🔔 FCM Notifications Configuration
For live Push Notification support, download your Firebase project's service account private key JSON file, rename it to `firebase-service-account.json`, and place it in the `server/` directory.
*   If this file is missing, the server will fallback to logging push notifications to the stdout console rather than failing.

---

## 🗄️ Database Tables Schema

QuickSlot relies on PostgreSQL tables initialized in Supabase. The database layout is defined in [schema.sql](file:///Users/admin/Downloads/swades/server/schema.sql):

### 1. `venues`
Stores the list of booking locations.
*   `id` (UUID, Primary Key)
*   `name` (TEXT)
*   `sport_type` (TEXT)
*   `location` (TEXT)
*   `image_url` (TEXT)
*   `created_at` (TIMESTAMP)

### 2. `bookings`
Handles slot reservations.
*   `id` (UUID, Primary Key)
*   `user_id` (TEXT) - Maps to Supabase auth user UID.
*   `venue_id` (UUID, References `venues.id`)
*   `booking_date` (DATE)
*   `start_time` (TIME)
*   `created_at` (TIMESTAMP)
*   **`unique_venue_slot`** Constraint: `UNIQUE(venue_id, booking_date, start_time)`

### 3. `user_fcm_tokens`
Stores device tokens for FCM push alerts.
*   `user_id` (TEXT, Primary Key)
*   `fcm_token` (TEXT)
*   `updated_at` (TIMESTAMP)

> [!IMPORTANT]
> To support real-time cancellation syncing, PostgreSQL replication needs to publish all columns when a row is deleted. Make sure to run this SQL in your Supabase console:
> ```sql
> ALTER TABLE bookings REPLICA IDENTITY FULL;
> ```

---

## 📡 API Endpoints Reference

All endpoints requiring auth must supply the Bearer JWT token in the request header:
`Authorization: Bearer <supabase_jwt_token>`

### 1. `GET /venues`
*   **Description**: Fetch all available venues ordered alphabetically by name.
*   **Auth Required**: No.
*   **Response**: `200 OK`
    ```json
    [
      {
        "id": "7ca642c8-8dfa-45c1-8408-efef2db26a7f",
        "name": "Greenfield Badminton Club",
        "sport_type": "Badminton",
        "location": "Sector 62, Noida",
        "image_url": "https://...",
        "created_at": "2026-06-10T12:00:00Z"
      }
    ]
    ```

---

### 2. `GET /venues/:id/slots?date=YYYY-MM-DD`
*   **Description**: Get 16 hourly slots (from 06:00 to 21:00) with their current reservation status.
*   **Query Parameters**:
    *   `date`: Target date to check.
*   **Validation Rules**:
    *   If query date is **today**, the server dynamically filters out and hides all slots whose start time is in the past relative to the local server hour.
*   **Response**: `200 OK`
    ```json
    [
      {
        "start_time": "06:00",
        "status": "booked",
        "booking_id": "713ba6a3-...",
        "user_id": "890fa3b1-..."
      },
      {
        "start_time": "07:00",
        "status": "available",
        "booking_id": null,
        "user_id": null
      }
    ]
    ```

---

### 3. `POST /bookings`
*   **Description**: Create a booking for the authenticated user.
*   **Auth Required**: Yes.
*   **Payload**:
    ```json
    {
      "venue_id": "7ca642c8-8dfa-45c1-8408-efef2db26a7f",
      "date": "2026-06-12",
      "start_time": "08:00"
    }
    ```
*   **Validation Rules**:
    *   `date` must not be in the past.
    *   `start_time` must be a valid hourly slot (06:00 to 21:00).
    *   If booking for **today**, the slot hour must be strictly greater than the current local hour.
*   **Responses**:
    *   `201 Created`: Booking successful.
    *   `400 Bad Request`: Validation failure (past date/slot).
    *   `409 Conflict`: Slot has already been booked (unique violation caught via PostgreSQL error code `23505`).

---

### 4. `GET /users/:id/bookings`
*   **Description**: List bookings for a specific user, sorted by date and start time.
*   **Auth Required**: Yes (users can only query their own ID).
*   **Query Parameters (Optional Filters)**:
    *   `date` (e.g. `2026-06-12`): Show bookings on a specific date.
    *   `start_time` (e.g. `10:00` or `10:00:00`): Show bookings starting at a specific hour.
    *   `sport_type` (e.g. `Badminton`): Filter by venue sport type.
*   **Response**: `200 OK`
    ```json
    [
      {
        "id": "713ba6a3-...",
        "user_id": "890fa3b1-...",
        "booking_date": "2026-06-12",
        "start_time": "08:00:00",
        "venues": {
          "id": "7ca642c8-8dfa-45c1-8408-efef2db26a7f",
          "name": "Greenfield Badminton Club",
          "sport_type": "Badminton",
          "location": "Sector 62, Noida",
          "image_url": "https://..."
        }
      }
    ]
    ```

---

### 5. `DELETE /bookings/:id`
*   **Description**: Cancel an existing booking.
*   **Auth Required**: Yes (users can only delete their own bookings).
*   **Response**: `200 OK`
    ```json
    { "message": "Booking cancelled successfully" }
    ```

---

### 6. `POST /users/fcm-token`
*   **Description**: Register or update the user's FCM push token.
*   **Auth Required**: Yes.
*   **Payload**:
    ```json
    { "token": "your-fcm-device-token" }
    ```
*   **Response**: `200 OK`

---

### 7. `DELETE /users/fcm-token`
*   **Description**: Delete the user's FCM registration record on logout.
*   **Auth Required**: Yes.
*   **Response**: `200 OK`
