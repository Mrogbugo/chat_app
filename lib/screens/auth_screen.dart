import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/auth/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var _isLoading = false;

  void _submitAuthForm(
      String email,
      String password,
      String username,
      File? image,
      bool isLogin,
      BuildContext ctx,
      ) async {
    UserCredential authResult;

    try {
      setState(() {
        _isLoading = true;
      });

      if (isLogin) {
        // Existing user login
        authResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // New user registration
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userId = authResult.user!.uid;
        String? imageUrl;

        if (image != null) {
          // Upload image to Firebase Storage
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('$userId.jpg');

          await ref.putFile(image);
          imageUrl = await ref.getDownloadURL();

          // Update photoURL in Firebase Auth
          await authResult.user?.updatePhotoURL(imageUrl);
        }

        // Update display name in Firebase Auth
        await authResult.user?.updateDisplayName(username);

        // Save user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'username': username,
          'email': email,
          'image_url': imageUrl,
        });
      }

      print('✅ Authenticated: ${authResult.user?.uid}');
    } on FirebaseAuthException catch (err) {
      print('❌ FirebaseAuthException: ${err.message}');
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(err.message ?? 'Authentication error')),
      );
      setState(() {
        _isLoading = false;
      });
    } on PlatformException catch (err) {
      final message = err.message ?? 'An error occurred, please check your credentials!';
      print('❌ PlatformException: $message');
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (err) {
      print('❌ Error: $err');
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: AuthForm(
        submitAuthForm: _submitAuthForm,
        isLoading: _isLoading,
      ),
    );
  }
}
