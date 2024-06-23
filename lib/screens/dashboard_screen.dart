import 'package:flutter/material.dart';
import 'package:practice_project/components/background.dart';
import 'package:practice_project/dashboard_widgets/add_product.dart';
import 'package:practice_project/dashboard_widgets/favorites.dart';
import 'package:practice_project/dashboard_widgets/profile.dart';
import 'package:practice_project/screens/for_you_page.dart';
import 'package:practice_project/screens/messages_screen.dart';
import 'package:practice_project/screens/product_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get widgetOptions => [
        ForYouPage(),
        ProductPage(),
        FavoriteProducts(),
        MessagesScreen(),
        AddProduct(),
        ProfileWidget()
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('lib/images/new_logo.jpg',  width: 100, height: 100), // Logo added here
        centerTitle: true, // To center the logo if needed
        flexibleSpace: Container(
          decoration: gradientDecoration2(),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: gradientDecoration(),
        child: Center(
          child: widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: gradientDecoration2(),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'For you',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outlined),
              label: 'Connect',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}