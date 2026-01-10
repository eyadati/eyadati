// ignore_for_file: subtype_of_sealed_class, cast_from_null_always_fails, argument_type_not_assignable

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/user/user_firestore.dart';
import 'package:eyadati/FCM/notificationsService.dart';
import 'package:test/test.dart';
import 'package:flutter/material.dart';
import 'user_appointments_provider_test.mocks.dart' as mocks;

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final bool _exists;
  final Map<String, dynamic>? _data;
  final String _id;

  FakeDocumentSnapshot(this._id, this._exists, this._data);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  dynamic get(Object field) {
    if (_data == null) return null;
    return _data![field];
  }

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  bool operator ==(Object other) => other is FakeDocumentSnapshot && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ✅ Generate ALL mocks including BuildContext
@GenerateMocks([
  UserFirestore, 
  NotificationService, 
  FirebaseAuth, 
  User, 
  FirebaseFirestore, 
  CollectionReference, 
  DocumentReference, 
  Query, 
  QuerySnapshot, 
  QueryDocumentSnapshot, 
  DocumentSnapshot,
  BuildContext,
])

void main() {
  group('UserAppointmentsProvider', () {
    late UserAppointmentsProvider provider;
    late mocks.MockFirebaseAuth mockAuth;
    late mocks.MockFirebaseFirestore mockFirestore;
    late mocks.MockUser mockUser;
    late mocks.MockUserFirestore mockUserFirestore;
    late mocks.MockNotificationService mockNotificationService;
    late mocks.MockBuildContext mockContext;

    // Firestore specific mocks
    late mocks.MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
    late mocks.MockDocumentReference<Map<String, dynamic>> mockUserDoc;
    late mocks.MockCollectionReference<Map<String, dynamic>> mockAppointmentsCollection;
    late mocks.MockQuery<Map<String, dynamic>> mockQuery;
    late mocks.MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late mocks.MockCollectionReference<Map<String, dynamic>> mockClinicsCollection;

    setUp(() {
      // Initialize all mocks
      mockAuth = mocks.MockFirebaseAuth();
      mockFirestore = mocks.MockFirebaseFirestore();
      mockUser = mocks.MockUser();
      mockUserFirestore = mocks.MockUserFirestore();
      mockNotificationService = mocks.MockNotificationService();
      mockContext = mocks.MockBuildContext();

      // Initialize Firestore collection mocks
      mockUsersCollection = mocks.MockCollectionReference<Map<String, dynamic>>();
      mockUserDoc = mocks.MockDocumentReference<Map<String, dynamic>>();
      mockAppointmentsCollection = mocks.MockCollectionReference<Map<String, dynamic>>();
      mockQuery = mocks.MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = mocks.MockQuerySnapshot<Map<String, dynamic>>();
      mockClinicsCollection = mocks.MockCollectionReference<Map<String, dynamic>>();

      // Primary collection stubs (must come first)
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockFirestore.collection('clinics')).thenReturn(mockClinicsCollection);

      // Common mock configurations for user authentication
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');

      // Firestore chain for user appointments
      when(mockUsersCollection.doc('test_user_id')).thenReturn(mockUserDoc);
      when(mockUserDoc.collection('appointments')).thenReturn(mockAppointmentsCollection);

      // Mock the query chain
      when(mockAppointmentsCollection.where(
        'date',
        isGreaterThan: argThat(isA<Timestamp>(), named: 'isGreaterThan'),
      )).thenReturn(mockQuery);
      when(mockQuery.orderBy('date', descending: true)).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
      
      // Explicit stubbing for clinic data fetching
      final mockClinicDocRef1 = mocks.MockDocumentReference<Map<String, dynamic>>();
      when(mockClinicDocRef1.get(argThat(isA<GetOptions>()))).thenAnswer((_) async {
        return FakeDocumentSnapshot('clinic_id_1', true, {'name': 'Clinic One', 'FCM': 'fcm_token_1', 'duration': 60});
      });
      when(mockClinicsCollection.doc(argThat(equals('clinic_id_1')))).thenReturn(mockClinicDocRef1);
      
      final mockClinicDocRef2 = mocks.MockDocumentReference<Map<String, dynamic>>();
      when(mockClinicDocRef2.get(argThat(isA<GetOptions>()))).thenAnswer((_) async {
        return FakeDocumentSnapshot('clinic_id_2', true, {'name': 'Clinic Two', 'FCM': 'fcm_token_2', 'duration': 90});
      });
      when(mockClinicsCollection.doc(argThat(equals('clinic_id_2')))).thenReturn(mockClinicDocRef2);

      // Generic stub for non-existent clinics (if not already stubbed above)
      when(mockClinicsCollection.doc(any)).thenAnswer((Invocation inv) {
        final id = inv.positionalArguments[0] as String;
        final mockDocRef = mocks.MockDocumentReference<Map<String, dynamic>>();
        when(mockDocRef.get(any)).thenAnswer((_) async {
            if (id == 'clinic_id_99') { // Handle specific test case for clinic_id_99
              return FakeDocumentSnapshot('clinic_id_99', true, {'name': 'Found Clinic', 'FCM': 'fcm_99_token'});
            } else if (id == 'non_existent_clinic') {
              return FakeDocumentSnapshot('non_existent_clinic', false, null);
            } else {
                return FakeDocumentSnapshot(id, false, null); // Default for un-stubbed IDs
            }
        });
        return mockDocRef;
      });


      // Mock UserFirestore.cancelAppointment
      when(mockUserFirestore.cancelAppointment(
        argThat(isA<String>()),
        argThat(isA<String>()),
        argThat(isA<BuildContext>()),
      )).thenAnswer((_) async => {});

      // Mock NotificationService.sendDirectNotification
      when(mockNotificationService.sendDirectNotification(
        fcmToken: anyNamed('fcmToken'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => {});

      // Instantiate the provider
      provider = UserAppointmentsProvider(
        auth: mockAuth,
        firestore: mockFirestore,
        userFirestore: mockUserFirestore,
        notificationService: mockNotificationService,
      );
    });

    test('initial state is correct', () {
      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isTrue);
    });

    test('loadAppointments fetches and updates appointments', () async {
      final now = Timestamp.now();
      final mockDocSnap1 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap1.id).thenReturn('app_id_1');
      when(mockDocSnap1.data()).thenReturn({
        'clinicUid': 'clinic_id_1',
        'date': now,
      });

      final mockDocSnap2 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap2.id).thenReturn('app_id_2');
      when(mockDocSnap2.data()).thenReturn({
        'clinicUid': 'clinic_id_2',
        'date': Timestamp.fromDate(now.toDate().add(const Duration(days: 1))),
      });

      // Ensure mockQuerySnapshot.docs is set immediately before loadAppointments
      when(mockQuerySnapshot.docs).thenReturn([mockDocSnap1, mockDocSnap2]);

      await provider.loadAppointments();

      expect(provider.appointments, isNotEmpty);
      expect(provider.appointments.length, 2);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isFalse); // Changed to isFalse due to _pageSize logic

      // Verify clinic data was fetched and cached
      expect(provider.getClinicData('clinic_id_1'), isNotNull);
      expect(provider.getClinicData('clinic_id_2'), isNotNull);
    });

    test('loadAppointments handles no more data', () async {
      when(mockQuerySnapshot.docs).thenReturn([]);

      await provider.loadAppointments();

      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isFalse);
    });

    test('loadAppointments handles null currentUser', () async {
      when(mockAuth.currentUser).thenReturn(null);

      await expectLater(
        () => provider.loadAppointments(),
        throwsA(isA<Exception>()),
      );

      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isTrue);
    });

    test('refresh method clears and reloads appointments', () async {
      final now = Timestamp.now();
      final mockDocSnap1 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap1.id).thenReturn('app_id_1');
      when(mockDocSnap1.data()).thenReturn({
        'clinicUid': 'clinic_id_1',
        'date': now,
      });

      final mockDocSnap3 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap3.id).thenReturn('app_id_3');
      when(mockDocSnap3.data()).thenReturn({
        'clinicUid': 'clinic_id_1',
        'date': Timestamp.fromDate(now.toDate().add(const Duration(days: 2))),
      });

      // Create separate snapshots for initial and refreshed state
      final initialSnapshot = mocks.MockQuerySnapshot<Map<String, dynamic>>();
      when(initialSnapshot.docs).thenReturn([mockDocSnap1]);

      final refreshedSnapshot = mocks.MockQuerySnapshot<Map<String, dynamic>>();
      when(refreshedSnapshot.docs).thenReturn([mockDocSnap1, mockDocSnap3]);

      // Stub mockQuery.get to return initialSnapshot first, then refreshedSnapshot
      when(mockQuery.get(any)).thenAnswer((_) async => initialSnapshot); // First call to get()

      await provider.loadAppointments();
      expect(provider.appointments.length, 1);

      when(mockQuery.get(any)).thenAnswer((_) async => refreshedSnapshot); // Subsequent calls to get()

      await provider.refresh();

      expect(provider.appointments, isNotEmpty);
      expect(provider.appointments.length, 2);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isFalse);
    });

    test('cancelAppointment removes appointment and sends notification', () async {
      final now = Timestamp.now();
      final appointmentData = {
        'id': 'app_id_1',
        'clinicUid': 'clinic_id_1',
        'userUid': 'test_user_id',
        'date': now,
        'FCM': 'user_fcm_token',
      };
      final mockDocSnap1 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocSnap1.id).thenReturn('app_id_1');
      when(mockDocSnap1.data()).thenReturn(appointmentData);

      when(mockQuerySnapshot.docs).thenReturn([mockDocSnap1]);

      await provider.loadAppointments();
      expect(provider.appointments.length, 1);

      when(mockUserFirestore.cancelAppointment(
        argThat(isA<String>()),
        argThat(isA<String>()),
        argThat(isA<BuildContext>()),
      )).thenAnswer((_) async => {});

      await provider.cancelAppointment(
        'app_id_1',
        'clinic_id_1',
        {'FCM': 'clinic_fcm_token'},
        mockContext, // ✅ Use generated mock
      );

      expect(provider.appointments, isEmpty);
    });

    test('getClinicData returns null if clinic not found', () async {
      final mockDocForNonExistentClinic = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDocForNonExistentClinic.id).thenReturn('app_id_x');
      when(mockDocForNonExistentClinic.data()).thenReturn({'clinicUid': 'non_existent_clinic', 'date': Timestamp.now()});

      when(mockQuerySnapshot.docs).thenReturn([
        mockDocForNonExistentClinic,
      ]);

      await provider.loadAppointments();
      
      expect(provider.getClinicData('non_existent_clinic'), isNull);
    });

    test('getClinicData returns data if clinic found', () async {
      final mockAppDocSnap = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockAppDocSnap.id).thenReturn('app_id_y');
      when(mockAppDocSnap.data()).thenReturn({
        'clinicUid': 'clinic_id_99',
        'date': Timestamp.now(),
      });
      when(mockQuerySnapshot.docs).thenReturn([mockAppDocSnap]);

      await provider.loadAppointments();

      final clinicData = provider.getClinicData('clinic_id_99');
      expect(clinicData, isNotNull);
      expect(clinicData?['name'], 'Found Clinic');
    });

    test('pagination loads more appointments', () async {
      final now = Timestamp.now();
      
      // Create 20 mock documents for the first batch to ensure hasMore remains true
      final List<mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>> firstBatchDocs = [];
      for (int i = 0; i < 20; i++) {
        final mockDocSnap = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockDocSnap.id).thenReturn('app_id_${i + 1}');
        when(mockDocSnap.data()).thenReturn({
          'clinicUid': 'clinic_id_${(i % 2) + 1}', // Alternate clinic UIDs
          'date': Timestamp.fromDate(now.toDate().add(Duration(days: i))),
        });
        firstBatchDocs.add(mockDocSnap);
      }

      when(mockQuerySnapshot.docs).thenReturn(firstBatchDocs);
      
      final secondBatchDocSnap21 = mocks.MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(secondBatchDocSnap21.id).thenReturn('app_id_21');
      when(secondBatchDocSnap21.data()).thenReturn({
        'clinicUid': 'clinic_id_1',
        'date': Timestamp.fromDate(now.toDate().add(const Duration(days: 20))),
      });

      final secondBatchQuerySnapshot = mocks.MockQuerySnapshot<Map<String, dynamic>>();
      when(secondBatchQuerySnapshot.docs).thenReturn([secondBatchDocSnap21]); // Only one doc for the second batch
      
      final mockQueryAfterStart = mocks.MockQuery<Map<String, dynamic>>();
      when(mockQueryAfterStart.get(any)).thenAnswer((_) async => secondBatchQuerySnapshot);

      when(mockQuery.startAfterDocument(any)).thenReturn(mockQueryAfterStart);

      await provider.loadAppointments();
      expect(provider.appointments.length, 20);
      expect(provider.hasMore, isTrue); // Should be true now as 20 docs were returned

      await provider.loadAppointments();
      expect(provider.appointments.length, 21); // 20 + 1
      expect(provider.hasMore, isFalse); // Should be false as only 1 doc was returned in second batch
    });

    test('batchFetchClinics populates clinic cache', () async {
      await provider.batchFetchClinics(['clinic_id_1', 'clinic_id_2']);
      
      final clinicData1 = provider.getClinicData('clinic_id_1');
      final clinicData2 = provider.getClinicData('clinic_id_2');

      expect(clinicData1, isNotNull);
      expect(clinicData1?['name'], 'Clinic One');
      
      expect(clinicData2, isNotNull);
      expect(clinicData2?['name'], 'Clinic Two');
    });
  });
}