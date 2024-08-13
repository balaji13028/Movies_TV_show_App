import 'dart:io';

import 'package:dtlive/model/rentmodel.dart';
import 'package:dtlive/pages/channels.dart';
import 'package:dtlive/pages/find.dart';
import 'package:dtlive/pages/home.dart';
import 'package:dtlive/pages/live_tv.dart';
import 'package:dtlive/pages/setting.dart';
import 'package:dtlive/pages/rentstore.dart';
import 'package:dtlive/pages/tv_shows.dart';
import 'package:dtlive/provider/bottombar_provider.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Bottombar extends StatefulWidget {
  const Bottombar({super.key});

  @override
  State<Bottombar> createState() => BottombarState();
}

class BottombarState extends State<Bottombar> {
  // late BottombarProvider bottomPRovider;
  int selectedIndex = 0;
  DateTime? currentBackPressTime;

  static List<Widget> widgetOptions = <Widget>[
    const Home(pageName: ""),
    const LiveTv(),
    const TvShows(),
    const Find(),
    const Setting(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPRovider = Provider.of<BottombarProvider>(context);
    selectedIndex = bottomPRovider.selectdindex;
    return Scaffold(
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
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 9, top: 4),
                child: _buildBottomNavIcon(
                    iconName: 'ic_home',
                    iconColor: primaryColor,
                    height: 22,
                    width: 22),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 9, top: 4),
                child: _buildBottomNavIcon(
                    iconName: 'ic_home',
                    iconColor: gray,
                    height: 22,
                    width: 22),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: black,
              label: bottomView2,
              activeIcon: _buildBottomNavIcon(
                  iconName: 'ic_live_tv',
                  iconColor: primaryColor,
                  height: 34,
                  width: 34),
              icon: _buildBottomNavIcon(
                  iconName: 'ic_live_tv',
                  iconColor: gray,
                  height: 34,
                  width: 34),
            ),
            BottomNavigationBarItem(
              backgroundColor: black,
              label: bottomView3,
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _buildBottomNavIcon(
                    iconName: 'ic_tvshow',
                    iconColor: primaryColor,
                    height: 27,
                    width: 27),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _buildBottomNavIcon(
                    iconName: 'ic_tvshow',
                    iconColor: gray,
                    height: 27,
                    width: 27),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: black,
              label: bottomView4,
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _buildBottomNavIcon(
                    iconName: 'ic_find', iconColor: primaryColor),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child:
                    _buildBottomNavIcon(iconName: 'ic_find', iconColor: gray),
              ),
            ),
            BottomNavigationBarItem(
              backgroundColor: black,
              label: bottomView5,
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildBottomNavIcon(
                    iconName: 'ic_stuff',
                    iconColor: primaryColor,
                    height: 24,
                    width: 24),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildBottomNavIcon(
                    iconName: 'ic_stuff',
                    iconColor: gray,
                    height: 24,
                    width: 24),
              ),
            ),
          ],
          onTap: (index) async {
            bottomPRovider.onItemTapped(index);
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(
      {required String iconName,
      required Color? iconColor,
      double? height,
      double? width}) {
    return Image.asset(
      "assets/images/$iconName.png",
      width: width ?? 22,
      height: height ?? 22,
      color: iconColor,
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
      // bottomPRovider.onItemTapped(0);
      return Future.value(false);
    }
  }
}
