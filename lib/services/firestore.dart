import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hifdh_planner_app/models/current_weekday.dart';
import 'package:hifdh_planner_app/models/daily_reading.dart';
import 'package:hifdh_planner_app/models/hifdh.dart';
import 'package:hifdh_planner_app/models/plan.dart';
import 'package:hifdh_planner_app/models/review.dart';

class FirestoreService extends ChangeNotifier {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference versesCollection =
      FirebaseFirestore.instance.collection('verses');

  final FirebaseAuth auth;
  late String uid;

  FirestoreService(this.auth) {
    final User? user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    uid = user.uid;
  }

  CollectionReference get plansCollection =>
      usersCollection.doc(uid).collection('plans');
  CollectionReference get hifdhsCollection =>
      usersCollection.doc(uid).collection('hifdhs');
  CollectionReference get dailyReadingCollection =>
      usersCollection.doc(uid).collection('dailyReadings');
  CollectionReference get reviewsCollection =>
      usersCollection.doc(uid).collection('reviews');
  CollectionReference get weeksCollection =>
      usersCollection.doc(uid).collection('weeks');
/*-------------------------------------------A D D   P L A N-------------------------------------------*/
  Future<void> addPlan(
    String name,
    String start,
    String end,
    int lines,
    int pages,
    int dailyReadingFrom,
    int dailyReadingTo,
    List<bool> hifdhDays,
    List<bool> dailyReadingDays,
  ) async {
    final startVerseSnapshot =
        await versesCollection.where('key', isEqualTo: start).get();
    String startVerseId = startVerseSnapshot.docs[0].reference.id;
    final startVerseDoc = await versesCollection.doc(startVerseId).get();
    Map<String, dynamic> startVerseData =
        startVerseDoc.data() as Map<String, dynamic>;
    final endVerseSnapshot =
        await versesCollection.where('key', isEqualTo: end).get();
    String endVerseId = endVerseSnapshot.docs[0].reference.id;
    final endVerseDoc = await versesCollection.doc(endVerseId).get();
    Map<String, dynamic> endVerseData =
        endVerseDoc.data() as Map<String, dynamic>;

    double totalLines = (startVerseData['page'] == endVerseData['page'])
        ? 0
        : ((endVerseData['page'] - startVerseData['page'] - 1) * 15).toDouble();
    totalLines += startVerseData['length'];

    startVerseId = (int.parse(startVerseId) + 1).toString();
    dynamic tempVerseDoc = await versesCollection.doc(startVerseId).get();
    Map<String, dynamic> tempVerseData =
        tempVerseDoc.data() as Map<String, dynamic>;

    while (startVerseData['page'] == tempVerseData['page']) {
      totalLines += tempVerseData['length'];
      startVerseId = (int.parse(startVerseId) + 1).toString();

      tempVerseDoc = await versesCollection.doc(startVerseId).get();
      tempVerseData = tempVerseDoc.data() as Map<String, dynamic>;
    }

    if (startVerseData['page'] != endVerseData['page']) {
      totalLines += endVerseData['length'];
      endVerseId = (int.parse(endVerseId) - 1).toString();
      tempVerseDoc = await versesCollection.doc(endVerseId).get();
      tempVerseData = tempVerseDoc.data() as Map<String, dynamic>;
      while (endVerseData['page'] == tempVerseData['page']) {
        totalLines += tempVerseData['length'];
        endVerseId = (int.parse(endVerseId) - 1).toString();

        tempVerseDoc = await versesCollection.doc(endVerseId).get();
        tempVerseData = tempVerseDoc.data() as Map<String, dynamic>;
      }
    }

    final newPlan = Plan(
      name: name,
      start: start,
      end: end,
      lines: lines,
      hifdhDays: hifdhDays,
      pages: pages,
      dailyReadingFrom: dailyReadingFrom,
      dailyReadingTo: dailyReadingTo,
      dailyReadingDays: dailyReadingDays,
      dailyReadings: [],
      totalLines: totalLines,
      completedLines: 0,
      hifdhs: [],
      hifdhIn: -1,
      reviews: [],
      streak: 0,
      missedReviews: 0,
      currentWeek: [],
      planCompleted: false,
    );

    final document = await plansCollection.add(newPlan.toMap());

    updateCurrentWeek(document.id);

    createNewHifdh(start, lines, document.id);

    createNewDailyReading(document.id, dailyReadingFrom);
  }

