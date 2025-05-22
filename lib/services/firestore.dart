import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jadwal/models/current_weekday.dart';
import 'package:jadwal/models/hifdh.dart';
import 'package:jadwal/models/plan.dart';
import 'package:jadwal/models/review.dart';
import 'package:jadwal/services/connectivity_service.dart';
import 'package:jadwal/services/achievement_service.dart';
import 'dart:math';

class FirestoreService extends ChangeNotifier {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference surahsCollection =
      FirebaseFirestore.instance.collection('surahs');
  final CollectionReference versesCollection =
      FirebaseFirestore.instance.collection('verses');
  final CollectionReference pagesCollection =
      FirebaseFirestore.instance.collection('pages');

  final FirebaseAuth auth;
  final String uid;
  final ConnectivityService? connectivityService;
  bool _isOfflineMode = false;

  bool get isOfflineMode => _isOfflineMode;

  FirestoreService(
      {required this.auth, required this.uid, this.connectivityService}) {
    final User? user = auth.currentUser;
    if (user == null && uid.isNotEmpty) {
      throw Exception('User not authenticated');
    }

    // Configure Firestore for offline persistence
    FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

    // Listen to connectivity changes if service is provided
    connectivityService?.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (connectivityService != null) {
      _isOfflineMode = !connectivityService!.isConnected;
      notifyListeners();
    }
  }

  DocumentReference get userDocument => usersCollection.doc(uid);

  CollectionReference get plansCollection =>
      usersCollection.doc(uid).collection('plans');
  CollectionReference get hifdhsCollection =>
      usersCollection.doc(uid).collection('hifdhs');
  CollectionReference get reviewsCollection =>
      usersCollection.doc(uid).collection('reviews');
  CollectionReference get weeksCollection =>
      usersCollection.doc(uid).collection('weeks');
  CollectionReference get surahsProgressCollection =>
      usersCollection.doc(uid).collection('surahsProgress');

  // Collection reference for quiz history
  CollectionReference get quizHistoryCollection =>
      usersCollection.doc(uid).collection('quizHistory');

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    await _executeWithRetry(
        () => userDocument.set(userData, SetOptions(merge: true)));

