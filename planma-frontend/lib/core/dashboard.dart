import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planma_app/Notifications/local_notification_service.dart';
import 'package:planma_app/Providers/activity_provider.dart';
import 'package:planma_app/Providers/class_schedule_provider.dart';
import 'package:planma_app/Providers/dashboard_provider.dart';
import 'package:planma_app/Providers/events_provider.dart';
import 'package:planma_app/Providers/goal_provider.dart';
import 'package:planma_app/Providers/semester_provider.dart';
import 'package:planma_app/Providers/task_provider.dart';
import 'package:planma_app/Providers/user_preferences_provider.dart';
import 'package:planma_app/Providers/userprof_provider.dart';
import 'package:planma_app/Providers/web_socket_provider.dart';
import 'package:planma_app/activities/activity_page.dart';
import 'package:planma_app/core/widget/button_sheet.dart';
import 'package:planma_app/core/widget/menu_button.dart';
import 'package:planma_app/event/event_page.dart';
import 'package:planma_app/features/authentication/presentation/providers/user_provider.dart';
import 'package:planma_app/goals/goal_page.dart';
import 'package:planma_app/models/clock_type.dart';
import 'package:planma_app/reports/report_page.dart';
import 'package:planma_app/services/v1_web_socket_service.dart';
import 'package:planma_app/subject/subject_page.dart';
import 'package:planma_app/task/task_page.dart';
import 'package:planma_app/timer/clock.dart';
import 'package:planma_app/timetable/calendar.dart';
import 'package:planma_app/user_profiile/user_page.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planma_app/widgets/reminder_notification.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? selectedSemester;
  int _selectedIndex = 0;

  // Base API URL - adjust this to match your backend URL
  late final String _baseApiUrl;
  bool _refreshAttached = false;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        print('📩 Received message while app is in foreground!');
        if (message.notification != null) {
          final title = message.notification!.title;
          final body = message.notification!.body;
          print('Notification Title: $title');
          print('Notification Body: $body');
          LocalNotificationService.showNotification(title: title, body: body);
        }
      } catch (e, stack) {
        print('Error showing notification: $e');
        print(stack);
      }
    });

    // final socketService = Provider.of<WebSocketService>(context, listen: false);
    // socketService.disconnect();  // Disconnect WebSocket when widget is disposed
    // super.dispose();

    // Fetch data for all relevant providers when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userPreferencesProvider = Provider.of<UserPreferencesProvider>(context, listen: false);
      if (!userProvider.isAuthenticated) return;
      
      // instantiate DashboardProvider via Provider tree
      final dashboard = context.read<DashboardProvider>();

      // load cached UI immediately then fetch remote
      await dashboard.fetchDashboardData();
      await userPreferencesProvider.fetchUserPreferences();
    });
  }

  final List<Widget> _screens = [
    Dashboard(),
    CustomCalendar(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Open BottomSheet instead of switching screen
      BottomSheetWidget.show(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? profilePictureUrl =
        context.watch<UserProfileProvider>().profilePicture;

    // Ensure the URL is absolute
    String getFullImageUrl(String? url) {
      if (url == null || url.isEmpty) {
        return ''; // Return empty string if there's no URL
      }

      // If the URL from the backend is already a full valid URL, use it directly.
      if (url.startsWith('http')) {
        return url;
      }

      // Otherwise, construct the full URL.
      // This correctly adds the '/media/' part and the slash.
      return '$_baseApiUrl/media/$url';
    }

    String profilePictureFullUrl = getFullImageUrl(profilePictureUrl);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Hello, ${context.watch<UserProfileProvider>().username}',
          style: GoogleFonts.openSans(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Color(0xFF173F70),
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 2,
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.yellow,
              backgroundImage: profilePictureFullUrl.isNotEmpty
                  ? NetworkImage(profilePictureFullUrl)
                  : null,
              child: profilePictureUrl == null || profilePictureUrl.isEmpty
                  ? Icon(Icons.person, color: Colors.black)
                  : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's make a productive plan together",
                  style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Menu',
                      style: GoogleFonts.openSans(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173F70),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      tooltip: 'Dashboard Legend',
                      onPressed: () {
                        _showDashboardLegend(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, _) =>
                            MenuButtonWidget(
                          color: const Color(0xFFFFE1BF),
                          icon: Icons.description,
                          title: 'Class Schedule',
                          subtitle: '${dashboard.classScheduleCount} classes',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ClassSchedule()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, _) => MenuButtonWidget(
                          color: const Color(0xFF50B6FF),
                          icon: Icons.check_circle,
                          title: 'Tasks',
                          subtitle: '${dashboard.pendingTasksCount} tasks',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TasksPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, _) =>
                            MenuButtonWidget(
                          color: const Color(0xFF7DCFB6),
                          icon: Icons.event,
                          title: 'Events',
                          subtitle:
                              '${dashboard.upcomingEventsCount} events',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EventsPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, _) =>
                            MenuButtonWidget(
                          color: const Color(0xFFFBA2A2),
                          icon: Icons.accessibility,
                          title: 'Activities',
                          subtitle:
                              '${dashboard.pendingActivitiesCount} activities',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ActivityPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, _) => MenuButtonWidget(
                          color: Color(0xFFD7C0F3),
                          icon: FontAwesomeIcons.flag,
                          title: 'Goals',
                          subtitle: '${dashboard.goalsCount} goals',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GoalPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<UserPreferencesProvider>(
                        builder: (context, userPreferencesProvider, _) =>
                            MenuButtonWidget(
                          color: Color(0xFF535D88),
                          icon: FontAwesomeIcons.moon,
                          title: 'Sleep',
                          subtitle: '',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClockScreen(
                                  themeColor: Color(0xFF535D88),
                                  title: "Sleep",
                                  clockContext: ClockContext(
                                      type: ClockContextType.sleep),
                                  record: userPreferencesProvider
                                      .userPreferences[0],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      MenuButtonWidget(
                          color: Color(0xFF537488),
                          icon: Icons.bar_chart_outlined,
                          title: 'Reports',
                          subtitle: '',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ReportsPage()),
                            );
                          }),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 10.0,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, size: 40),
                  color: Color(0xFF173F70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Dashboard()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, size: 40),
                  color: Color(0xFF173F70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CustomCalendar()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BottomSheetWidget.show(context);
        },
        backgroundColor: Color(0xFF173F70),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

void _showDashboardLegend(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 80,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Color(0xFF173F70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Dashboard Legend',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173F70),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _legendItem(
                Icons.description,
                "Class Schedule",
                "Your weekly class schedules and enrolled subjects.",
                color: Color(0xFFFFE1BF),
              ),
              _legendItem(
                Icons.check_circle,
                "Tasks",
                "Your subject-related schoolwork, assignments, and academic to-dos.",
                color: Color(0xFF50B6FF),
              ),
              _legendItem(
                Icons.event, 
                "Events", 
                "Your scheduled academic or personal events, like seminars and appointments",
                color: Colors.greenAccent),
              _legendItem(
                Icons.accessibility,
                "Activities",
                "Your casual personal activities you schedule outside of classes and schoolwork",
                color: Color(0xFFFBA2A2),
              ),
              _legendItem(
                FontAwesomeIcons.flag,
                "Goals",
                "Your long-term goals with the hours and sessions you plan to complete.",
                color: Color(0xFFD7C0F3),
              ),
              _legendItem(
                FontAwesomeIcons.moon,
                "Sleep",
                "Your recorded sleep sessions used to track your sleep habits.",
                color: Color(0xFF535D88),
              ),
              _legendItem(
                Icons.bar_chart_outlined,
                "Reports",
                "Your generated summaries based on your time logs, attendance, and progress.",
                color: Color(0xFF537488),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _legendItem(
  IconData icon,
  String title,
  String description, {
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 35,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF173F70),
                ),
              ),
              Text(
                description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: const Color(0xFF173F70),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
