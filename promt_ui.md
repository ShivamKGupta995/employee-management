This Markdown file contains the exact "DNA" of your application's design. You can copy and paste the **"Universal Prompt"** section into any AI (AI Studio, Claude, GPT) whenever you need to create a new screen that matches your current theme.

# 🟢 Executive Luxury UI Design Guide

This guide ensures all future screens maintain the **Deep Forest Green & Metallic Gold** brand identity.

---

## 🚀 The Universal Prompt
*Copy and paste the text below to generate new screens.*

> **Prompt:**
> "Generate a Flutter UI for a **[INSERT SCREEN NAME HERE]** using a **High-End Executive Luxury** aesthetic.
>
> **1. Color Palette:**
> - **Background:** Deep Emerald Green (#13211C). Use a `RadialGradient` with a center spotlight effect using an Accent Green (#1D322C).
> - **Accents:** Muted Brass Gold (#C5A367) for borders/icons and Champagne Gold (#F1D18A) for gradients.
> - **Containers:** Use semi-transparent 'Glassmorphism' (Accent Green with 0.2 alpha).
>
> **2. Typography Guidelines:**
> - **Headers/Titles:** Must use a **Serif font** (e.g., Playfair Display or standard 'serif') in semi-bold.
> - **Labels/Tags:** Use clean Sans-Serif with high tracking (`letterSpacing: 2.0` to `4.0`) and uppercase transformation.
> - **Body:** White or Gold with 0.7 alpha transparency.
>
> **3. Visual Elements:**
> - **Borders:** All containers must have thin gold outlines (`width: 1.0`) with `0.2` to `0.4` alpha.
> - **Buttons:** Primary actions must use a **Vertical Linear Gold Gradient** with dark green text (#13211C) and a bold weight.
> - **Shapes:** Use a consistent `BorderRadius` of `15` to `25`.
> - **Icons:** Use outlined icons in Gold.
>
> **4. Implementation Rules:**
> - Use modern Flutter `withValues(alpha: ...)` for transparency.
> - Ensure zero layout overflows by using `FittedBox` or `Flexible` inside buttons and rows.
> - The atmosphere must feel official, secure, and expensive. Avoid bright standard colors (no solid reds/blues); use monochromatic gold shades for status indicators."

---

## 🛠 Technical Reference Sheet
*Use these specific code snippets for consistency.*

### 1. The Core Palette (AppColors)
```dart
static const Color luxDarkGreen = Color(0xFF13211C);
static const Color luxAccentGreen = Color(0xFF1D322C);
static const Color luxGold = Color(0xFFC5A367);
static const Color luxLightGold = Color(0xFFF1D18A);

// The Signature Background
static const RadialGradient luxBgGradient = RadialGradient(
  center: Alignment(0, -0.5),
  radius: 1.2,
  colors: [luxAccentGreen, luxDarkGreen],
);

// The Signature Button
static const LinearGradient luxGoldGradient = LinearGradient(
  colors: [luxLightGold, luxGold],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
```

### 2. Luxury Text Styles
| Element | Font | Weight | Spacing | Color |
| :--- | :--- | :--- | :--- | :--- |
| **Main Title** | Serif | Bold | 2.0 | `luxGold` |
| **Sub-header** | Serif | Medium | 1.0 | `Colors.white` |
| **Small Labels** | Sans-Serif | Bold | 3.5 | `luxGold (0.5 alpha)` |
| **Button Text** | Sans-Serif | Black | 1.5 | `luxDarkGreen` |

### 3. Glassmorphism Container Decoration
```dart
BoxDecoration(
  color: luxAccentGreen.withValues(alpha: 0.2),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: luxGold.withValues(alpha: 0.2), 
    width: 1.0
  ),
)
```

---

## 📝 Usage Example
If you want to create a "Settings" page in the future, your input to the AI would be:

**"Using the [Universal Prompt above], generate a Settings Screen that includes toggles for Notifications, Biometric Login, and a 'Change PIN' button."**