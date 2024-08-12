// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'crud_operations.dart';
import 'login_page.dart';
import 'password_reset_page.dart';
import 'registration_page.dart';
import 'reports/reports_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import 'generated/l10n.dart';
import 'home_screen.dart';
import 'models/employee.dart';
import 'models/account_transaction.dart';
import 'models/category.dart' as my_models;
import 'models/courses.dart';
import 'models/student.dart';
import 'models/attendance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();

  // Register all adapters
  Hive.registerAdapter(my_models.CategoryAdapter());
  Hive.registerAdapter(AccountTransactionAdapter());
  Hive.registerAdapter(CoursesAdapter());
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(AttendanceAdapter());

  // Open all the boxes
  await Hive.openBox<my_models.Category>('categories');
  await Hive.openBox<AccountTransaction>('transactions');
  await Hive.openBox<Courses>('courses');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<Student>('students');
  await Hive.openBox<Attendance>('attendance');

  // Ensure the admin user exists
  var employeesBox = Hive.box<Employee>('employees');
  if (employeesBox.values
      .where((e) => e.username == 'admin' && e.password == 'admin')
      .isEmpty) {
    employeesBox.add(Employee(
      empNumber: '1',
      name: 'Administrator',
      position: 'Admin',
      phone: '1234567890',
      address: 'Admin Address',
      password: 'admin',
      role: 'Admin',
      isActive: true,
      username: 'admin',
      profilePicture: 'assets/iat_logo.jpg',
    ));
  }

  // Update existing users with default username
  await updateExistingUsersWithDefaultUsername();

  // Start syncing transactions
  CRUDOperations().startSyncingTransactions();

  runApp(const MyApp());
}

Future<void> updateExistingUsersWithDefaultUsername() async {
  final employeesBox = Hive.box<Employee>('employees');

  for (var employee in employeesBox.values) {
    if (employee.username == null || employee.username!.isEmpty) {
      employee.username = 'default_${employee.empNumber}';
      await employee.save();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // Initialize _themeMode
  Locale _locale = const Locale('en');
  late Box<Employee> employeesBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  void _initializeHive() async {
    employeesBox = await Hive.openBox<Employee>('employees');
    _syncWithFirebase();
  }

  void _syncWithFirebase() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      var employeesCollection =
          FirebaseFirestore.instance.collection('employees');
      var querySnapshot = await employeesCollection.get();

      // Merge Firebase data into Hive
      for (var doc in querySnapshot.docs) {
        var employee = Employee.fromFirestore(doc);
        if (employeesBox.values
            .where((e) => e.empNumber == employee.empNumber)
            .isEmpty) {
          await employeesBox.add(employee);
        }
      }

      // Push local changes to Firebase if not already existing
      for (var employee in employeesBox.values) {
        var docSnapshot =
            await employeesCollection.doc(employee.empNumber).get();
        if (!docSnapshot.exists) {
          await employeesCollection
              .doc(employee.empNumber)
              .set(employee.toFirestore());
        }
      }
    }
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Institute Management App',
      theme: ThemeData(
        fontFamily: 'Roboto', // Use the local Roboto font
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Roboto', // Use the local Roboto font
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: _themeMode, // Use the _themeMode field here
      locale: _locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) {
          final employee =
              ModalRoute.of(context)?.settings.arguments as Employee?;
          if (employee == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            return const SizedBox.shrink();
          }
          return MainScreen(
            onThemeChanged: _toggleTheme,
            onLanguageChanged: _changeLanguage,
            currentUser: employee,
          );
        },
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/reset-password': (context) => const PasswordResetPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final Employee currentUser;

  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentUser,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      HomeScreen(currentUser: widget.currentUser),
      ReportsScreen(currentUser: widget.currentUser),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    void logout() {
      Navigator.pushReplacementNamed(context, '/login');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(S.of(context).appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.amber,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[700],
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: S.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: S.of(context).reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: S.of(context).settings,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
