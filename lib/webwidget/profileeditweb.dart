import 'dart:developer';
import 'dart:io';

import 'package:dtlive/provider/profileprovider.dart';
import 'package:dtlive/widget/myimage.dart';
import 'package:dtlive/widget/mynetworkimg.dart';
import 'package:dtlive/widget/mytextformfield.dart';
import 'package:flutter/material.dart';

import 'package:dtlive/utils/color.dart';
import 'package:dtlive/utils/sharedpre.dart';
import 'package:dtlive/utils/strings.dart';
import 'package:dtlive/utils/utils.dart';
import 'package:dtlive/widget/mytext.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileEditWeb extends StatefulWidget {
  const ProfileEditWeb({super.key});

  @override
  State<ProfileEditWeb> createState() => _ProfileEditWebState();
}

class _ProfileEditWebState extends State<ProfileEditWeb> {
  SharedPre sharePref = SharedPre();
  final ImagePicker imagePicker = ImagePicker();
  File? pickedImageFile;
  String? userId, userName;
  final nameController = TextEditingController();
  late ProfileProvider profileProvider;

  @override
  void initState() {
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    getUserData();
    super.initState();
  }

  getUserData() async {
    await profileProvider.getProfile();

    if (!profileProvider.loading) {
      if (profileProvider.profileModel.status == 200) {
        if (profileProvider.profileModel.result != null) {
          if (nameController.text.toString() == "") {
            if ((profileProvider.profileModel.result?[0].name ?? "") != "") {
              nameController.text =
                  profileProvider.profileModel.result?[0].name ?? "";
            }
          }
        }
      }
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      constraints: const BoxConstraints(
        minWidth: 300,
        minHeight: 0,
        maxWidth: 350,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                focusColor: white.withOpacity(0.5),
                child: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.centerRight,
                  child: MyImage(
                    fit: BoxFit.contain,
                    imagePath: "ic_close.png",
                    color: otherColor,
                  ),
                ),
              ),
            ),

            /* Profile Image */
            Consumer<ProfileProvider>(
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  clipBehavior: Clip.antiAlias,
                  child: pickedImageFile != null
                      ? Image.network(
                          pickedImageFile?.path ?? "",
                          fit: BoxFit.cover,
                          height: 90,
                          width: 90,
                        )
                      : MyNetworkImage(
                          imageUrl: profileProvider.profileModel.status == 200
                              ? profileProvider.profileModel.result != null
                                  ? (profileProvider
                                          .profileModel.result?[0].image ??
                                      "")
                                  : ""
                              : "",
                          fit: BoxFit.cover,
                          imgHeight: 90,
                          imgWidth: 90,
                        ),
                );
              },
            ),
            const SizedBox(height: 8),

            /* Change Button */
            Container(
              height: 35,
              padding: const EdgeInsets.only(left: 10, right: 10),
              alignment: Alignment.center,
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  getFromGallery();
                },
                focusColor: white.withOpacity(0.5),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 35,
                    maxWidth: 100,
                  ),
                  alignment: Alignment.center,
                  child: MyText(
                    text: "chnage",
                    fontsizeNormal: 16,
                    fontsizeWeb: 16,
                    multilanguage: true,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w500,
                    fontstyle: FontStyle.normal,
                    textalign: TextAlign.center,
                    color: otherColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            /* Name */
            Container(
              height: 35,
              padding: const EdgeInsets.only(left: 10, right: 10),
              decoration: Utils.textFieldBGWithBorder(),
              alignment: Alignment.center,
              child: MyTextFormField(
                mHint: enterName,
                mController: nameController,
                mObscureText: false,
                mMaxLine: 1,
                mHintTextColor: otherColor,
                mTextColor: black,
                mkeyboardType: TextInputType.name,
                mTextInputAction: TextInputAction.next,
                mInputBorder: InputBorder.none,
                mTextAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            /* Save */
            Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                focusColor: white.withOpacity(0.5),
                onTap: () async {
                  log("nameController Name ==> ${nameController.text.toString()}");
                  log("pickedImageFile ==> ${pickedImageFile?.path ?? "not picked"}");
                  if (nameController.text.toString().isEmpty) {
                    return Utils.showSnackbar(
                        context, "info", enterName, false);
                  }
                  await sharePref.save(
                      "username", nameController.text.toString());
                  if (pickedImageFile != null) {
                    await profileProvider.getImageUpload(pickedImageFile);
                  }
                  await profileProvider
                      .getUpdateProfile(nameController.text.toString());
                  await profileProvider.getProfile();
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    height: 35,
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    decoration: BoxDecoration(
                      color: primaryDark,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: MyText(
                      color: white,
                      text: "save",
                      multilanguage: true,
                      textalign: TextAlign.center,
                      fontsizeNormal: 15,
                      fontsizeWeb: 15,
                      fontweight: FontWeight.w600,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get from gallery
  void getFromGallery() async {
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 100,
    );
    if (pickedFile != null) {
      setState(() {
        pickedImageFile = File(pickedFile.path);
        log("Gallery pickedImageFile ==> ${pickedImageFile?.path}");
      });
    }
  }
}
