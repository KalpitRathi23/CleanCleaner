// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use

import 'package:client_manage/utils/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:client_manage/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? selectedAgent;
  String? selectedRole;
  List<String> agents = [];

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    // _checkLoggedInUser();
  }

  Future<void> _fetchAgents() async {
    try {
      List<String> agentNames = await _firebaseService.fetchAgentNames();
      setState(() {
        agents = agentNames;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching agents: $e')),
      );
    }
  }

  Future<void> _storePreferences(String agentName, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAgent', agentName);
    await prefs.setString('email', email);
  }

  void login() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role.')),
      );
      return;
    }

    if (selectedRole == 'Agent' && selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an agent username.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });

    try {
      String email = emailController.text.trim().toLowerCase();
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(email).get();

      if (userDoc.exists) {
        String firebaseRole = userDoc['role'];
        if (firebaseRole != selectedRole) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'The selected role does not match the registered role for this email.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        if (selectedRole == 'Agent' && userDoc['agentName'] != selectedAgent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Incorrect agent username for the provided email.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: passwordController.text.trim(),
        );

        String? userEmail = userCredential.user?.email;

        await _storePreferences(
            selectedRole == 'Owner' ? 'Owner' : selectedAgent!, userEmail!);

        if (userDoc.exists && userDoc['isVerified'] == true) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
        }
      } else {
        await registerUser();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> registerUser() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
      );
      String? userEmail = userCredential.user?.email;

      await _firestore.collection('users').doc(userEmail).set({
        'uid': userCredential.user!.uid,
        'email': userEmail,
        'isVerified': false,
        'role': selectedRole,
        'agentName': selectedAgent ?? "0",
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created. Waiting for admin approval.')),
      );
      await _storePreferences(
          selectedRole == 'Owner' ? 'Owner' : selectedAgent!, userEmail!);
      Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  // void _checkLoggedInUser() async {
  //   try {
  //     User? currentUser = _auth.currentUser;
  //     if (currentUser != null) {
  //       DocumentSnapshot userDoc =
  //           await _firestore.collection('users').doc(currentUser.email).get();

  //       if (userDoc.exists && userDoc['isVerified'] == true) {
  //         Navigator.pushReplacementNamed(context, AppRoutes.home);
  //       } else {
  //         Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error checking logged-in user: $e')),
  //     );
  //   }
  // }

  Future<void> forgotPassword() async {
    String email = emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your email to reset the password.')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is not registered. Please sign up first.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send reset email.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Role",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            hint: const Text('Select Role'),
                            dropdownColor: Colors.white,
                            elevation: 16,
                            alignment: Alignment.centerLeft,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value;
                                selectedAgent = null;
                              });
                            },
                            items: ['Owner', 'Agent']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              size: 30,
                              color: Colors.black,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a role';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          if (selectedRole == 'Agent') ...[
                            const Text(
                              "Username",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              value: selectedAgent,
                              hint: const Text('Select Username'),
                              dropdownColor: Colors.white,
                              alignment: Alignment.centerLeft,
                              onChanged: (value) {
                                setState(() {
                                  selectedAgent = value;
                                });
                              },
                              items: agents
                                  .map((agent) => DropdownMenuItem(
                                        value: agent,
                                        child: Text(agent),
                                      ))
                                  .toList(),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                size: 30,
                                color: Colors.black,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                          ],
                          const Text(
                            "Email",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: emailController,
                            cursorColor: Colors.black,
                            decoration: const InputDecoration(
                              hintText: 'Enter Email',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "Password",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: passwordController,
                            cursorColor: Colors.black,
                            decoration: const InputDecoration(
                              hintText: 'Enter Password',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: forgotPassword,
                              behavior: HitTestBehavior.translucent,
                              child: const Text(
                                'Forgot Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isLoading ? null : login,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
