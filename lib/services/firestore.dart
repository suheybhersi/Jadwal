import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hifdh_planner_app/models/current_weekday.dart';
import 'package:hifdh_planner_app/models/hifdh.dart';
import 'package:hifdh_planner_app/models/plan.dart';
import 'package:hifdh_planner_app/models/review.dart';

class FirestoreService extends ChangeNotifier {
  final CollectionReference plansCollection =
      FirebaseFirestore.instance.collection('plans');
  final CollectionReference versesCollection =
      FirebaseFirestore.instance.collection('verses');
  final CollectionReference hifdhsCollection =
      FirebaseFirestore.instance.collection('hifdhs');
  final CollectionReference reviewsCollection =
      FirebaseFirestore.instance.collection('reviews');
  final CollectionReference weeksCollection =
      FirebaseFirestore.instance.collection('weeks');
/*-------------------------------------------A D D   P L A N-------------------------------------------*/
  Future<void> addPlan(
    String name,
    String start,
    String end,
    int lines,
    List<bool> days,
  ) async {
    final newPlan = Plan(
      name: name,
      start: start,
      end: end,
      lines: lines,
      hifdhDays: days,
      dailyReadingDays: [false, false, false, false, false, false, false],
      pages: 0,
      active: false,
      totalAjza: 0,
      completedAjza: 0,
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
    updateActivePlan(document.id);
  }

/*------------------------------------G E T   P L A N   S T R E A M------------------------------------*/
  Stream<QuerySnapshot> getPlansStream() {
    final plansStream =
        plansCollection.orderBy('active', descending: true).snapshots();
    return plansStream;
  }

/*---------------------------------U P D A T E   A C T I V E   P L A N---------------------------------*/
  Future<void> updateActivePlan(String id) {
    return plansCollection.where('active', isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        return value.docs[0].reference
            .update({'active': false}); // Deactivate current active plan
      }
    }).then((_) {
      return plansCollection
          .doc(id)
          .update({'active': true}); // Activate the new plan
    });
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

    DateTime currWeekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final week = await weeksCollection
        .where(
          'weekStart',
          isEqualTo:
              '${currWeekStart.day}-${currWeekStart.month}-${currWeekStart.year}',
        )
        .where('planId', isEqualTo: id)
        .get();

    if (plan['currentWeek'].isEmpty || week.docs.isEmpty) {
      List<String> weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      List<Map<String, dynamic>> currentWeek = [];
      DateTime weekStart = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1),
      );
      weekDays.forEach((element) async {
        final weekDay = CurrentWeekDay(
          day: element,
          completed: false,
          missed: false,
          weekStart: '${weekStart.day}-${weekStart.month}-${weekStart.year}',
          planId: id,
        );

        currentWeek.add(weekDay.toMap());
      });

      await weeksCollection.add({
        'weekStart': '${weekStart.day}-${weekStart.month}-${weekStart.year}',
        'weekDays': currentWeek,
        'planId': id,
      });
      await plansCollection.doc(id).update({'currentWeek': currentWeek});
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

    // Check if the plan has hifdhs i.e the plan has not just been made
    if (hifdhs.isNotEmpty) {
      dynamic hifdh = hifdhs.last;
      hifdh['completed'] = true;

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

      final newReview = Review(
          review: hifdh['hifdh'],
          date: reviewDate,
          ratings: [],
          planId: id,
          sm2: [0, 2.0, 1]);
      await reviewsCollection.add(newReview.toMap());
      List<dynamic> planReviews = planData['reviews'];
      planReviews = List.from(planReviews)..add(newReview.toMap());
      planData['streak'] += 1;
      plansCollection.doc(id).update({
        'streak': planData['streak'],
        'reviews': planReviews,
        'hifdhs': hifdhs,
      });
    }

    /*C A L C U L A T E   H I F D H   S T A R T   A N D   E N D*/

    final verseSnapshot =
        await versesCollection.where('key', isEqualTo: key).get();
    String verseId = verseSnapshot.docs[0].reference.id;
    final verseDoc = await versesCollection.doc(verseId).get();
    Map<String, dynamic> verseData = verseDoc.data() as Map<String, dynamic>;

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
      if (verseId != '6237') {
        final nextVerse = await versesCollection.doc(verseId).get();
        verseData = nextVerse.data() as Map<String, dynamic>;
        nextKey = verseData['key'];
      } else {
        nextKey = endKey;
      }
    }

    /*A D D   N E W   H I F D H   T O   D A T A B A S E*/
    Hifdh newHifdh = Hifdh(
      hifdh: '$key - $endKey',
      date:
          '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
      completed: false,
      nextKey: nextKey,
      planId: id,
    );

    final newHifdhDoc = await hifdhsCollection.add(newHifdh.toMap());

    /*C A L C U L A T E   H I F D H   D A T E*/
    DateTime today = DateTime.now();
    List<dynamic> hifdhDays = planData['hifdhDays'];
    bool calculated = false;
    int count = today.weekday - 1;
    int nextHifdh = 0;
    dynamic hifdh;

    if (hifdhs.isNotEmpty) {
      hifdh = hifdhs.last;
    }

    while (!calculated) {
      if (hifdhDays[count] == true &&
          nextHifdh != planData['hifdhIn'] &&
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
    //update hifdh date
    await hifdhsCollection.doc(newHifdhDoc.id).update({'date': nextHifdhDate});
    newHifdh.date = nextHifdhDate;
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
        updateNextHifdh(id);
      }
    }
  }

