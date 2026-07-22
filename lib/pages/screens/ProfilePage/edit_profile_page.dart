import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      if (user != null) {
        final userData =
            await FirestoreService(uid: user!.uid, auth: FirebaseAuth.instance)
                .getUserProfile();
        if (userData != null) {
          firstNameController.text = userData['firstName'] ?? '';
          lastNameController.text = userData['lastName'] ?? '';
          userNameController.text = userData['username'] ?? '';
          emailController.text =
              user?.email ?? userData['email'] ?? '';
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (user == null) return;

    setState(() => isSaving = true);

    try {
      await FirestoreService(uid: user!.uid, auth: FirebaseAuth.instance)
          .updateUserProfile({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'username': userNameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Iconsax.tick_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile updated successfully',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 73, 121, 251),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: Theme.of(context).colorScheme.inversePrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 73, 121, 251),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Main content - scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile header
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 73, 121, 251)
                                          .withValues(alpha: 0.7),
                                      Color.fromARGB(255, 73, 121, 251),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.user,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(height: 30),

                            // Form fields group - compact layout
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                            SizedBox(height: 30),

                            // First Name and Last Name in a row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: firstNameController,
                                    labelText: 'First Name',
                                    hintText: 'First name',
                                    prefixIcon: Iconsax.personalcard,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    controller: lastNameController,
                                    labelText: 'Last Name',
                                    hintText: 'Last name',
                                    prefixIcon: Iconsax.personalcard,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),

                            // Username
                            _buildTextField(
                              controller: userNameController,
                              labelText: 'Username',
                              hintText: 'Enter your username',
                              prefixIcon: Iconsax.user,
                            ),
                            SizedBox(height: 30),

                            // Email (login identity — read-only)
                            _buildTextField(
                              controller: emailController,
                              labelText: 'Email',
                              hintText: 'Login email',
                              prefixIcon: Iconsax.direct_right,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              helperText:
                                  'Your login email can’t be changed here.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Save button - fixed at bottom
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 73, 121, 251),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isSaving
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        enableInteractiveSelection: !readOnly,
        style: TextStyle(
          fontSize: 16,
          color: readOnly
              ? Theme.of(context).colorScheme.secondary
              : null,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 16,
          ),
          helperText: helperText,
          helperStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.secondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}
