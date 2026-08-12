import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: unnecessary_import
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
//import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SIGNUP SCREEN  ·  Web + Android compatible
//
//  Platform strategy:
//   Android  → Full OTP flow via verifyPhoneNumber (no reCAPTCHA needed)
//   Web      → RecaptchaVerifier (invisible) + signInWithPhoneNumber
//              OTP field shown after "Send OTP" completes.
//              If phone auth is skipped, email-only signup still works.
// ─────────────────────────────────────────────────────────────────────────────

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  // ── Form controllers ──────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;

  /// Android: verificationId from verifyPhoneNumber()
  String? _verificationId;

  /// Web: ConfirmationResult returned by signInWithPhoneNumber()
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _verifier;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _logoSlide;
  late Animation<Offset> _cardSlide;
  late Animation<double> _taglineScale;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _taglineScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      try {
        _verifier?.clear();
      } catch (_) {}
    }
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── SnackBars ────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ]),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Input helpers ─────────────────────────────────────────────────────────

  /// Normalise phone number — prepend +91 if no country code given.
  String _normalizePhone(String phone) {
    phone = phone.trim();
    if (!phone.startsWith('+')) phone = '+91$phone';
    return phone;
  }

  /// Validate inputs before sending OTP.
  bool _validateForOtp() {
    if (_mobileController.text.trim().isEmpty) {
      _showError('Please enter a mobile number first.');
      return false;
    }
    return true;
  }

  /// Validate all inputs before final signup.
  bool _validateForSignup() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in Name, Email, and Password.');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return false;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return false;
    }
    // If OTP was sent but not entered, block signup.
    if (_otpSent && _otpController.text.trim().isEmpty) {
      _showError('Please enter the OTP sent to your mobile.');
      return false;
    }
    return true;
  }

  // ── Send OTP ─────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_validateForOtp()) return;
    final phone = _normalizePhone(_mobileController.text);

    setState(() => _isSendingOtp = true);
    try {
      if (kIsWeb) {
        await _sendOtpWeb(phone);
      } else {
        await _sendOtpAndroid(phone);
      }
    } catch (e) {
      _showError('Failed to send OTP. Check the number and try again.');
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  /// Web OTP — uses invisible RecaptchaVerifier.
  Future<void> _sendOtpWeb(String phone) async {
    // RecaptchaVerifier anchors to 'recaptcha-container' div in index.html.
    if (_verifier == null) {
      _verifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance,
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
        onSuccess: () => debugPrint('reCAPTCHA solved'),
        onError: (FirebaseAuthException e) =>
            _showError('reCAPTCHA failed: ${e.message}'),
        onExpired: () => _showError('reCAPTCHA expired. Try again.'),
      );
      
      await _verifier!.render().timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('reCAPTCHA loading timeout. Check config/internet.');
      });
    }

    _webConfirmationResult = await FirebaseAuth.instance
        .signInWithPhoneNumber(phone, _verifier)
        .timeout(const Duration(seconds: 60), onTimeout: () {
      throw Exception('OTP request timeout.');
    });

    if (mounted) {
      setState(() => _otpSent = true);
      _showSuccess('OTP sent to $phone');
    }
  }

  /// Android OTP — uses verifyPhoneNumber.
  Future<void> _sendOtpAndroid(String phone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-retrieval: fill OTP field silently.
        if (mounted && credential.smsCode != null) {
          setState(() {
            _otpController.text = credential.smsCode!;
            _otpSent = true;
          });
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _showError(e.message ?? 'Phone verification failed.');
        if (mounted) setState(() => _isSendingOtp = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
          _showSuccess('OTP sent to $phone');
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // ── Main signup ──────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    if (!_validateForSignup()) return;

    setState(() => _isLoading = true);
    try {
      // Step 1 — Create email/password account.
      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCred.user;
      if (user == null) throw Exception('User creation returned null.');

      // Step 2 — Store display name.
      await user.updateDisplayName(_nameController.text.trim());

      // Step 3 — Link phone credential if OTP was completed.
      final otpVal = _otpController.text.trim();
      if ((_verificationId != null || _webConfirmationResult != null) &&
          otpVal.isNotEmpty) {
        await _linkPhoneCredential(user, otpVal);
      }

      // Step 4 — Pop back to root so AuthWrapper can navigate to Home.
      _showSuccess('Welcome to Routo!');
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e.code, e.message));
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Link phone credential to the freshly created email account.
  Future<void> _linkPhoneCredential(User user, String otp) async {
    try {
      if (kIsWeb && _webConfirmationResult != null) {
        // Web: call confirm() on the ConfirmationResult object directly.
        await _webConfirmationResult!.confirm(otp);
        // confirm() signs in as phone user — we must sign in the email user back.
        // Re-sign-in with email so the email account is the primary user.
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else if (!kIsWeb && _verificationId != null) {
        // Android: use PhoneAuthCredential and link it.
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        await user.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // Phone linking failed — account is still created, just log the issue.
      debugPrint('Phone link failed (non-fatal): ${e.code} – ${e.message}');
      if (e.code == 'invalid-verification-code') {
        _showError(
            'Invalid OTP — your account was created but phone was not linked.');
      }
      // Don't rethrow; email account creation succeeded.
    }
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _authErrorMessage(String code, String? rawMessage) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Please sign in.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled. Contact support.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return rawMessage ?? 'Sign-up failed. Please try again.';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      GoogleSignIn googleSignIn;
      if (kIsWeb) {
        googleSignIn = GoogleSignIn(
          clientId: '547297166217-92vllrd37bhq9pa6v8oo7njell3p4lgc.apps.googleusercontent.com',
        );
      } else {
        googleSignIn = GoogleSignIn();
      }
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return; // user canceled
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showError('Google Sign-In failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF1976D2),
                Color(0xFFE65100),
                Color(0xFFFF6F00),
              ],
              stops: [0.0, 0.25, 0.45, 0.78, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -60,
                  child: _decoCircle(200, Colors.white.withValues(alpha: 0.04)),
                ),
                Positioned(
                  top: 80,
                  left: -80,
                  child: _decoCircle(160, Colors.white.withValues(alpha: 0.03)),
                ),
                Positioned(
                  bottom: 100,
                  right: -40,
                  child: _decoCircle(120, Colors.white.withValues(alpha: 0.04)),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: SignupRouteDotsPainter()),
                ),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          SlideTransition(
                              position: _logoSlide, child: _buildLogoSection()),
                          const SizedBox(height: 12),
                          ScaleTransition(
                              scale: _taglineScale, child: _buildTagline()),
                          const SizedBox(height: 44),
                          SlideTransition(
                              position: _cardSlide, child: _buildSignupCard()),
                          const SizedBox(height: 24),
                          FadeTransition(
                              opacity: _fadeAnim, child: _buildFooter()),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Decorative helpers ───────────────────────────────────────────────────

  Widget _decoCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _buildLogoSection() {
    return Column(children: [
      AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pulseAnim.value, child: child),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 4),
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child:
                Image.asset('assets/images/routo_logo.png', fit: BoxFit.cover),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'ROUTO',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
          shadows: [
            Shadow(
                color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
      ),
    ]);
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.white.withValues(alpha: 0.12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rocket_launch_rounded, color: Color(0xFFFFCC80), size: 16),
          SizedBox(width: 6),
          Text(
            'Join the Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B2A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign up to get started with Routo',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A97A6),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),

            // Name
            _buildTextField(
              controller: _nameController,
              hint: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            // Email
            _buildTextField(
              controller: _emailController,
              hint: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Mobile + Send OTP button
            _buildTextField(
              controller: _mobileController,
              hint: 'Mobile Number (with country code)',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              suffix: _isSendingOtp
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: _sendOtp,
                      child: Text(
                        _otpSent ? 'Resend' : 'Send OTP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // OTP field — shown prominently once OTP is sent
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(children: [
                _buildTextField(
                  controller: _otpController,
                  hint: 'Enter OTP',
                  icon: Icons.message_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
              ]),
              crossFadeState: _otpSent
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // Password
            _buildTextField(
              controller: _passwordController,
              hint: 'Password (min 6 characters)',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 28),

            // Sign Up button
            _buildSignupButton(),
            const SizedBox(height: 20),

            // Divider
            Row(children: [
              Expanded(
                  child:
                      Container(height: 0.8, color: const Color(0xFFE8ECF0))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: TextStyle(color: Color(0xFFB0BAC5), fontSize: 12.5)),
              ),
              Expanded(
                  child:
                      Container(height: 0.8, color: const Color(0xFFE8ECF0))),
            ]),
            const SizedBox(height: 16),

            // Google button (UI only — wire up when needed)
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF0D1B2A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFB0BAC5),
            fontWeight: FontWeight.w400,
            fontSize: 14.5,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: const Color(0xFF8A97A6), size: 20),
          ),
          suffixIcon: suffix ??
              (isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF8A97A6),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignup,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isLoading
                ? [const Color(0xFF9E9E9E), const Color(0xFF757575)]
                : [const Color(0xFF1565C0), const Color(0xFFE65100)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isLoading ? null : _handleGoogleSignIn,
        splashColor: const Color(0xFFE8F0FE),
        highlightColor: const Color(0xFFF0F4FF),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E4EA), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2), shape: BoxShape.circle),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/google.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('G',
                      style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Continue with Google',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTE DOTS BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class SignupRouteDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dotRadius = 3.0;
    final points = [
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.75, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.28),
      Offset(size.width * 0.70, size.height * 0.35),
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.22, size.height * 0.82),
      Offset(size.width * 0.08, size.height * 0.90),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      const dashLength = 6.0;
      const gapLength = 5.0;
      final dx = points[i + 1].dx - points[i].dx;
      final dy = points[i + 1].dy - points[i].dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final nx = dx / dist;
      final ny = dy / dist;
      double traveled = 0;
      bool drawing = true;
      while (traveled < dist) {
        final segEnd =
            math.min(traveled + (drawing ? dashLength : gapLength), dist);
        if (drawing) {
          canvas.drawLine(
            Offset(points[i].dx + nx * traveled, points[i].dy + ny * traveled),
            Offset(points[i].dx + nx * segEnd, points[i].dy + ny * segEnd),
            linePaint,
          );
        }
        traveled = segEnd;
        drawing = !drawing;
      }
    }

    for (final point in points) {
      canvas.drawCircle(point, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