/*----------------------------------U P D A T E   N E X T   H I F D H----------------------------------*/
  Future<void> updateNextHifdh(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;
    dynamic currentWeek = planData['currentWeek'];

    final hifdh = await hifdhsCollection.where('planId', isEqualTo: id).get();
    final hifdhData = hifdh.docs;

    if (hifdhData.length != planData['hifdhs'].length) {
      final nextHifdh = await hifdhsCollection
          .where('planId', isEqualTo: id)
          .where('completed', isEqualTo: false)
          .get();

      final hifdhSnapshot =
          await hifdhsCollection.doc(nextHifdh.docs.last.id).get();
      String hifdhDate = planData['hifdhs'].last['date'];

      DateTime hifdhDT = DateTime(
        int.parse(hifdhDate.split('-')[2]),
        int.parse(hifdhDate.split('-')[1]),
        int.parse(hifdhDate.split('-')[0]),
        0,
        0,
      );

      dynamic weekDay = currentWeek[hifdhDT.weekday - 1];

      weekDay['completed'] = true;

      weeksCollection
          .where('weekStart', isEqualTo: weekDay['weekStart'])
          .get()
          .then(
            (value) =>
                value.docs[0].reference.update({'weekDays': currentWeek}),
          );

      List<dynamic> planHifdhs = planData['hifdhs'];
      planHifdhs = List.from(planHifdhs)
        ..add(hifdhSnapshot.data() as Map<String, dynamic>);

      await plansCollection.doc(id).update({
        'hifdhIn': 0,
        'hifdhs': planHifdhs,
        'currentWeek': currentWeek
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
        print('success');
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
        print('fail');
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

      await plansCollection.doc(id).update({
        'reviews': planData['reviews'],
      });
    }
  }

/*---------------------------------------H I F D H   M I S S E D---------------------------------------*/
  Future<void> hifdhMissed(String id) async {
    /**
     * * if a user last used the app on sunday and then goes back on tuesday(has hifdh on monday) monday isnt updated as missed
     * * if more than one day is missed only the last day is shown to be missed whilst the others are just blank
    **/
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

    weekDay['missed'] = true;

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
    final reviewsSnapshot =
        await reviewsCollection.where('planId', isEqualTo: id).get();
    final weeksSnapshot =
        await weeksCollection.where('planId', isEqualTo: id).get();

    hifdhsSnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });

    reviewsSnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });

    weeksSnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });
  }
}
