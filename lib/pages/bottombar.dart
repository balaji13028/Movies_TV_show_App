import 'dart:io';

import 'package:dtlive/pages/channels.dart';
import 'package:dtlive/pages/find.dart';
import 'package:dtlive/pages/home.dart';
import 'package:dtlive/pages/setting.dart';
import 'package:dtlive/pages/rentstore.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Bottombar extends StatefulWidget {
  const Bottombar({Key? key}) : super(key: key);

  @override
  State<Bottombar> createState() => BottombarState();
}

class BottombarState extends State<Bottombar> {
  int selectedIndex = 0;
  DateTime? currentBackPressTime;

  static List<Widget> widgetOptions = <Widget>[
    const Home(pageName: ""),
    const Find(),
    const Channels(),
    const RentStore(),
    const Setting(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        body: Center(
          child: widgetOptions[selectedIndex],
        ),
        bottomNavigationBar: Container(
          height: Platform.isIOS ? 92 : 70,
          alignment: Alignment.center,
          color: black,
          child: BottomNavigationBar(
            backgroundColor: black,
            selectedLabelStyle: GoogleFonts.montserrat(
              fontSize: 10,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
            unselectedLabelStyle: GoogleFonts.montserrat(
              fontSize: 10,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 5,
            currentIndex: selectedIndex,
            unselectedItemColor: gray,
            selectedItemColor: primaryColor,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                backgroundColor: black,
                label: bottomView1,
                activeIcon: _buildBottomNavIcon(
                    iconName: 'ic_home', iconColor: primaryColor),
                icon: _buildBottomNavIcon(iconName: 'ic_home', iconColor: gray),
              ),
              BottomNavigationBarItem(
                backgroundColor: black,
                label: bottomView2,
                activeIcon: _buildBottomNavIcon(
                    iconName: 'ic_find', iconColor: primaryColor),
                icon: _buildBottomNavIcon(iconName: 'ic_find', iconColor: gray),
              ),
              BottomNavigationBarItem(
                backgroundColor: black,
                label: bottomView3,
                activeIcon: _buildBottomNavIcon(
                    iconName: 'ic_channels', iconColor: primaryColor),
                icon: _buildBottomNavIcon(
                    iconName: 'ic_channels', iconColor: gray),
              ),
              BottomNavigationBarItem(
                backgroundColor: black,
                label: bottomView4,
                activeIcon: _buildBottomNavIcon(
                    iconName: 'ic_store', iconColor: primaryColor),
                icon:
                    _buildBottomNavIcon(iconName: 'ic_store', iconColor: gray),
              ),
              BottomNavigationBarItem(
                backgroundColor: black,
                label: bottomView5,
                activeIcon: _buildBottomNavIcon(
                    iconName: 'ic_stuff', iconColor: primaryColor),
                icon:
                    _buildBottomNavIcon(iconName: 'ic_stuff', iconColor: gray),
              ),
            ],
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(
      {required String iconName, required Color? iconColor}) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Image.asset(
          "assets/images/$iconName.png",
          width: 22,
          height: 22,
          color: iconColor,
        ),
      ),
    );
  }

  Future<bool> onBackPressed() async {
    if (selectedIndex == 0) {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        Utils.showSnackbar(context, "", "exit_warning", true);
        return Future.value(false);
      }
      SystemNavigator.pop();
      return Future.value(true);
    } else {
      _onItemTapped(0);
      return Future.value(false);
    }
  }
}
