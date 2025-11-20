import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planma_app/Providers/activity_log_provider.dart';
import 'package:planma_app/Providers/activity_provider.dart';
import 'package:planma_app/Providers/goal_progress_provider.dart';
import 'package:planma_app/Providers/goal_schedule_provider.dart';
import 'package:planma_app/Providers/sleep_provider.dart';
import 'package:planma_app/Providers/task_log_provider.dart';
import 'package:planma_app/Providers/task_provider.dart';
import 'package:planma_app/models/clock_type.dart';
import 'package:planma_app/timer/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:planma_app/timer/widget/widget.dart';

class TimerWidget extends StatefulWidget {
  final Color themeColor;
  final ClockContext clockContext;
  final dynamic record;

  const TimerWidget({
    super.key,
    required this.themeColor,
    required this.clockContext,
    this.record,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  String? startTime;
  String? endTime;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = context.read<TimerProvider>();
      if (widget.record != null) {
        switch (widget.clockContext.type) {
          case ClockContextType.sleep:
            startTime = widget.record.usualSleepTime;
            endTime = widget.record.usualWakeTime;
            print("Sleep Clock Detected");
            break;
          case ClockContextType.task ||
                ClockContextType.activity ||
                ClockContextType.goal:
            print("Record: ${jsonEncode(widget.record)}");
            startTime = widget.record.scheduledStartTime;
            endTime = widget.record.scheduledEndTime;
            print("Task OR Activity OR Goal Clock Detected");
            break;
        }
        timerProvider.setInitialTimeFromRecord(
          startTime!,
          endTime!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sleepLogProvider = context.read<SleepLogProvider>();
    final taskTimeLogProvider = context.read<TaskTimeLogProvider>();
    final activityTimeLogProvider = context.read<ActivityTimeLogProvider>();
    final goalProgressProvider = context.read<GoalProgressProvider>();

    final taskProvider = context.read<TaskProvider>();
    final activityProvider = context.read<ActivityProvider>();
    final goalScheduleProvider = context.read<GoalScheduleProvider>();

    final timerProvider = context.read<TimerProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 250,
                width: 250,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  value: timerProvider.initialTime > 0
                      ? timerProvider.remainingTime / timerProvider.initialTime
                      : 0,
                  strokeWidth: 8,
                  color: widget.themeColor,
                ),
              ),
              GestureDetector(
                onTap: () => _showTimePicker(context, timerProvider),
                child: Text(
                  _formatTime(timerProvider.remainingTime),
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (timerProvider.isRunning) {
                    timerProvider.stopTimer();
                    _showSaveConfirmationDialog(
                        context,
                        timerProvider,
                        sleepLogProvider,
                        taskTimeLogProvider,
                        activityTimeLogProvider,
                        goalProgressProvider,
                        taskProvider,
                        activityProvider,
                        goalScheduleProvider);
                  } else {
                    timerProvider.startTimer(
                      onFinished: () async {
                        await timerProvider.saveTimeSpent(
                          clockContext: widget.clockContext, 
                          record: widget.record, 
                          sleepLogProvider: sleepLogProvider, 
                          taskTimeLogProvider: taskTimeLogProvider, 
                          activityTimeLogProvider: activityTimeLogProvider, 
                          goalProgressProvider: goalProgressProvider, 
                          taskProvider: taskProvider, 
                          activityProvider: activityProvider, 
                          goalScheduleProvider: goalScheduleProvider
                        );

                        final formattedDuration =
                            _formatTime(timerProvider.timeSpent);
                        safePop(context); // Close Timer screen
                        // safePop(context); // Close Clock screen
                        CustomWidgets.showTimerSavedPopup(context, formattedDuration);
                      },
                    ); // Start the timer
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
                    timerProvider.isRunning ? Icons.stop : Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSaveConfirmationDialog(
      BuildContext context,
      TimerProvider timerProvider,
      SleepLogProvider sleepLogProvider,
      TaskTimeLogProvider taskTimeLogProvider,
      ActivityTimeLogProvider activityTimeLogProvider,
      GoalProgressProvider goalProgressProvider,
      TaskProvider taskProvider,
      ActivityProvider activityProvider,
      GoalScheduleProvider goalScheduleProvider) {
    if (timerProvider.remainingTime > 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
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
                  fontSize: 14,
                  color: Colors.black54,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Are you sure you want to save the time log? The timer stopped at ',
                  ),
                  TextSpan(
                    text: _formatTime(timerProvider.remainingTime!),
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
                  Navigator.of(context).pop();
                  timerProvider.startTimer();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFEF4738),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Future.microtask(() {
                    timerProvider.saveTimeSpent(
                        clockContext: widget.clockContext,
                        record: widget.record,
                        sleepLogProvider: sleepLogProvider,
                        taskTimeLogProvider: taskTimeLogProvider,
                        activityTimeLogProvider: activityTimeLogProvider,
                        goalProgressProvider: goalProgressProvider,
                        taskProvider: taskProvider,
                        activityProvider: activityProvider,
                        goalScheduleProvider: goalScheduleProvider);
                  });

                  final formattedDuration = _formatTime(timerProvider.timeSpent);

                  timerProvider.resetTimer();
                  safePop(context);
                  safePop(context);
                  CustomWidgets.showTimerSavedPopup(context, formattedDuration);
                },
                child: Text(
                  'Save',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF173F70),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showTimePicker(BuildContext context, TimerProvider timerProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          height: 300,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration:
                Duration(seconds: timerProvider.remainingTime),
            onTimerDurationChanged: (Duration newDuration) {
              if (newDuration.inSeconds > 0) {
                timerProvider.setTime(newDuration.inSeconds);
              }
            },
          ),
        );
      },
    );
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

  DateTime _parseTimeString(String time) {
    final now = DateTime.now();
    final parts = time.split(":");
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  String _formatDurationDifference(String startTime) {
    final now = DateTime.now();
    final scheduled = _parseTimeString(startTime);
    final diff = scheduled.difference(now);
    final actualDiff = diff.isNegative ? diff.abs() : Duration.zero;
    return _formatDuration(actualDiff);
  }
}
