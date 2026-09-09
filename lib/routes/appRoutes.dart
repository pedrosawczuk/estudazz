import 'package:estudazz_main_code/views/about/aboutPage.dart';
import 'package:estudazz_main_code/views/ia/settings/settingsIAPage.dart';
import 'package:estudazz_main_code/views/settings/notifications/notificationsPage.dart';
import 'package:estudazz_main_code/views/splashPage.dart';
import 'package:estudazz_main_code/views/studyRoom/studyRoomPage.dart';
import 'package:estudazz_main_code/views/studyRoom/studyRoomDetailsPage.dart';
import 'package:get/get.dart';
import 'package:estudazz_main_code/views/settings/user/editDataPage.dart';
import 'package:estudazz_main_code/views/settings/user/myDataPage.dart';
import 'package:estudazz_main_code/views/homePage.dart';
import 'package:estudazz_main_code/views/tasks/allTasksPage.dart';
import 'package:estudazz_main_code/views/calendar/calendarPage.dart';
import 'package:estudazz_main_code/views/performance/performancePage.dart';
import 'package:estudazz_main_code/views/ia/iaPage.dart';
import 'package:estudazz_main_code/views/settings/settingsPage.dart';
import 'package:estudazz_main_code/views/profile/profilePage.dart';
import 'package:estudazz_main_code/views/auth/signUpPage.dart';
import 'package:estudazz_main_code/views/auth/signInPage.dart';
import 'package:estudazz_main_code/views/auth/forgotPasswordPage.dart';

class AppRoutes {
  static const String splashPage = '/splashPage';
  static const String homePage = '/homePage';
  static const String settingsPage = '/settingsPage';
  static const String allTasksPage = '/allTasksPage';
  static const String profilePage = '/profilePage';
  static const String calendarPage = '/calendarPage';
  static const String studyRoomPage = '/studyRoomPage';
  static const String studyRoomDetailsPage = '/studyRoomDetailsPage';

  static const String iaPage = '/iaPage';
  static const String settingsAIPage = '/settingsAIPage';

  static const String performancePage = '/performancePage';

  static const String notificationsPage = '/notificationsPage';
  static const String myDataPage = '/myDataPage';
  static const String editDataPage = '/editDataPage';
  static const String aboutPage = '/aboutPage';

  static const String signUpPage = '/signUpPage';
  static const String signInPage = '/signInPage';
  static const String forgotPasswordPage = '/forgotPasswordPage';

  static final routes = [
    GetPage(name: splashPage, page: () => const SplashPage()),
    GetPage(name: homePage, page: () => const HomePage()),
    GetPage(name: settingsPage, page: () => const SettingsPage()),
    GetPage(name: allTasksPage, page: () => const AllTasksPage()),
    GetPage(name: profilePage, page: () => const ProfilePage()),
    GetPage(name: calendarPage, page: () => const CalendarPage()),
    GetPage(name: studyRoomPage, page: () => const StudyRoomPage()),
    GetPage(
      name: studyRoomDetailsPage,
      page: () => StudyRoomDetailsPage(room: Get.arguments),
    ),
    GetPage(name: performancePage, page: () => const PerformancePage()),

    GetPage(name: iaPage, page: () => const IaPage()),
    GetPage(name: settingsAIPage, page: () => const SettingsAIPage()),

    GetPage(name: notificationsPage, page: () => const NotificationsSettingsPage()),
    GetPage(name: myDataPage, page: () => const MyDataPage()),
    GetPage(name: editDataPage, page: () => const EditDataPage()),
    GetPage(name: aboutPage, page: () => const AboutPage()),

    GetPage(name: signUpPage, page: () => const SignUpPage()),
    GetPage(name: signInPage, page: () => const SignInPage()),
    GetPage(name: forgotPasswordPage, page: () => const ForgotPasswordPage()),
  ];
}
