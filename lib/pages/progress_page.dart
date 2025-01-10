import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for demonstration
    final List<Map<String, dynamic>> surahData = [
      {'surah': 'Al-Fatiha', 'completedTasks': 7, 'totalTasks': 7, 'streak': 3},
      {
        'surah': 'Al-Baqarah',
        'completedTasks': 20,
        'totalTasks': 286,
        'streak': 5
      },
      {
        'surah': 'Al-Imran',
        'completedTasks': 10,
        'totalTasks': 200,
        'streak': 2
      },
      // Add more Surah data as needed
    ];

    final double overallProgress = surahData.fold(
            0.0,
            (sum, item) =>
                sum + (item['completedTasks'] / item['totalTasks'])) /
        surahData.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Page', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Overall Progress',
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: overallProgress,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            SizedBox(height: 10),
            Text(
              '${(overallProgress * 100).toStringAsFixed(0)}% Completed',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Streak: ${surahData.map((surah) => surah['streak']).reduce((a, b) => a + b)} days',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Progress by Surah:',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: surahData.length,
                itemBuilder: (context, index) {
                  final surah = surahData[index];
                  final double progress =
                      surah['completedTasks'] / surah['totalTasks'];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah['surah'],
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% Completed',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Streak: ${surah['streak']} days',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the previous page
              },
              child: Text('Back to Home', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}