    // Update user activity and check achievements
    await updateUserAchievements();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _executeWithRetry<Map<String, dynamic>?>(() async {
      DocumentSnapshot doc = await userDocument.get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    });
  }

  /// Generic method to execute Firestore operations with retry logic
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    const maxRetries = 3;
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        if ((e.code == 'unavailable' || e.code == 'network-request-failed') &&
            attempts < maxRetries - 1) {
          // Exponential backoff: wait longer between each retry
          final waitTime =
              Duration(milliseconds: 300 * pow(2, attempts).toInt());
          if (kDebugMode) {
            print(
                'Firestore operation failed: ${e.message}, retrying in ${waitTime.inMilliseconds}ms');
          }
          await Future.delayed(waitTime);
          attempts++;
        } else {
          _isOfflineMode = true;
          notifyListeners();
          rethrow; // If it's not a network error or we've exhausted retries
        }
      } catch (e) {
        if (kDebugMode) {
          print('Unexpected error during Firestore operation: $e');
        }
        _isOfflineMode = true;
        notifyListeners();
        rethrow;
      }
    }

    _isOfflineMode = true;
    notifyListeners();
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Service still unavailable after $maxRetries retries',
    );
  }

  @override
  void dispose() {
    connectivityService?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

/*-------------------------------------------A D D   P L A N-------------------------------------------*/
  Future<void> addPlan(
    bool backToFront,
    String memorisedFrom,
    String memorisedTo,
    int lines,
    List<bool> hifdhDays,
  ) async {
    double memorisedLines = 0;
    double lastPageMemorisedLines = 0;
    Map<String, dynamic> memorisedFromData = {};
    Map<String, dynamic> memorisedToData = {};
    String startVerseId = '';
    String startKey = '';
    double lastSurahMemorisedLines = 0;
    if (!backToFront) {
      /*-----------C A L C U L A T E   M E M O R I S E D   L I N E S--------------*/
      if (memorisedTo == 'null:null') {
        startVerseId = '1';
        startKey = '1:1';
      } else {
        //get memorisedFrom data
        final memorisedFromSnapshot =
            await versesCollection.where('key', isEqualTo: memorisedFrom).get();
        String memorisedFromId = memorisedFromSnapshot.docs[0].reference.id;
        final memorisedFromDoc =
            await versesCollection.doc(memorisedFromId).get();
        memorisedFromData = memorisedFromDoc.data() as Map<String, dynamic>;

        //get memorisedTo data
        final memorisedToSnapshot =
            await versesCollection.where('key', isEqualTo: memorisedTo).get();
        String memorisedToId = memorisedToSnapshot.docs[0].reference.id;
        final memorisedToDoc = await versesCollection.doc(memorisedToId).get();
        memorisedToData = memorisedToDoc.data() as Map<String, dynamic>;

        String memorisedFromSurah = memorisedFromData['key'].split(':')[0];
        String memorisedToSurah = memorisedToData['key'].split(':')[0];

        if (memorisedFromSurah != memorisedToSurah) {
          // Get last full surah data
          final lastFullSurahSnapshot = await versesCollection
              .where('key',
                  isEqualTo:
                      '${(int.parse(memorisedToData['key'].split(':')[0]) - 1)}:1')
              .get();
          String lastFullSurahId = lastFullSurahSnapshot.docs[0].reference.id;
          dynamic lastFullSurahDoc =
              await versesCollection.doc(lastFullSurahId).get();
          Map<String, dynamic> lastFullSurahData =
              lastFullSurahDoc.data() as Map<String, dynamic>;

          // calculate completed lines for full surahs

          String lastFullSurah = lastFullSurahData['key'].split(':')[0];

          while (int.parse(memorisedFromSurah) <= int.parse(lastFullSurah)) {
            lastFullSurahDoc = await surahsCollection.doc(lastFullSurah).get();
            lastFullSurahData = lastFullSurahDoc.data() as Map<String, dynamic>;
            memorisedLines += lastFullSurahData['totalLines'].toDouble();

            lastFullSurah = (int.parse(lastFullSurah) - 1).toString();
          }
        }

        String tempKey = '${memorisedToData['key'].split(':')[0]}:1';
        dynamic tempSnapshot =
            await versesCollection.where('key', isEqualTo: tempKey).get();
        String tempId = tempSnapshot.docs[0].reference.id;
        dynamic tempDoc = await versesCollection.doc(tempId).get();
        Map<String, dynamic> tempData = tempDoc.data() as Map<String, dynamic>;

        memorisedLines += tempData['length'];
        lastSurahMemorisedLines += tempData['length'];
        int tempPage = tempData['page'];

        tempId = (int.parse(tempId) + 1).toString();
        tempDoc = await versesCollection.doc(tempId).get();
        tempData = tempDoc.data() as Map<String, dynamic>;

        //calculate memorisedLines for first page
        while (tempData['page'] == tempPage &&
            tempId != (int.parse(memorisedToId) + 1).toString()) {
          memorisedLines += tempData['length'].toDouble();
          lastSurahMemorisedLines += tempData['length'].toDouble();
          tempId = (int.parse(tempId) + 1).toString();

          tempDoc = await versesCollection.doc(tempId).get();
          tempData = tempDoc.data() as Map<String, dynamic>;
        }

        if (tempData['page'] != tempPage &&
            tempId != (int.parse(memorisedToId) + 1).toString()) {
          //calculate memorisedLines for middle pages
          memorisedLines +=
              ((memorisedToData['page'] - tempPage - 1) * 15).toDouble();
          lastSurahMemorisedLines +=
              ((memorisedToData['page'] - tempPage - 1) * 15).toDouble();

          //calculate memorisedLines for last page
          memorisedLines += memorisedToData['length'].toDouble();
          lastSurahMemorisedLines += memorisedToData['length'].toDouble();
          lastPageMemorisedLines = memorisedToData['length'].toDouble();
          tempId = memorisedToId;
          tempId = (int.parse(tempId) - 1).toString();
          tempDoc = await versesCollection.doc(tempId).get();
          tempData = tempDoc.data() as Map<String, dynamic>;
          while (memorisedToData['page'] == tempData['page']) {
            memorisedLines += tempData['length'].toDouble();
            lastSurahMemorisedLines += tempData['length'].toDouble();
            lastPageMemorisedLines += tempData['length'].toDouble();
            tempId = (int.parse(tempId) - 1).toString();

            tempDoc = await versesCollection.doc(tempId).get();
            tempData = tempDoc.data() as Map<String, dynamic>;
          }
        }

        //get startVerseId
        startVerseId = (int.parse(memorisedToId) + 1).toString();

        tempDoc = await versesCollection.doc(startVerseId).get();
        tempData = tempDoc.data() as Map<String, dynamic>;
        startKey = tempData['key'];
      }

      /*-------------------------------------C R E A T E   P L A N---------------------------------------*/
      if (startVerseId != '6237') {
        final newPlan = Plan(
          backToFront: backToFront,
          start: startKey,
          lines: lines,
          hifdhDays: hifdhDays,
          totalLines: 8820,
          completedLines: memorisedLines,
          hifdhs: [],
          hifdhIn: -1,
          reviews: [],
          streak: 0,
          missedReviews: 0,
          currentWeek: [],
          planCompleted: false,
          missedHifdhs: [],
        );

        final document = await plansCollection.add(newPlan.toMap());

        final surahsSnapshot = await surahsCollection.get();
        String memorisedFromSurah = '';
        String memorisedToSurah = '';

        if (memorisedFrom != 'null:null' && memorisedTo != 'null:null') {
          memorisedFromSurah = memorisedFromData['key'].split(':')[0];
          memorisedToSurah = memorisedToData['key'].split(':')[0];
        }

        //set tempCompletedLines to 0 for all surahs
        for (var doc in surahsSnapshot.docs) {
          if (memorisedFromSurah == '' && memorisedToSurah == '') {
            await surahsProgressCollection.doc(doc.id).set(doc.data());
          } else if (int.parse(doc.id) >= int.parse(memorisedFromSurah) &&
              int.parse(doc.id) < int.parse(memorisedToSurah)) {
            await surahsProgressCollection.doc(doc.id).set(
              {
                'surah': (doc.data() as Map<String, dynamic>)['surah'],
                'surahNumber':
                    (doc.data() as Map<String, dynamic>)['surahNumber'],
                'verses': (doc.data() as Map<String, dynamic>)['verses'],
                'totalLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'tempCompletedLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'completedLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
              },
            );
          } else if (int.parse(doc.id) == int.parse(memorisedToSurah)) {
            final firstPageLastSurahSnapshot = await versesCollection
                .where('key',
                    isEqualTo: memorisedToData['key'].split(':')[0] + ':1')
                .get();
            String firstPageLastSurahId =
                firstPageLastSurahSnapshot.docs[0].reference.id;
            final firstPageLastSurahDoc =
                await versesCollection.doc(firstPageLastSurahId).get();
            Map<String, dynamic> firstPageLastSurahData =
                firstPageLastSurahDoc.data() as Map<String, dynamic>;

            double firstPageLastSurahMemorisedLines =
                firstPageLastSurahData['length'].toDouble();

            firstPageLastSurahId =
                (int.parse(firstPageLastSurahId) + 1).toString();
            dynamic tempVerseDoc =
                await versesCollection.doc(firstPageLastSurahId).get();
            Map<String, dynamic> tempVerseData =
                tempVerseDoc.data() as Map<String, dynamic>;

            //calculate memorisedLines for first page
            while (firstPageLastSurahData['page'] == tempVerseData['page']) {
              firstPageLastSurahMemorisedLines +=
                  tempVerseData['length'].toDouble();
              firstPageLastSurahId =
                  (int.parse(firstPageLastSurahId) + 1).toString();

              tempVerseDoc =
                  await versesCollection.doc(firstPageLastSurahId).get();
              tempVerseData = tempVerseDoc.data() as Map<String, dynamic>;
            }

            double memorisedToSurahCompletedLines = lastPageMemorisedLines +
                firstPageLastSurahMemorisedLines +
                ((memorisedToData['page'] -
                        firstPageLastSurahData['page'] -
                        (memorisedToData['page'] ==
                                firstPageLastSurahData['page']
                            ? 0
                            : 1)) *
                    15);

            await surahsProgressCollection.doc(doc.id).set(
              {
                'surah': (doc.data() as Map<String, dynamic>)['surah'],
                'surahNumber':
                    (doc.data() as Map<String, dynamic>)['surahNumber'],
                'verses': (doc.data() as Map<String, dynamic>)['verses'],
                'totalLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'tempCompletedLines': memorisedToSurahCompletedLines,
                'completedLines': memorisedToSurahCompletedLines,
              },
            );
          } else {
            await surahsProgressCollection.doc(doc.id).set(doc.data());
          }
        }

        updateCurrentWeek(document.id);

        createNewHifdh(startKey, lines, document.id);
      }
    } else {
      /*-----------C A L C U L A T E   M E M O R I S E D   L I N E S--------------*/
      if (memorisedTo == 'null:null') {
        startVerseId = '6231'; // Start from last verse
        startKey = '114:1';
      } else {
        // Get memorisedFrom data
        final memorisedFromSnapshot =
            await versesCollection.where('key', isEqualTo: memorisedFrom).get();
        String memorisedFromId = memorisedFromSnapshot.docs[0].reference.id;
        final memorisedFromDoc =
            await versesCollection.doc(memorisedFromId).get();
        memorisedFromData = memorisedFromDoc.data() as Map<String, dynamic>;

        // Get memorisedTo data
        final memorisedToSnapshot =
            await versesCollection.where('key', isEqualTo: memorisedTo).get();
        String memorisedToId = memorisedToSnapshot.docs[0].reference.id;
        final memorisedToDoc = await versesCollection.doc(memorisedToId).get();
        memorisedToData = memorisedToDoc.data() as Map<String, dynamic>;

        String memorisedFromSurah = memorisedFromData['key'].split(':')[0];
        String memorisedToSurah = memorisedToData['key'].split(':')[0];

        if (memorisedFromSurah != memorisedToSurah) {
          // Get last full surah data
          final lastFullSurahSnapshot = await versesCollection
              .where('key',
                  isEqualTo:
                      '${(int.parse(memorisedToData['key'].split(':')[0]) + 1)}:1')
              .get();
          String lastFullSurahId = lastFullSurahSnapshot.docs[0].reference.id;
          dynamic lastFullSurahDoc =
              await versesCollection.doc(lastFullSurahId).get();
          Map<String, dynamic> lastFullSurahData =
              lastFullSurahDoc.data() as Map<String, dynamic>;

          // calculate completed lines for full surahs

          String lastFullSurah = lastFullSurahData['key'].split(':')[0];

          while (int.parse(memorisedFromSurah) >= int.parse(lastFullSurah)) {
            lastFullSurahDoc = await surahsCollection.doc(lastFullSurah).get();
            lastFullSurahData = lastFullSurahDoc.data() as Map<String, dynamic>;
            memorisedLines += lastFullSurahData['totalLines'].toDouble();

            lastFullSurah = (int.parse(lastFullSurah) + 1).toString();
          }
        }

        String tempKey = '${memorisedToData['key'].split(':')[0]}:1';
        dynamic tempSnapshot =
            await versesCollection.where('key', isEqualTo: tempKey).get();
        String tempId = tempSnapshot.docs[0].reference.id;
        dynamic tempDoc = await versesCollection.doc(tempId).get();
        Map<String, dynamic> tempData = tempDoc.data() as Map<String, dynamic>;

        memorisedLines += tempData['length'];
        lastSurahMemorisedLines += tempData['length'];
        int tempPage = tempData['page'];

        tempId = (int.parse(tempId) + 1).toString();
        tempDoc = await versesCollection.doc(tempId).get();
        tempData = tempDoc.data() as Map<String, dynamic>;

        //calculate memorisedLines for first page
        while (tempData['page'] == tempPage &&
            tempId != (int.parse(memorisedToId) + 1).toString()) {
          memorisedLines += tempData['length'].toDouble();
          lastSurahMemorisedLines += tempData['length'].toDouble();
          tempId = (int.parse(tempId) + 1).toString();

          tempDoc = await versesCollection.doc(tempId).get();
          tempData = tempDoc.data() as Map<String, dynamic>;
        }

        if (tempData['page'] != tempPage &&
            tempId != (int.parse(memorisedToId) + 1).toString()) {
          //calculate memorisedLines for middle pages
          memorisedLines +=
              ((memorisedToData['page'] - tempPage - 1) * 15).toDouble();
          lastSurahMemorisedLines +=
              ((memorisedToData['page'] - tempPage - 1) * 15).toDouble();

          //calculate memorisedLines for last page
          memorisedLines += memorisedToData['length'].toDouble();
          lastSurahMemorisedLines += memorisedToData['length'].toDouble();
          lastPageMemorisedLines = memorisedToData['length'].toDouble();
          tempId = memorisedToId;
          tempId = (int.parse(tempId) - 1).toString();
          tempDoc = await versesCollection.doc(tempId).get();
          tempData = tempDoc.data() as Map<String, dynamic>;
          while (memorisedToData['page'] == tempData['page']) {
            memorisedLines += tempData['length'].toDouble();
            lastSurahMemorisedLines += tempData['length'].toDouble();
            lastPageMemorisedLines += tempData['length'].toDouble();
            tempId = (int.parse(tempId) - 1).toString();

            tempDoc = await versesCollection.doc(tempId).get();
            tempData = tempDoc.data() as Map<String, dynamic>;
          }
        }

        //get startVerseId
        startVerseId = (int.parse(memorisedToId) + 1).toString();

        tempDoc = await versesCollection.doc(startVerseId).get();
        tempData = tempDoc.data() as Map<String, dynamic>;
        if (tempData['surah'] == memorisedToData['surah']) {
          startKey = tempData['key'];
        } else {
          tempDoc = await versesCollection
              .where('key',
                  isEqualTo:
                      '${int.parse(memorisedToData['key'].split(':')[0]) - 1}:1')
              .get();
          startVerseId = tempDoc.docs[0].reference.id;
          tempDoc = await versesCollection.doc(startVerseId).get();
          tempData = tempDoc.data() as Map<String, dynamic>;
          startKey = tempData['key'];
        }
      }

      /*-------------------------------------C R E A T E   P L A N---------------------------------------*/
      if (startVerseId != '0') {
        final newPlan = Plan(
          backToFront: backToFront,
          start: startKey,
          lines: lines,
          hifdhDays: hifdhDays,
          totalLines: 8820,
          completedLines: memorisedLines,
          hifdhs: [],
          hifdhIn: -1,
          reviews: [],
          streak: 0,
          missedReviews: 0,
          currentWeek: [],
          planCompleted: false,
          missedHifdhs: [],
        );

        final document = await plansCollection.add(newPlan.toMap());

        final surahsSnapshot = await surahsCollection.get();
        String memorisedFromSurah = '';
        String memorisedToSurah = '';

        if (memorisedFrom != 'null:null' && memorisedTo != 'null:null') {
          memorisedFromSurah = memorisedFromData['key'].split(':')[0];
          memorisedToSurah = memorisedToData['key'].split(':')[0];
        }

        //set tempCompletedLines to 0 for all surahs
        for (var doc in surahsSnapshot.docs) {
          if (memorisedFromSurah == '' && memorisedToSurah == '') {
            await surahsProgressCollection.doc(doc.id).set(doc.data());
          } else if (int.parse(doc.id) <= int.parse(memorisedFromSurah) &&
              int.parse(doc.id) > int.parse(memorisedToSurah)) {
            await surahsProgressCollection.doc(doc.id).set(
              {
                'surah': (doc.data() as Map<String, dynamic>)['surah'],
                'surahNumber':
                    (doc.data() as Map<String, dynamic>)['surahNumber'],
                'verses': (doc.data() as Map<String, dynamic>)['verses'],
                'totalLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'tempCompletedLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'completedLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
              },
            );
          } else if (int.parse(doc.id) == int.parse(memorisedToSurah)) {
            await surahsProgressCollection.doc(doc.id).set(
              {
                'surah': (doc.data() as Map<String, dynamic>)['surah'],
                'surahNumber':
                    (doc.data() as Map<String, dynamic>)['surahNumber'],
                'verses': (doc.data() as Map<String, dynamic>)['verses'],
                'totalLines':
                    (doc.data() as Map<String, dynamic>)['totalLines'],
                'tempCompletedLines': lastSurahMemorisedLines >
                        (doc.data() as Map<String, dynamic>)['totalLines']
                    ? (doc.data() as Map<String, dynamic>)['totalLines']
                    : lastSurahMemorisedLines,
                'completedLines': lastSurahMemorisedLines >
                        (doc.data() as Map<String, dynamic>)['totalLines']
                    ? (doc.data() as Map<String, dynamic>)['totalLines']
                    : lastSurahMemorisedLines,
              },
            );
          } else {
            await surahsProgressCollection.doc(doc.id).set(doc.data());
          }
        }

        updateCurrentWeek(document.id);

        createNewHifdh(startKey, lines, document.id);
      }
    }
  }

/*------------------------------------G E T   P L A N   S T R E A M------------------------------------*/
  Stream<QuerySnapshot> getPlansStream() {
    return plansCollection.snapshots();
  }

  Stream<QuerySnapshot> getVerseJuz(String key) {
    return versesCollection.where('key', isEqualTo: key).snapshots();
  }

  Stream<DocumentSnapshot<Object?>> getRandomVerseStream() {
    // Get today's date as a string in the format YYYY-MM-DD
    final today = DateTime.now();
    final dateString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Create a deterministic random number for today
    // Using the date string as seed so it's consistent for the whole day
    final seed = dateString.hashCode;
    final random = Random(seed);

    // Total number of verses in the Quran is 6236
    // Generate a random verse ID between 1 and 6236
    final verseId = random.nextInt(6236) + 1;

    // Return a stream that emits the verse for today
    return versesCollection.doc(verseId.toString()).snapshots();
  }

  Stream<QuerySnapshot> getSurahsStream() {
    final User? user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final surahsStream = surahsCollection.snapshots();
    return surahsStream;
  }

  Stream<QuerySnapshot> getSurahProgressStream() {
    final User? user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final surahsStream = surahsProgressCollection.snapshots();
    return surahsStream;
  }

  Stream<QuerySnapshot> getHifdhsStream() {
    final User? user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final hifdhsStream = hifdhsCollection.snapshots();
    return hifdhsStream;
  }

/*----------------------------------------U P D A T E   P L A N----------------------------------------*/
  Future<void> updatePlan(
    String id,
    int lines,
    List<dynamic> days,
  ) {
    return plansCollection.doc(id).update({
      'lines': lines,
      'hifdhDays': days,
    });
  }

/*--------------------------------U P D A T E   C U R R E N T   W E E K--------------------------------*/
  Future<void> updateCurrentWeek(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final plan = planSnapshot.data() as Map<String, dynamic>;

    List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<Map<String, dynamic>> currentWeek = [];
    DateTime weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    String weekStartString =
        '${weekStart.day}-${weekStart.month}-${weekStart.year}';
    weekStart = DateTime(
      int.parse(weekStartString.split('-')[2]),
      int.parse(weekStartString.split('-')[1]),
      int.parse(weekStartString.split('-')[0]),
      0,
      0,
    );
    final week = await weeksCollection
        .where(
          'weekStart',
          isEqualTo: weekStartString,
        )
        .get();

    if (plan['currentWeek'].isEmpty) {
      for (int i = 0; i < weekDays.length; i++) {
        final weekDay = CurrentWeekDay(
          day: weekDays[i],
          completed: false,
          missed: false,
          weekStart: '${weekStart.day}-${weekStart.month}-${weekStart.year}',
        );

        currentWeek.add(weekDay.toMap());
      }

      await weeksCollection.add({
        'weekStart': '${weekStart.day}-${weekStart.month}-${weekStart.year}',
        'weekDays': currentWeek,
      });
      await plansCollection.doc(id).update({'currentWeek': currentWeek});
    } else if (week.docs.isEmpty) {
      String hifdhDate = plan['hifdhs'].last['date'];

      DateTime hifdhDT = DateTime(
        int.parse(hifdhDate.split('-')[2]),
        int.parse(hifdhDate.split('-')[1]),
        int.parse(hifdhDate.split('-')[0]),
        0,
        0,
      );

      DateTime hifdhWeekStart = hifdhDT.subtract(
        Duration(days: hifdhDT.weekday - 1),
      );
      if (weekStart.isBefore(hifdhWeekStart)) {
      } else {
        List<dynamic> prevWeek = plan['currentWeek'];

        //mark the rest of the previous week as missed

        if ('${hifdhWeekStart.day}-${hifdhWeekStart.month}-${hifdhWeekStart.year}' ==
            prevWeek[0]['weekStart']) {
          dynamic weekDay = prevWeek[hifdhDT.weekday - 1];

          for (int i = hifdhDT.weekday - 1; i < 7; i++) {
            weekDay = prevWeek[i];
            if (plan['hifdhDays'][i]) {
              weekDay['missed'] = true;
            }
          }

          weeksCollection
              .where('weekStart', isEqualTo: weekDay['weekStart'])
              .get()
              .then(
                (value) =>
                    value.docs[0].reference.update({'weekDays': prevWeek}),
              );
        }

        String lastHifdh = plan['hifdhs'].last['date'];
        String todayString =
            '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

        DateTime todayDT = DateTime(
          int.parse(todayString.split('-')[2]),
          int.parse(todayString.split('-')[1]),
          int.parse(todayString.split('-')[0]),
          0,
          0,
        );
        for (int i = 0; i < weekDays.length; i++) {
          final weekDay = CurrentWeekDay(
            day: weekDays[i],
            completed:
                '${weekStart.add(Duration(days: i)).day}-${weekStart.add(Duration(days: i)).month}-${weekStart.add(Duration(days: i)).year}' ==
                        lastHifdh
                    ? plan['hifdhs'].last['completed']
                    : false,
            missed: plan['hifdhDays'][i] &&
                    todayDT.isAfter(weekStart.add(Duration(days: i))) &&
                    '${weekStart.add(Duration(days: i)).day}-${weekStart.add(Duration(days: i)).month}-${weekStart.add(Duration(days: i)).year}' !=
                        lastHifdh
                ? true
                : plan['hifdhDays'][i] &&
                        todayDT.isAfter(weekStart.add(Duration(days: i))) &&
                        '${weekStart.add(Duration(days: i)).day}-${weekStart.add(Duration(days: i)).month}-${weekStart.add(Duration(days: i)).year}' ==
                            lastHifdh
                    ? !plan['hifdhs'].last['completed']
                    : false,
            weekStart: '${weekStart.day}-${weekStart.month}-${weekStart.year}',
          );

          currentWeek.add(weekDay.toMap());
        }

        await weeksCollection.add({
          'weekStart': '${weekStart.day}-${weekStart.month}-${weekStart.year}',
          'weekDays': currentWeek,
        });
        await plansCollection.doc(id).update({'currentWeek': currentWeek});
      }
    } else {
      String weekId = week.docs[0].id;
      final weekSnapshot = await weeksCollection.doc(weekId).get();
      final currWeek = weekSnapshot.data() as Map<String, dynamic>;
      await plansCollection
          .doc(id)
          .update({'currentWeek': currWeek['weekDays']});
    }
  }

/*-----------------------------------C R E A T E   N E W   H I F D H-----------------------------------*/
  Future<void> createNewHifdh(String key, int length, String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;
    List<dynamic> hifdhs = planData['hifdhs'];
    String endKey = '';
    String nextKey = '';
    String surah = '';
    String startVerse = '';
    String endVerse = '';
    double verseLength = 0;
    List<String> versesList = [];

    // Check if the plan has hifdhs i.e the plan has not just been made
    if (hifdhs.isNotEmpty) {
      dynamic hifdh = hifdhs.last;
      hifdh['completed'] = true;

      String hifdhDate = planData['hifdhs'].last['date'];

      DateTime hifdhDT = DateTime(
        int.parse(hifdhDate.split('-')[2]),
        int.parse(hifdhDate.split('-')[1]),
        int.parse(hifdhDate.split('-')[0]),
        0,
        0,
      );

      // Get the week start date for the hifdh date
      DateTime hifdhWeekStart = hifdhDT.subtract(
        Duration(days: hifdhDT.weekday - 1),
      );
      String hifdhWeekStartString =
          '${hifdhWeekStart.day}-${hifdhWeekStart.month}-${hifdhWeekStart.year}';

      dynamic currentWeek = planData['currentWeek'];
      dynamic weekDay = currentWeek[hifdhDT.weekday - 1];

      if (weekDay['weekStart'] == hifdhWeekStartString) {
        weekDay['completed'] = true;
      }

      await weeksCollection
          .where('weekStart', isEqualTo: weekDay['weekStart'])
          .get()
          .then(
            (value) =>
                value.docs[0].reference.update({'weekDays': currentWeek}),
          );

      try {
        final hifdhSnapshot = await hifdhsCollection
            .where('hifdh', isEqualTo: hifdh['hifdh'])
            .get();

        if (hifdhSnapshot.docs.isNotEmpty) {
          await hifdhSnapshot.docs[0].reference.update({'completed': true});
        } else {
          if (kDebugMode) {
            print('No hifdh document found with hifdh: ${hifdh['hifdh']}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating hifdh completion status: $e');
        }
        // Continue execution despite error to ensure other operations complete
      }

      //create review for hifdh
      String reviewDate = hifdh['date'];

      DateTime reviewDT = DateTime(
        int.parse(reviewDate.split('-')[2]),
        int.parse(reviewDate.split('-')[1]),
        int.parse(reviewDate.split('-')[0]),
        0,
        0,
      ).add(const Duration(days: 1));

      reviewDate = '${reviewDT.day}-${reviewDT.month}-${reviewDT.year}';
      surah = hifdh['surah'];
      startVerse = hifdh['startVerse'];
      endVerse = hifdh['endVerse'];
      verseLength = double.parse(hifdh['length'].toString());

      final newReview = Review(
        review: hifdh['hifdh'],
        date: reviewDate,
        ratings: [],
        surah: surah,
        startVerse: startVerse,
        endVerse: endVerse,
        length: verseLength,
        sm2: [0, 2.0, 1],
        versesList: hifdh['versesList'],
      );
      await reviewsCollection.add(newReview.toMap());

      List<dynamic> planReviews = planData['reviews'];
      planReviews = List.from(planReviews)..add(newReview.toMap());
      planData['streak'] += 1;
      plansCollection.doc(id).update({
        'streak': planData['streak'],
        'reviews': planReviews,
        'hifdhs': hifdhs,
        'completedLines': planData['completedLines'] + length,
        'currentWeek': currentWeek
      });

      final surahSnapshot = await surahsProgressCollection
          .where('surah', isEqualTo: surah.split(' ')[0])
          .get();
      String surahId = surahSnapshot.docs[0].reference.id;
      final surahDoc = await surahsProgressCollection.doc(surahId).get();
      Map<String, dynamic> surahData = surahDoc.data() as Map<String, dynamic>;
      surahsProgressCollection
          .doc(surahId)
          .update({'completedLines': surahData['tempCompletedLines']});

      if (surah.split(' ')[0] != surah.split(' ')[1]) {
        final secondSurahSnapshot = await surahsProgressCollection
            .where('surah', isEqualTo: surah.split(' ')[1])
            .get();
        String secondSurahId = secondSurahSnapshot.docs[0].reference.id;
        int tempId = planData['backToFront']
            ? int.parse(surahId) - 1
            : int.parse(surahId) + 1;
        while (planData['backToFront']
            ? int.parse(secondSurahId) <= tempId
            : int.parse(secondSurahId) >= tempId) {
          final nextSurahDoc =
              await surahsProgressCollection.doc(tempId.toString()).get();
          Map<String, dynamic> nextSurahData =
              nextSurahDoc.data() as Map<String, dynamic>;
          surahsProgressCollection
              .doc(tempId.toString())
              .update({'completedLines': nextSurahData['tempCompletedLines']});

          tempId = planData['backToFront'] ? tempId - 1 : tempId + 1;
        }
      }
    }

    /*C A L C U L A T E   H I F D H   S T A R T   A N D   E N D*/

    for (int i = 0; i < hifdhs.length; i++) {
      if (hifdhs[i]['hifdh'].split('-')[0].trim() == key) {
        key = hifdhs[hifdhs.length - 2]['nextKey'];
        break;
      }
    }

    final verseSnapshot =
        await versesCollection.where('key', isEqualTo: key).get();
    String verseId = verseSnapshot.docs[0].reference.id;
    final verseDoc = await versesCollection.doc(verseId).get();
    Map<String, dynamic> verseData = verseDoc.data() as Map<String, dynamic>;
    surah = verseData['surah'];
    startVerse = verseData['text'];
    verseLength = double.parse(verseData['length'].toString());

    if (verseId != '6236') {
      double total = double.parse(verseData['length'].toString());
      double tempTotal = total;
      dynamic prevVerseDoc;

      if (verseData['key'].split(':')[1] == '1' &&
          planData['backToFront'] &&
          verseData['surah'] != 'An-Nas') {
        prevVerseDoc = await versesCollection
            .where('key',
                isEqualTo: '${int.parse(verseData['key'].split(':')[0]) + 1}:1')
            .get();
        String tempId = prevVerseDoc.docs[0].reference.id;

        prevVerseDoc = await versesCollection.doc(tempId).get();
        Map<String, dynamic> prevVerseSurahData =
            prevVerseDoc.data() as Map<String, dynamic>;

        prevVerseDoc = await surahsProgressCollection
            .where('surah', isEqualTo: prevVerseSurahData['surah'])
            .get();
        String prevVerseSurahId = prevVerseDoc.docs[0].reference.id;
        prevVerseDoc =
            await surahsProgressCollection.doc(prevVerseSurahId).get();
        prevVerseSurahData = prevVerseDoc.data() as Map<String, dynamic>;

        int prevVerseSurahTotalVerses = prevVerseSurahData['verses'];

        //last verse of prev verse surah
        final lastVerse = await versesCollection
            .where('key',
                isEqualTo:
                    '${int.parse(verseData['key'].split(':')[0]) + 1}:$prevVerseSurahTotalVerses')
            .get();
        tempId = lastVerse.docs[0].reference.id;
        prevVerseDoc = await versesCollection.doc(tempId).get();
      } else {
        if (verseId != '1' && verseId != '6231') {
          prevVerseDoc = await versesCollection
              .doc((int.parse(verseId) - 1).toString())
              .get();
        } else {
          prevVerseDoc = verseDoc;
        }
      }

      Map<String, dynamic> prevVerseData =
          prevVerseDoc.data() as Map<String, dynamic>;

      // if ((prevVerseData['page'] == verseData['page']) ||
      //     planData['lines'] % 15 != 0) {
      double prevTotal = 0.0;
      bool calculated = false;
      while (!calculated) {
        if (int.parse(verseId) == 6237 || int.parse(verseId) == 0) {
          verseData = prevVerseData;
          plansCollection.doc(id).update({'planCompleted': true});
          break;
        }
        if (length < total) {
          if (length - prevTotal > total - length) {
            verseId = (int.parse(verseId) + 1).toString();
          } else {
            tempTotal -= verseData['length'];
            verseData = prevVerseData;
          }

          calculated = true;
          break;
        }

        verseId = (int.parse(verseId) + 1).toString();

        if (planData['backToFront']) {
          if (verseId == '6237') {
            verseId = '6226';
          } else {
            dynamic tempDoc = await versesCollection.doc(verseId).get();
            Map<String, dynamic> tempData =
                tempDoc.data() as Map<String, dynamic>;
            if (tempData['surah'] != verseData['surah']) {
              final tempDoc = await versesCollection
                  .where('key',
                      isEqualTo:
                          '${int.parse(verseData['key'].split(':')[0]) - 1}:1')
                  .get();
              verseId = tempDoc.docs[0].reference.id;
            }
          }
        } else {
          if (verseId == '6237') {
            break;
          }
        }

        prevVerseData = verseData;
        versesList.add(prevVerseData['text']);
        final nextVerse = await versesCollection.doc(verseId).get();
        verseData = nextVerse.data() as Map<String, dynamic>;
        prevTotal = total;
        total += verseData['length'];

        if (prevVerseData['surah'] != verseData['surah']) {
          final surahSnapshot = await surahsProgressCollection
              .where('surah', isEqualTo: prevVerseData['surah'])
              .get();
          String surahId = surahSnapshot.docs[0].reference.id;
          final surahDoc = await surahsProgressCollection.doc(surahId).get();
          Map<String, dynamic> surahData =
              surahDoc.data() as Map<String, dynamic>;
          surahsProgressCollection
              .doc(surahId)
              .update({'tempCompletedLines': surahData['totalLines']});
          tempTotal = 0.0;
        }

        tempTotal += verseData['length'];
      }
      // }

      // else {
      //   int pages =
      //       int.parse(((planData['lines'] / 15).toString()).split('.')[0]);
      //   dynamic tempVerseData = verseData;
      //   bool calculated = false;
      //   while (!calculated) {
      //     if (int.parse(verseId) == 6237 || int.parse(verseId) == 0) {
      //       plansCollection.doc(id).update({'planCompleted': true});
      //       break;
      //     }
      //     if (!planData['backToFront']) {
      //       if (verseData['page'] ==
      //           ((prevVerseData['page'] ?? 0) + pages + 1)) {
      //         tempTotal -= verseData['length'];
      //         verseData = tempVerseData;
      //         calculated = true;
      //         break;
      //       }
      //     } else {
      //       int i = pages;

      //       final prevVerseSurah = await surahsProgressCollection
      //           .where('surah', isEqualTo: prevVerseData['surah'])
      //           .get();
      //       String prevVerseSurahId = prevVerseSurah.docs[0].reference.id;
      //       //page of last verse
      //       final prevVerseSurahDoc =
      //           await surahsProgressCollection.doc(prevVerseSurahId).get();
      //       int prevVerseSurahTotalVerses =
      //           (prevVerseSurahDoc.data() as Map<String, dynamic>)['verses'];

      //       //last verse of prev verse surah
      //       final lastVerse = await versesCollection
      //           .where('key',
      //               isEqualTo:
      //                   '${prevVerseData['key'].split(':')[0]}:$prevVerseSurahTotalVerses')
      //           .get();
      //       String lastVerseId = lastVerse.docs[0].reference.id;
      //       //page of last verse
      //       final lastVersePageDoc =
      //           await versesCollection.doc(lastVerseId).get();
      //       int lastVersePage =
      //           (lastVersePageDoc.data() as Map<String, dynamic>)['page'];

      //       if (lastVersePage - prevVerseData['page'] < pages) {
      //         i = (pages - (lastVersePage - prevVerseData['page'])).toInt();
      //         //go to the first verse of the next surah
      //         final nextSurahFirstVerse = await versesCollection
      //             .where('key',
      //                 isEqualTo:
      //                     '${int.parse(prevVerseData['key'].split(':')[0]) - 1}:1')
      //             .get();
      //         String nextSurahFirstVerseId =
      //             nextSurahFirstVerse.docs[0].reference.id;
      //         final nextSurahFirstVerseDoc =
      //             await versesCollection.doc(nextSurahFirstVerseId).get();
      //         Map<String, dynamic> nextSurahFirstVerseData =
      //             nextSurahFirstVerseDoc.data() as Map<String, dynamic>;
      //         int nextSurahFirstVersePage = nextSurahFirstVerseData['page'];
      //         if (verseData['page'] == nextSurahFirstVersePage + i) {
      //           tempTotal -= verseData['length'];
      //           verseData = tempVerseData;
      //           calculated = true;
      //           break;
      //         }
      //       } else {
      //         if (verseData['page'] ==
      //             ((prevVerseData['page'] ?? 0) + pages + 1)) {
      //           tempTotal -= verseData['length'];
      //           verseData = tempVerseData;
      //           calculated = true;
      //           break;
      //         }
      //       }
      //     }

      //     verseId = (int.parse(verseId) + 1).toString();
      //     if (planData['backToFront']) {
      //       if (verseId == '6237') {
      //         verseId = '6226';
      //       } else {
      //         dynamic tempDoc = await versesCollection.doc(verseId).get();
      //         Map<String, dynamic> tempData =
      //             tempDoc.data() as Map<String, dynamic>;
      //         if (tempData['surah'] != verseData['surah']) {
      //           final tempDoc = await versesCollection
      //               .where('key',
      //                   isEqualTo:
      //                       '${int.parse(verseData['key'].split(':')[0]) - 1}:1')
      //               .get();
      //           verseId = tempDoc.docs[0].reference.id;
      //         }
      //       }
      //     } else {
      //       if (verseId == '6237') {
      //         break;
      //       }
      //     }

      //     tempVerseData = verseData;
      //     final nextVerse = await versesCollection.doc(verseId).get();
      //     verseData = nextVerse.data() as Map<String, dynamic>;

      //     if (tempVerseData['surah'] != verseData['surah']) {
      //       final surahSnapshot = await surahsProgressCollection
      //           .where('surah', isEqualTo: tempVerseData['surah'])
      //           .get();
      //       String surahId = surahSnapshot.docs[0].reference.id;
      //       final surahDoc = await surahsProgressCollection.doc(surahId).get();
      //       Map<String, dynamic> surahData =
      //           surahDoc.data() as Map<String, dynamic>;
      //       surahsProgressCollection
      //           .doc(surahId)
      //           .update({'tempCompletedLines': surahData['totalLines']});
      //       tempTotal = 0.0;
      //     }

      //     tempTotal += verseData['length'];
      //   }
      // }

      final surahSnapshot = await surahsProgressCollection
          .where('surah', isEqualTo: verseData['surah'])
          .get();
      String surahId = surahSnapshot.docs[0].reference.id;
      final surahDoc = await surahsProgressCollection.doc(surahId).get();
      Map<String, dynamic> surahData = surahDoc.data() as Map<String, dynamic>;
      surahsProgressCollection.doc(surahId).update(
          {'tempCompletedLines': surahData['completedLines'] + tempTotal});

      endKey = verseData['key'];
      endVerse = verseData['text'];
      surah += ' ${verseData['surah']}';
      if (verseId != '6237' || (planData['backToFront'] && verseId != '8')) {
        final nextVerse = await versesCollection.doc(verseId).get();
        verseData = nextVerse.data() as Map<String, dynamic>;

        // Check if we're at the end of a surah in back-to-front mode
        if (planData['backToFront'] && verseData['key'].split(':')[1] == '1') {
          // We need to get the first verse of the previous surah
          final prevSurahId =
              (int.parse(verseData['key'].split(':')[0]) - 2).toString();
          if (prevSurahId != '0') {
            // Check to avoid going past Surah 1
            final prevSurahVerseSnapshot = await versesCollection
                .where('key', isEqualTo: '$prevSurahId:1')
                .get();
            if (prevSurahVerseSnapshot.docs.isNotEmpty) {
              final prevSurahVerseDoc = await versesCollection
                  .doc(prevSurahVerseSnapshot.docs[0].id)
                  .get();
              Map<String, dynamic> prevSurahVerseData =
                  prevSurahVerseDoc.data() as Map<String, dynamic>;
              nextKey = prevSurahVerseData['key'];
            } else {
              nextKey = verseData['key']; // Fallback
            }
          } else {
            nextKey = verseData['key']; // At Surah 1, can't go further back
          }
        } else {
          nextKey = verseData['key'];
        }
      } else {
        nextKey = endKey;
      }
    }

    /*C A L C U L A T E   H I F D H   D A T E*/
    DateTime today = DateTime.now();
    List<dynamic> hifdhDays = planData['hifdhDays'];
    int i = today.weekday - 1;
    int counter = 0;
    DateTime date = DateTime.now();

    if (hifdhs.isNotEmpty) {
      String hifdhDateString = planData['hifdhs'].last['date'];
      DateTime hifdhDateDT = DateTime(
        int.parse(hifdhDateString.split('-')[2]),
        int.parse(hifdhDateString.split('-')[1]),
        int.parse(hifdhDateString.split('-')[0]),
        0,
        0,
      );

      i = hifdhDateDT.weekday == 7 ? 0 : hifdhDateDT.weekday;
      counter = 1;
      date = hifdhDateDT;
    }
    while (!hifdhDays[i]) {
      i++;
      counter++;
      if (i == 7) {
        i = 0;
      }
    }
    date = date.add(Duration(days: counter));
    String nextHifdhDate = '${date.day}-${date.month}-${date.year}';

    /*A D D   N E W   H I F D H   T O   D A T A B A S E*/
    Hifdh newHifdh = Hifdh(
      hifdh: '$key - $endKey',
      date: nextHifdhDate,
      completed: false,
      nextKey: nextKey,
      surah: surah,
      startVerse: startVerse,
      endVerse: endVerse,
      length: verseLength,
      versesList: versesList,
    );

    final newHifdhDoc = await hifdhsCollection.add(newHifdh.toMap());

    if (planData['hifdhs'].isEmpty) {
      //calculate time left until hifdh
      int hifdhIn = 0;
      final hifdhDoc = await hifdhsCollection.doc(newHifdhDoc.id).get();
      Map<String, dynamic> hifdhData = hifdhDoc.data() as Map<String, dynamic>;
      String hifdhDate = hifdhData['date'];

      String todayString = '${today.day}-${today.month}-${today.year}';

      DateTime hifdhDT = DateTime(
        int.parse(hifdhDate.split('-')[2]),
        int.parse(hifdhDate.split('-')[1]),
        int.parse(hifdhDate.split('-')[0]),
        0,
        0,
      );
      DateTime todayDT = DateTime(
        int.parse(todayString.split('-')[2]),
        int.parse(todayString.split('-')[1]),
        int.parse(todayString.split('-')[0]),
        0,
        0,
      );

      if (hifdhDate != todayString) {
        hifdhIn = hifdhDT.difference(todayDT).inDays;
      }

      List<dynamic> planHifdhs = planData['hifdhs'];
      planHifdhs = List.from(planHifdhs)..add(newHifdh.toMap());

      await plansCollection.doc(id).update({
        'hifdhIn': hifdhIn,
        'hifdhs': planHifdhs,
      }); //update plan with hifdhIn and newHifdh
    } else {
      String hifdhDate = planData['hifdhs'].last['date'];
      String todayString = '${today.day}-${today.month}-${today.year}';

      DateTime hifdhDT = DateTime(
        int.parse(hifdhDate.split('-')[2]),
        int.parse(hifdhDate.split('-')[1]),
        int.parse(hifdhDate.split('-')[0]),
        0,
        0,
      );
      DateTime todayDT = DateTime(
        int.parse(todayString.split('-')[2]),
        int.parse(todayString.split('-')[1]),
        int.parse(todayString.split('-')[0]),
        0,
        0,
      );

      if (hifdhDate == todayString || todayDT.isAfter(hifdhDT)) {
        await updateNextHifdh(id);
      }
    }

    // After hifdh is created, update achievements
    await updateUserAchievements();
  }

/*----------------------------------U P D A T E   N E X T   H I F D H----------------------------------*/
  Future<void> updateNextHifdh(String id) async {
    var planSnapshot = await plansCollection.doc(id).get();
    var planData = planSnapshot.data() as Map<String, dynamic>;

    String weekStart = planData['currentWeek'][0]['weekStart'];

    DateTime currWeekStartDT = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );

    String currWeekStart =
        '${currWeekStartDT.day}-${currWeekStartDT.month}-${currWeekStartDT.year}';

    String hifdhDate = planData['hifdhs'].last['date'];

    DateTime hifdhDT = DateTime(
      int.parse(hifdhDate.split('-')[2]),
      int.parse(hifdhDate.split('-')[1]),
      int.parse(hifdhDate.split('-')[0]),
      0,
      0,
    );
    DateTime hifdhWeekStartDT = hifdhDT.subtract(
      Duration(days: hifdhDT.weekday - 1),
    );

    String hifdhWeekStart =
        '${hifdhWeekStartDT.day}-${hifdhWeekStartDT.month}-${hifdhWeekStartDT.year}';

    if (currWeekStart != weekStart && hifdhWeekStart == currWeekStart) {
      await updateCurrentWeek(id);
      planSnapshot = await plansCollection.doc(id).get();
      planData = planSnapshot.data() as Map<String, dynamic>;
    }

    final hifdh = await hifdhsCollection.get();
    final hifdhData = hifdh.docs;

    if (hifdhData.length != planData['hifdhs'].length) {
      final nextHifdh =
          await hifdhsCollection.where('completed', isEqualTo: false).get();

      final hifdhSnapshot =
          await hifdhsCollection.doc(nextHifdh.docs.last.id).get();

      List<dynamic> planHifdhs = planData['hifdhs'];
      planHifdhs = List.from(planHifdhs)
        ..add(hifdhSnapshot.data() as Map<String, dynamic>);

      await plansCollection.doc(id).update({
        'hifdhIn': 0,
        'hifdhs': planHifdhs,
      }); //update plan with hifdhIn and newHifdh
    }
  }

  Future<List<dynamic>> sm2(String id, List<dynamic> arr) async {
    final reviewSnapshot = await reviewsCollection.doc(id).get();
    final review = reviewSnapshot.data() as Map<String, dynamic>;

    List<dynamic> ratings = review['ratings'];

    int corrects = ratings.where((i) => i > 2).toList().length;
    int wrongs = ratings.where((i) => i < 3).toList().length;

    //add rating to ratings list

    if (arr[0] >= 3) {
      corrects++;
      arr[1]++;
      if (corrects == 3) {
        return ['success'];
      }
      if (arr[1] == 1) {
        arr[3] = 3;
      } else {
        arr[3] = double.parse((arr[3] * arr[2]).toStringAsFixed(2));
      }
    } else {
      wrongs++;
      if (wrongs == 3) {
        return ['fail'];
      }
      arr[1] = 0;
      arr[3] = 1;
    }
    arr[2] =
        arr[2] + ((0.1 - (5 - arr[0]) * (0.08 + (5 - arr[0]) * 0.02)) * 0.75);
    if (arr[2] < 1.3) {
      arr[2] = 1.3;
    }
    return ([arr[1], arr[2], arr[3].truncate()]);
  }

  Future<void> updateReview(String id, String review, String rating) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;

    final reviewQuery =
        await reviewsCollection.where('review', isEqualTo: review).get();

    // Check if any matching reviews were found
    if (reviewQuery.docs.isEmpty) {
      if (kDebugMode) {
        print('No review found with review ID: $review');
      }
      return;
    }

    String reviewId = reviewQuery.docs[0].id;
    final reviewSnapshot = await reviewsCollection.doc(reviewId).get();
    final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
    List<dynamic> prevSm2 = reviewData['sm2'];
    prevSm2.insert(0, int.parse(rating));
    List<dynamic> updatedSm2 = await sm2(reviewId, prevSm2);

    List<dynamic> ratings = reviewData['ratings'];
    ratings = List.from(ratings)..add(int.parse(rating));

    // Find the matching review in the plan data, with null safety
    final matchingReviews =
        planData['reviews'].where((rev) => rev['review'] == review).toList();
    if (matchingReviews.isEmpty) {
      if (kDebugMode) {
        print('No matching review found in plan data for review: $review');
      }
      return;
    }

    Map<String, dynamic> rev = matchingReviews[0];

    if (updatedSm2.length == 1) {
      if (updatedSm2[0] == 'success') {
        //* A D D   T O   D A I L Y   R E A D I N G   L I S T
      } else if (updatedSm2[0] == 'fail') {
        // Find the next hifdh day (that is not today)
        DateTime today = DateTime.now();
        List<dynamic> hifdhDays = planData['hifdhDays'];
        int i = today.weekday - 1;
        int counter = 0;

        // Find the next hifdh day
        while (true) {
          i = (i + 1) % 7;
          counter++;
          if (hifdhDays[i] && counter > 0) {
            break;
          }
        }

        DateTime nextHifdhDate = today.add(Duration(days: counter));
        String nextHifdhDateStr =
            '${nextHifdhDate.day}-${nextHifdhDate.month}-${nextHifdhDate.year}';

        // Find the hifdh in the collection that matches the review's content
        final existingHifdhQuery = await hifdhsCollection
            .where('hifdh', isEqualTo: reviewData['review'])
            .get();

        if (existingHifdhQuery.docs.isNotEmpty) {
          // The hifdh exists, update its date and completed status
          String hifdhId = existingHifdhQuery.docs[0].id;
          await hifdhsCollection
              .doc(hifdhId)
              .update({'date': nextHifdhDateStr, 'completed': false});

          // Check if there's already a hifdh scheduled for this day
          // Modified query to avoid composite index requirement
          final conflictingHifdhQuery = await hifdhsCollection
              .where('hifdh', isEqualTo: planData['hifdhs'].last['hifdh'])
              .get();

          // There's a conflicting hifdh, reschedule it to the next hifdh day
          String conflictingHifdhId = conflictingHifdhQuery.docs[0].id;
          await hifdhsCollection.doc(conflictingHifdhId).delete();

          // Update the plan's hifdhs list to reflect these changes
          List<dynamic> updatedHifdhs = List.from(planData['hifdhs']);
          updatedHifdhs.remove(updatedHifdhs.last);
          for (int j = 0; j < updatedHifdhs.length; j++) {
            if (updatedHifdhs[j]['hifdh'] == reviewData['review']) {
              dynamic temp = updatedHifdhs[j];
              updatedHifdhs.remove(updatedHifdhs[j]);
              temp['date'] = nextHifdhDateStr;
              temp['completed'] = false;
              updatedHifdhs.add(temp);
              break;
            }
          }

          await plansCollection.doc(id).update({
            'hifdhs': updatedHifdhs,
            'hifdhIn': counter, // Update hifdhIn to the days until next hifdh
          });
        }
      }
      //remove review from review list
      planData['reviews'].removeWhere((review) => review == rev);
      await plansCollection.doc(id).update({
        'reviews': planData['reviews'],
      });
      await reviewsCollection.doc(reviewId).delete();
    } else {
      String reviewST = reviewData['date'];
      DateTime reviewDT = DateTime(
        int.parse(reviewST.split('-')[2]),
        int.parse(reviewST.split('-')[1]),
        int.parse(reviewST.split('-')[0]),
        0,
        0,
      );
      DateTime newReviewDT = reviewDT.add(Duration(days: updatedSm2[2]));

      await reviewsCollection.doc(reviewId).update({
        'date': '${newReviewDT.day}-${newReviewDT.month}-${newReviewDT.year}',
        'ratings': ratings,
        'sm2': updatedSm2,
      });

      rev['date'] =
          '${newReviewDT.day}-${newReviewDT.month}-${newReviewDT.year}';
      rev['ratings'] = ratings;
      rev['sm2'] = updatedSm2;

      await plansCollection.doc(id).update({
        'reviews': planData['reviews'],
      });
    }

    // After review is completed, update achievements
    await updateUserAchievements();
  }

