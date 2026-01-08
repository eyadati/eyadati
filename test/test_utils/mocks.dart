import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  QuerySnapshot,
  QueryDocumentSnapshot,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Query,
])
void main() {} // Required for build_runner to find annotations