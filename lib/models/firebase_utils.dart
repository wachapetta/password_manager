import 'dart:io';

import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encryptor/encryptor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert'; // for the utf8.encode method

import 'package:password_manager/constants.dart';
import 'package:password_manager/models/exceptions.dart';

class FirebaseUtils {
  //preventing the class from being instantiated
  FirebaseUtils._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //static const int LEVELS_OF_ENCRYPTION = 5;

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadFile(String userId, File image) async {
    try {
      //UploadTask uploadTask =
          await _storage.ref().child('Profile Pictures/$userId.png').putFile(image);

      String fileURL = await _storage
          .ref()
          .child('Profile Pictures/$userId.png')
          .getDownloadURL();
      return fileURL;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static Future<String> updateProfilePicture(
      {String userId, String oldImageURL, File newImage}) async {
    try {
      if (oldImageURL != kDefaultProfilePictureURL) {
        Reference photoRef =
            await _storage.refFromURL(oldImageURL);
        await photoRef.delete();
      }

      String newFileURL = await uploadFile(userId, newImage);
      await _firestore.collection("data").doc(userId).update({
        'profilePicURL': newFileURL,
      });

      return newFileURL;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  static Future<void> removeProfilePicture(
      {String userId, String oldImageURL}) async {
    try {
      if (oldImageURL != kDefaultProfilePictureURL) {
        Reference photoRef =
            await _storage.refFromURL(oldImageURL);
        await photoRef.delete();

        await _firestore.collection("data").doc(userId).update({
          'profilePicURL': FieldValue.delete(),
        });
      }
    } catch (e) {
      print(e.toString());
      return;
    }
  }

  static Future<User> getCurrentUser() async {
    try {
      final User currentUser = await _auth.currentUser;
      if (currentUser != null && currentUser.emailVerified)
        return currentUser;
      else
        return null;
    } catch (e) {
      print("ERROR WHILE GETTING CURRENT USER : $e");
      return null;
    }
  }

  static Future<String> getCurrentUserEmail() async {
    try {
      final User user = await getCurrentUser();
      if (user != null) {
        return user.email;
      } else
        return "";
    } catch (e) {
      print("ERROR WHILE GETTING CURRENT USER EMAIL : $e");
      return "";
    }
  }

  static Future<Map<String, dynamic>> getAppData(
      User currentUser) async {
    List<Map<String, dynamic>> passwords = [];
    String fullName;
    String key;
    String profilePicURL;

    try {
      developer.log('user document retrieved befor');
      final DocumentSnapshot dataSnapshot =
          await _firestore.collection("data").doc(currentUser.uid).get();

      developer.log('user document retrieved after');

      if (dataSnapshot.data == null) {
        fullName = "";
        key = "";
        profilePicURL = kDefaultProfilePictureURL;
        developer.log('user prpo if');
      } else {

        Map<String, dynamic> dt = dataSnapshot.data() as Map<String, dynamic>;
        fullName = dt['fullName'];
        key = dt['key'];
        profilePicURL = dt['profilePicURL'] ?? kDefaultProfilePictureURL;
        developer.log('user props esle');
      }

      developer.log('user props read');

      final documentSnapshot = await _firestore
          .collection("data")
          .doc(currentUser.uid)
          .collection("passwords")
          .orderBy('Title')
          .get();

      developer.log('pwds retrieved');

      for (var document in documentSnapshot.docs) {
        Map<String, dynamic> data = document.data();
        // decrypting password
        if (data.containsKey('Password'))
          data['Password'] = await _decryptPassword(data['Password'], key);
        passwords.add(data);
      }
      developer.log('pwds read');

      final Map<String, dynamic> appData = {
        'name': fullName,
        'passwords': passwords,
        'key': key,
        'profilePicURL': profilePicURL,
      };

      return appData;
    } catch (e) {
      print("ERROR WHILE GETTING APP DATA : $e");
      throw AppDataReceiveException(
          "An error occurred while fetching data. Please restart the app or try deleting the account and creating a new one !");
    }
  }

  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("ERROR WHILE SENDING PASSWORD RESET EMAIL : $e");
      throw ForgotPasswordException(e.message);
    }
  }

  static Future<bool> resendEmailVerificationLink(
      String email, String password) async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (user != null) {
        await user.user.sendEmailVerification();
        return true;
      } else
        return false;
    } catch (e) {
      print("ERROR WHILE RE SENDING EMAIL VERIFICATION LINK : $e");
      return false;
    }
  }

  static Future<bool> registerUser(String email, String password,
      {String fullName, File image}) async {
    try {
      final UserCredential user = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      String profilePicURL = kDefaultProfilePictureURL;
      if (image != null) profilePicURL = await uploadFile(user.user.uid, image);

      await user.user.sendEmailVerification();

      if (user != null) {

        Digest key = sha256.convert(utf8.encode(password));
        final String _key = '$key';

        developer.log('key: $_key');

        // creating document for new user
        if (profilePicURL == kDefaultProfilePictureURL)
          await _firestore.collection("data").doc(user.user.uid).set({
            "fullName": fullName,
            "key": _key,
          });
        else
          await _firestore.collection("data").doc(user.user.uid).set({
            "fullName": fullName,
            "key": _key,
            "profilePicURL": profilePicURL,
          });
        return true;
      } else
        return false;
    } catch (e) {
      print("EXCEPTION WHILE REGISTERING NEW USER : $e");
      throw RegisterException(e.message);
    }
  }

