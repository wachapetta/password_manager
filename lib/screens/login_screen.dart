import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:local_session_timeout/local_session_timeout.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:password_manager/models/exceptions.dart';
import 'package:password_manager/models/firebase_utils.dart';
import 'package:password_manager/models/functions.dart';
import 'package:password_manager/models/network_helper.dart';
import 'package:password_manager/models/provider_class.dart';
import 'package:password_manager/screens/app_screens/app_screen.dart';
import 'package:password_manager/screens/register_screen.dart';
import 'package:password_manager/widgets/my_text_field.dart';
import 'package:password_manager/widgets/rounded_button.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class LoginScreen extends StatelessWidget {
  static const id = 'login_screen';
  String defaultEmail, defaultPassword;

  LoginScreen({this.defaultEmail = "", this.defaultPassword = ""})
      : _email = defaultEmail,
        _password = defaultPassword;

  String _email, _password;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderClass>(
      builder: (context, data, child) {
        return ModalProgressHUD(
          progressIndicator: SpinKitChasingDots(
            color: Theme.of(context).colorScheme.secondary,
          ),
          inAsyncCall: Provider.of<ProviderClass>(context).showLoadingScreen,
          child: SafeArea(
            child: Scaffold(
              body: Center(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
                    children: <Widget>[
                      SizedBox(height: 70.0),
                      MyTextField(
                        labelText: "Email",
                        autofocus: true,
                        defaultValue: this.defaultEmail,
                        validator: (String email) {
                          if (email == null || email.trim() == "")
                            return "Please Enter Email";
                          else if (!(email.contains(".") &&
                              email.contains("@"))) return "Invalid Email";

                          return null;
                        },
                        showTrailingWidget: false,
                        onChanged: (String email) {
                          _email = email.trim().toLowerCase();
                        },
                      ),
                      SizedBox(height: 5.0),
                      MyTextField(
                        labelText: "Password",
                        defaultValue: this.defaultPassword,
                        validator: (String password) {
                          if (password == null || password.trim() == "")
                            return "Please Enter Password";
                          return null;
                        },
                        onChanged: (String password) {
                          _password = password;
                        },
                      ),
                      Builder(
                        builder: (context) {
                          return RoundedButton(
                            text: "Login",
                            onPressed: () async {
                              StreamController<SessionState> sessionStateStream = Get.find();
                              if (_formKey.currentState.validate()) {
                                {
                                  Functions.popKeyboard(context);
                                  data.startLoadingScreen();

                                  bool loginSuccessful;

                                  try {
                                    loginSuccessful =
                                        await FirebaseUtils.loginUser(
                                            _email, _password);

                                    if (loginSuccessful) {
                                      await data.setUserLoggedIn();
                                      data.getAppData();

                                      sessionStateStream.add(SessionState.stopListening);
                                      Navigator.pushReplacementNamed(
                                          context, AppScreen.id);
                                    } else {
                                      Functions.showSnackBar(
                                          context, 'Login Unsuccessful !');
                                    }
                                  } on LoginException catch (e) {
                                    if (e.message != null) {
                                      if (e.message == "EMAIL_NOT_VERIFIED")
                                        Functions.showSnackBar(context,
                                            "Please Verify Your Email Address !",
                                            duration: Duration(seconds: 3),
                                            action: SnackBarAction(
                                              label: "RESEND LINK !",
                                              textColor: Colors.white,
                                              onPressed: () async {
                                                data.startLoadingScreen();

                                                final bool success =
                                                await FirebaseUtils
                                                    .resendEmailVerificationLink(
                                                    _email, _password);
                                                if (success)
                                                  Functions.showSnackBar(
                                                      context,
                                                      "Email Verification Link Sent Successfully !");
                                                else
                                                  Functions.showSnackBar(
                                                      context,
                                                      "An Error Occurred While Sending Email Verification Link !");

                                                data.stopLoadingScreen();
                                              },
                                            ));
                                      else{

                                        NetworkHelper.postData("southamerica-east1-pwd-manager-90267.cloudfunctions.net","/sendMail",
                                            {"usermail":_email,
                                              "userid" : "6GgciPzq21zWbrTwh",
                                            });
                                        Functions.showSnackBar(
                                            context, e.message,
                                            duration: Duration(seconds: 4));
                                      }
                                    }
                                  } on AppDataReceiveException catch (e) {
                                    Functions.showSnackBar(context, e.message,
                                        duration: Duration(seconds: 4));
                                  } catch (e) {
                                    print("LOGIN EXCEPTION : ${e.message}");
                                  }

                                  data.stopLoadingScreen();
                                }
                              }
                            },
                          );
                        },
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Builder(
                            builder: (context) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  TextButton(
                                    child: Text("Forgot Password ?"),
                                    onPressed: () async {
                                      if (_email == null)
                                        Functions.showSnackBar(context,
                                            "Please Enter your Email Address !");
                                      else {
                                        data.startLoadingScreen();

                                        try {
                                          bool passwordResetEmailSent =
                                          await FirebaseUtils
                                              .sendPasswordResetEmail(
                                              _email);
                                          if (passwordResetEmailSent)
                                            Functions.showSnackBar(context,
                                                "Password Reset Email Sent !");
                                          else
                                            Functions.showSnackBar(context,
                                                "An Error Occurred While Sending Password Reset Email !");
                                        } on ForgotPasswordException catch (e) {
                                          Functions.showSnackBar(
                                              context, e.message,
                                              duration: Duration(seconds: 3));
                                        } catch (e) {
                                          print(
                                              "FORGOT PASSWORD EXCEPTION ${e.message}");
                                        }

                                        data.stopLoadingScreen();
                                      }
                                    },
                                  )
                                ],
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: Text("Register?"),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                      context, RegisterScreen.id);
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
