import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formattedNumber(double num) {
  return NumberFormat.decimalPattern().format(num);
}

void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// Define consistent color variables
const Color primaryColor = Color(0xff4e00e8); // Primary purple color
const Color secondaryColor = Color(0xff25a8d0); // Secondary blue color
const Color buttonTextColor = Colors.white; // Button text color
const Color backgroundColor = Colors.white; // Background color
const Color borderColor = Colors.grey; // Input field borders
const Color disabledButtonColor = Colors.grey; // Disabled button color
const Color hintTextColor = Colors.grey; // Hint text color
// Define consistent color variables
const Color pprimaryColor = Color(0xff4e00e8); // Primary purple color
const Color ssecondaryColor = Color(0xff25a8d0); // Secondary blue color
const Color bbuttonTextColor = Colors.white; // Button text color
Color cardBackgroundColor = const Color(0xff4e00e8).withOpacity(0.2); // Card background color
const Color refundedProductColor = Color(0xff8b00e8); // Dark purple for refunded products
const Color exchangedProductColor = Color.fromARGB(255, 53, 47, 133); // Teal for exchanged products
// Exchanged product color
const Color receiptIconColor = Colors.blue; // Icon color
const Color textColor = Colors.black; // Regular text color
const Color invoiceIdColor = Colors.white; // Invoice ID text color



