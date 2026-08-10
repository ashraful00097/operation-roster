import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/roster_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await RosterService.reloadEmergencyRosters();

  runApp(const OperationRosterApp());
}

class OperationRosterApp extends StatelessWidget {
  const OperationRosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Operation Duty Roster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ===================================================
// AUTH GATE
// ===================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ---------------------------------------------
        // AUTH LOADING
        // ---------------------------------------------

        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;

        // ---------------------------------------------
        // NOT LOGGED IN
        // ---------------------------------------------

        if (user == null) {
          return const LoginScreen();
        }

        // ---------------------------------------------
        // WATCH USER PROFILE
        // ---------------------------------------------

        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            // -----------------------------------------
            // PROFILE LOADING
            // -----------------------------------------

            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // -----------------------------------------
            // PROFILE DOES NOT EXIST
            // -----------------------------------------

            if (!profileSnapshot.hasData ||
                !profileSnapshot.data!.exists) {
              return const ProfileSetupScreen();
            }

            // -----------------------------------------
            // PROFILE EXISTS
            // -----------------------------------------

            return const HomeScreen();
          },
        );
      },
    );
  }
}

// ===================================================
// LOGIN SCREEN
// ===================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLoading = false;

  bool obscurePassword = true;

  bool rememberMe = false;

  static const String savedEmailKey =
      'remembered_email';

  // =================================================
  // LOAD SAVED EMAIL
  // =================================================

  @override
  void initState() {
    super.initState();

    loadSavedEmail();
  }

  Future<void> loadSavedEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedEmail =
        prefs.getString(savedEmailKey);

    if (!mounted) {
      return;
    }

    if (savedEmail != null &&
        savedEmail.isNotEmpty) {
      emailController.text =
          savedEmail;

      setState(() {
        rememberMe = true;
      });
    }
  }

  // =================================================
  // SAVE / CLEAR EMAIL
  // =================================================

  Future<void> saveRememberedEmail(
    String email,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    if (rememberMe &&
        email.isNotEmpty) {
      await prefs.setString(
        savedEmailKey,
        email,
      );
    } else {
      await prefs.remove(
        savedEmailKey,
      );
    }
  }

  // =================================================
  // LOGIN
  // =================================================

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'Email and password দিতে হবে।',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ---------------------------------------------
      // REMEMBER EMAIL
      // ---------------------------------------------

      await saveRememberedEmail(
        email,
      );
    } on FirebaseAuthException catch (error) {
      showMessage(
        getAuthErrorMessage(error),
      );
    } catch (error) {
      showMessage(
        'Login করা যায়নি: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =================================================
  // CREATE ACCOUNT
  // =================================================

  Future<void> createAccount() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'Account তৈরি করতে email এবং password দিতে হবে।',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password কমপক্ষে 6 characters হতে হবে।',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // AuthGate automatically detects
      // the new user and opens ProfileSetupScreen.
    } on FirebaseAuthException catch (error) {
      showMessage(
        getAuthErrorMessage(error),
      );
    } catch (error) {
      showMessage(
        'Account তৈরি করা যায়নি: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =================================================
  // AUTH ERROR
  // =================================================

  String getAuthErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email address ঠিক নেই.';

      case 'user-not-found':
        return 'এই email দিয়ে কোনো account নেই।';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email অথবা password ভুল।';

      case 'email-already-in-use':
        return 'এই email দিয়ে account আগে থেকেই আছে।';

      case 'weak-password':
        return 'Password আরও শক্তিশালী দিন।';

      case 'network-request-failed':
        return 'Internet connection check করুন।';

      default:
        return error.message ??
            'Authentication error হয়েছে।';
    }
  }

  // =================================================
  // MESSAGE
  // =================================================

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =================================================
  // DISPOSE
  // =================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =================================================
  // BUILD
  // =================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F9),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1565C0),

        foregroundColor:
            Colors.white,

        centerTitle: true,

        title: const Text(
          'Operation Duty Roster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 450,
            ),

            child: Card(
              elevation: 3,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    const Icon(
                      Icons.assignment_rounded,
                      size: 64,
                      color:
                          Color(0xFF1565C0),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Welcome',
                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Login to your roster account',
                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // =================================
                    // EMAIL
                    // =================================

                    TextField(
                      controller:
                          emailController,

                      keyboardType:
                          TextInputType.emailAddress,

                      decoration:
                          InputDecoration(
                        labelText: 'Email',

                        prefixIcon:
                            const Icon(
                          Icons.email_outlined,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================
                    // PASSWORD
                    // =================================

                    TextField(
                      controller:
                          passwordController,

                      obscureText:
                          obscurePassword,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Password',

                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                        ),

                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },

                          icon: Icon(
                            obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    // =================================
                    // REMEMBER ME
                    // =================================

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value:
                              rememberMe,

                          activeColor:
                              const Color(
                            0xFF1565C0,
                          ),

                          onChanged:
                              isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        rememberMe =
                                            value ??
                                                false;
                                      });
                                    },
                        ),

                        const Text(
                          'Remember me',

                          style:
                              TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================
                    // LOGIN BUTTON
                    // =================================

                    SizedBox(
                      height: 52,

                      child: FilledButton(
                        onPressed:
                            isLoading
                                ? null
                                : login,

                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF1565C0,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),

                        child:
                            isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',

                                    style:
                                        TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================
                    // CREATE ACCOUNT
                    // =================================

                    OutlinedButton(
                      onPressed:
                          isLoading
                              ? null
                              : createAccount,

                      style:
                          OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(
                          double.infinity,
                          52,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child:
                          const Text(
                        'Create Account',

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}