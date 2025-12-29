import 'package:employee_system/config/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your dashboards
import 'package:employee_system/screens/admin/admin_dashboard.dart';
import 'package:employee_system/screens/employee/employee_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('user').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'not-found', message: 'User profile not found in database.');
      }

      final data = userDoc.data();
      final role = data?['role'] ?? 'unknown';
      final name = data?['name'] ?? 'User';
      final isFrozen = data?['isFrozen'] ?? false;

      if (isFrozen == true) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'frozen', message: 'Your account has been suspended. Contact Admin.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);
      await prefs.setString('role', role);
      await prefs.setString('username', name);

      if (_rememberMe) {
        await prefs.setString('email', _emailController.text.trim());
      } else {
        await prefs.remove('email');
      }
      
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboard()), (route) => false);
      } else if (role == 'employee') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const EmployeeDashboard()), (route) => false);
      } else {
        await _auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Role not assigned. Contact Admin.')));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') message = 'No user found for that email.';
      if (e.code == 'wrong-password') message = 'Wrong password provided.';
      if (e.code == 'frozen') message = e.message!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 1. App Logo/Brand
                        SizedBox(
                          height: 100,
                          child: Image.asset('assets/images/osc-light.png', color: AppColors.luxGold),
                        ),
                        const SizedBox(height: 20),

                        // // 2. Welcome Texts (Restored to match image)
                        // const Text(
                        //   "Welcome Back", 
                        //   style: TextStyle(fontSize: 32, color: AppColors.luxGold, fontFamily: 'serif', fontWeight: FontWeight.w400)
                        // ),
                        // const SizedBox(height: 8),
                        // Text(
                        //   "Sign in to continue", 
                        //   style: TextStyle(color: AppColors.withValues(AppColors.luxGold, 0.7), fontSize: 16)
                        // ),
                        // const SizedBox(height: 50),

                        // 3. Email Field
                        TextFormField(
                          controller: _emailController,
                          // Explicitly set text style to ensure visibility
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          cursorColor: AppColors.luxGold,
                          decoration: _inputDecoration("Email", Icons.email_outlined),
                          validator: (val) => (val == null || !val.contains('@')) ? 'Invalid Email' : null,
                        ),
                        const SizedBox(height: 25),

                        // 4. Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          cursorColor: AppColors.luxGold,
                          decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                                color: AppColors.withValues(AppColors.luxGold, 0.7), 
                                size: 22
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (val) => (val == null || val.length < 6) ? 'Min 6 chars required' : null,
                        ),
                        
                        const SizedBox(height: 15),

                        // 5. Remember Me
                        Row(
                          children: [
                            SizedBox(
                              height: 24, width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.luxGold,
                                checkColor: AppColors.luxDarkGreen,
                                side: const BorderSide(color: AppColors.luxGold),
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Remember Email', style: TextStyle(color: AppColors.luxGold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 45),

                        // 6. Login Button
                        InkWell(
                          onTap: _loading ? null : _login,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity, height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: AppColors.luxGoldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4), 
                                  blurRadius: 8, 
                                  offset: const Offset(0, 4)
                                )
                              ],
                            ),
                            child: Center(
                              child: _loading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.luxDarkGreen))
                                  : const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.black87)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.luxGold, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.withValues(AppColors.luxGold, 0.8), size: 22),
      
      // ✅ ADDED THIS: Background fill makes typing text clearly visible
      filled: true,
      fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.3),
      
      floatingLabelBehavior: FloatingLabelBehavior.always, 
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.withValues(AppColors.luxGold, 0.6), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.luxGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    );
  }
}