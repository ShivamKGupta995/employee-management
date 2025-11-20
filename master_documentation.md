I **cannot directly access your Google Drive** to create or save files for you. As an AI, I do not have permission to log into your personal accounts or modify your cloud storage.

However, **YOU can save everything** to your Google Drive easily.

Here is the best way to back up your work right now:

### **Option A: Save the Code (Best Practice)**
Since you are building an app, **GitHub** is better than Google Drive for code.
1.  Open your terminal in the project folder.
2.  Run these commands (as we discussed):
    ```bash
    git add .
    git commit -m "Final MVP: Admin Dashboard, Employee App, Location, Contacts, and Salary features completed"
    git push origin main
    ```
3.  Now your code is safe in the cloud.

---

### **Option B: Save the Documentation to Google Drive**
If you want to save the **Guides and Manuals** I wrote for you (`Firebase Setup`, `Feature Documentation`, etc.), follow these steps:

1.  **Open Google Drive** (drive.google.com).
2.  Click **+ New** -> **Google Doc**.
3.  Name the document: **"Employee App Master Documentation"**.
4.  **Copy and Paste** the text below into that document.

***

# 📁 MASTER PROJECT DOCUMENTATION
**Project Name:** Employee Management System
**Date:** November 19, 2025

## 1. Project Setup & Dependencies
*   **Flutter:** SDK Installed.
*   **Firebase:** Configured via `flutterfire configure`.
*   **Google Maps:** API Key added to AndroidManifest.
*   **Permissions:** Location, Contacts, Camera, Files, Phone State added to AndroidManifest.

## 2. Key Features Implemented
1.  **Authentication:**
    *   Role-based login (Admin vs Employee).
    *   Account Freezing mechanism (Security).
    *   Single Device Login enforcement (via `uid` tracking).
2.  **Admin Dashboard:**
    *   **Monitor:** Live Map tracking, Contact viewing, Gallery viewing.
    *   **Salary:** Generate Monthly Slips (Single or Bulk Excel Upload).
    *   **Notices:** Post Urgent/Holiday announcements.
    *   **Investigation:** Activate "Theft Protocol" to force-upload data.
3.  **Employee Dashboard:**
    *   **Attendance:** Monthly Report Card (Present/Absent/Late).
    *   **Tracking:** Background Service uploads GPS every 15 mins.
    *   **Uploads:** Send Photos/Documents to Admin.
    *   **Contacts:** Sync Phonebook to Cloud.

## 3. Database Architecture (Firestore)
*   **`user`**: Profiles & Roles.
*   **`attendance`**: Daily Clock In/Out logs.
*   **`monthly_stats`**: Admin-generated monthly reports.
*   **`salary_slips`**: Admin-generated slips (Latest view only).
*   **`locations`**: Live GPS history.
*   **`uploads`**: Evidence photos/files.
*   **`announcements`**: Company news.

## 4. Excel Formats (for Admin)
**Salary/Attendance Bulk Upload:**
| A | B | C | D | E | F |
|---|---|---|---|---|---|
| **Email** | **Month** | **Year** | **Present** | **Absent** | **Late** |
| `john@a.com` | `November` | `2025` | `28` | `1` | `1` |

## 5. Next Steps (Future)
1.  **Payments:** Upgrade Firebase to Blaze Plan.
2.  **Cloud Functions:** Deploy the `index.js` script for Push Notifications.
3.  **Play Store:** Fill out "Location Permission" declaration forms before release.

***

### **Files you should have in your Project Folder:**
*   `lib/main.dart`
*   `lib/screens/login_screen.dart` (The final secure version)
*   `lib/screens/admin/admin_dashboard.dart`
*   `lib/screens/admin/manage_employees.dart`
*   `lib/screens/admin/employee_monitor_dashboard.dart`
*   `lib/screens/admin/generate_salary_screen.dart`
*   `lib/screens/admin/notifications_screen.dart`
*   `lib/screens/employee/employee_dashboard.dart`
*   `lib/screens/employee/salary_screen.dart`
*   `lib/screens/employee/upload_screen.dart`
*   `lib/screens/employee/employee_notifications_screen.dart`
*   `lib/screens/employee/attendance_tab.dart`
*   `lib/services/background_location_service.dart`
*   `lib/services/contact_service.dart`
*   `lib/services/investigation_service.dart`
*   `android/app/src/main/AndroidManifest.xml`
*   `pubspec.yaml`