/*---------------------------------------H I F D H   M I S S E D---------------------------------------*/
  Future<void> hifdhMissed(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;
    dynamic hifdhs = planData['hifdhs'];
    dynamic currentWeek = planData['currentWeek'];
    String hifdhDate = planData['hifdhs'].last['date'];
    String today =
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

    DateTime hifdhDT = DateTime(
      int.parse(hifdhDate.split('-')[2]),
      int.parse(hifdhDate.split('-')[1]),
      int.parse(hifdhDate.split('-')[0]),
      0,
      0,
    );
    DateTime todayDT = DateTime(
      int.parse(today.split('-')[2]),
      int.parse(today.split('-')[1]),
      int.parse(today.split('-')[0]),
      0,
      0,
    );

    // Get existing missedHifdhs or initialise an empty list
    List<dynamic> missedHifdhs = planData['missedHifdhs'] ?? [];

    // Mark days as missed in the current week
    dynamic weekDay = currentWeek[hifdhDT.weekday - 1];
    List<dynamic> hifdhDays = planData['hifdhDays'];

    // Store the hifdh information for the original missed day
    if (hifdhDT.isBefore(todayDT)) {
      Map<String, dynamic> missedHifdh = {
        'date': hifdhDate,
        'hifdh': hifdhs.last['hifdh'],
        'surah': hifdhs.last['surah'],
        'startVerse': hifdhs.last['startVerse'],
        'endVerse': hifdhs.last['endVerse'],
        'length': hifdhs.last['length'],
        'versesList': hifdhs.last['versesList'],
      };

      // Check if this date is already in missedHifdhs to avoid duplicates
      bool alreadyMissed =
          missedHifdhs.any((missed) => missed['date'] == hifdhDate);
      if (!alreadyMissed) {
        missedHifdhs = List.from(missedHifdhs)..add(missedHifdh);
      }
    }

    // Check for additional missed days between the hifdh date and today
    DateTime checkDate = hifdhDT.add(const Duration(days: 1));
    while (checkDate.isBefore(todayDT)) {
      String checkDateStr =
          '${checkDate.day}-${checkDate.month}-${checkDate.year}';
      int weekdayIndex = checkDate.weekday - 1;

      // If this is a hifdh day, mark it as missed
      if (weekdayIndex < hifdhDays.length && hifdhDays[weekdayIndex]) {
        // Mark the day as missed in the current week if it's in the same week
        if (checkDate.difference(hifdhDT).inDays < 7 &&
            weekdayIndex < currentWeek.length) {
          currentWeek[weekdayIndex]['missed'] = true;
        }

        // Store the missed hifdh information
        Map<String, dynamic> additionalMissedHifdh = {
          'date': checkDateStr,
          'hifdh': hifdhs.last['hifdh'],
          'surah': hifdhs.last['surah'],
          'startVerse': hifdhs.last['startVerse'],
          'endVerse': hifdhs.last['endVerse'],
          'length': hifdhs.last['length'],
          'versesList': hifdhs.last['versesList'],
        };

        // Check if this date is already in missedHifdhs to avoid duplicates
        bool alreadyMissed =
            missedHifdhs.any((missed) => missed['date'] == checkDateStr);
        if (!alreadyMissed) {
          missedHifdhs = List.from(missedHifdhs)..add(additionalMissedHifdh);
        }
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Update the week collection
    weeksCollection
        .where('weekStart', isEqualTo: weekDay['weekStart'])
        .get()
        .then(
          (value) => value.docs[0].reference.update({'weekDays': currentWeek}),
        );

    // Calculate the next hifdh date
    bool calculated = false;
    int count = todayDT.weekday - 1;
    int nextHifdh = 0;
    dynamic hifdh;

    if (hifdhs.isNotEmpty) {
      hifdh = hifdhs.last;
    }

    while (!calculated) {
      if (hifdhDays[count] == true &&
          (nextHifdh != planData['hifdhIn'] || todayDT.isAfter(hifdhDT)) &&
          (nextHifdh != 0 ||
              (nextHifdh == 0 &&
                  (hifdh == null || hifdh['completed'] == false)))) {
        calculated = true;
      } else {
        count++;
        nextHifdh++;
        if (count > 6) {
          count = 0;
        }
      }
    }
    DateTime date = DateTime.now().add(Duration(days: nextHifdh));
    String nextHifdhDate = '${date.day}-${date.month}-${date.year}';
    hifdhs.last['date'] = nextHifdhDate;
    planData['streak'] = 0;
    plansCollection.doc(id).update({
      'hifdhs': hifdhs,
      'currentWeek': currentWeek,
      'streak': planData['streak'],
      'missedHifdhs': missedHifdhs,
    });
    final hifdhSnapshot = await hifdhsCollection
        .where('hifdh', isEqualTo: hifdhs.last['hifdh'])
        .get();
    hifdhSnapshot.docs[0].reference.update({'date': nextHifdhDate});
  }

/*-------------------------------------------H I F D H   I N-------------------------------------------*/
  Future<void> hifdhIn(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;

    //calculate time left until hifdh
    int hifdhIn = 0;

    String hifdhDate = planData['hifdhs'].last['date'];
    String today =
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

    DateTime hifdhDT = DateTime(
      int.parse(hifdhDate.split('-')[2]),
      int.parse(hifdhDate.split('-')[1]),
      int.parse(hifdhDate.split('-')[0]),
      0,
      0,
    );
    DateTime todayDT = DateTime(
      int.parse(today.split('-')[2]),
      int.parse(today.split('-')[1]),
      int.parse(today.split('-')[0]),
      0,
      0,
    );

    if (hifdhDate != today) {
      hifdhIn = hifdhDT.difference(todayDT).inDays;
    }

    await plansCollection
        .doc(id)
        .update({'hifdhIn': hifdhIn}); //update plan with hifdhIn
  }

  /*---------------------------------------D E L E T E   U S E R   A C C O U N T----------------------------------------*/
  Future<void> deleteUserAccount() async {
    try {
      // Store user reference before logging out
      final String userId = uid;
      final DocumentReference userDocRef = usersCollection.doc(userId);
      final CollectionReference userPlansCollection =
          userDocRef.collection('plans');
      final CollectionReference userHifdhsCollection =
          userDocRef.collection('hifdhs');
      final CollectionReference userReviewsCollection =
          userDocRef.collection('reviews');
      final CollectionReference userWeeksCollection =
          userDocRef.collection('weeks');
      final CollectionReference userSurahsProgressCollection =
          userDocRef.collection('surahsProgress');
      final CollectionReference userQuizHistoryCollection =
          userDocRef.collection('quizHistory');

      // Get all documents from subcollections
      final plansSnapshot = await userPlansCollection.get();
      final hifdhsSnapshot = await userHifdhsCollection.get();
      final reviewsSnapshot = await userReviewsCollection.get();
      final weeksSnapshot = await userWeeksCollection.get();
      final surahsProgressSnapshot = await userSurahsProgressCollection.get();
      final quizHistorySnapshot = await userQuizHistoryCollection.get();
      // Delete the user document itself
      await userDocRef.delete();

      // Then delete the Firebase Auth user
      final User? currentUser = auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }

      // Delete all documents in each subcollection
      for (var doc in plansSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in hifdhsSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in weeksSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in surahsProgressSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in quizHistorySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user account: $e');
      }
      rethrow; // Rethrow to handle in the UI
    }
  }

  /*---------------------------------------R E S E T   P L A N---------------------------------------*/
  Future<void> resetPlan() async {
    try {
      // Store user reference before logging out
      final String userId = uid;
      final DocumentReference userDocRef = usersCollection.doc(userId);
      final CollectionReference userPlansCollection =
          userDocRef.collection('plans');
      final CollectionReference userHifdhsCollection =
          userDocRef.collection('hifdhs');
      final CollectionReference userReviewsCollection =
          userDocRef.collection('reviews');
      final CollectionReference userWeeksCollection =
          userDocRef.collection('weeks');
      final CollectionReference userSurahsProgressCollection =
          userDocRef.collection('surahsProgress');
      final CollectionReference userQuizHistoryCollection =
          userDocRef.collection('quizHistory');

      // Get all documents from subcollections
      final plansSnapshot = await userPlansCollection.get();
      final hifdhsSnapshot = await userHifdhsCollection.get();
      final reviewsSnapshot = await userReviewsCollection.get();
      final weeksSnapshot = await userWeeksCollection.get();
      final surahsProgressSnapshot = await userSurahsProgressCollection.get();
      final quizHistorySnapshot = await userQuizHistoryCollection.get();
      // Delete all documents in each subcollection
      for (var doc in plansSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in hifdhsSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in weeksSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in surahsProgressSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in quizHistorySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting plan: $e');
      }
      rethrow; // Rethrow to handle in the UI
    }
  }

  /*---------------------------------------G E T   P A G E   F O R   V E R S E   K E Y----------------------------------------*/
  Future<int> getPageForVerseKey(String verseKey) async {
    try {
      final verseSnapshot =
          await versesCollection.where('key', isEqualTo: verseKey).get();

      if (verseSnapshot.docs.isEmpty) {
        throw Exception('Verse not found for key: $verseKey');
      }

      final verseData = verseSnapshot.docs[0].data() as Map<String, dynamic>;
      return verseData['page'] as int;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting page for verse key: $e');
      }
      rethrow;
    }
  }

  /*---------------------------------------G E T   A L L   P A G E S----------------------------------------*/
  Future<List<DocumentSnapshot>> getAllPages() async {
    try {
      final pagesSnapshot = await pagesCollection.get();

      // Sort pages numerically based on page number (document ID)
      final sortedDocs = pagesSnapshot.docs.toList()
        ..sort((a, b) {
          final pageNumberA = int.parse(a.id);
          final pageNumberB = int.parse(b.id);
          return pageNumberA.compareTo(pageNumberB);
        });

      // Log info about the first document for debugging
      if (sortedDocs.isNotEmpty) {
        final firstDoc = sortedDocs.first;
        if (kDebugMode) {
          print('First page ID: ${firstDoc.id}');
          print('First page data structure: ${firstDoc.data()}');
          print(
              'First page fields: ${(firstDoc.data() as Map<String, dynamic>).keys.join(', ')}');
        }
      } else {
        if (kDebugMode) {
          print('No pages found in collection');
        }
      }

      return sortedDocs;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all pages: $e');
      }
      rethrow;
    }
  }

  /*---------------------------------------G E T   P A G E   S T R U C T U R E----------------------------------------*/
  Future<Map<String, dynamic>> getPageStructure(String pageId) async {
    try {
      final pageDoc = await pagesCollection.doc(pageId).get();
      if (!pageDoc.exists) {
        return {'exists': false, 'message': 'Page does not exist'};
      }

      final data = pageDoc.data() as Map<String, dynamic>;
      final result = <String, dynamic>{
        'exists': true,
        'id': pageDoc.id,
        'fields': data.keys.toList(),
      };

      // Add sample data for each field
      data.forEach((key, value) {
        if (value is String) {
          result['${key}_type'] = 'String';
          result['${key}_sample'] =
              value.length > 100 ? '${value.substring(0, 100)}...' : value;
        } else if (value is List) {
          result['${key}_type'] = 'List (${value.length} items)';
          if (value.isNotEmpty) {
            result['${key}_sample'] = value[0] is Map
                ? (value[0] as Map).keys.toList()
                : value[0].toString();
          }
        } else if (value is Map) {
          result['${key}_type'] = 'Map';
          result['${key}_keys'] = value.keys.toList();
        } else {
          result['${key}_type'] = value.runtimeType.toString();
        }
      });

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting page structure: $e');
      }
      return {'error': e.toString()};
    }
  }

  /*---------------------------------------U P D A T E   D O C U M E N T----------------------------------------*/

  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    await _executeWithRetry(() => plansCollection.doc(docId).update(data));
  }

  Future<void> reviewMissed(String planId) async {
    final planSnapshot = await plansCollection.doc(planId).get();
    if (!planSnapshot.exists) return;

    final planData = planSnapshot.data() as Map<String, dynamic>;
    final List<dynamic> reviews = planData['reviews'] ?? [];

    var today = DateTime.now();
    today = DateTime(
      today.year,
      today.month,
      today.day,
    );
    bool updated = false;

    // Reschedule any missed reviews (date < today) to the next day
    for (var review in reviews) {
      final parts = (review['date'] as String).split('-');
      final reviewDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      // Check if the review date is before today and not completed
      if (reviewDate.isBefore(today) &&
          reviewDate != today &&
          (review['completed'] != true)) {
        review['date'] = '${today.day}-${today.month}-${today.year}';
        updated = true;
        // Update the review date in the database
        final reviewQ = await reviewsCollection
            .where('review', isEqualTo: review['review'])
            .get();
        final reviewId = reviewQ.docs[0].id;
        if (reviewId.isNotEmpty) {
          await reviewsCollection.doc(reviewId).update({
            'date': '${today.day}-${today.month}-${today.year}',
          });
        }
      }
    }

    if (updated) {
      await plansCollection.doc(planId).update({'reviews': reviews});
    }
  }

  /*----------------------------------------Q U I Z   H I S T O R Y---------------------------------------*/

  /// Save quiz results to Firestore
  Future<void> saveQuizHistory({
    required String dateCompleted,
    required bool isCustomQuiz,
    required int score,
    required int totalQuestions,
    required List<Map<String, dynamic>> questions,
    required Map<String, dynamic> answeredQuestions,
    required String quizId,
    String quizContent = '',
  }) async {
    try {
      Map<String, dynamic> quizResult = {
        'dateCompleted': dateCompleted,
        'isCustomQuiz': isCustomQuiz,
        'score': score,
        'totalQuestions': totalQuestions,
        'questions': questions,
        'answeredQuestions': answeredQuestions,
        'quizId': quizId,
        'quizContent': quizContent,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await quizHistoryCollection.add(quizResult);

      // After quiz is saved, update achievements
      await updateUserAchievements();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving quiz history: $e');
      }
      rethrow;
    }
  }

  /// Get stream of custom quiz history with client-side sorting
  Stream<List<QueryDocumentSnapshot>> getCustomQuizHistoryStream() {
    return quizHistoryCollection
        .where('isCustomQuiz', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var docs = snapshot.docs;
      docs.sort((a, b) {
        var aData = a.data() as Map<String, dynamic>;
        var bData = b.data() as Map<String, dynamic>;
        Timestamp aTime = aData['timestamp'] ?? Timestamp.now();
        Timestamp bTime = bData['timestamp'] ?? Timestamp.now();
        return bTime.compareTo(aTime); // Descending order
      });
      return docs;
    });
  }

  /// Get stream of review quiz history with client-side sorting
  Stream<List<QueryDocumentSnapshot>> getReviewQuizHistoryStream() {
    return quizHistoryCollection
        .where('isCustomQuiz', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      var docs = snapshot.docs;
      docs.sort((a, b) {
        var aData = a.data() as Map<String, dynamic>;
        var bData = b.data() as Map<String, dynamic>;
        Timestamp aTime = aData['timestamp'] ?? Timestamp.now();
        Timestamp bTime = bData['timestamp'] ?? Timestamp.now();
        return bTime.compareTo(aTime); // Descending order
      });
      return docs;
    });
  }

  /// Get all quiz history without filtering, with client-side sorting
  Stream<List<QueryDocumentSnapshot>> getAllQuizHistoryStream() {
    return quizHistoryCollection.snapshots().map((snapshot) {
      var docs = snapshot.docs;
      docs.sort((a, b) {
        var aData = a.data() as Map<String, dynamic>;
        var bData = b.data() as Map<String, dynamic>;
        Timestamp aTime = aData['timestamp'] ?? Timestamp.now();
        Timestamp bTime = bData['timestamp'] ?? Timestamp.now();
        return bTime.compareTo(aTime); // Descending order
      });
      return docs;
    });
  }

  /// Delete a quiz history entry
  Future<void> deleteQuizHistory(String quizHistoryId) async {
    try {
      await quizHistoryCollection.doc(quizHistoryId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting quiz history: $e');
      }
      rethrow;
    }
  }

  /// Get a specific quiz history detail
  Future<Map<String, dynamic>?> getQuizHistoryDetail(
      String quizHistoryId) async {
    try {
      DocumentSnapshot doc =
          await quizHistoryCollection.doc(quizHistoryId).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quiz history detail: $e');
      }
      rethrow;
    }
  }

  // New method to update user activity and check achievements
  Future<void> updateUserAchievements() async {
    try {
      final AchievementService achievementService = AchievementService(
        auth: auth,
        uid: uid,
      );

      // Update user's daily activity (tracks logins and streaks)
      await achievementService.updateUserActivity();

      // Check and update achievements based on current progress
      await achievementService.checkAndUpdateAchievements();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating achievements: $e');
      }
      // Don't rethrow - achievement updates should not block main functionality
    }
  }
}
