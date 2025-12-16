import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:media9/firebase_options.dart';
import 'package:media9/pages/home.dart';
import 'package:media9/pages/splash.dart';
import 'package:media9/pagetransition.dart';
import 'package:media9/provider/adventisements_provider.dart';
import 'package:media9/provider/avatarprovider.dart';
import 'package:media9/provider/bottombar_provider.dart';
import 'package:media9/provider/castdetailsprovider.dart';
import 'package:media9/provider/channelsectionprovider.dart';
import 'package:media9/provider/episodeprovider.dart';
import 'package:media9/provider/findprovider.dart';
import 'package:media9/provider/generalprovider.dart';
import 'package:media9/provider/homeprovider.dart';
import 'package:media9/provider/livetv_provider.dart';
import 'package:media9/provider/menulist_provider.dart';
import 'package:media9/provider/paymentprovider.dart';
import 'package:media9/provider/playerprovider.dart';
import 'package:media9/provider/poster_ads_provider.dart';
import 'package:media9/provider/profileprovider.dart';
import 'package:media9/provider/purchaselistprovider.dart';
import 'package:media9/provider/rentstoreprovider.dart';
import 'package:media9/provider/searchprovider.dart';
import 'package:media9/provider/sectionbytypeprovider.dart';
import 'package:media9/provider/sectiondataprovider.dart';
import 'package:media9/provider/showdetailsprovider.dart';
import 'package:media9/provider/showdownloadprovider.dart';
import 'package:media9/provider/slides_provider.dart';
import 'package:media9/provider/subhistoryprovider.dart';
import 'package:media9/provider/subscriptionprovider.dart';
import 'package:media9/provider/tv_showprovider.dart';
import 'package:media9/provider/videobyidprovider.dart';
import 'package:media9/provider/videodetailsprovider.dart';
import 'package:media9/provider/videodownloadprovider.dart';
import 'package:media9/provider/watchlistprovider.dart';
import 'package:media9/restartapp_wiget.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/constant.dart';
import 'package:media9/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:responsive_framework/responsive_framework.dart';

bool adShownThisSession = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    log('Firebase initialization error: $e');
  }
  
  await Locales.init(['en', 'ar', 'hi', 'pt']);
  PWAInstall().setup(installCallback: () {
    log('APP INSTALLED!');
  });
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AvatarProvider()),
      ChangeNotifierProvider(create: (_) => CastDetailsProvider()),
      ChangeNotifierProvider(create: (_) => ChannelSectionProvider()),
      ChangeNotifierProvider(create: (_) => EpisodeProvider()),
      ChangeNotifierProvider(create: (_) => FindProvider()),
      ChangeNotifierProvider(create: (_) => GeneralProvider()),
      ChangeNotifierProvider(create: (_) => HomeProvider()),
      ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => PurchaselistProvider()),
      ChangeNotifierProvider(create: (_) => RentStoreProvider()),
      ChangeNotifierProvider(create: (_) => SearchProvider()),
      ChangeNotifierProvider(create: (_) => SectionByTypeProvider()),
      ChangeNotifierProvider(create: (_) => SectionDataProvider()),
      ChangeNotifierProvider(create: (_) => ShowDownloadProvider()),
      ChangeNotifierProvider(create: (_) => ShowDetailsProvider()),
      ChangeNotifierProvider(create: (_) => SubHistoryProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => VideoByIDProvider()),
      ChangeNotifierProvider(create: (_) => VideoDetailsProvider()),
      ChangeNotifierProvider(create: (_) => VideoDownloadProvider()),
      ChangeNotifierProvider(create: (_) => WatchlistProvider()),
      ChangeNotifierProvider(create: (_) => TvShowprovider()),
      ChangeNotifierProvider(create: (_) => LivetvProvider()),
      ChangeNotifierProvider(create: (_) => SlidesProvider()),
      ChangeNotifierProvider(create: (_) => BottombarProvider()),
      ChangeNotifierProvider(create: (_) => AdventisementsProvider()),
      ChangeNotifierProvider(create: (_) => PosterAdsProvider()),
      ChangeNotifierProvider(create: (_) => MenulistProvider()),
    ], child: const RestartWidget(child: MyApp())),
  );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    if (!kIsWeb) {
      Utils.enableScreenCapture();
      WidgetsBinding.instance.addObserver(this);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  late AppLifecycleState previewsSate;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    previewsSate = state;
    // print(previewsSate);
    // print('state = $state');
    if (!kIsWeb && Platform.isAndroid) {
      if (state == AppLifecycleState.resumed &&
              previewsSate == AppLifecycleState.inactive ||
          previewsSate == AppLifecycleState.hidden ||
          previewsSate == AppLifecycleState.paused) {
        return RestartWidget.restartApp(context);
      }
    }
    // if(app)
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: LocaleBuilder(
        builder: (locale) => MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver], //HERE
          theme: ThemeData(
            primaryColor: primaryColor,
            primaryColorDark: primaryDarkColor,
            primaryColorLight: primaryLight,
            scaffoldBackgroundColor: appBgColor,
          ).copyWith(
            scrollbarTheme: const ScrollbarThemeData().copyWith(
              thumbColor: WidgetStateProperty.all(white),
              trackVisibility: WidgetStateProperty.all(true),
              trackColor: WidgetStateProperty.all(whiteTransparent),
            ),
          ),
          title: Constant.appName ?? "",
          localizationsDelegates: Locales.delegates,
          supportedLocales: Locales.supportedLocales,
          locale: locale,
          localeResolutionCallback:
              (Locale? locale, Iterable<Locale> supportedLocales) {
            return locale;
          },
          builder: (context, child) {
            return ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 360, name: MOBILE),
                const Breakpoint(start: 361, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1000, name: DESKTOP),
                const Breakpoint(start: 1001, end: double.infinity, name: '4K'),
              ],
            );
          },
          home: const Home(pageName: ""),

          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
              PointerDeviceKind.trackpad
            },
          ),
        ),
      ),
    );
  }
}
