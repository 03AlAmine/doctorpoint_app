
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/presentation/pages/appointments_page.dart';

import 'package:badges/badges.dart' as badges;

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePage(userName: '',),
    const AppointmentsPage(),

  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Désactive le swipe
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isSmallScreen),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(bool isSmallScreen) {
    final labelStyle = TextStyle(
      fontSize: isSmallScreen ? 10 : 12,
    );

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.greyColor,
      selectedLabelStyle: labelStyle.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: labelStyle,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      iconSize: isSmallScreen ? 20 : 24,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
          _pageController.jumpToPage(index);
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_outlined,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.home,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.calendar_today_outlined,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.calendar_today,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Rendez-vous',
        ),
        BottomNavigationBarItem(
          icon: badges.Badge(
            position: badges.BadgePosition.topEnd(top: -8, end: -10),
            badgeContent: Text(
              '3',
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 5,
                vertical: isSmallScreen ? 1 : 2,
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          activeIcon: badges.Badge(
            position: badges.BadgePosition.topEnd(top: -8, end: -10),
            badgeContent: Text(
              '3',
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 5,
                vertical: isSmallScreen ? 1 : 2,
              ),
            ),
            child: Icon(
              Icons.chat_bubble,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.person,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}