  Future<void> createNewDailyReading(String id, int from) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;
    List<dynamic> dailyReadings = planData['dailyReadings'];
    dynamic dailyReading;

    if (dailyReadings.isNotEmpty) {
      dailyReading = dailyReadings.last;
      dailyReading['completed'] = true;

      final dailyReadingSnapshot = await dailyReadingCollection
          .where('dailyReading', isEqualTo: dailyReading['dailyReading'])
          .where('planId', isEqualTo: id)
          .get();
      dailyReadingSnapshot.docs[0].reference.update({'completed': true});

      await plansCollection.doc(id).update({
        'dailyReadings': dailyReadings,
      });
    }

    /*C A L C U L A T E   D A I L Y   R E A D I N G   D A T E*/
    DateTime today = DateTime.now();
    List<dynamic> dailyReadingDays = planData['dailyReadingDays'];
    bool calculated = false;
    int count = today.weekday - 1;
    int nextDailyReading = 0;

    while (!calculated) {
      if (dailyReadingDays[count] == true &&
          (nextDailyReading != 0 ||
              (nextDailyReading == 0 && dailyReading == null))) {
        calculated = true;
      } else {
        count++;
        nextDailyReading++;
        if (count > 6) {
          count = 0;
        }
      }
    }
    DateTime date = DateTime.now().add(Duration(days: nextDailyReading));
    String nextDailyReadingDate = '${date.day}-${date.month}-${date.year}';
    dynamic nextStart = from + planData['pages'];

    DailyReading newDailyReading = DailyReading(
      dailyReading: '$from - ${nextStart - 1}',
      date: nextDailyReadingDate,
      completed: false,
      nextStart: nextStart,
      planId: id,
    );

    await dailyReadingCollection.add(newDailyReading.toMap());

    List<dynamic> planDailyReadings = planData['dailyReadings'];
    planDailyReadings = List.from(planDailyReadings)
      ..add(newDailyReading.toMap());

    await plansCollection.doc(id).update({
      'dailyReadings': planDailyReadings,
    }); //update plan with dailyReading
  }

/*------------------------------------G E T   P L A N   S T R E A M------------------------------------*/
  Stream<QuerySnapshot> getPlansStream() {
    final User? user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    uid = user.uid;
    final plansStream = plansCollection.snapshots();
    return plansStream;
  }

/*----------------------------------------U P D A T E   P L A N----------------------------------------*/
  Future<void> updatePlan(
    String id,
    String name,
    int lines,
    List<dynamic> days,
  ) {
    return plansCollection.doc(id).update({
      'name': name,
      'lines': lines,
      'hifdhDays': days,
    });
  }

