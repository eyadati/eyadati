import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eyadati/clinic/clinic_firestore.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('ClinicFirestore - Clinic Visibility', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late ClinicFirestore clinicFirestore;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockFirestore.collection('clinics')).thenReturn(mockCollection);
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('clinic123'); // Mock a logged-in user

      clinicFirestore = ClinicFirestore(
        firestore: mockFirestore,
        firebaseAuth: mockFirebaseAuth,
      );
    });

    test('getAvailableClinics should filter out paused clinics', () async {
      // Arrange
      final activeClinicData = {
        'uid': 'clinic1',
        'clinicName': 'Active Clinic',
        'paused': false,
      };
      final pausedClinicData = {
        'uid': 'clinic2',
        'clinicName': 'Paused Clinic',
        'paused': true,
      };

      final mockQueryDocumentSnapshot1 = MockQueryDocumentSnapshot();
      when(mockQueryDocumentSnapshot1.data()).thenReturn(activeClinicData);
      when(mockQueryDocumentSnapshot1.id).thenReturn('clinic1');

      final mockQueryDocumentSnapshot2 = MockQueryDocumentSnapshot();
      when(mockQueryDocumentSnapshot2.data()).thenReturn(pausedClinicData);
      when(mockQueryDocumentSnapshot2.id).thenReturn('clinic2');

      final mockQuerySnapshot = MockQuerySnapshot();
      when(
        mockQuerySnapshot.docs,
      ).thenReturn([mockQueryDocumentSnapshot1, mockQueryDocumentSnapshot2]);

      // Mock the query that filters by 'paused' status
      final mockQueryWhere = MockQuery();
      when(
        mockCollection.where('paused', isEqualTo: false),
      ).thenReturn(mockQueryWhere);
      when(
        mockQueryWhere.snapshots(),
      ).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      // Act
      // We expect this method to filter out paused clinics
      // The actual implementation of getAvailableClinics will be added in ClinicFirestore
      // This test will fail until getAvailableClinics is implemented correctly
      final resultStream = clinicFirestore.getAvailableClinics();

      // Assert
      await expectLater(resultStream, emits([activeClinicData]));
    });
  });
}
