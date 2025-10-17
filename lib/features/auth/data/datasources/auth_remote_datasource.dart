import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<bool> checkIfUserExists(String phoneNumber);
  Future<UserModel> verifyOtpAndLogin(String otp);
  Future<void> saveUserProfile(String uid, String phoneNumber, String name, String voiceProfileUrl);
  Future<String> storeUserVoiceProfile(String uid, List<int> voiceProfileBytes);
  Future<String?> getRemoteUserVoiceProfile(String uid);
  Future<List<int>?> downloadUserVoiceProfile(String uid);
  Future<void> deleteRemoteVoiceProfile(String uid);
  Future<UserModel> getUserData(String uid);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  String? _verificationId;

  AuthRemoteDataSourceImpl({required this.auth, required this.firestore, required this.storage});

  @override
  Future<bool> checkIfUserExists(String phoneNumber) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ServerException('فشل التحقق من وجود المستخدم.');
    }
  }

  @override
  Future<UserModel> verifyOtpAndLogin(String otp) async {
    if (_verificationId == null) {
      throw const ServerException('لم يتم إرسال رمز التحقق بعد.');
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null && firebaseUser.phoneNumber != null) {
        final querySnapshot = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: firebaseUser.phoneNumber!)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return UserModel.fromJson(querySnapshot.docs.first.data());
        } else {
          return UserModel(
            uid: firebaseUser.uid,
            name: '',
            phoneNumber: firebaseUser.phoneNumber!,
          );
        }
      } else {
        throw const ServerException('فشل تسجيل الدخول: المستخدم غير موجود.');
      }
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'رمز التحقق خاطئ أو انتهت صلاحيته.');
    } catch (e) {
      throw ServerException('فشل التحقق من الرمز: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUserProfile(String uid, String phoneNumber, String name, String voiceProfileUrl) async {
    try {
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'phoneNumber': phoneNumber,
      });
    } on FirebaseException catch (e) {
      throw ServerException('فشل حفظ بيانات المستخدم في Firestore: ${e.message}');
    }
  }

  @override
  Future<String> storeUserVoiceProfile(String uid, List<int> voiceProfileBytes) async {
    try {
      final profileRef = storage.ref().child('users').child(uid).child('voice_profile.bin');
      await profileRef.putData(Uint8List.fromList(voiceProfileBytes));
      final downloadUrl = await profileRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException('فشل في رفع ملف الصوت إلى Firebase Storage: ${e.message}');
    }
  }

  @override
  Future<String?> getRemoteUserVoiceProfile(String uid) async {
    try {
      final profileRef = storage.ref().child('users').child(uid).child('voice_profile.bin');
      return await profileRef.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<int>?> downloadUserVoiceProfile(String uid) async {
    try {
      final profileRef = storage.ref().child('users').child(uid).child('voice_profile.bin');
      final data = await profileRef.getData();
      return data?.toList();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteRemoteVoiceProfile(String uid) async {
    final profileRef = storage.ref().child('users').child(uid).child('voice_profile.bin');
    await profileRef.delete();
  }

  @override
  Future<UserModel> getUserData(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        throw const ServerException('User not found');
      }
    } catch (e) {
      throw ServerException('Failed to get user data: $e');
    }
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }
}
