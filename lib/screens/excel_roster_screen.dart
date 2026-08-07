import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/roster_service.dart';

class ExcelRosterScreen extends StatefulWidget {
  const ExcelRosterScreen({super.key});

  @override
  State<ExcelRosterScreen> createState() =>
      _ExcelRosterScreenState();
}

class _ExcelRosterScreenState extends State<ExcelRosterScreen> {
  DateTime selectedMonth = DateTime.now();

  bool isGenerating = false;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color restGreen = Color(0xFF99FF33);

  // ===================================================
  // MONTH NAME
  // ===================================================

  String monthName(int month) {
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
      'December',
    ];

    return months[month - 1];
  }

  // ===================================================
  // WEEKDAY
  // ===================================================

  String shortWeekday(DateTime date) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return weekdays[date.weekday - 1];
  }

  // ===================================================
  // MONTH CONTROL
  // ===================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  // ===================================================
  // EXCEL STATUS
  // ===================================================

  String getExcelStatus(
    String group,
    DateTime date,
  ) {
    final status = RosterService.getStatus(
      group,
      date,
    );

    if (status == 'D') {
      return 'M';
    }

    if (status == 'N') {
      return 'N';
    }

    return 'R';
  }

  // ===================================================
  // EXCEL START DATE
  // ===================================================

  DateTime excelStartDate() {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    return firstDay.subtract(
      const Duration(days: 7),
    );
  }

  // ===================================================
  // COLUMN NAME
  // ===================================================

  String columnName(int column) {
    String result = '';
    int value = column;

    while (value > 0) {
      value--;

      result =
          String.fromCharCode(
            65 + (value % 26),
          ) +
          result;

      value ~/= 26;
    }

    return result;
  }

  // ===================================================
  // XML ESCAPE
  // ===================================================

  String xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ===================================================
  // SET CELL TEXT
  //
  // Handles:
  //
  // <c r="A1">...</c>
  //
  // AND
  //
  // <c r="B4" s="125" />
  //
  // ===================================================

  String setCellText(
    String xml,
    String cellReference,
    String value,
  ) {
    final escapedValue = xmlEscape(value);

    // ===============================================
    // NORMAL CELL
    // ===============================================

    final normalPattern = RegExp(
      '<c\\b([^>]*\\br="$cellReference"[^>]*)>'
      '.*?</c>',
      dotAll: true,
    );

    final normalMatch =
        normalPattern.firstMatch(xml);

    if (normalMatch != null) {
      var attributes =
          normalMatch.group(1) ?? '';

      // Remove old type.
      attributes = attributes.replaceAll(
        RegExp(r'\s+t="[^"]*"'),
        '',
      );

      // Remove accidental trailing slash.
      attributes = attributes.replaceAll(
        RegExp(r'\s*/\s*$'),
        '',
      );

      final newCell =
          '<c$attributes t="inlineStr">'
          '<is><t>$escapedValue</t></is>'
          '</c>';

      return xml.replaceRange(
        normalMatch.start,
        normalMatch.end,
        newCell,
      );
    }

    // ===============================================
    // SELF-CLOSING CELL
    // ===============================================

    final selfClosingPattern = RegExp(
      '<c\\b([^>]*\\br="$cellReference"[^>]*)/\\s*>',
    );

    final selfClosingMatch =
        selfClosingPattern.firstMatch(xml);

    if (selfClosingMatch != null) {
      var attributes =
          selfClosingMatch.group(1) ?? '';

      // Remove old type.
      attributes = attributes.replaceAll(
        RegExp(r'\s+t="[^"]*"'),
        '',
      );

      // CRITICAL FIX:
      //
      // Prevent invalid XML like:
      //
      // <c r="B4" s="125" / t="inlineStr">
      //
      attributes = attributes.replaceAll(
        RegExp(r'\s*/\s*$'),
        '',
      );

      final newCell =
          '<c$attributes t="inlineStr">'
          '<is><t>$escapedValue</t></is>'
          '</c>';

      return xml.replaceRange(
        selfClosingMatch.start,
        selfClosingMatch.end,
        newCell,
      );
    }

    return xml;
  }

  // ===================================================
  // NORMAL ROSTER STYLE
  // M + N = NO GREEN
  // ===================================================

  int normalStyleFor(int currentStyle) {
    switch (currentStyle) {
      // BORDER 13
      case 16:
      case 25:
      case 29:
        return 25;

      // BORDER 14
      case 10:
      case 12:
      case 15:
      case 28:
        return 10;

      // BORDER 16
      case 11:
      case 19:
      case 32:
        return 11;

      // BORDER 17
      case 18:
      case 27:
        return 27;

      // BORDER 18
      case 13:
      case 17:
      case 26:
      case 31:
        return 13;

      // BORDER 19
      case 20:
        return 20;

      default:
        return currentStyle;
    }
  }

  // ===================================================
  // REST STYLE
  // ONLY R = GREEN
  // ===================================================

  int restStyleFor(int currentStyle) {
    switch (currentStyle) {
      // BORDER 13
      case 16:
      case 25:
      case 29:
        return 16;

      // BORDER 14
      case 10:
      case 12:
      case 15:
      case 28:
        return 15;

      // BORDER 16
      case 11:
      case 19:
      case 32:
        return 19;

      // BORDER 17
      case 18:
      case 27:
        return 18;

      // BORDER 18
      case 13:
      case 17:
      case 26:
      case 31:
        return 17;

      // BORDER 19
      case 20:
        return 20;

      default:
        return currentStyle;
    }
  }

  // ===================================================
  // SET ROSTER CELL
  //
  // R = GREEN
  // M = NORMAL
  // N = NORMAL
  //
  // Template shared strings:
  //
  // 3 = R
  // 4 = M
  // 5 = N
  //
  // ===================================================

  String setRosterCell(
    String xml,
    String cellReference,
    String value,
  ) {
    final pattern = RegExp(
      '<c\\b([^>]*\\br="$cellReference"[^>]*)>'
      '.*?</c>',
      dotAll: true,
    );

    final match = pattern.firstMatch(xml);

    if (match == null) {
      return xml;
    }

    var attributes =
        match.group(1) ?? '';

    // ===============================================
    // CURRENT STYLE
    // ===============================================

    final styleMatch = RegExp(
      r'\bs="(\d+)"',
    ).firstMatch(attributes);

    final currentStyle =
        int.tryParse(
          styleMatch?.group(1) ?? '',
        ) ??
        10;

    // ===============================================
    // CHOOSE STYLE
    // ===============================================

    final int newStyle;

    if (value == 'R') {
      newStyle =
          restStyleFor(currentStyle);
    } else {
      newStyle =
          normalStyleFor(currentStyle);
    }

    // ===============================================
    // SHARED STRING
    // ===============================================

    int sharedStringIndex;

    switch (value) {
      case 'R':
        sharedStringIndex = 3;
        break;

      case 'M':
        sharedStringIndex = 4;
        break;

      case 'N':
        sharedStringIndex = 5;
        break;

      default:
        sharedStringIndex = 3;
    }

    // ===============================================
    // CLEAN OLD TYPE
    // ===============================================

    attributes = attributes.replaceAll(
      RegExp(r'\s+t="[^"]*"'),
      '',
    );

    // ===============================================
    // CLEAN OLD STYLE
    // ===============================================

    attributes = attributes.replaceAll(
      RegExp(r'\s+s="\d+"'),
      '',
    );

    // ===============================================
    // REMOVE TRAILING SLASH IF PRESENT
    // ===============================================

    attributes = attributes.replaceAll(
      RegExp(r'\s*/\s*$'),
      '',
    );

    // ===============================================
    // CREATE VALID CELL
    // ===============================================

    final newCell =
        '<c$attributes '
        's="$newStyle" '
        't="s">'
        '<v>$sharedStringIndex</v>'
        '</c>';

    return xml.replaceRange(
      match.start,
      match.end,
      newCell,
    );
  }

  // ===================================================
  // CHANGE SHEET NAME
  // ===================================================

  String changeSheetName(
    String workbookXml,
  ) {
    final newName =
        '${monthName(selectedMonth.month)} '
        '${selectedMonth.year}';

    return workbookXml.replaceFirst(
      RegExp(
        '<sheet name="[^"]*"',
      ),
      '<sheet name="${xmlEscape(newName)}"',
    );
  }

  // ===================================================
  // DOWNLOAD EXCEL
  // ===================================================

  Future<void> downloadExcel() async {
    if (isGenerating) {
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      // ===============================================
      // LOAD ORIGINAL TEMPLATE
      // ===============================================

      final data = await rootBundle.load(
        'assets/templates/duty_roster_template.xlsx',
      );

      final originalBytes =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // ===============================================
      // XLSX = ZIP
      // ===============================================

      final archive =
          ZipDecoder().decodeBytes(
        originalBytes,
      );

      // ===============================================
      // FIND XML FILES
      // ===============================================

      final worksheetFile =
          archive.findFile(
        'xl/worksheets/sheet1.xml',
      );

      final workbookFile =
          archive.findFile(
        'xl/workbook.xml',
      );

      if (worksheetFile == null ||
          workbookFile == null) {
        throw Exception(
          'Excel template structure not found.',
        );
      }

      // ===============================================
      // READ XML
      // ===============================================

      String sheetXml =
          String.fromCharCodes(
        worksheetFile.content as List<int>,
      );

      String workbookXml =
          String.fromCharCodes(
        workbookFile.content as List<int>,
      );

      // ===============================================
      // CHANGE SHEET NAME
      // ===============================================

      workbookXml =
          changeSheetName(
        workbookXml,
      );

      // ===============================================
      // TITLE
      // ===============================================

      sheetXml = setCellText(
        sheetXml,
        'A1',
        'Duty Roster of '
        '${monthName(selectedMonth.month)} '
        '${selectedMonth.year}',
      );

      // ===============================================
      // ROW 4 MONTH HEADERS
      // ===============================================

      const shortMonths = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

  

      
      // ===============================================
      // EXAMPLES
      //
      // August 2026
      // B4 = Jul 26
      // I4 = Aug 26
      //
      // September 2026
      // B4 = Aug 26
      // I4 = Sep 26
      //
      // October 2026
      // B4 = Sep 26
      // I4 = Oct 26
      // ===============================================

      final row4StartDate = excelStartDate();

final row4PreviousMonth = DateTime(
  row4StartDate.year,
  row4StartDate.month,
);

final row4CurrentMonth = DateTime(
  selectedMonth.year,
  selectedMonth.month,
);

final row4PreviousText =
    '${shortMonths[row4PreviousMonth.month - 1]} '
    '${row4PreviousMonth.year.toString().substring(2)}';

final row4CurrentText =
    '${shortMonths[row4CurrentMonth.month - 1]} '
    '${row4CurrentMonth.year.toString().substring(2)}';

sheetXml = setCellText(
  sheetXml,
  'A4',
  row4PreviousText,
);

sheetXml = setCellText(
  sheetXml,
  'I4',
  row4CurrentText,
);

      // ===============================================
      // DATE RANGE
      //
      // B -> AM
      // 38 DAYS
      // ===============================================

      final startDate =
          excelStartDate();

      for (int index = 0;
          index < 38;
          index++) {
        final date =
            startDate.add(
          Duration(
            days: index,
          ),
        );

        final column =
            columnName(
          index + 2,
        );

        // =============================================
        // DATE ROW
        // =============================================

        sheetXml = setCellText(
          sheetXml,
          '${column}5',
          date.day.toString(),
        );

        // =============================================
        // WEEKDAY ROW
        // =============================================

        sheetXml = setCellText(
          sheetXml,
          '${column}6',
          shortWeekday(date),
        );
      }

      // ===============================================
      // GROUP ROWS
      // ===============================================

      const groups = {
        'G-A': 7,
        'G-B': 8,
        'G-C': 9,
        'G-D': 10,
      };

      for (final entry
          in groups.entries) {
        final group = entry.key;
        final row = entry.value;

        for (int index = 0;
            index < 38;
            index++) {
          final date =
              startDate.add(
            Duration(
              days: index,
            ),
          );

          final column =
              columnName(
            index + 2,
          );

          final status =
              getExcelStatus(
            group,
            date,
          );

          // ===========================================
          // R = GREEN
          // M = WHITE / NO HIGHLIGHT
          // N = WHITE / NO HIGHLIGHT
          // ===========================================

          sheetXml = setRosterCell(
            sheetXml,
            '$column$row',
            status,
          );
        }
      }

      // ===============================================
      // CREATE NEW XLSX ARCHIVE
      // ===============================================

      final newArchive =
          Archive();

      for (final archiveFile
          in archive) {
        // =============================================
        // SHEET XML
        // =============================================

        if (archiveFile.name ==
            'xl/worksheets/sheet1.xml') {
          final bytes =
              Uint8List.fromList(
            sheetXml.codeUnits,
          );

          newArchive.addFile(
            ArchiveFile(
              archiveFile.name,
              bytes.length,
              bytes,
            ),
          );
        }

        // =============================================
        // WORKBOOK XML
        // =============================================

        else if (archiveFile.name ==
            'xl/workbook.xml') {
          final bytes =
              Uint8List.fromList(
            workbookXml.codeUnits,
          );

          newArchive.addFile(
            ArchiveFile(
              archiveFile.name,
              bytes.length,
              bytes,
            ),
          );
        }

        // =============================================
        // KEEP EVERYTHING ELSE EXACTLY SAME
        // =============================================

        else {
          final content =
              archiveFile.content
                  as List<int>;

          newArchive.addFile(
            ArchiveFile(
              archiveFile.name,
              content.length,
              content,
            ),
          );
        }
      }

      // ===============================================
      // ENCODE XLSX
      // ===============================================

      final outputBytes =
          ZipEncoder().encode(
        newArchive,
      );

      if (outputBytes == null) {
        throw Exception(
          'Excel file could not be created.',
        );
      }

      // ===============================================
      // TEMP DIRECTORY
      // ===============================================

      final directory =
          await getTemporaryDirectory();

      // ===============================================
      // FILE NAME
      // ===============================================

      final fileName =
          'Duty Roster of '
          '${monthName(selectedMonth.month)} '
          '${selectedMonth.year}.xlsx';

      final file = File(
        '${directory.path}/$fileName',
      );

      // ===============================================
      // WRITE FILE
      // ===============================================

      await file.writeAsBytes(
        outputBytes,
        flush: true,
      );

      // ===============================================
      // SHARE / SAVE
      // ===============================================

      final params =
          ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: fileName,
        text:
            '${monthName(selectedMonth.month)} '
            '${selectedMonth.year} Duty Roster',
      );

      await SharePlus.instance.share(
        params,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Excel তৈরি করা যায়নি: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final daysInMonth =
        DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final dates =
        List.generate(
      daysInMonth,
      (index) => DateTime(
        selectedMonth.year,
        selectedMonth.month,
        index + 1,
      ),
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F6F9,
      ),

      appBar: AppBar(
        backgroundColor:
            primaryBlue,
        foregroundColor:
            Colors.white,
        centerTitle: true,

        title: const Text(
          'Excel Duty Roster',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // =============================================
          // MONTH SELECTOR
          // =============================================

          Container(
            color:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),

            child: Row(
              children: [
                IconButton(
                  onPressed:
                      previousMonth,
                  icon:
                      const Icon(
                    Icons
                        .chevron_left_rounded,
                    size: 32,
                  ),
                ),

                Expanded(
                  child: Text(
                    '${monthName(selectedMonth.month)} '
                    '${selectedMonth.year}',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed:
                      nextMonth,
                  icon:
                      const Icon(
                    Icons
                        .chevron_right_rounded,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // =============================================
          // DOWNLOAD BUTTON
          // =============================================

          Container(
            width:
                double.infinity,
            color:
                Colors.white,

            padding:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),

            child:
                FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    primaryBlue,
                foregroundColor:
                    Colors.white,
                minimumSize:
                    const Size(
                  double.infinity,
                  52,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              onPressed:
                  isGenerating
                      ? null
                      : downloadExcel,

              icon:
                  isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .download_rounded,
                        ),

              label: Text(
                isGenerating
                    ? 'Creating Excel...'
                    : 'Download Excel',
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // =============================================
          // LEGEND
          // =============================================

          Container(
            width:
                double.infinity,
            color:
                const Color(
              0xFFE3F2FD,
            ),

            padding:
                const EdgeInsets.all(
              9,
            ),

            child: const Text(
              'M = Day Duty   •   N = Night Duty   •   R = Rest',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    primaryBlue,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          // =============================================
          // PREVIEW
          // =============================================

          Expanded(
            child:
                SingleChildScrollView(
              child:
                  SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // =================================
                      // TITLE
                      // =================================

                      Container(
                        width:
                            75 +
                            daysInMonth *
                                48,
                        height: 45,
                        alignment:
                            Alignment.center,

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFCC99,
                          ),
                          border:
                              Border.all(),
                        ),

                        child: Text(
                          'Duty Roster of '
                          '${monthName(selectedMonth.month)} '
                          '${selectedMonth.year}',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      // =================================
                      // DATE ROW
                      // =================================

                      Row(
                        children: [
                          headerCell(
                            'Date',
                            75,
                          ),

                          ...dates.map(
                            (date) =>
                                headerCell(
                              '${date.day}',
                              48,
                            ),
                          ),
                        ],
                      ),

                      // =================================
                      // DAY ROW
                      // =================================

                      Row(
                        children: [
                          headerCell(
                            'Day',
                            75,
                          ),

                          ...dates.map(
                            (date) =>
                                headerCell(
                              shortWeekday(
                                date,
                              ),
                              48,
                            ),
                          ),
                        ],
                      ),

                      // =================================
                      // GROUP A
                      // =================================

                      rosterRow(
                        'G-A',
                        'A',
                        dates,
                      ),

                      // =================================
                      // GROUP B
                      // =================================

                      rosterRow(
                        'G-B',
                        'B',
                        dates,
                      ),

                      // =================================
                      // GROUP C
                      // =================================

                      rosterRow(
                        'G-C',
                        'C',
                        dates,
                      ),

                      // =================================
                      // GROUP D
                      // =================================

                      rosterRow(
                        'G-D',
                        'D',
                        dates,
                      ),

                      const SizedBox(
                        height: 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // HEADER CELL
  // ===================================================

  Widget headerCell(
    String text,
    double width,
  ) {
    return Container(
      width: width,
      height: 44,
      alignment:
          Alignment.center,

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        border:
            Border.all(),
      ),

      child: Text(
        text,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // ===================================================
  // ROSTER ROW
  // ===================================================

  Widget rosterRow(
    String group,
    String label,
    List<DateTime> dates,
  ) {
    return Row(
      children: [
        // =============================================
        // GROUP LABEL
        // =============================================

        Container(
          width: 75,
          height: 48,
          alignment:
              Alignment.center,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFE8F5E9,
            ),
            border:
                Border.all(),
          ),

          child: Text(
            label,
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        // =============================================
        // ROSTER CELLS
        // =============================================

        ...dates.map(
          (date) {
            final status =
                getExcelStatus(
              group,
              date,
            );

            return Container(
              width: 48,
              height: 48,
              alignment:
                  Alignment.center,

              decoration:
                  BoxDecoration(
                // =====================================
                // ONLY REST GREEN
                // =====================================

                color:
                    status == 'R'
                        ? restGreen
                        : Colors.white,

                border:
                    Border.all(),
              ),

              child: Text(
                status,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}