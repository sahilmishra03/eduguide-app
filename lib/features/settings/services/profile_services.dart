import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// The UserProfile model now includes a field for the photo URL.
class UserProfile {
  String name;
  String mobileNumber;
  String email;
  String college;
  String course;
  String branch;
  String yearOfPassing;
  String photoUrl; // <-- NEW FIELD

  UserProfile({
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.college,
    required this.course,
    required this.branch,
    required this.yearOfPassing,
    required this.photoUrl, // <-- ADDED TO CONSTRUCTOR
  });

  // Converts a Firestore document into a UserProfile object
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      name: data['name'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'] ?? '',
      college: data['college'] ?? '',
      course: data['course'] ?? '',
      branch: data['branch'] ?? '',
      yearOfPassing: data['yearOfPassing'] ?? '',
      photoUrl: data['photoUrl'] ?? '', // <-- GET PHOTO URL
    );
  }

  // Converts a UserProfile object into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'college': college,
      'course': course,
      'branch': branch,
      'yearOfPassing': yearOfPassing,
      'photoUrl': photoUrl, // <-- ADD PHOTO URL TO JSON
    };
  }
}

// The service now includes logic for uploading images to Firebase Storage.
class ProfileService {
  final UsersService _usersService = UsersService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserProfile> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final doc = await _usersService.readUser(user.uid);

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    } else {
      throw Exception('User profile does not exist in the database.');
    }
  }

  // --- NEW METHOD TO UPLOAD IMAGE ---
  // Takes an image file, uploads it, and returns the download URL.
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Image upload failed: $e");
      throw Exception('Failed to upload profile image.');
    }
  }
  // ---------------------------------

  Future<bool> saveUserProfile(UserProfile userProfile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');
    try {
      await _usersService.updateUser(user.uid, userProfile.toJson());
      return true;
    } catch (e) {
      print('Error saving profile: $e');
      return false;
    }
  }
}
