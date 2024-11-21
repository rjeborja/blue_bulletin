import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:blue_bulletin/main.dart';
import 'package:blue_bulletin/profile.dart';
import 'package:blue_bulletin/login.dart';
import 'package:blue_bulletin/navbar.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});
  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final session = supabase.auth.currentSession;

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const Navbar(),
          ),
        );
      });
    }

    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // User just signed in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const Navbar(),
          ),
        );
      }
    });
  }

  Future<AuthResponse> _googleSignIn() async {
    const webClientId =
        '889641398241-4f5fsvh2q2jdjek2r9tljhgae6mkr10k.apps.googleusercontent.com';
    const iosClientId =
        '889641398241-ll6t5lhvclaef75v8qa5186u9gt2lgql.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> guestLogin() async {
    try {
      final response = await supabase.auth.signInAnonymously();
      if (response.user != null) {}
    } catch (error) {
      print('Guest login failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x99636fb5),
                Color(0x992E3192),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/logo.png',
                  width: 150,
                  height: 150,
                ),
                const Text(
                  'BLUE BULLETIN',
                  style: TextStyle(
                    fontFamily: 'Standup',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200.0,
                  child: ElevatedButton(
                    onPressed: _googleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.google,
                          color: Color(0xFF2E3192),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Google login',
                          style: TextStyle(
                            color: Color(0xFF2E3192),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 200.0,
                  child: ElevatedButton(
                    onPressed: guestLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.user,
                          color: Color(0xFF2E3192),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Guest login',
                          style: TextStyle(
                            color: Color(0xFF2E3192),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