/*-------------------------------U P D A T E   D A I L Y   R E A D I N G-------------------------------*/
  Future<void> updateDailyReading(
    String id,
    int pages,
    List<dynamic> days,
  ) {
    return plansCollection.doc(id).update({
      'pages': pages,
      'dailyReadingDays': days,
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
        .where('planId', isEqualTo: id)
        .get();

    if (plan['currentWeek'].isEmpty) {
      for (int i = 0; i < weekDays.length; i++) {
        final weekDay = CurrentWeekDay(
          day: weekDays[i],
          completed: false,
          missed: false,
          weekStart: '${weekStart.day}-${weekStart.month}-${weekStart.year}',
          planId: id,
        );

        currentWeek.add(weekDay.toMap());
      }

      await weeksCollection.add({
        'weekStart': '${weekStart.day}-${weekStart.month}-${weekStart.year}',
        'weekDays': currentWeek,
        'planId': id,
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
        print("went to a previous week that doesn't exist");
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
            planId: id,
          );

          currentWeek.add(weekDay.toMap());
        }

        await weeksCollection.add({
          'weekStart': '${weekStart.day}-${weekStart.month}-${weekStart.year}',
          'weekDays': currentWeek,
          'planId': id,
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
    String verse = '';
    double verseLength = 0;

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
      dynamic currentWeek = planData['currentWeek'];
      dynamic weekDay = currentWeek[hifdhDT.weekday - 1];

      weekDay['completed'] = true;

      await weeksCollection
          .where('weekStart', isEqualTo: weekDay['weekStart'])
          .get()
          .then(
            (value) =>
                value.docs[0].reference.update({'weekDays': currentWeek}),
          );

      final hifdhSnapshot = await hifdhsCollection
          .where('hifdh', isEqualTo: hifdh['hifdh'])
          .where('planId', isEqualTo: id)
          .get();
      hifdhSnapshot.docs[0].reference.update({'completed': true});

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
      verse = hifdh['verse'];
      verseLength = double.parse(hifdh['length'].toString());

      final newReview = Review(
          review: hifdh['hifdh'],
          date: reviewDate,
          ratings: [],
          planId: id,
          surah: surah,
          verse: verse,
          length: verseLength,
          sm2: [0, 2.0, 1]);
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
    }

    /*C A L C U L A T E   H I F D H   S T A R T   A N D   E N D*/

    final verseSnapshot =
        await versesCollection.where('key', isEqualTo: key).get();
    String verseId = verseSnapshot.docs[0].reference.id;
    final verseDoc = await versesCollection.doc(verseId).get();
    Map<String, dynamic> verseData = verseDoc.data() as Map<String, dynamic>;
    surah = verseData['surah'];
    verse = verseData['text'];
    verseLength = double.parse(verseData['length'].toString());

    final endOfPlanVerseSnapshot =
        await versesCollection.where('key', isEqualTo: planData['end']).get();
    String endOfPlanVerse = endOfPlanVerseSnapshot.docs[0].reference.id;

    if (verseId != '6236') {
      final prevVerseDoc =
          await versesCollection.doc((int.parse(verseId) - 1).toString()).get();
      double total = double.parse(verseData['length'].toString());
      Map<String, dynamic> prevVerseData = {};
      if (prevVerseDoc.exists) {
        prevVerseData = prevVerseDoc.data() as Map<String, dynamic>;
      }

      if ((prevVerseData != {} && prevVerseData['page'] == verseData['page']) ||
          planData['lines'] % 15 != 0) {
        double prevTotal = 0.0;
        bool calculated = false;
        Map<String, dynamic> prevVerseData = {};
        while (!calculated) {
          if (int.parse(verseId) > int.parse(endOfPlanVerse)) {
            verseData = prevVerseData;
            plansCollection.doc(id).update({'planCompleted': true});
            break;
          }
          if (length < total) {
            length - prevTotal > total - length
                ? verseId = (int.parse(verseId) + 1).toString()
                : verseData = prevVerseData;

            calculated = true;
            break;
          }
          verseId = (int.parse(verseId) + 1).toString();
          if (verseId == '6237') {
            break;
          }
          prevVerseData = verseData;
          final nextVerse = await versesCollection.doc(verseId).get();
          verseData = nextVerse.data() as Map<String, dynamic>;
          prevTotal = total;
          total += verseData['length'];
        }
      } else {
        int pages =
            int.parse(((planData['lines'] / 15).toString()).split('.')[0]);
        dynamic tempVerseData = verseData;
        while (tempVerseData['page'] !=
            ((prevVerseData['page'] ?? 0) + pages + 1)) {
          if (int.parse(verseId) > int.parse(endOfPlanVerse)) {
            plansCollection.doc(id).update({'planCompleted': true});
            break;
          }
          verseData = tempVerseData;
          verseId = (int.parse(verseId) + 1).toString();
          if (verseId == '6237') {
            break;
          }
          final nextVerse = await versesCollection.doc(verseId).get();
          tempVerseData = nextVerse.data() as Map<String, dynamic>;
        }
      }
      endKey = verseData['key'];
      surah += ' ${verseData['surah']}';
      if (verseId != '6237') {
        final nextVerse = await versesCollection.doc(verseId).get();
        verseData = nextVerse.data() as Map<String, dynamic>;
        nextKey = verseData['key'];
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

    // DateTime today = DateTime.now();
    // List<dynamic> hifdhDays = planData['hifdhDays'];
    // bool calculated = false;
    // int count = today.weekday - 1;
    // int nextHifdh = 0;
    // dynamic hifdh;

    // if (hifdhs.isNotEmpty) {
    //   hifdh = hifdhs.last;
    // }

    // while (!calculated) {
    //   if (hifdhDays[count] == true &&
    //       nextHifdh != planData['hifdhIn'] &&
    //       (nextHifdh != 0 ||
    //           (nextHifdh == 0 &&
    //               (hifdh == null || hifdh['completed'] == false)))) {
    //     calculated = true;
    //   } else {
    //     count++;
    //     nextHifdh++;
    //     if (count > 6) {
    //       count = 0;
    //     }
    //   }
    // }

    /*A D D   N E W   H I F D H   T O   D A T A B A S E*/
    Hifdh newHifdh = Hifdh(
        hifdh: '$key - $endKey',
        date: nextHifdhDate,
        completed: false,
        nextKey: nextKey,
        planId: id,
        surah: surah,
        verse: verse,
        length: verseLength);

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

    final hifdh = await hifdhsCollection.where('planId', isEqualTo: id).get();
    final hifdhData = hifdh.docs;

    if (hifdhData.length != planData['hifdhs'].length) {
      final nextHifdh = await hifdhsCollection
          .where('planId', isEqualTo: id)
          .where('completed', isEqualTo: false)
          .get();

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

    final reviewQuery = await reviewsCollection
        .where('planId', isEqualTo: id)
        .where('review', isEqualTo: review)
        .get();
    String reviewId = reviewQuery.docs[0].id;
    final reviewSnapshot = await reviewsCollection.doc(reviewId).get();
    final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
    List<dynamic> prevSm2 = reviewData['sm2'];
    prevSm2.insert(0, int.parse(rating));
    List<dynamic> updatedSm2 = await sm2(reviewId, prevSm2);

    List<dynamic> ratings = reviewData['ratings'];
    ratings = List.from(ratings)..add(int.parse(rating));
    Map<String, dynamic> rev =
        planData['reviews'].where((rev) => rev['review'] == review).toList()[0];

    if (updatedSm2.length == 1) {
      if (updatedSm2[0] == 'success') {
        //* A D D   T O   D A I L Y   R E A D I N G   L I S T
      } else {
        //* A D D   T O   H I F D H   L I S T
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

    dynamic weekDay = currentWeek[hifdhDT.weekday - 1];

    for (int i = hifdhDT.weekday - 1; i < 7 && i < todayDT.weekday - 1; i++) {
      weekDay = currentWeek[i];
      if (planData['hifdhDays'][i]) {
        weekDay['missed'] = true;
      }
    }

    weeksCollection
        .where('weekStart', isEqualTo: weekDay['weekStart'])
        .get()
        .then(
          (value) => value.docs[0].reference.update({'weekDays': currentWeek}),
        );

    List<dynamic> hifdhDays = planData['hifdhDays'];
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
      'streak': planData['streak']
    });
    final hifdhSnapshot = await hifdhsCollection
        .where('hifdh', isEqualTo: hifdhs.last['hifdh'])
        .where('planId', isEqualTo: id)
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

/*---------------------------------------D E L E T E   P L A N----------------------------------------*/
  Future<void> deletePlan(String id) async {
    await plansCollection.doc(id).delete();
    final hifdhsSnapshot =
        await hifdhsCollection.where('planId', isEqualTo: id).get();
    final dailyReadingSnapshot =
        await dailyReadingCollection.where('planId', isEqualTo: id).get();
    final reviewsSnapshot =
        await reviewsCollection.where('planId', isEqualTo: id).get();
    final weeksSnapshot =
        await weeksCollection.where('planId', isEqualTo: id).get();

    for (int i = 0; i < hifdhsSnapshot.docs.length; i++) {
      await hifdhsSnapshot.docs[i].reference.delete();
    }
    for (int i = 0; i < dailyReadingSnapshot.docs.length; i++) {
      await dailyReadingSnapshot.docs[i].reference.delete();
    }
    for (int i = 0; i < reviewsSnapshot.docs.length; i++) {
      await reviewsSnapshot.docs[i].reference.delete();
    }
    for (int i = 0; i < weeksSnapshot.docs.length; i++) {
      await weeksSnapshot.docs[i].reference.delete();
    }
  }
}
