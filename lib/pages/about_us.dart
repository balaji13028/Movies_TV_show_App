import 'package:flutter/material.dart';
import 'package:media9/utils/utils.dart';
import 'package:media9/widget/mytext.dart';

import '../utils/strings.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Utils.myAppBarWithBack(context, 'About us', false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              MyText(
                  color: Colors.white,
                  fontsizeNormal: 14,
                  fontweight: FontWeight.normal,
                  text:aboutMedia9,),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}