  static Future<bool> loginUser(String email, String password) async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (user != null) {
        if (user.user.emailVerified)
          return true;
        else
          throw LoginException("EMAIL_NOT_VERIFIED");
      } else
        return false;
    } catch (e) {
      print("EXCEPTION WHILE LOGGING IN USER : $e");
      throw LoginException(e.message);
    }
  }

  static Future<bool> logoutUser() async {
    try {
      _auth.signOut();
      return true;
    } catch (e) {
      print("EXCEPTION WHILE LOGGING OUT USER : $e");
      return false;
    }
  }

  static Future<String> addPasswordFieldToDatabase(Map<String, dynamic> _fields,
      User currentUser, String key) async {
    // check if empty map is not received
    if (_fields.isNotEmpty)
      try {
        final String userId = currentUser.uid;

        Map<String, dynamic> fields = Map<String, dynamic>.from(_fields);

        String docID = _firestore
            .collection("data")
            .doc(userId)
            .collection("passwords")
            .doc().id;

        //adding documentId to fields
        fields.addAll({
          "documentId": docID,
        });

        //encrypting passwords before sending to firebase
        if (fields['Password'] != null && fields['Password'] != "")
          fields['Password'] = await _encryptPassword(fields['Password'], key);
        else
          fields.remove('Password');

        //setting the value of the new document with fields
        await _firestore
            .collection("data")
            .doc(userId)
            .collection("passwords")
            .doc(fields['documentId'])
            .set(fields);

        return docID;
      } catch (e) {
        print("ERROR WHILE ADDING NEW PASSWORD : $e");
        return null;
      }
    else
      //fields is empty
      return null;
  }

  static Future<bool> editPasswordFieldInDatabase(
      Map<String, dynamic> newFields,
      User currentUser,
      String key) async {
    try {
      final String userId = currentUser.uid;

      Map<String, dynamic> fields = Map<String, dynamic>.from(newFields);

      //encrypting passwords before sending to firebase
      if (fields.containsKey('Password'))
        fields['Password'] = await _encryptPassword(fields['Password'], key);

      // adding new data
      await _firestore
          .collection("data")
          .doc(userId)
          .collection("passwords")
          .doc(newFields['documentId'])
          .set(fields, SetOptions(merge: false));

      return true;
    } catch (e) {
      print("ERROR WHILE UPDATING PASSWORD $e");
      return false;
    }
  }

  static Future<bool> deletePasswordFieldFromDatabase(
      String documentId, User currentUser) async {
    try {
      final String userId = currentUser.uid;

      await _firestore
          .collection("data")
          .doc(userId)
          .collection("passwords")
          .doc(documentId)
          .delete();

      return true;
    } catch (e) {
      print("ERROR WHILE DELETING PASSWORD $e");
      return false;
    }
  }

  static Future<bool> changeCurrentUserName(
      String name, User currentUser) async {
    try {
      await _firestore
          .collection("data")
          .doc(currentUser.uid)
          .set({"fullName": name}, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("ERROR WHILE CHANGING CURRENT USER NAME : $e");
      return false;
    }
  }

  static Future<bool> changeCurrentUserPassword(
      String oldPassword, String newPassword) async {
    try {
      final User user = await getCurrentUser();

      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email, password: oldPassword);
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print("ERROR WHILE CHANGING CURRENT USER PASSWORD : $e");
      throw ChangePasswordException(e.message);
    }
  }

  static Future<bool> changeCurrentUserEmail(
      {String newEmail, String password}) async {
    try {
      final User user = await getCurrentUser();

      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email, password: password);
      await user.reauthenticateWithCredential(credential);

      await user.updateEmail(newEmail);

      await user.sendEmailVerification();
      return true;
    } catch (e) {
      print("ERROR WHILE CHANGING CURRENT USER EMAIL : $e");
      throw ChangePasswordException(e.message);
    }
  }

  static Future<bool> deleteCurrentUser(
      {String oldImageURL, String password}) async {
    try {
      final User user = await getCurrentUser();

      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email, password: password);
      await user.reauthenticateWithCredential(credential);

      if (user != null) {
        // deleting image from storage
        if (oldImageURL != kDefaultProfilePictureURL) {
          Reference photoRef =
          await _storage.refFromURL(oldImageURL);
          await photoRef.delete();
        }

        // deleting passwords
        final passwordsSnapshot = await _firestore
            .collection("data")
            .doc(user.uid)
            .collection("passwords")
            .get();

        for (var passwordField in passwordsSnapshot.docs)
          await _firestore
              .collection("data")
              .doc(user.uid)
              .collection("passwords")
              .doc((passwordField.data as Map<String,dynamic>)['documentId'])
              .delete();

        // deleting users document
        await _firestore.collection("data").doc(user.uid).delete();
        // deleting user
        await user.delete();
      }
      return true;
    } catch (e) {
      print("ERROR WHILE DELETING USER : $e");
      throw DeleteUserException(e.message);
    }
  }

   static Future<String> _encryptPassword(String password, String _key) async {

    try{
        String encrypted = Encryptor.encrypt(_key, password);
        password = encrypted;

    } catch (e) {
      print("ERROR WHILE ENCRYPTING PASSWORD : $e");
    }
    return password;
  }

  static Future<String> _decryptPassword(String password, String _key) async {
    try {

      String decrypted = Encryptor.decrypt(_key, password);

      password = decrypted;

    } catch (e) {
      print("ERROR WHILE DECRYPTING PASSWORD : $e");
    }
    return password;
  }
}
