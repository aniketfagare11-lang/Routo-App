import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg0        = Color(0xFF0F172A);
  static const bg1        = Color(0xFF020617);
  static const glass      = Color(0x14FFFFFF);
  static const glassBorder= Color(0x20FFFFFF);
  static const surfaceEl  = Color(0xFF131F38);

  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);
  static const green   = Color(0xFF10B981);
  static const amber   = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);
  static const textSec = Color(0xFF64748B);

  static Color blueGlow(double a)   => accentA.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERSONAL DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen>
    with TickerProviderStateMixin {

  // Controllers initialised with blank values — populated in initState
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;

  User? _currentUser;
  bool _isUploadingImage = false;

  // KYC status: 0 = Not Verified, 1 = Pending, 2 = Verified
  int _kycStatus = 0;

  late AnimationController _fadeCtrl;
  late AnimationController _bgCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _bgAnim;

  @override
  void initState() {
    super.initState();
    // Init controllers with empty values first (avoids LateInit error)
    _nameController  = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _bgAnim   = CurvedAnimation(parent: _bgCtrl,   curve: Curves.linear);

    _loadUserData();
    _fadeCtrl.forward();
  }

  void _loadUserData() {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text  = user?.displayName ?? 'User';
          _emailController.text = user?.email       ?? 'No email';
          _mobileController.text = user?.phoneNumber ?? '';
        });
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    if (_currentUser == null) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final storageRef = FirebaseStorage.instance.ref().child('profiles/${_currentUser!.uid}.jpg');
      
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await storageRef.putFile(File(pickedFile.path), SettableMetadata(contentType: 'image/jpeg'));
      }

      final downloadUrl = await storageRef.getDownloadURL();
      await _currentUser!.updatePhotoURL(downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated.'),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose(); _mobileController.dispose();
    _fadeCtrl.dispose(); _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(children: [
        _buildBackground(),
        FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                const SizedBox(height: 20),
                _buildAvatarSection(context),
                const SizedBox(height: 28),
                _buildInputSection(),
                const SizedBox(height: 20),
                _buildKycSection(context),
                const SizedBox(height: 32),
                _buildSaveButton(context),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: _appBarAction(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
    title: const Text('Personal Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      _appBarAction(icon: Icons.home_rounded, onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
      const SizedBox(width: 10),
    ],
  );

  Widget _appBarAction({required IconData icon, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );

  // ── Avatar Section ─────────────────────────────────────────────────────────
  Widget _buildAvatarSection(BuildContext context) {
    return Center(
      child: Stack(alignment: Alignment.bottomRight, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.accentA.withValues(alpha: 0.3), width: 3),
            gradient: LinearGradient(colors: [_C.blueGlow(0.2), Colors.transparent]),
          ),
          padding: const EdgeInsets.all(6),
          child: _currentUser?.photoURL != null
              ? CircleAvatar(
                  backgroundColor: _C.surfaceEl,
                  backgroundImage: NetworkImage(_currentUser!.photoURL!),
                )
              : const CircleAvatar(
                  backgroundColor: _C.surfaceEl,
                  child: Icon(Icons.person_rounded, size: 60, color: _C.textSec),
                ),
        ),
        GestureDetector(
          onTap: _isUploadingImage ? null : _pickAndUploadImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
              shape: BoxShape.circle,
              border: Border.all(color: _C.bg0, width: 2.5),
              boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: _isUploadingImage 
               ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
               : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }

  // ── Input Section ──────────────────────────────────────────────────────────
  Widget _buildInputSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            color: _C.glass,
          ),
          child: Column(children: [
            _buildInput(_nameController,  'Full Name',     Icons.person_outline_rounded,   _C.accentA, TextInputType.name),
            const SizedBox(height: 20),
            _buildInput(_emailController, 'Email Address', Icons.alternate_email_rounded,  _C.accentC, TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildInput(_mobileController, 'Phone Number',  Icons.phone_android_rounded,    _C.accentB, TextInputType.phone),
          ]),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, Color color, TextInputType kt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: const TextStyle(color: _C.textSec, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _C.surfaceEl,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.glassBorder),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: kt,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]);
  }

  // ── KYC Section ───────────────────────────────────────────────────────────
  Widget _buildKycSection(BuildContext context) {
    final statusLabels = ['Not Verified', 'Pending', 'Verified'];
    final statusColors = [_C.red, _C.amber, _C.green];
    final statusIcons  = [Icons.cancel_outlined, Icons.hourglass_top_rounded, Icons.verified_rounded];
    final color        = statusColors[_kycStatus];
    final icon         = statusIcons[_kycStatus];
    final label        = statusLabels[_kycStatus];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.08), Colors.transparent],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Text('KYC Verification', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, color: color, size: 12),
                    const SizedBox(width: 5),
                    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
            ]),
            const SizedBox(height: 16),
            // Aadhaar row
            _buildDocRow(context, 'Aadhaar Card', Icons.credit_card_rounded, _C.accentA),
            const SizedBox(height: 12),
            // PAN row
            _buildDocRow(context, 'PAN Card', Icons.assignment_ind_rounded, _C.accentC),
            if (_kycStatus == 0) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() => _kycStatus = 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Documents submitted! Verification pending.'),
                      backgroundColor: _C.amber,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
                  ),
                  child: const Center(child: Text('Submit for Verification', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildDocRow(BuildContext context, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDocDialog(context, label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surfaceEl,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.glassBorder),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.upload_rounded, color: color, size: 14),
              const SizedBox(width: 5),
              Text('Upload', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showDocDialog(BuildContext context, String docName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.glassBorder)),
        title: Text('Upload $docName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Document upload will be available in the next update.', style: TextStyle(color: _C.textSec, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _C.accentA, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_currentUser == null) return;
        HapticFeedback.mediumImpact();
        
        setState(() => _isUploadingImage = true); // use the loading state
        try {
          // 1. Update Display Name
          await _currentUser!.updateDisplayName(_nameController.text.trim());
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully!'),
                backgroundColor: _C.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Update failed: $e'),
                backgroundColor: _C.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      },
      child: Container(
        width: double.infinity, height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
          boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isUploadingImage 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground() => AnimatedBuilder(
    animation: _bgAnim,
    builder: (_, __) {
      final t = _bgAnim.value * 2 * math.pi;
      return Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
        _orb(0.12 + 0.05 * math.cos(t),       0.15 + 0.08 * math.sin(t),       260, _C.blueGlow(0.08)),
        _orb(0.85 + 0.04 * math.cos(t + 2.1), 0.40 + 0.10 * math.sin(t + 2.1), 200, _C.orangeGlow(0.07)),
        _orb(0.45 + 0.06 * math.cos(t + 4.2), 0.75 + 0.05 * math.sin(t + 4.2), 180, _C.purpleGlow(0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent]))),
    ),
  );
}
