import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:media9/provider/generalprovider.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/dimens.dart';
import 'package:media9/utils/sharedpre.dart';
import 'package:media9/web_js/js_helper.dart';
import 'package:media9/webwidget/interactive_icon.dart';
import 'package:media9/webwidget/interactive_networkicon.dart';
import 'package:media9/webwidget/interactive_text.dart';
import 'package:media9/widget/myimage.dart';
import 'package:media9/widget/mytext.dart';
import 'package:provider/provider.dart';

class FooterWeb extends StatefulWidget {
  const FooterWeb({super.key});

  @override
  State<FooterWeb> createState() => _FooterWebState();
}

class _FooterWebState extends State<FooterWeb> {
  final JSHelper _jsHelper = JSHelper();
  SharedPre sharedPref = SharedPre();
  late GeneralProvider generalProvider;
  String? appDescription,
      aboutUsUrl,
      privacyUrl,
      termsConditionUrl,
      refundPolicyUrl;

  @override
  void initState() {
    _getData();
    super.initState();
  }

  _redirectToUrl(loadingUrl) async {
    debugPrint("loadingUrl -----------> $loadingUrl");
    /*
      _blank => open new Tab
      _self => open in current Tab
    */
    String dataFromJS = await _jsHelper.callOpenTab(loadingUrl, '_blank');
    debugPrint("dataFromJS -----------> $dataFromJS");
  }

