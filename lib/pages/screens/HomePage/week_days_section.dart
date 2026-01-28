import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';

class WeekDaysSection extends StatelessWidget {
  const WeekDaysSection({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  color: Color.fromARGB(255, 73, 121, 251),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'This Week',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              children: [
                // Days of the week with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    dynamic day = plan['currentWeek'][index];
                    List<String> weekStartString = day['weekStart'].split('-');
                    List<String> today =
                        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}'
                            .split('-');
                    DateTime weekStart = DateTime(
                      int.parse(weekStartString[2]),
                      int.parse(weekStartString[1]),
                      int.parse(weekStartString[0]),
                      0,
                      0,
                    );

                    DateTime todayDT = DateTime(
                      int.parse(today[2]),
                      int.parse(today[1]),
                      int.parse(today[0]),
                      0,
                      0,
                    );

                    DateTime dayDate = weekStart.add(Duration(days: index));
                    String formattedDate =
                        '${dayDate.day}-${dayDate.month}-${dayDate.year}';

                    bool isToday =
                        weekStart.add(Duration(days: index)) == todayDT;
                    bool isPast =
                        weekStart.add(Duration(days: index)).isBefore(todayDT);
                    bool hasHifdh = plan['hifdhDays'][index] == true;
                    bool isCompleted = day['completed'] && (isToday || isPast);
                    bool isMissed = day['missed'] && (isToday || isPast);

                    // Determine status color
                    Color statusColor = Colors.transparent;
                    if (hasHifdh) {
                      if (isCompleted) {
                        statusColor = Color.fromARGB(255, 113, 233, 175);
                      } else if (isMissed) {
                        statusColor = Colors.red.shade300;
                      } else if (isToday) {
                        statusColor = Color.fromARGB(255, 73, 121, 251);
                      } else if (!isPast) {
                        statusColor = Color.fromARGB(255, 254, 189, 89);
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        _showDayDetails(context, dayDate, formattedDate, plan,
                            isPast, hasHifdh);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Color.fromARGB(255, 73, 121, 251)
                                  : Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: Color.fromARGB(255, 73, 121, 251)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${weekStart.add(Duration(days: index)).day}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            day['day'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w600 : FontWeight.w500,
                              color: isToday
                                  ? Color.fromARGB(255, 73, 121, 251)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Status indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(
      BuildContext context,
      DateTime dayDate,
      String formattedDate,
      Map<String, dynamic> plan,
      bool isPast,
      bool hasHifdh) {
    // Find hifdh tasks for this day
    List<dynamic> hifdhTasks = [];
    if (plan['hifdhs'] != null) {
      hifdhTasks = plan['hifdhs']
          .where((hifdh) => hifdh['date'] == formattedDate)
          .toList();
    }

    // Find missed hifdh tasks for this day
    List<dynamic> missedHifdhTasks = [];
    if (plan['missedHifdhs'] != null) {
      missedHifdhTasks = plan['missedHifdhs']
          .where((hifdh) => hifdh['date'] == formattedDate)
          .toList();
    }

    // Find review tasks for this day (only if not in Flexible mode)
    List<dynamic> reviewTasks = [];
    final prefsService = Provider.of<UserPreferencesService>(context, listen: false);
    if (prefsService.shouldScheduleReviews && plan['reviews'] != null) {
      reviewTasks = plan['reviews']
          .where((review) => review['date'] == formattedDate)
          .toList();
    }

    Widget makeDissmissable({required Widget child}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return makeDissmissable(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ListView(
                          controller: controller,
                          children: [
                            // Header with date
                            Container(
                              margin: EdgeInsets.only(top: 16, bottom: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color:
                                              Color.fromARGB(255, 73, 121, 251)
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${dayDate.day}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromARGB(
                                                  255, 73, 121, 251),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getDayName(dayDate.weekday),
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${_getMonthName(dayDate.month)} ${dayDate.year}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isPast
                                          ? Theme.of(context)
                                              .colorScheme
                                              .inversePrimary
                                              .withValues(alpha: 0.1)
                                          : Color.fromARGB(255, 73, 121, 251)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPast
                                              ? Iconsax.clock
                                              : Iconsax.calendar_1,
                                          size: 14,
                                          color: isPast
                                              ? Colors.grey.shade700
                                              : Color.fromARGB(
                                                  255, 73, 121, 251),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          isPast ? 'Past' : 'Upcoming',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isPast
                                                ? Colors.grey.shade700
                                                : Color.fromARGB(
                                                    255, 73, 121, 251),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Summary section
                            Container(
                              margin: EdgeInsets.only(bottom: 24),
                              padding: EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryItem(
                                      hifdhTasks.length +
                                          missedHifdhTasks.length,
                                      'Memorisation',
                                      Iconsax.book_1,
                                      Color.fromARGB(255, 73, 121, 251)),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withValues(alpha: 0.5),
                                  ),
                                  // Only show review count if reviews are enabled
                                  if (Provider.of<UserPreferencesService>(context, listen: false).shouldScheduleReviews)
                                    _buildSummaryItem(
                                        reviewTasks.length,
                                        'Reviews',
                                        Iconsax.refresh,
                                        Color.fromARGB(255, 100, 163, 119)),
                                ],
                              ),
                            ),

                            // No tasks message
                            Builder(
                              builder: (context) {
                                final prefsService = Provider.of<UserPreferencesService>(context, listen: false);
                                final showReviews = prefsService.shouldScheduleReviews;
                                final hasNoTasks = hifdhTasks.isEmpty &&
                                    (!showReviews || reviewTasks.isEmpty) &&
                                    missedHifdhTasks.isEmpty;
                                
                                if (!hasNoTasks) return SizedBox();
                                
                                return Container(
                                margin: EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      hasHifdh
                                          ? Iconsax.calendar_1
                                          : Iconsax.calendar_remove,
                                      size: 60,
                                      color: Colors.grey.shade300,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      hasHifdh
                                          ? isPast
                                              ? 'No completed tasks found'
                                              : 'Tasks will appear here soon'
                                          : 'No tasks scheduled for this day',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      hasHifdh
                                          ? isPast
                                              ? 'Tasks may have been missed or rescheduled'
                                              : 'Check back later for updates'
                                          : 'This is a rest day in your schedule',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                              },
                            ),

                            // Hifdh tasks
                            if (hifdhTasks.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'Memorisation Tasks', Iconsax.book_1),
                              SizedBox(height: 12),
                              ...hifdhTasks.map((hifdh) =>
                                  _buildHifdhCard(hifdh, isPast, context)),
                              SizedBox(height: 24),
                            ],

                            // Missed Hifdh tasks
                            if (missedHifdhTasks.isNotEmpty) ...[
                              _buildSectionHeader(
                                  'Memorisation Tasks', Iconsax.book_1),
                              SizedBox(height: 12),
                              ...missedHifdhTasks.map((hifdh) =>
                                  _buildHifdhCard(hifdh, true, context)),
                              SizedBox(height: 24),
                            ],

                            // Review tasks (only show if reviews are enabled)
                            Builder(
                              builder: (context) {
                                final prefsService = Provider.of<UserPreferencesService>(context, listen: false);
                                if (!prefsService.shouldScheduleReviews || reviewTasks.isEmpty) {
                                  return SizedBox();
                                }
                                
                                return Column(
                                  children: [
                                    _buildSectionHeader(
                                        'Review Tasks', Iconsax.refresh),
                                    SizedBox(height: 12),
                                    ...reviewTasks.map(
                                        (review) => _buildReviewCard(review, isPast)),
                                    SizedBox(height: 24),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildSummaryItem(
      int count, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Color.fromARGB(255, 73, 121, 251),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHifdhCard(
      Map<String, dynamic> hifdh, bool isPast, BuildContext context) {
    // Split the surah string to get start and end surahs
    List<String> surahs = hifdh['surah'].split(' ');
    String startSurah = surahs[0];
    String endSurah = surahs.length > 1 ? surahs[1] : surahs[0];

    // Get verse numbers
    String startVerse = hifdh['hifdh'].split('-')[0].split(':')[1];
    String endVerse = hifdh['hifdh'].split('-')[1].split(':')[1];

    // Check if this is a missed hifdh (from missedHifdhs array)
    bool isMissedHifdh = !hifdh.containsKey('completed');
    bool isCompleted =
        hifdh.containsKey('completed') ? hifdh['completed'] : false;

    // Status text and color
    String statusText = isCompleted
        ? 'Completed'
        : isMissedHifdh
            ? 'Missed'
            : isPast
                ? 'Missed'
                : 'Upcoming';

    Color statusColor = isCompleted
        ? Color.fromARGB(255, 90, 180, 140) // Less bright green
        : isMissedHifdh || isPast
            ? Colors.red.shade300
            : Color.fromARGB(255, 254, 189, 89);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 73, 121, 251).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 73, 121, 251),
                Color.fromARGB(255, 114, 152, 255),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Status indicator in top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start verse section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.book_1,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah $startSurah',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Verse $startVerse',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Divider with arrow
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.arrow_down_1,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // End verse section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.book_1,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah $endSurah',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Verse $endVerse',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isPast) {
    // Split the surah string to get start and end surahs
    List<String> surahs = review['surah'].split(' ');
    String startSurah = surahs[0];
    String endSurah = surahs.length > 1 ? surahs[1] : surahs[0];

    // Get verse numbers
    String startVerse = review['review'].split('-')[0].split(':')[1];
    String endVerse = review['review'].split('-')[1].split(':')[1];

    // Determine status based on date and ratings
    bool isCompleted =
        review['ratings'] != null && review['ratings'].isNotEmpty;
    String statusText =
        isPast ? (isCompleted ? 'Completed' : 'Missed') : 'Upcoming';

    Color statusColor = isPast
        ? (isCompleted
            ? Color.fromARGB(255, 90, 180, 140) // Less bright green
            : Colors.red.shade300)
        : Color.fromARGB(255, 254, 189, 89);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 100, 163, 119).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 100, 163, 119),
                Color.fromARGB(255, 129, 186, 145),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Status indicator in top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start verse section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Surah $startSurah',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Verse $startVerse',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Divider with arrow
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.arrow_down_1,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // End verse section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.refresh,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah $endSurah',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Verse $endVerse',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
