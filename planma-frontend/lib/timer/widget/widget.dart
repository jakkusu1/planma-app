import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomWidgets {
  static void showTimerSavedPopup(BuildContext context, String duration) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.timer, color: Colors.green),
              SizedBox(width: 5),
              Text(
                "Time Saved Successfully!",
                style: GoogleFonts.openSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173F70)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You've recorded a time of:",
                style: GoogleFonts.openSans(
                    fontSize: 16, color: Color(0xFF173F70)),
              ),
              SizedBox(height: 8),
              Text(
                duration,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Done",
                style: GoogleFonts.openSans(
                    fontSize: 14, color: Color(0xFF173F70)),
              ),
            ),
          ],
        );
      },
    );
  }
}
