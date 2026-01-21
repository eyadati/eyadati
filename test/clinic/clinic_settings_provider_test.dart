import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eyadati/clinic/clinic_firestore.dart';
import 'package:eyadati/clinic/clinicSettingsPage.dart'; // Import the provider
// For ChangeNotifier

// Mock classes (re-use from clinic_visibility_test.dart if possible, or define here)
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

// Mock function for notifyListeners
class MockFunction extends Mock {
  void call();
}

void main() {
  group('ClinicsettingProvider', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocumentReference;
    late MockDocumentSnapshot mockDocumentSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCollection = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testClinicUid');
      when(mockFirestore.collection('clinics')).thenReturn(mockCollection);
      when(
        mockCollection.doc('testClinicUid'),
      ).thenReturn(mockDocumentReference);
    });

    test('isPaused is initialized correctly from Firestore', () async {
      // Arrange
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.data()).thenReturn({'paused': true});
      when(mockDocumentSnapshot.exists).thenReturn(true);

      // Act
      final clinicSettingProvider = ClinicsettingProvider();
      // The constructor already calls _loadPauseStatus, so no need to call manually
      await Future.value(); // Allow microtasks to complete for _loadPauseStatus

      // Assert
      expect(clinicSettingProvider.isPaused, true);
    });

    test(
      'togglePauseStatus updates isPaused and calls notifyListeners',
      () async {
        // Arrange
        when(
          mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.data()).thenReturn({'paused': false});
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(
          mockDocumentReference.update(any),
        ).thenAnswer((_) async => Future.value()); // Mock update call

        final clinicSettingProvider = ClinicsettingProvider();
        await Future.value(); // Allow microtasks to complete for _loadPauseStatus

        final listener = MockFunction();
        clinicSettingProvider.addListener(listener);

        // Act
        await clinicSettingProvider.togglePauseStatus(true);

        // Assert
        expect(clinicSettingProvider.isPaused, true);
        verify(listener()).called(1); // Verify notifyListeners was called
        verify(
          mockDocumentReference.update({'paused': true}),
        ).called(1); // Verify Firestore update
      },
    );

    test(
      'togglePauseStatus sets isPaused to false and calls notifyListeners',
      () async {
        // Arrange
        when(
          mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.data()).thenReturn({'paused': true});
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(
          mockDocumentReference.update(any),
        ).thenAnswer((_) async => Future.value()); // Mock update call

        final clinicSettingProvider = ClinicsettingProvider();
        await Future.value(); // Allow microtasks to complete for _loadPauseStatus

        final listener = MockFunction();
        clinicSettingProvider.addListener(listener);

        // Act
        await clinicSettingProvider.togglePauseStatus(false);

        // Assert
        expect(clinicSettingProvider.isPaused, false);
        verify(listener()).called(1); // Verify notifyListeners was called
        verify(
          mockDocumentReference.update({'paused': false}),
        ).called(1); // Verify Firestore update
      },
    );
  });

  group('ClinicFirestore', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocumentReference;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late ClinicFirestore clinicFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();

      when(mockFirestore.collection('clinics')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocumentReference);

      clinicFirestore = ClinicFirestore(firestore: mockFirestore);
    });

    test('getClinicData returns clinic data', () async {
      // Arrange
      final clinicData = {'uid': 'clinic123', 'paused': false};
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.data()).thenReturn(clinicData);
      when(mockDocumentSnapshot.exists).thenReturn(true);

      // Act
      final result = await clinicFirestore.getClinicData('clinic123');

      // Assert
      expect(result, clinicData);
    });

    test('updateClinicPauseStatus updates the paused field', () async {
      // Arrange
      when(
        mockDocumentReference.update(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await clinicFirestore.updateClinicPauseStatus('clinic123', true);

      // Assert
      verify(mockDocumentReference.update({'paused': true})).called(1);
    });
  });
}
