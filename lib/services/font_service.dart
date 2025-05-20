import 'package:flutter/services.dart';

class FontService {
  static Future<void> loadPageFont(int pageNumber) async {
    final pageStr = pageNumber.toString();
    final fontLoader = FontLoader('Page$pageStr');
    fontLoader.addFont(
      rootBundle.load('assets/fonts/page_fonts/p$pageStr.ttf'),
    );
    await fontLoader.load();
  }

  static String getPageFontFamily(int pageNumber) {
    return 'Page${pageNumber.toString()}';
  }
}
