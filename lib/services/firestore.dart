import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    );

    /* * * * * * * * * * * M A K E   P L A N   A C T I V E   A S   S O O N   A S   N E W   P L A N   IS  A D D E D * * * * * * * * * * */

    final document = await plansCollection.add(newPlan.toMap());

    createNewHifdh(start, lines, document.id);
    updateActivePlan(document.id);
  }

  Stream<QuerySnapshot> getPlansStream() {
    final plansStream =
        plansCollection.orderBy('active', descending: true).snapshots();
    return plansStream;
  }

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

  Future<void> createNewHifdh(String key, int length, String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;
    List<dynamic> hifdhs = planData['hifdhs'];

    // Check if the plan has no hifdhs i.e the plan has just been made
    if (hifdhs.isNotEmpty) {
      dynamic hifdh = hifdhs.last;
      hifdh['completed'] = true;
      final hifdhSnapshot = await hifdhsCollection
          .where('hifdh', isEqualTo: hifdh['hifdh'])
          .where('planId', isEqualTo: id)
          .get();
      hifdhSnapshot.docs[0].reference.update({'completed': true});

      Timestamp reviewTimestamp = hifdh['date'];
      DateTime reviewDate = reviewTimestamp.toDate();
      final newReview = Review(
          review: hifdh['hifdh'], date: reviewDate, ratings: [], planId: id);
      await reviewsCollection.add(newReview.toMap());
      List<dynamic> planReviews = planData['reviews'];
      planReviews = List.from(planReviews)..add(newReview.toMap());

      plansCollection
          .doc(id)
          .update({'reviews': planReviews, 'hifdhs': hifdhs});
    }

    //calculate the hifdh start and end
    final verseSnapshot =
        await versesCollection.where('key', isEqualTo: key).get();
    String verseId = verseSnapshot.docs[0].reference.id;

    final verseDoc = await versesCollection.doc(verseId).get();
    Map<String, dynamic> verseData = verseDoc.data() as Map<String, dynamic>;
    double total = double.parse(verseData['length'].toString());

    while (length > total) {
      verseId = (int.parse(verseId) + 1).toString();
      final nextVerse = await versesCollection.doc(verseId).get();
      verseData = nextVerse.data() as Map<String, dynamic>;
      total += verseData['length'];
    }

    String endKey = verseData['key'];
    final nextVerse =
        await versesCollection.doc((int.parse(verseId) + 1).toString()).get();
    verseData = nextVerse.data() as Map<String, dynamic>;
    String nextKey = verseData['key'];

    // add new hifdh to database
    var newHifdh = Hifdh(
      hifdh: '$key - $endKey',
      date: DateTime.now(),
      completed: false,
      nextKey: nextKey,
      planId: id,
    );

    final newHifdhDoc = await hifdhsCollection.add(newHifdh.toMap());

    //calculate hifdh date
    int today = DateTime.now().weekday;
    List<dynamic> hifdhDays = planData['hifdhDays'];
    bool calculated = false;
    int count = today - 1;
    int nextHifdh = 0;
    dynamic hifdh;

    if (hifdhs.isNotEmpty) {
      hifdh = hifdhs.last;
    }

    while (calculated == false) {
      if (hifdhDays[count] == true &&
          nextHifdh != planData['hifdhIn'] &&
          (nextHifdh != 0 ||
              (nextHifdh == 0 &&
                  (hifdh == null || hifdh['completed'] == false)))) {
        calculated = true;
        break;
      } else if (count == 6) {
        count = 0;
      } else {
        count++;
      }
      nextHifdh++;
    }
    //update hifdh date
    await hifdhsCollection
        .doc(newHifdhDoc.id)
        .update({'date': DateTime.now().add(Duration(days: nextHifdh))});
    newHifdh.date = DateTime.now().add(Duration(days: nextHifdh));
    if (planData['hifdhs'].isEmpty) {
      //calculate time left until hifdh
      int hifdhIn = 0;
      final hifdhDoc = await hifdhsCollection.doc(newHifdhDoc.id).get();
      Map<String, dynamic> hifdhData = hifdhDoc.data() as Map<String, dynamic>;
      Timestamp hifdhTimestamp = hifdhData['date'];
      DateTime hifdhDate = hifdhTimestamp.toDate();
      if (hifdhDate.day != DateTime.now().day) {
        hifdhIn = hifdhDate.difference(DateTime.now()).inDays + 1;
      }

      List<dynamic> planHifdhs = planData['hifdhs'];
      planHifdhs = List.from(planHifdhs)..add(newHifdh.toMap());

      await plansCollection.doc(id).update({
        'hifdhIn': hifdhIn,
        'hifdhs': planHifdhs,
      }); //update plan with hifdhIn and newHifdh
    } else {
      Timestamp hifdhTimestamp = planData['hifdhs'].last['date'];
      DateTime hifdhDate = hifdhTimestamp.toDate();

      if (hifdhDate.day == DateTime.now().day) {
        updateNextHifdh(id);
      }
    }
  }

  Future<void> updateNextHifdh(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;

    final hifdh = await hifdhsCollection.where('planId', isEqualTo: id).get();
    final hifdhData = hifdh.docs;

    if (hifdhData.length != planData['hifdhs'].length) {
      final nextHifdh = await hifdhsCollection
          .where('planId', isEqualTo: id)
          .where('completed', isEqualTo: false)
          .get();

      final hifdhSnapshot =
          await hifdhsCollection.doc(nextHifdh.docs.last.id).get();
      //calculate time left until hifdh
      int hifdhIn = 0;
      Timestamp hifdhTimestamp = planData['hifdhs'].last['date'];
      DateTime hifdhDate = hifdhTimestamp.toDate();
      if (hifdhDate.day != DateTime.now().day) {
        hifdhIn = hifdhDate.difference(DateTime.now()).inDays + 1;
      }

      List<dynamic> planHifdhs = planData['hifdhs'];
      planHifdhs = List.from(planHifdhs)
        ..add(hifdhSnapshot.data() as Map<String, dynamic>);

      await plansCollection.doc(id).update({
        'hifdhIn': hifdhIn,
        'hifdhs': planHifdhs,
      }); //update plan with hifdhIn and newHifdh
    }
  }

  Future<void> hifdhIn(String id) async {
    final planSnapshot = await plansCollection.doc(id).get();
    final planData = planSnapshot.data() as Map<String, dynamic>;

    //calculate time left until hifdh
    int hifdhIn = 0;
    Timestamp hifdhTimestamp = planData['hifdhs'].last['date'];
    DateTime hifdhDate = hifdhTimestamp.toDate();
    if (hifdhDate.day != DateTime.now().day) {
      hifdhIn = hifdhDate.difference(DateTime.now()).inDays + 1;
    }

    await plansCollection
        .doc(id)
        .update({'hifdhIn': hifdhIn}); //update plan with hifdhIn
  }

  Future<void> deletePlan(String id) async {
    await plansCollection.doc(id).delete();
    final hifdhsSnapshot =
        await hifdhsCollection.where('planId', isEqualTo: id).get();
    final reviewsSnapshot =
        await reviewsCollection.where('planId', isEqualTo: id).get();

    hifdhsSnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });

    reviewsSnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });
  }
}
