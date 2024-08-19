import 'dart:developer';
import 'dart:io';

import 'package:dtlive/pages/aboutprivacyterms.dart';
import 'package:dtlive/pages/activetv.dart';
import 'package:dtlive/pages/loginsocial.dart';
import 'package:dtlive/pages/mydownloads.dart';
import 'package:dtlive/pages/mypurchaselist.dart';
import 'package:dtlive/pages/mywatchlist.dart';
import 'package:dtlive/pages/profileedit.dart';
import 'package:dtlive/provider/generalprovider.dart';
import 'package:dtlive/provider/homeprovider.dart';
import 'package:dtlive/provider/sectiondataprovider.dart';
import 'package:dtlive/subscription/subscription.dart';
import 'package:dtlive/subscription/subscriptionhistory.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/constant.dart';
import 'package:dtlive/utils/dimens.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => SettingState();
}

class SettingState extends State<Setting> {
  bool? isSwitched;
  String? userName, userType, userMobileNo;
  late GeneralProvider generalProvider;
  SharedPre sharedPref = SharedPre();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    getUserData();
    super.initState();
  }

  toggleSwitch(bool value) async {
    if (isSwitched == false) {
      setState(() {
        isSwitched = true;
      });
    } else {
      setState(() {
        isSwitched = false;
      });
    }
    log('toggleSwitch isSwitched ==> $isSwitched');
    if (!kIsWeb) {
      // Flutter SDK 3.x.x use
      await OneSignal.InAppMessages.paused(isSwitched ?? true);
      await sharedPref.saveBool("PUSH", isSwitched);
    }
  }

  getUserData() async {
    userName = await sharedPref.read("username");
    userType = await sharedPref.read("usertype");
    userMobileNo = await sharedPref.read("usermobile");
    log('getUserData userName ==> $userName');
    log('getUserData userType ==> $userType');
    log('getUserData userMobileNo ==> $userMobileNo');

    await generalProvider.getPages();

    isSwitched = await sharedPref.readBool("PUSH");
    log('getUserData isSwitched ==> $isSwitched');
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBar(context, "setting", true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.all(22),
            child: Column(
              children: [
                /* Account Details */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const ProfileEdit(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'accountdetails',
                //     subTitle: 'manageprofile',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 16.0),

                /* Active TV */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const ActiveTV(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'activetv',
                //     subTitle: 'activetv_desc',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 16.0),

                // /* Watchlist */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const MyWatchlist(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'watchlist',
                //     subTitle: 'view_your_watchlist',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 16.0),

                // /* Purchases */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const MyPurchaselist(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'purchases',
                //     subTitle: 'view_your_purchases',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 16.0),

                /* Downloads */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const MyDownloads(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'downloads',
                //     subTitle: 'view_your_downloads',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 16.0),

                // /* Subscription */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const Subscription(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'subsciption',
                //     subTitle: 'subsciptionnotes',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 8.0),

                /* Transactions */
                // InkWell(
                //   borderRadius: BorderRadius.circular(2),
                //   onTap: () {
                //     if (Constant.userID != null) {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const SubscriptionHistory(),
                //         ),
                //       );
                //     } else {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => const LoginSocial(),
                //         ),
                //       );
                //     }
                //   },
                //   child: _buildSettingButton(
                //     title: 'transactions',
                //     subTitle: 'transactions_notes',
                //     titleMultilang: true,
                //     subTitleMultilang: true,
                //   ),
                // ),
                // _buildLine(16.0, 8.0),

                /* MaltiLanguage */
                InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () {
                    _languageChangeDialog();
                  },
                  child: _buildSettingButton(
                    title: 'language_',
                    subTitle: '',
                    titleMultilang: true,
                    subTitleMultilang: false,
                  ),
                ),
                _buildLine(8.0, 8.0),

                /* Push Notification enable/disable */
                Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: BoxConstraints(
                    minHeight: Dimens.minHeightSettings,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            color: white,
                            text: "notification",
                            fontsizeNormal: 14,
                            maxline: 1,
                            multilanguage: true,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w500,
                            textalign: TextAlign.center,
                            fontstyle: FontStyle.normal,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          MyText(
                            color: otherColor,
                            text: "recivepushnotification",
                            fontsizeNormal: 12,
                            multilanguage: true,
                            maxline: 1,
                            overflow: TextOverflow.ellipsis,
                            fontweight: FontWeight.w500,
                            textalign: TextAlign.start,
                            fontstyle: FontStyle.normal,
                          ),
                        ],
                      ),
                      Switch(
                        activeColor: primaryDark,
                        activeTrackColor: primaryLight,
                        inactiveTrackColor: gray,
                        value: isSwitched ?? true,
                        onChanged: toggleSwitch,
                      ),
                    ],
                  ),
                ),
                _buildLine(16.0, 16.0),

                /* Clear Cache */
                if (!Platform.isIOS)
                  InkWell(
                    borderRadius: BorderRadius.circular(2),
                    onTap: () async {
                      if (!(kIsWeb || Constant.isTV)) Utils.deleteCacheDir();
                      if (!mounted) return;
                      Utils.showSnackbar(
                          context, "success", "cacheclearmsg", true);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(
                        minHeight: Dimens.minHeightSettings,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  color: white,
                                  text: "clearcatch",
                                  fontsizeNormal: 14,
                                  multilanguage: true,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontweight: FontWeight.w500,
                                  textalign: TextAlign.start,
                                  fontstyle: FontStyle.normal,
                                ),
                                const SizedBox(height: 5),
                                MyText(
                                  color: otherColor,
                                  text: "clearlocallycatch",
                                  fontsizeNormal: 12,
                                  maxline: 1,
                                  multilanguage: true,
                                  overflow: TextOverflow.ellipsis,
                                  fontweight: FontWeight.w500,
                                  textalign: TextAlign.start,
                                  fontstyle: FontStyle.normal,
                                ),
                              ],
                            ),
                          ),
                          MyImage(
                            width: 28,
                            height: 28,
                            imagePath: "ic_clear.png",
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!Platform.isIOS) _buildLine(16.0, 16.0),

                /* SignIn / SignOut */
                InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () async {
                    if (Constant.userID != null) {
                      logoutConfirmDialog();
                    } else {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginSocial(),
                        ),
                      );
                      setState(() {});
                    }
                  },
                  child: _buildSettingButton(
                    title: Constant.userID == null
                        ? youAreNotSignIn
                        : (userType == "3" && (userName ?? "").isEmpty)
                            ? ("$signedInAs ${userMobileNo ?? ""}")
                            : ("$signedInAs ${userName ?? ""}"),
                    subTitle: Constant.userID == null ? "sign_in" : "sign_out",
                    titleMultilang: false,
                    subTitleMultilang: true,
                  ),
                ),
                _buildLine(16.0, 16.0),

                /* Rate App */
                InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () async {
                    debugPrint("Clicked on rateApp");
                    await Utils.redirectToStore();
                  },
                  child: _buildSettingButton(
                    title: 'rateus',
                    subTitle: 'rateourapp',
                    titleMultilang: true,
                    subTitleMultilang: true,
                  ),
                ),
                _buildLine(16.0, 16.0),

                /* Share App */
                InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () async {
                    await Utils.shareApp(Platform.isIOS
                        ? Constant.iosAppShareUrlDesc
                        : Constant.androidAppShareUrlDesc);
                  },
                  child: _buildSettingButton(
                    title: 'shareapp',
                    subTitle: 'sharewithfriends',
                    titleMultilang: true,
                    subTitleMultilang: true,
                  ),
                ),
                _buildLine(16.0, 16.0),

                /* Delete Account */
                if (Constant.userID != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(2),
                    onTap: () async {
                      if (Constant.userID != null) {
                        deleteConfirmDialog();
                      } else {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginSocial(),
                          ),
                        );
                        setState(() {});
                      }
                    },
                    child: _buildSettingButton(
                      title: 'delete_account',
                      subTitle: '',
                      titleMultilang: true,
                      subTitleMultilang: false,
                    ),
                  ),
                if (Constant.userID != null) _buildLine(8.0, 8.0),

                /* Pages */
                _buildPages(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPages() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.pagesModel.status == 200 &&
          generalProvider.pagesModel.result != null) {
        return AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          itemCount: (generalProvider.pagesModel.result?.length ?? 0),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int position) {
            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(2),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AboutPrivacyTerms(
                          appBarTitle: generalProvider
                                  .pagesModel.result?[position].pageName ??
                              '',
                          loadURL: generalProvider
                                  .pagesModel.result?[position].url ??
                              '',
                        ),
                      ),
                    );
                  },
                  child: _buildSettingButton(
                    title:
                        generalProvider.pagesModel.result?[position].pageName ??
                            '',
                    subTitle: '',
                    titleMultilang: false,
                    subTitleMultilang: false,
                  ),
                ),
                _buildLine(8.0, 0.0),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSettingButton({
    required String title,
    required String subTitle,
    required bool titleMultilang,
    required bool subTitleMultilang,
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
          SizedBox(height: subTitle.isEmpty ? 0 : 5),
          subTitle.isEmpty
              ? const SizedBox.shrink()
              : MyText(
                  color: otherColor,
                  text: subTitle,
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  multilanguage: subTitleMultilang,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontweight: FontWeight.w500,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
        ],
      ),
    );
  }

  Widget _buildLine(double topMargin, double bottomMargin) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 0.5,
      margin: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
      color: otherColor,
    );
  }

  _languageChangeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: lightBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
      ),
      elevation: 20,
      builder: (BuildContext context) {
        return BottomSheet(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(0),
            ),
          ),
          onClosing: () {},
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, state) {
                return Wrap(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      color: lightBlack,
                      padding: const EdgeInsets.all(23),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  color: white,
                                  text: "changelanguage",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 16,
                                  fontweight: FontWeight.bold,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                ),
                                const SizedBox(height: 3),
                                MyText(
                                  color: white,
                                  text: "selectyourlanguage",
                                  multilanguage: true,
                                  textalign: TextAlign.start,
                                  fontsizeNormal: 12,
                                  fontweight: FontWeight.w500,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontstyle: FontStyle.normal,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          /* English */
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () {
                              state(() {});
                              LocaleNotifier.of(context)?.change('en');
                              Navigator.pop(context);
                            },
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              height: 48,
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryLight,
                                  width: .5,
                                ),
                                color: primaryDarkColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: MyText(
                                color: white,
                                text: "English",
                                textalign: TextAlign.center,
                                fontsizeNormal: 16,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /* Arabic */
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () {
                              state(() {});
                              LocaleNotifier.of(context)?.change('ar');
                              Navigator.pop(context);
                            },
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              height: 48,
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryLight,
                                  width: .5,
                                ),
                                color: primaryDarkColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: MyText(
                                color: white,
                                text: "Arabic",
                                textalign: TextAlign.center,
                                fontsizeNormal: 16,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /* Hindi */
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () {
                              state(() {});
                              LocaleNotifier.of(context)?.change('hi');
                              Navigator.pop(context);
                            },
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              height: 48,
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryLight,
                                  width: .5,
                                ),
                                color: primaryDarkColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: MyText(
                                color: white,
                                text: "Hindi",
                                textalign: TextAlign.center,
                                fontsizeNormal: 16,
                                multilanguage: false,
                                maxline: 1,
                                overflow: TextOverflow.ellipsis,
                                fontweight: FontWeight.w500,
                                fontstyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /* Portuguese (Brazil) */
                          // InkWell(
                          //   borderRadius: BorderRadius.circular(5),
                          //   onTap: () {
                          //     state(() {});
                          //     LocaleNotifier.of(context)?.change('pt');
                          //     Navigator.pop(context);
                          //   },
                          //   child: Container(
                          //     constraints: BoxConstraints(
                          //       minWidth: MediaQuery.of(context).size.width,
                          //     ),
                          //     height: 48,
                          //     padding:
                          //         const EdgeInsets.only(left: 10, right: 10),
                          //     alignment: Alignment.center,
                          //     decoration: BoxDecoration(
                          //       border: Border.all(
                          //         color: primaryLight,
                          //         width: .5,
                          //       ),
                          //       color: primaryDarkColor,
                          //       borderRadius: BorderRadius.circular(5),
                          //     ),
                          //     child: MyText(
                          //       color: white,
                          //       text: "Portuguese (Brazil)",
                          //       textalign: TextAlign.center,
                          //       fontsizeNormal: 16,
                          //       multilanguage: false,
                          //       maxline: 1,
                          //       overflow: TextOverflow.ellipsis,
                          //       fontweight: FontWeight.w500,
                          //       fontstyle: FontStyle.normal,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  logoutConfirmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              color: lightBlack,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: white,
                          text: "confirmsognout",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsizeNormal: 16,
                          fontweight: FontWeight.bold,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        MyText(
                          color: white,
                          text: "areyousurewanrtosignout",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 75,
                            ),
                            height: 50,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: otherColor,
                                width: .5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: MyText(
                              color: white,
                              text: "cancel",
                              multilanguage: true,
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () async {
                            final homeProvider = Provider.of<HomeProvider>(
                                context,
                                listen: false);
                            final sectionDataProvider =
                                Provider.of<SectionDataProvider>(context,
                                    listen: false);
                            await homeProvider.setSelectedTab(0);
                            await sectionDataProvider.clearProvider();
                            // Firebase Signout
                            await _auth.signOut();
                            await GoogleSignIn().signOut();
                            await Utils.setUserId(null);
                            sectionDataProvider.getSectionBanner("0", "1");
                            sectionDataProvider.getSectionList("0", "1");
                            getUserData();
                            if (!mounted) return;
                            Navigator.pop(context);
                            if (!mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginSocial(),
                              ),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 75,
                            ),
                            height: 50,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(5),
                              shape: BoxShape.rectangle,
                            ),
                            child: MyText(
                              color: black,
                              text: "sign_out",
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              multilanguage: true,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  deleteConfirmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(23),
              color: lightBlack,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: white,
                          text: "confirm_delete_account",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 16,
                          fontweight: FontWeight.bold,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 3),
                        MyText(
                          color: white,
                          text: "delete_account_msg",
                          multilanguage: true,
                          textalign: TextAlign.center,
                          fontsizeNormal: 12,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 75,
                            ),
                            height: 50,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: otherColor,
                                width: .5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: MyText(
                              color: white,
                              text: "cancel",
                              multilanguage: true,
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () async {
                            final homeProvider = Provider.of<HomeProvider>(
                                context,
                                listen: false);
                            final sectionDataProvider =
                                Provider.of<SectionDataProvider>(context,
                                    listen: false);
                            await homeProvider.setSelectedTab(0);
                            await sectionDataProvider.clearProvider();
                            // Firebase Signout
                            await _auth.signOut();
                            await GoogleSignIn().signOut();
                            await Utils.setUserId(null);
                            sectionDataProvider.getSectionBanner("0", "1");
                            sectionDataProvider.getSectionList("0", "1");
                            getUserData();
                            if (!mounted) return;
                            Navigator.pop(context);
                            if (!mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginSocial(),
                              ),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 75,
                            ),
                            height: 50,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(5),
                              shape: BoxShape.rectangle,
                            ),
                            child: MyText(
                              color: black,
                              text: "delete",
                              textalign: TextAlign.center,
                              fontsizeNormal: 16,
                              multilanguage: true,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontweight: FontWeight.w500,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
