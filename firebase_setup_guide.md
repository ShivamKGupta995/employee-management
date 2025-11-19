Here is the complete **Firebase Setup Guide** in Markdown format. You can save this file as **`Firebase_Setup_Guide.md`**.

***

# Firebase Backend Setup Guide
**Project:** Employee Management System
**Tech Stack:** Flutter + Firebase (Firestore, Auth, Storage, Functions)

This guide covers the complete "Start to End" setup required to make the app function, including database structure, security rules, and data backup strategies.

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
3.  Name it: `Employee System` (or similar).
4.  Disable Google Analytics (optional, simplifies setup).
5.  Click **Create Project**.

### 3. Link Flutter App (The Modern Way)
1.  Open your terminal / command prompt.
2.  Log in to Firebase:
    ```bash
    firebase login
    ```
3.  Install the FlutterFire CLI:
    ```bash
    dart pub global activate flutterfire_cli
    ```
4.  Navigate to your Flutter project folder:
    ```bash
    cd path/to/your/flutter_project
    ```
5.  Configure the app:
    ```bash
    flutterfire configure
    ```
    *   Select the project you just created.
    *   Select platforms (Android & iOS).
    *   This will generate `firebase_options.dart` in your `lib/` folder automatically.

---

## Phase 2: Authentication Setup

1.  Go to Firebase Console -> **Build** -> **Authentication**.
2.  Click **Get Started**.
3.  Select **Email/Password** as the Sign-in provider.
4.  Toggle **Enable** and click **Save**.

### **Crucial Step: Create the First Admin**
Since the app logic hides Admin features from normal users, you must create the first Admin manually.

1.  In the **Authentication** tab, click **Add User**.
2.  Email: `admin@company.com`
3.  Password: `password123`
4.  Copy the **User UID** created (e.g., `AbCdEf123456...`). You will need this for Phase 3.

---

## Phase 3: Firestore Database (The Schema)

Go to **Build** -> **Firestore Database** -> **Create Database**.
*   Select a location (e.g., `nam5` or `asia-south1`).
*   Start in **Test Mode** (we will add security rules later).

### Data Structure Reference
You do not need to create these manually; the app creates them. However, this is how the data is organized for your "Backup to Cloud" strategy.

#### 1. `user` Collection (Employee Details)
Stores profile data.
*   **Document ID:** `Auth UID`
*   **Fields:**
    *   `name`: String
    *   `email`: String
    *   `phone`: String
    *   `department`: String
    *   `role`: String (**Important:** Set to `'admin'` for the user created in Phase 2).
    *   `isFrozen`: Boolean (false)
    *   `createdAt`: Timestamp

#### 2. `user/{uid}/synced_contacts` (Sub-Collection)
Stores the backup of employee phone contacts.
*   **Document ID:** Auto-ID
*   **Fields:**
    *   `name`: String
    *   `phone`: String

#### 3. `attendance` Collection
Stores clock-in/out logs.
*   **Document ID:** Auto-ID
*   **Fields:**
    *   `uid`: String
    *   `name`: String
    *   `type`: String ('Clock In' / 'Clock Out')
    *   `timestamp`: Timestamp

#### 4. `monthly_stats` Collection
Stores the Monthly Report Card (Attendance/Late/Absent).
*   **Document ID:** `UID_Month_Year` (e.g., `abc123_November_2025`)
*   **Fields:**
    *   `uid`: String
    *   `month`: String
    *   `year`: String
    *   `present`: Number
    *   `absent`: Number
    *   `late`: Number

#### 5. `salary_slips` Collection
Stores the generated slips viewable by employees.
*   **Document ID:** Auto-ID
*   **Fields:**
    *   `uid`: String
    *   `month`: String
    *   `year`: String
    *   `present`: Number
    *   `absent`: Number
    *   `late`: Number
    *   `timestamp`: Timestamp (Used for sorting "Latest Only")