  _getData() async {
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    appDescription = await sharedPref.read("app_desripation") ?? "";

    // await generalProvider.getPages();
    // await generalProvider.getSocialLinks();

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      child: (MediaQuery.of(context).size.width < 800)
          ? _buildColumnFooter()
          : _buildRowFooter(),
    );
  }

  Widget _buildRowFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* App Icon & Desc. */
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 90,
                // alignment: Alignment.centerLeft,
                child: MyImage(
                  fit: BoxFit.cover,
                  imagePath: "appicon.png",
                ),
              ),
              // const SizedBox(height: 5),
              MyText(
                color: lightGray,
                multilanguage: false,
                text:
                    'Media9 is the go-to platform for entertaining and informative Indian Live Television , Digital News Channels and Popular TV shows, short videos, documentaries, LIVE TV, and across the genres of News and Digital Media and Sports, Food, History, Mythology, Travel, and more.',
                fontweight: FontWeight.w500,
                fontsizeWeb: 10,
                fontsizeNormal: 12,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
                maxline: 10,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              MyText(
                color: lightGray,
                multilanguage: false,
                text:
                    'The streaming service offers free  Live Television and TV Shows, exciting Video content, and popular Live Digital Media - easily accessible on Smart phones and other smart devices. Explore, discover, and be inspired by all things Indian on Media9.',
                fontweight: FontWeight.w500,
                fontsizeWeb: 10,
                fontsizeNormal: 12,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
                maxline: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),

        /* Quick Links */
        Expanded(
          child: _buildPages(),
        ),
        const SizedBox(width: 30),

        /* Contact With us & Available On */
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* Social Icons */
              (generalProvider.socialLinkModel.status == 200 &&
                      generalProvider.socialLinkModel.result != null)
                  ? ((generalProvider.socialLinkModel.result?.length ?? 0) > 0)
                      ? MyText(
                          color: white,
                          multilanguage: true,
                          text: "connect_with_us",
                          fontweight: FontWeight.w600,
                          fontsizeWeb: 13,
                          fontsizeNormal: 13,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink()
                  : const SizedBox.shrink(),
              /* Social Icons */
              _buildSocialLink(),
              const SizedBox(height: 20),

              /* Available On */
              MyText(
                color: white,
                multilanguage: false,
                text: "${Constant.appName} Available On",
                fontweight: FontWeight.w600,
                fontsizeWeb: 13,
                fontsizeNormal: 13,
                textalign: TextAlign.start,
                fontstyle: FontStyle.normal,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // const SizedBox(height: 8),

              /* Store Icons */
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      _redirectToUrl(Constant.androidAppUrl);
                    },
                    borderRadius: BorderRadius.circular(3),
                    child: InteractiveIcon(
                      imagePath: "ic_playstore.png",
                      height: 45,
                      width: 125,
                      withBG: true,
                      bgRadius: 3,
                      bgColor: transparentColor,
                      bgHoverColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // InkWell(
                  //   onTap: () {
                  //     _redirectToUrl(Constant.iosAppUrl);
                  //   },
                  //   borderRadius: BorderRadius.circular(3),
                  //   child: InteractiveIcon(
                  //     height: 25,
                  //     width: 25,
                  //     imagePath: "applestore.png",
                  //     iconColor: white,
                  //     withBG: true,
                  //     bgRadius: 3,
                  //     bgColor: transparentColor,
                  //     bgHoverColor: primaryColor,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingButton({
    required String title,
    required String subTitle,
    required bool titleMultilang,
    required bool subTitleMultilang,
    required BuildContext context,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: Dimens.minHeightSettings,
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            color: white,
            text: title,
            fontsizeNormal: 14,
            fontsizeWeb: 15,
            maxline: 1,
            multilanguage: titleMultilang,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
          // SizedBox(height: subTitle.isEmpty ? 0 : 5),
        ],
      ),
    );
  }

  Widget _buildColumnFooter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* App Icon & Desc. */
        SizedBox(
          width: 120,
          height: 90,
          // alignment: Alignment.centerLeft,
          child: MyImage(
            fit: BoxFit.cover,
            imagePath: "appicon.png",
          ),
        ),
        // const SizedBox(height: 8),
        MyText(
          color: lightGray,
          multilanguage: false,
          text:
              '   Media9 is the go-to platform for entertaining and informative Indian Live Television , Digital News Channels and Popular TV shows, short videos, documentaries, LIVE TV, and across the genres of News and Digital Media and sports, food, history, mythology, travel, and more.\n\n    The streaming service offers free  Live Television and TV Shows, exciting Video content, and popular Live Digital Media - easily accessible om Smart phones and other smart devices. Explore, discover, and be inspired by all things Indian on Media9.',
          fontweight: FontWeight.w500,
          fontsizeWeb: 12,
          fontsizeNormal: 12,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
          maxline: 8,
          overflow: TextOverflow.ellipsis,
        ),
        // const SizedBox(height: 5),

        /* Quick Links */
        _buildPages(),
        // const SizedBox(height: 10),

        /* Contact With us & Store Icons */
        (generalProvider.socialLinkModel.status == 200 &&
                generalProvider.socialLinkModel.result != null)
            ? ((generalProvider.socialLinkModel.result?.length ?? 0) > 0)
                ? MyText(
                    color: white,
                    multilanguage: true,
                    text: "connect_with_us",
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 13,
                    fontsizeNormal: 13,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink()
            : const SizedBox.shrink(),
        /* Social Icons */
        _buildSocialLink(),
        const SizedBox(height: 20),

        /* Available On */
        MyText(
          color: white,
          multilanguage: false,
          text: "${Constant.appName} Available On",
          fontweight: FontWeight.w600,
          fontsizeWeb: 13,
          fontsizeNormal: 13,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        /* Store Icons */
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                _redirectToUrl(Constant.androidAppUrl);
              },
              borderRadius: BorderRadius.circular(3),
              child: InteractiveIcon(
                imagePath: "playstore.png",
                height: 25,
                width: 25,
                withBG: true,
                bgRadius: 3,
                bgColor: transparentColor,
                bgHoverColor: primaryColor,
              ),
            ),
            const SizedBox(width: 5),
            // InkWell(
            //   onTap: () {
            //     _redirectToUrl(Constant.iosAppUrl);
            //   },
            //   borderRadius: BorderRadius.circular(3),
            //   child: InteractiveIcon(
            //     height: 25,
            //     width: 25,
            //     imagePath: "applestore.png",
            //     iconColor: white,
            //     withBG: true,
            //     bgRadius: 3,
            //     bgColor: transparentColor,
            //     bgHoverColor: primaryColor,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildPages() {
    return Column(
      children: [
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(2),
          onTap: () {
            _redirectToUrl(
                'https://www.termsfeed.com/live/7cf2b76a-79bd-43f1-ab7b-e1b2e877e44e');
          },
          child: _buildSettingButton(
              title: 'Privacy Policy',
              subTitle: '',
              titleMultilang: false,
              subTitleMultilang: false,
              context: context),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(2),
          onTap: () {
            _redirectToUrl(
                'https://www.termsfeed.com/live/978c64e2-3de6-4584-91a2-4593f831b7b3');
          },
          child: _buildSettingButton(
              title: 'Terms & Conditions',
              subTitle: '',
              titleMultilang: false,
              subTitleMultilang: false,
              context: context),
        ),
      ],
    );
    // if (generalProvider.loading) {
    //   return const SizedBox.shrink();
    // } else {
    //   if (generalProvider.pagesModel.status == 200 &&
    //       generalProvider.pagesModel.result != null) {
    //     return AlignedGridView.count(
    //       shrinkWrap: true,
    //       crossAxisCount: 1,
    //       crossAxisSpacing: 10,
    //       mainAxisSpacing: 10,
    //       itemCount: (generalProvider.pagesModel.result?.length ?? 0),
    //       padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
    //       physics: const NeverScrollableScrollPhysics(),
    //       itemBuilder: (BuildContext context, int position) {
    //         return _buildPageItem(
    //           pageName:
    //               generalProvider.pagesModel.result?[position].pageName ?? "",
    //           onClick: () {
    //             _redirectToUrl(
    //                 generalProvider.pagesModel.result?[position].url ?? "");
    //           },
    //         );
    //       },
    //     );
    //   } else {
    //     return const SizedBox.shrink();
    //   }
    // }
  }

  Widget _buildPageItem({
    required String pageName,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      child: InteractiveText(
        text: pageName,
        multilanguage: false,
        maxline: 2,
        textalign: TextAlign.justify,
        fontstyle: FontStyle.normal,
        fontsizeWeb: 14,
        fontweight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSocialLink() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.socialLinkModel.status == 200 &&
          generalProvider.socialLinkModel.result != null) {
        return AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          itemCount: (generalProvider.socialLinkModel.result?.length ?? 0),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int position) {
            return Wrap(
              children: [
                _buildSocialIcon(
                  iconUrl:
                      generalProvider.socialLinkModel.result?[position].image ??
                          "",
                  onClick: () {
                    _redirectToUrl(
                        generalProvider.socialLinkModel.result?[position].url ??
                            "");
                  },
                ),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSocialIcon({
    required String iconUrl,
    required Function() onClick,
  }) {
    return SizedBox(
      height: Dimens.heightSocialBtn,
      width: Dimens.widthSocialBtn,
      child: InkWell(
        borderRadius: BorderRadius.circular(3.0),
        onTap: onClick,
        child: InteractiveNetworkIcon(
          height: 20,
          width: 20,
          iconFit: BoxFit.contain,
          imagePath: iconUrl,
          withBG: true,
          bgRadius: 3.0,
          bgColor: lightBlack,
          bgHoverColor: primaryColor,
        ),
      ),
    );
  }
}
