import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:password_manager/constants.dart';
import 'package:password_manager/models/provider_class.dart';
import 'package:password_manager/models/route_generator.dart';
import 'package:password_manager/screens/initial_screen_handler.dart';
import 'package:password_manager/screens/login_screen.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:local_session_timeout/local_session_timeout.dart';

import 'models/firebase_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  final StreamController<SessionState> sessionStateStream = Get.put(StreamController<SessionState>());

  final ThemeData appTheme = ThemeData(
    fontFamily: 'ProductSans',
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(color: kSecondaryColor),
    scaffoldBackgroundColor: kScaffoldBackgroundColor,
    dialogBackgroundColor: kCardBackgroundColor,
    canvasColor: kCardBackgroundColor,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.deepPurple,
      contentTextStyle: TextStyle(
        color: Colors.white,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final sessionConfig = SessionConfig(
      invalidateSessionForAppLostFocus: const Duration(seconds: 10),
      invalidateSessionForUserInactivity: const Duration(seconds: 10),
    );

    sessionConfig.stream.listen((SessionTimeoutState timeoutEvent) async {
      // stop listening, as user will already be in auth page
      sessionStateStream.add(SessionState.stopListening);
      if (timeoutEvent == SessionTimeoutState.userInactivityTimeout) {
        // handle user  inactive timeout
        await logout(context);
        Fluttertoast.showToast(
          msg: "Logged out because of user inactivity",
          gravity: ToastGravity.TOP,
        );
      } else if (timeoutEvent == SessionTimeoutState.appFocusTimeout) {
        // handle user  app lost focus timeout
        await logout(context);
        Fluttertoast.showToast(
          msg: "Logged out because app lost focus",
          gravity: ToastGravity.TOP,
        );
      }
    });

    return ChangeNotifierProvider<ProviderClass>(
      create: (context) => ProviderClass(),
      child: SessionTimeoutManager(
        userActivityDebounceDuration: const Duration(seconds: 1),
        sessionConfig: sessionConfig,
        sessionStateStream: sessionStateStream.stream,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: this.appTheme,
          darkTheme: this.appTheme,
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: InitialScreenHandler.id,
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseUtils.logoutUser();
    Provider.of<ProviderClass>(context, listen: false)
        .setDataToNull();
    Navigator.pushReplacementNamed(
        context, LoginScreen.id);
  }
}
