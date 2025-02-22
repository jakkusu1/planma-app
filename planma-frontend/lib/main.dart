import 'package:flutter/material.dart';
import 'package:planma_app/Providers/activity_log_provider.dart';
import 'package:planma_app/Providers/activity_provider.dart';
import 'package:planma_app/Providers/attended_events_provider.dart';
import 'package:planma_app/Providers/class_schedule_provider.dart';
import 'package:planma_app/Providers/goal_progress_provider.dart';
import 'package:planma_app/Providers/goal_provider.dart';
import 'package:planma_app/Providers/goal_schedule_provider.dart';
import 'package:planma_app/Providers/schedule_entry_provider.dart';
import 'package:planma_app/Providers/semester_provider.dart';
import 'package:planma_app/Providers/sleep_provider.dart';
import 'package:planma_app/Providers/task_log_provider.dart';
import 'package:planma_app/Providers/task_provider.dart';
import 'package:planma_app/Providers/user_preferences_provider.dart';
import 'package:planma_app/Providers/userprof_provider.dart';
import 'package:planma_app/authentication/splash_screen.dart';
import 'package:planma_app/core/dashboard.dart';
import 'package:planma_app/timer/stopwatch_provider.dart';
import 'package:planma_app/timer/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:planma_app/authentication/log_in.dart';
import 'package:planma_app/Providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planma_app/Providers/events_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => ActivityProvider()),
        ChangeNotifierProvider(create: (context) => GoalProvider()),
        ChangeNotifierProvider(create: (context) => SemesterProvider()),
        ChangeNotifierProvider(create: (context) => ClassScheduleProvider()),
        ChangeNotifierProvider(create: (context) => EventsProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => GoalScheduleProvider()),
        ChangeNotifierProvider(create: (context) => AttendedEventsProvider()),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (context) => TimerProvider()),
        ChangeNotifierProvider(create: (context) => StopwatchProvider()),
        ChangeNotifierProvider(create: (context) => SleepLogProvider()),
        ChangeNotifierProvider(create: (context) => TaskTimeLogProvider()),
        ChangeNotifierProvider(create: (context) => ActivityTimeLogProvider()),
        ChangeNotifierProvider(create: (context) => GoalProgressProvider()),
        ChangeNotifierProvider(create: (context) => ScheduleEntryProvider())
      ],
      child: MaterialApp(
          // home: SleepWakeSetupScreen(),
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
          // home: Dashboard(),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
          )),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void> _loadProviders(
      {required BuildContext context,
      required List<Function> initFunctions}) async {
    for (Function func in initFunctions) {
      if (func is Future<dynamic> Function()) {
        print(func.toString());
        await func();
      } else if (func is Future<dynamic> Function(BuildContext)) {
        if (context.mounted) {
          await func(context);
        }
      } else {
        func();
      }
    }
    return;
  }

  Future<bool> _authCheck() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? accessToken = sharedPreferences.getString("access");
    String? refreshToken = sharedPreferences.getString("refresh");

    if (accessToken == null && refreshToken == null) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _authCheck(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            if (snapshot.data!) {
              return FutureBuilder(
                  future: _loadProviders(context: context, initFunctions: [
                    context.read<UserProfileProvider>().init,
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Dashboard();
                  });
            } else {
              return LogIn();
            }
          }
          return const Center(
            child: Text('AuthorPage._authCheck has returned null value.'),
          );
        });
  }
}
