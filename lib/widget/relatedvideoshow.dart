import 'dart:developer';

import 'package:dtlive/model/sectiondetailmodel.dart';
import 'package:dtlive/pages/home.dart';
import 'package:dtlive/pages/moviedetails.dart';
import 'package:dtlive/pages/showdetails.dart';
import 'package:dtlive/tvpages/tvmoviedetails.dart';
import 'package:dtlive/tvpages/tvshowdetails.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RelatedVideoShow extends StatefulWidget {
  final List<GetRelatedVideo>? relatedDataList;
  const RelatedVideoShow({required this.relatedDataList, Key? key})
      : super(key: key);

  @override
  State<RelatedVideoShow> createState() => _RelatedVideoShowState();
}

class _RelatedVideoShowState extends State<RelatedVideoShow> {
  HomeState? homeStateObject;

  @override
  void initState() {
    homeStateObject = context.findAncestorStateOfType<HomeState>();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.relatedDataList != null &&
        (widget.relatedDataList?.length ?? 0) > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: MyText(
              color: white,
              text: "customer_also_watch",
              multilanguage: true,
              textalign: TextAlign.start,
              fontsizeNormal: 15,
              fontweight: FontWeight.w600,
              fontsizeWeb: 16,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              fontstyle: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          /* video_type =>  1-video,  2-show,  3-language,  4-category */
          /* screen_layout =>  landscape, potrait, square */
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: Dimens.heightLand,
            child: landscape(widget.relatedDataList),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget landscape(List<GetRelatedVideo>? relatedDataList) {
    return ListView.separated(
      itemCount: relatedDataList?.length ?? 0,
      shrinkWrap: true,
      padding: const EdgeInsets.only(left: 20, right: 20),
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      separatorBuilder: (context, index) => const SizedBox(width: 5),
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          focusColor: white,
          onTap: () async {
            log("Clicked on index ==> $index");
            if ((relatedDataList?[index].videoType ?? 0) == 5) {
              if ((relatedDataList?[index].upcomingType ?? 0) == 1) {
                if (!(context.mounted)) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      if (kIsWeb || Constant.isTV) {
                        return TVMovieDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      } else {
                        return MovieDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      }
                    },
                  ),
                );
              } else if ((relatedDataList?[index].upcomingType ?? 0) == 2) {
                if (!(context.mounted)) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      if (kIsWeb || Constant.isTV) {
                        return TVShowDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      } else {
                        return ShowDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      }
                    },
                  ),
                );
              }
            } else {
              if ((relatedDataList?[index].videoType ?? 0) == 1) {
                if (!(context.mounted)) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      if (kIsWeb || Constant.isTV) {
                        return TVMovieDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      } else {
                        return MovieDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      }
                    },
                  ),
                );
              } else if ((relatedDataList?[index].videoType ?? 0) == 2) {
                if (!(context.mounted)) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      if (kIsWeb || Constant.isTV) {
                        return TVShowDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      } else {
                        return ShowDetails(
                          relatedDataList?[index].id ?? 0,
                          relatedDataList?[index].upcomingType ?? 0,
                          relatedDataList?[index].videoType ?? 0,
                          relatedDataList?[index].typeId ?? 0,
                        );
                      }
                    },
                  ),
                );
              }
            }
          },
          child: Container(
            width: Dimens.widthLand,
            height: Dimens.heightLand,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: MyNetworkImage(
                imageUrl: relatedDataList?[index].landscape.toString() ?? "",
                fit: BoxFit.cover,
                imgHeight: MediaQuery.of(context).size.height,
                imgWidth: MediaQuery.of(context).size.width,
              ),
            ),
          ),
        );
      },
    );
  }
}