#### 6. `locations` Collection
Stores live tracking data (Real-time updates).
*   **Document ID:** Auto-ID
*   **Fields:**
    *   `empId`: String
    *   `lat`: Number
    *   `lng`: Number
    *   `timestamp`: Timestamp

#### 7. `announcements` Collection
Stores Admin notices.
*   **Document ID:** Auto-ID
*   **Fields:**
    *   `title`: String
    *   `message`: String
    *   `category`: String ('Urgent', 'Holiday', etc.)
    *   `timestamp`: Timestamp

---

## Phase 4: Storage (Files & Images)

Go to **Build** -> **Storage** -> **Get Started**.
Select **Test Mode**.

This bucket will store:
1.  **Profile Pictures:** `profile_pics/{uid}.jpg`
2.  **Uploaded Documents:** `uploads/{uid}/filename.ext`

---

## Phase 5: Security Rules (Safety)

Go to **Firestore Database** -> **Rules** tab.
Delete existing rules and paste this. This ensures employees cannot see Admin data or other employees' data.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Check if user is Admin
    function isAdmin() {
      return get(/databases/$(database)/documents/user/$(request.auth.uid)).data.role == "admin";
    }

    // 1. USER PROFILES
    // Employees read their own; Admins read all.
    match /user/{userId} {
      allow read, write: if request.auth.uid == userId || isAdmin();
      
      // Contact Backup (Sub-collection)
      match /synced_contacts/{contactId} {
         allow read, write: if request.auth.uid == userId || isAdmin();
      }
    }

    // 2. ATTENDANCE & LOCATIONS
    match /attendance/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if request.auth.uid != null;
    }
    
    match /locations/{docId} {
       allow read: if isAdmin(); // Only Admin tracks location
       allow write: if request.auth.uid != null; // Employees upload location
    }

    // 3. REPORTS (Salary & Stats)
    // Employees read their own; Only Admin writes.
    match /salary_slips/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if isAdmin();
    }
    
    match /monthly_stats/{docId} {
      allow read: if resource.data.uid == request.auth.uid || isAdmin();
      allow write: if isAdmin();
    }

    // 4. ANNOUNCEMENTS
    // Everyone reads; Only Admin writes.
    match /announcements/{docId} {
      allow read: if request.auth.uid != null;
      allow write: if isAdmin();
    }
  }
}
```

---

## Phase 6: Cloud Functions (Notifications)

To enable automated Push Notifications when an Admin posts a notice:

1.  Open terminal in project root.
2.  Run `firebase init functions`.
    *   Select **JavaScript**.
    *   Install dependencies: **Yes**.
3.  Go to `functions/index.js` and paste the code provided in the documentation (Code Snippet 4).
4.  Deploy:
    ```bash
    firebase deploy --only functions
    ```

---

## Phase 7: Data Backup Strategy

The user asked: *"How to backup from employee to cloud?"*

In this architecture, **The Cloud (Firestore) IS the Backup.**
The Flutter app does not store data permanently on the phone.

1.  **Contacts Backup:**
    *   The app reads contacts using `flutter_contacts`.
    *   It loops through them and saves them to `user/{uid}/synced_contacts`.
    *   *Result:* Even if the employee loses their phone, the Admin sees the contacts in Firebase.

2.  **Employee Details:**
    *   When Admin adds an employee, data goes straight to Firestore.
    *   There is no local database (SQLite) to lose.

3.  **Live Location:**
    *   The Background Service pushes coordinates every 15 minutes to Firestore.
    *   History is preserved in the `locations` collection.

---

## Phase 8: Troubleshooting

**Error: "The query requires an index"**
*   If you sort by Date (e.g., Latest Salary Slip), the debug console will show a URL.
*   **Solution:** Click the URL. It opens Firebase Console and builds the index automatically.

**Error: "Permission Denied"**
*   Check if the user has the correct `role` in the `user` collection (`admin` vs `employee`).