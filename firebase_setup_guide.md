### Part 2: The Updated Firebase Setup Guide (MD File)

Save this as **`Firebase_Setup_Guide.md`**.

***

# Firebase Backend Setup Guide
**Project:** Employee Management System
**Tech Stack:** Flutter + Firebase (Firestore, Auth, Storage, Functions)

This guide covers the complete "Start to End" setup required to make the app function.

---

## Phase 1: Initialization

### 1. Prerequisites
Ensure you have these installed on your computer:
*   **Node.js** (for Firebase tools)
*   **Flutter SDK**
*   **Firebase CLI:** Run `npm install -g firebase-tools` in your terminal.

### 2. Create Project on Console
1.  Go to [console.firebase.google.com](https://console.firebase.google.com/).
2.  Click **Add Project**.
3.  Name it: `Employee System`.
4.  Disable Google Analytics.
5.  Click **Create Project**.

### 3. Link Flutter App
1.  Open terminal in project folder.
2.  Run:
    ```bash
    firebase login
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```

---

## Phase 2: Authentication Setup

1.  Go to **Authentication** -> **Get Started**.
2.  Enable **Email/Password**.
3.  **Crucial:** Create the first Admin manually.
    *   **Add User** -> Email: `admin@company.com`, Password: `password123`.
    *   **Copy the User UID** (You need this for Phase 3).

---

## Phase 3: Firestore Database (The Schema)

Go to **Firestore Database** -> **Create Database**. Select **Test Mode**.

### Data Structure

#### 1. `user` Collection (Main Profile & Location)
*   **Document ID:** `Auth UID`
*   **Fields:**
    *   `name`: String
    *   `email`: String
    *   `role`: String (Set to `'admin'` for the manual user created in Phase 2).
    *   `phone`: String
    *   `department`: String
    *   `isFrozen`: Boolean
    *   **Live Location Fields:**
        *   `current_lat`: Number
        *   `current_lng`: Number
        *   `last_seen`: Timestamp
        *   `speed`: Number

#### 2. `user/{uid}/location_history` (Sub-Collection)
Stores the path history (The "Trail" on the map).
*   **Document ID:** Auto-ID
*   **Fields:** `lat`, `lng`, `timestamp`, `speed`.

#### 3. `user/{uid}/synced_contacts` (Sub-Collection)
Stores the backup of employee phone contacts.
*   **Document ID:** Auto-ID
*   **Fields:** `name`, `phone`

#### 4. `attendance` Collection
*   **Document ID:** Auto-ID
*   **Fields:** `uid`, `name`, `type` ('Clock In' / 'Clock Out'), `timestamp`.

#### 5. `monthly_stats` Collection
*   **Document ID:** `UID_Month_Year`
*   **Fields:** `uid`, `month`, `year`, `present`, `absent`, `late`.

#### 6. `announcements` Collection
*   **Document ID:** Auto-ID
*   **Fields:** `title`, `message`, `category`, `timestamp`.

---

## Phase 4: Storage

Go to **Storage** -> **Get Started** -> **Test Mode**.
*   **Paths:** `profile_pics/{uid}.jpg`, `uploads/{uid}/...`

---

## Phase 5: Security Rules (Updated)

Go to **Firestore Database** -> **Rules**. Paste this to secure the `user` collection.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Check if user is Admin
    // We check the 'user' collection
    function isAdmin() {
      return get(/databases/$(database)/documents/user/$(request.auth.uid)).data.role == "admin";
    }

    // 1. USER COLLECTION (Profile + Live Location)
    match /user/{userId} {
      // Admin: Full Access
      // Employee: Can READ self, Can WRITE self (To update location/profile)
      allow read: if request.auth.uid == userId || isAdmin();
      allow write: if request.auth.uid == userId || isAdmin();
      
      // 1a. Contact Backup (Sub-collection)
      match /synced_contacts/{contactId} {
         allow read, write: if request.auth.uid == userId || isAdmin();
      }

      // 1b. Location History (Sub-collection)
      match /location_history/{historyId} {
         allow read: if request.auth.uid == userId || isAdmin();
         allow write: if request.auth.uid == userId;
      }
    }

    // 2. ATTENDANCE
    match /attendance/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if request.auth.uid != null;
    }

    // 3. REPORTS (Salary & Stats)
    match /salary_slips/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if isAdmin();
    }
    
    match /monthly_stats/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if isAdmin();
    }

    // 4. ANNOUNCEMENTS
    match /announcements/{docId} {
      allow read: if request.auth.uid != null;
      allow write: if isAdmin();
    }
  }
}
```