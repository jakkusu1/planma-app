import 'package:flutter/cupertino.dart';
import 'package:planma_app/Providers/activity_log_provider.dart';
import 'package:planma_app/Providers/activity_provider.dart';
import 'package:planma_app/Providers/goal_progress_provider.dart';
import 'package:planma_app/Providers/sleep_provider.dart';
import 'package:planma_app/Providers/task_log_provider.dart';
import 'package:planma_app/Providers/task_provider.dart';
import 'package:planma_app/models/clock_type.dart';
import 'package:planma_app/timer/stopwatch_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planma_app/timer/widget/widget.dart';

class StopwatchWidget extends StatefulWidget {
  final Color themeColor;
  final ClockContext clockContext;
  final dynamic record;
  const StopwatchWidget(
      {super.key,
      required this.themeColor,
      required this.clockContext,
      this.record});

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  @override
  Widget build(BuildContext context) {
    final sleepLogProvider = context.read<SleepLogProvider>();
    final taskTimeLogProvider = context.read<TaskTimeLogProvider>();
    final activityTimeLogProvider = context.read<ActivityTimeLogProvider>();
    final goalProgressProvider = context.read<GoalProgressProvider>();

    final taskProvider = context.read<TaskProvider>();
    final activityProvider = context.read<ActivityProvider>();

    final stopwatchProvider = Provider.of<StopwatchProvider>(context);

    return Center(
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        Text(
          _formatTime(stopwatchProvider.elapsedTime),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 45,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (stopwatchProvider.isRunning) {
                  stopwatchProvider.stopStopwatch();
                  // Show Save Confirmation Dialog after stopping the stopwatch
                  _showSaveConfirmationDialog(
                      context,
                      stopwatchProvider,
                      sleepLogProvider,
                      taskTimeLogProvider,
                      activityTimeLogProvider,
                      goalProgressProvider,
                      taskProvider,
                      activityProvider);
                } else {
                  stopwatchProvider.startStopwatch();
                }
              },
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.themeColor,
                ),
                child: Icon(
                  stopwatchProvider.isRunning ? Icons.stop : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  // Helper Methods
  void _showSaveConfirmationDialog(
      BuildContext context,
      StopwatchProvider stopwatchProvider,
      SleepLogProvider sleepLogProvider,
      TaskTimeLogProvider taskTimeLogProvider,
      ActivityTimeLogProvider activityTimeLogProvider,
      GoalProgressProvider goalProgressProvider,
      TaskProvider taskProvider,
      ActivityProvider activityProvider) {
    if (stopwatchProvider.elapsedTime > 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Confirm Save',
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF173F70),
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                children: [
                  const TextSpan(
                      text:
                          'Are you sure you want to save the time log? The stopwatch stopped at '),
                  TextSpan(
                    text: _formatTime(stopwatchProvider.elapsedTime),
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Close the dialog without saving
                  stopwatchProvider.startStopwatch(); // Resume the stopwatch
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFFEF4738),
                  textStyle: GoogleFonts.openSans(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await Future.microtask(() {
                    stopwatchProvider.saveTimeLog(
                        clockContext: widget.clockContext,
                        record: widget.record,
                        sleepLogProvider: sleepLogProvider,
                        taskTimeLogProvider: taskTimeLogProvider,
                        activityTimeLogProvider: activityTimeLogProvider,
                        goalProgressProvider: goalProgressProvider,
                        taskProvider: taskProvider,
                        activityProvider: activityProvider); // Save time spent
                  });

                  final String formattedDuration =_formatTime(stopwatchProvider.elapsedTime);

                  stopwatchProvider.resetStopwatch(); // Reset the stopwatch
                  safePop(context); // Close dialog after saving
                  safePop(context); // Close Clock Screen after saving
                  CustomWidgets.showTimerSavedPopup(context, formattedDuration);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF173F70),
                  textStyle: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  }

  void safePop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }
}
