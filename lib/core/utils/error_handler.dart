import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Maps Firebase / common errors to user-friendly snackbars.
class ErrorHandler {
  ErrorHandler._();

  static String message(Object e) {
    if (e is FirebaseAuthException) {
      return e.message ?? e.code;
    }
    return e.toString();
  }

  static void showSnack(BuildContext context, Object e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message(e)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
