class Review {
  final String review;
  final String date;
  final List<int> ratings;
  final String planId;

  Review({
    required this.review,
    required this.date,
    required this.ratings,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'review': review,
      'date': date,
      'ratings': ratings,
      'planId': planId,
    };
  }
}
