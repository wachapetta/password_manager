
import 'package:flutter/material.dart';
import 'package:password_manager/models/functions.dart';
import 'package:password_manager/models/provider_class.dart';
import 'package:password_manager/screens/app_screens/show_generated_passwords.dart';
import 'package:password_manager/widgets/my_slider_card.dart';
import 'package:password_manager/widgets/my_switch_card.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;


import 'package:random_password_generator/random_password_generator.dart';

import '../../models/network_helper.dart';

//void main() => runApp(PasswordGenerator());

class PasswordGenerator extends StatefulWidget {
  @override
  _PasswordGeneratorState createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  //String url;
  bool upper = true, lower = true, numbers = true, special = true;
  int length = 15, repeat = 10;

  String getStringFromBoolean(bool boolean) => boolean ? "on" : "off";

  final String _uppercaseLettersSubtitle = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final String _lowercaseLettersSubtitle = "abcdefghijklmnopqrstuvwxyz";
  final String _numbersSubtitle = "0123456789";
  final String _specialCharactersSubtitle =
      "( < > ` ! ? @ # \$ % ^ & * ( ) . , _ - )";

  final passwordGen = RandomPasswordGenerator();

  @override
  Widget build(BuildContext context) {

    return Consumer<ProviderClass>(
      builder: (context, data, child) {
        return SafeArea(
          child: Scaffold(
            body: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overScroll) {
                  overScroll.disallowIndicator();
                  return;
                },
                child: ListView(
                  children: <Widget>[
                    MySwitchCard(
                      title: "Uppercase Letters",
                      subtitle: this._uppercaseLettersSubtitle,
                      currentValue: upper,
                      onChanged: (bool newValue) {
                        setState(() {
                          upper = newValue;
                        });
                      },
                    ),
                    MySwitchCard(
                      title: "Lowercase Letters",
                      subtitle: this._lowercaseLettersSubtitle,
                      currentValue: lower,
                      onChanged: (bool newValue) {
                        setState(() {
                          lower = newValue;
                        });
                      },
                    ),
                    MySwitchCard(
                      title: "Numbers",
                      currentValue: numbers,
                      subtitle: this._numbersSubtitle,
                      onChanged: (bool newValue) {
                        setState(() {
                          numbers = newValue;
                        });
                      },
                    ),
                    MySwitchCard(
                      title: "Special Characters",
                      currentValue: special,
                      subtitle: this._specialCharactersSubtitle,
                      onChanged: (bool newValue) {
                        setState(() {
                          special = newValue;
                        });
                      },
                    ),
                    MySliderCard(
                      title: "Password Length",
                      value: length,
                      onChanged: (double newValue) {
                        setState(() {
                          length = newValue.round();
                        });
                      },
                    ),
                    MySliderCard(
                      title: "Number of Passwords",
                      value: repeat,
                      onChanged: (double newValue) {
                        setState(() {
                          repeat = newValue.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.check),
              onPressed: () async {
                // if all values are false
                if (!upper && !lower && !numbers && !special) {
                  Functions.showSnackBar(
                      context, "No Content Is Chosen for the Password !",
                      duration: Duration(seconds: 4));
                } else {

                  data.startLoadingScreenOnMainAppScreen();
                  bool localGeneration = false;//Random().nextBool();
                  List<String> passwordsFromAPI = [];

                  if(localGeneration) {
                    for (int i = 0; i < repeat; i++)
                      passwordsFromAPI.add(passwordGen.randomPassword(
                          letters: lower,
                          uppercase: upper,
                          numbers: numbers,
                          specialChar: special,
                          passwordLength: length.toDouble()));
                    developer.log('locally generated passwd(s)');
                  }
                  else{
                    Map<String, String> params = {
                      'upper': getStringFromBoolean(upper),
                      'lower': getStringFromBoolean(lower),
                      'numbers':getStringFromBoolean(numbers),
                      'special':getStringFromBoolean(special),
                      'length': length.toString(),
                      'repeat': repeat.toString()
                    };
                    //String paramStr = '?upper=${params['upper']}&lower=${params['lower']}&numbers=${params['numbers']}&special=${params['special']}&length=${params['length']}&repeat=${params['repeat']}';
                    passwordsFromAPI =
                    await NetworkHelper.getData('southamerica-east1-pwd-manager-90267.cloudfunctions.net','/externalPwdGeneratorProxy',params);
                    developer.log('distributed generated passwd(s)');
                  }
                  showModalBottomSheet(
                      context: context,
                      builder: (context) =>
                          ShowGeneratedPasswordsScreen(passwordsFromAPI));

                  data.stopLoadingScreenOnMainAppScreen();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
