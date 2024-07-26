import 'dart:developer';

import 'package:dtlive/provider/generalprovider.dart';
import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class ActiveTV extends StatefulWidget {
  const ActiveTV({Key? key}) : super(key: key);

  @override
  State<ActiveTV> createState() => ActiveTVState();
}

class ActiveTVState extends State<ActiveTV> {
  late ProgressDialog prDialog;
  SharedPre sharePref = SharedPre();
  final pinPutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    prDialog = ProgressDialog(context);
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    pinPutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          margin: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: MyImage(
                        fit: BoxFit.fill,
                        imagePath: "backwith_bg.png",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyText(
                  color: white,
                  text: "verify_tvcode",
                  fontsizeNormal: 22,
                  multilanguage: true,
                  fontweight: FontWeight.bold,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 8),
                MyText(
                  color: otherColor,
                  text: "tvcode_desc",
                  fontsizeNormal: 15,
                  fontweight: FontWeight.w500,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  multilanguage: true,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 40),

                /* Enter TV pin */
                Pinput(
                  length: 4,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  controller: pinPutController,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  defaultPinTheme: PinTheme(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor, width: 0.7),
                      shape: BoxShape.rectangle,
                      color: edtBG,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      color: white,
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                /* Confirm Button */
                InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () {
                    debugPrint(
                        "Clicked sms Code =====> ${pinPutController.text}");
                    if (pinPutController.text.toString().isEmpty) {
                      Utils.showSnackbar(
                          context, "info", "enter_tv_code", true);
                    } else {
                      Utils.showProgress(context, prDialog);
                      _checkAndLogin();
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          primaryLight,
                          primaryDark,
                        ],
                        begin: FractionalOffset(0.0, 0.0),
                        end: FractionalOffset(1.0, 0.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: MyText(
                      color: white,
                      text: "confirm",
                      fontsizeNormal: 17,
                      multilanguage: true,
                      fontweight: FontWeight.w700,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _checkAndLogin() async {
    log("click on Submit mobile => ${pinPutController.text}");
    var generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    if (!prDialog.isShowing()) {
      Utils.showProgress(context, prDialog);
    }
    await generalProvider.loginWithTV(pinPutController.text.toString());

    if (!generalProvider.loading) {
      if (generalProvider.loginTVModel.status == 200) {
        log('Login Successfull!');
        await prDialog.hide();
        if (!mounted) return;
        Utils.showSnackbar(context, "success", "tv_login_success", true);
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        await prDialog.hide();
        if (!mounted) return;
        Utils.showSnackbar(
            context, "fail", "${generalProvider.loginTVModel.message}", false);
      }
    }
  }
}
