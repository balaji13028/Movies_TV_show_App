import 'package:flutter/material.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/widget/mytext.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Utils.myAppBarWithBack(context, 'About us', false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: MyText(
            color: Colors.white,
            fontsizeNormal: 14,
            fontweight: FontWeight.normal,
            text:
                "         Media9 is the go-to platform for entertaining and informative Indian Live Television , Digital News Channels and Popular TV shows, short videos, documentaries, LIVE TV, and across the genres of News and Digital Media and Sports, Food, History, Mythology, Travel, and more.\n         The streaming service offers free  Live Television and TV Shows, exciting Video content, and popular Live Digital Media - easily accessible on Smart phones and other smart devices. Explore, discover, and be inspired by all things Indian on Media9."),
      ),
    );
  }
}


