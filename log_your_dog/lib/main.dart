import 'package:flutter/material.dart';
import 'screens/home_feed_screen.dart';
import 'screens/log_dog_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/notifications_screen.dart';

void main() {
  runApp(const LogYourDogApp());
}

class LogYourDogApp extends StatelessWidget {
  const LogYourDogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log Your Dog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _navigateToFeed() {
    setState(() {
      _selectedIndex = 0; // Navigate to feed tab
    });
  }

  List<Widget> get _screens => <Widget>[
    HomeFeedScreen(),
    CollectionsScreen(),
    LogDogScreen(onDogLogged: _navigateToFeed),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Log Dog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        onTap: _onItemTapped,
      ),
    );
  }
}
