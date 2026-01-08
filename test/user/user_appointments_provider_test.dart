import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/user/user_appointments.dart';

// Mock Firebase and Firestore dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuery extends Mock implements Query {}

void main() {
  group('UserAppointmentsProvider', () {
    late UserAppointmentsProvider provider;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockAppointmentsCollection;
    late MockQuery mockQuery;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockAppointmentsCollection = MockCollectionReference();
      mockQuery = MockQuery();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc('test_user_id')).thenReturn(mockUserDoc);
      when(mockUserDoc.collection('appointments')).thenReturn(mockAppointmentsCollection);
      when(mockAppointmentsCollection.where(any, isGreaterThan: anyNamed('isGreaterThan')))
          .thenReturn(mockQuery);
      when(mockQuery.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);

      provider = UserAppointmentsProvider(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('initial state is correct', () {
      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isTrue);
    });

    test('loadAppointments fetches and updates appointments', () async {
      // Mock snapshot with some data
      final mockSnapshot = MockQuerySnapshot();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockDoc2 = MockQueryDocumentSnapshot();

      when(mockDoc1.id).thenReturn('appointment_id_1');
      when(mockDoc1.data()).thenReturn({
        'clinicUid': 'clinic_id_1',
        'date': Timestamp.now(),
      });
      when(mockDoc2.id).thenReturn('appointment_id_2');
      when(mockDoc2.data()).thenReturn({
        'clinicUid': 'clinic_id_2',
        'date': Timestamp.now(),
      });

      when(mockSnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockSnapshot.isEmpty).thenReturn(false);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      // Mock clinic data fetching
      final mockClinicDoc1 = MockDocumentSnapshot();
      when(mockClinicDoc1.exists).thenReturn(true);
      when(mockClinicDoc1.data()).thenReturn({'clinicName': 'Clinic One'});
      when(mockFirestore.collection('clinics').doc('clinic_id_1').get())
          .thenAnswer((_) async => mockClinicDoc1);

      final mockClinicDoc2 = MockDocumentSnapshot();
      when(mockClinicDoc2.exists).thenReturn(true);
      when(mockClinicDoc2.data()).thenReturn({'clinicName': 'Clinic Two'});
      when(mockFirestore.collection('clinics').doc('clinic_id_2').get())
          .thenAnswer((_) async => mockClinicDoc2);

      await provider.loadAppointments();

      expect(provider.appointments, isNotEmpty);
      expect(provider.appointments.length, 2);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isTrue); // Assuming more data could exist
      expect(provider.getClinicData('clinic_id_1'), isNotNull);
      expect(provider.getClinicData('clinic_id_2'), isNotNull);
    });

    test('loadAppointments handles no more data', () async {
      final mockSnapshot = MockQuerySnapshot();
      when(mockSnapshot.docs).thenReturn([]);
      when(mockSnapshot.isEmpty).thenReturn(true);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      await provider.loadAppointments();

      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isFalse);
    });

    // Add more tests for:
    // - error handling in loadAppointments
    // - refresh method
    // - cancelAppointment method (requires mocking UserFirestore and NotificationService)
    // - pagination logic
  });
}
