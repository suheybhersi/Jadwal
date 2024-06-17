import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';

// ignore: must_be_immutable
class ReviewTile extends StatelessWidget {
  Map<String, dynamic> review;
  String id;

  ReviewTile({super.key, required this.review, required this.id});
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);
  final TextEditingController ratingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verses ${review['review']}',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Text(
            //   review['reviewIn'] == 0
            //       ? 'Today'
            //       : review['reviewIn'] == 1
            //           ? 'Tomorrow'
            //           : 'In ${review['reviewIn']} days',
            //   style: TextStyle(
            //     color: Colors.grey.shade100,
            //     fontSize: 20,
            //   ),
            // )
          ],
        ),
        IconButton(
          onPressed: () {
            // if (review['ratings'].isEmpty) {
            markReviewAsComplete(context, review['review']);
            // }
          },
          icon: ImageIcon(
            const AssetImage('assets/unchecked.png'),
            size: 35,
            color: Colors.grey.shade100,
          ),
        )
      ],
    );
  }

  void markReviewAsComplete(BuildContext context, String review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: TextFormField(
            // validator: (name) => name!.isEmpty ? 'give a rating...' : null,
            controller: ratingController,
            decoration: const InputDecoration(
                hintText: 'Rating', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              firestoreService.updateReview(id, review, ratingController.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
