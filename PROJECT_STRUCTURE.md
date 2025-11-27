# Employee System - Project Structure Guide

## 📁 New Folder Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
│
├── config/                            # ⭐ NEW: App configuration
│   ├── app_theme.dart                 # Centralized theme
│   ├── routes.dart                    # Named routes
│   └── constants/
│       ├── constants.dart             # Export all constants
│       ├── app_colors.dart            # Color palette
│       ├── app_strings.dart           # Static strings
│       ├── app_dimensions.dart        # Spacing, sizes
│       └── firebase_collections.dart  # Firestore collection names
│
├── models/                            # ⭐ NEW: Data models
│   ├── models.dart                    # Export all models
│   ├── user_model.dart
│   ├── attendance_model.dart
│   ├── announcement_model.dart
│   └── location_model.dart
│
├── services/                          # Business logic
│   ├── background_location_service.dart
│   ├── contact_service.dart
│   └── notification_service.dart
│
├── screens/                           # UI screens
│   ├── login_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── manage_employees.dart
│   │   └── ...
│   └── employee/
│       ├── employee_dashboard.dart
│       └── ...
│
├── widgets/                           # ⭐ NEW: Reusable widgets
│   ├── common/
│   │   ├── common_widgets.dart        # Export all widgets
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_card.dart
│   │   ├── loading_indicator.dart
│   │   └── empty_state.dart
│   └── custom_drawer.dart
│
└── utils/                             # ⭐ NEW: Utility helpers
    ├── utils.dart                     # Export all utils
    ├── date_formatter.dart
    ├── validators.dart
    ├── snackbar_helper.dart
    ├── dialog_helper.dart
    └── battery_optimization_helper.dart
```

## 🎨 Using Colors

```dart
// Before (hardcoded):
color: Colors.blue.shade800

// After (centralized):
import 'package:employee_system/config/constants/app_colors.dart';
color: AppColors.primary
color: AppColors.success
color: AppColors.getCategoryColor('Urgent')
```

## 📐 Using Dimensions

```dart
// Before:
padding: EdgeInsets.all(16)
borderRadius: BorderRadius.circular(12)

// After:
import 'package:employee_system/config/constants/app_dimensions.dart';
padding: AppDimensions.paddingAll
borderRadius: AppDimensions.borderRadiusMD
```

## 📝 Using Strings

```dart
// Before:
Text("Welcome Back")

// After:
import 'package:employee_system/config/constants/app_strings.dart';
Text(AppStrings.welcomeBack)
```

## 🔥 Using Firebase Collections

```dart
// Before:
FirebaseFirestore.instance.collection('user')

// After:
import 'package:employee_system/config/constants/firebase_collections.dart';
FirebaseFirestore.instance.collection(FirebaseCollections.users)
```

## 🧩 Using Widgets

```dart
import 'package:employee_system/widgets/common/common_widgets.dart';

// Buttons
AppButton.primary(text: 'Login', onPressed: () {})
AppButton.success(text: 'Save', isLoading: true)
AppButton.danger(text: 'Delete')
AppButton.outlined(text: 'Cancel')

// Text Fields
AppTextField.email(controller: _emailController)
AppTextField.password(controller: _passwordController)
AppTextField.phone(controller: _phoneController)
AppTextField.multiline(label: 'Message', maxLines: 4)

// Cards
AppCard.elevated(child: Text('Content'))
StatCard(title: 'Total', value: '25', icon: Icons.people, color: Colors.blue)
ActionCard(title: 'Upload', icon: Icons.upload, color: Colors.orange, onTap: () {})

// Loading
LoadingIndicator()
LoadingIndicator.large()
LoadingPage(message: 'Loading...')

// Empty State
EmptyState.noData()
EmptyState.notifications()
EmptyState.error(onRetry: () {})
```

## 🛠 Using Utilities

```dart
import 'package:employee_system/utils/utils.dart';

// Date Formatting
DateFormatter.formatFull(DateTime.now())      // "Wednesday, 26 November 2025"
DateFormatter.formatDateTime(date)             // "Nov 26, 3:45 PM"
DateFormatter.getRelativeTime(date)            // "2h ago"

// Validation
Validators.email(value)
Validators.password(value)
Validators.required(value, 'Name')

// Snackbars
SnackbarHelper.showSuccess(context, 'Saved!')
SnackbarHelper.showError(context, 'Failed!')
SnackbarHelper.showWarning(context, 'Warning!')

// Dialogs
await DialogHelper.showConfirmation(context, title: 'Delete?', message: 'Sure?')
await DialogHelper.showDeleteConfirmation(context, itemName: 'John')
DialogHelper.showLoading(context)
```

## 📦 Using Models

```dart
import 'package:employee_system/models/models.dart';

// Create from Firestore
UserModel user = UserModel.fromFirestore(doc);
print(user.name);
print(user.isOnline);
print(user.initials);

// Convert to Map for saving
Map<String, dynamic> data = user.toMap();
```

## ✅ Benefits of This Structure

1. **No More Hardcoded Values** - All colors, strings, dimensions in one place
2. **Easy to Change** - Update once, applies everywhere
3. **Consistent UI** - Same styling across all screens
4. **Reusable Components** - Less code duplication
5. **Type Safety** - Models with proper typing
6. **Easy Localization** - Strings ready for i18n
7. **Better Maintenance** - Clear organization
8. **Faster Development** - Pre-built widgets

## 🚀 Next Steps

1. Run `flutter pub get`
2. Test the app to ensure everything works
3. Gradually refactor existing screens to use new widgets/constants
4. Remove any duplicate code
