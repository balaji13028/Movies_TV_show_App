import 'package:cached_network_image/cached_network_image.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyNetworkImage extends StatelessWidget {
  String imageUrl;
  double? imgHeight, imgWidth;
  dynamic fit;

  MyNetworkImage(
      {super.key,
      required this.imageUrl,
      required this.fit,
      this.imgHeight,
      this.imgWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imgHeight,
      width: imgWidth,
      child: CachedNetworkImage(
        imageUrl: 'https://media9tv.com/storage/$imageUrl',
        fit: fit,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        ),
        placeholder: (context, url) {
          return MyImage(
            width: imgWidth,
            height: imgHeight,
            imagePath:
                imageUrl.contains('land_') ? "appicon.png" : "appicon.png",
            fit: BoxFit.cover,
          );
        },
        errorWidget: (context, url, error) {
          return MyImage(
            width: imgWidth,
            height: imgHeight,
            imagePath:
                imageUrl.contains('land_') ? "appicon.png" : "appicon.png",
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
