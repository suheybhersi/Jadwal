class Review {
  final String review;
  final String date;
  final List<int> ratings;
  final String planId;
  final List<dynamic> sm2;

  Review({
    required this.review,
    required this.date,
    required this.ratings,
    required this.planId,
    required this.sm2,
  });

  Map<String, dynamic> toMap() {
    return {
      'review': review,
      'date': date,
      'ratings': ratings,
      'planId': planId,
      'sm2': sm2,
    };
  }
}
