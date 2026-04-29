import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/activity.dart';
import '../models/trip.dart';

class PdfExporter {
  /// 生成一份完整的行程详细版 PDF，并调用系统分享面板
  static Future<void> exportTripDetailed({
    required Trip trip,
    required List<TripActivity> activities,
  }) async {
    // 加载中文字体
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      title: trip.title,
      author: 'Dreamaker',
      creator: '旅行伴侣',
    );

    // 按天分组活动
    final byDay = <int, List<TripActivity>>{};
    for (final a in activities) {
      byDay.putIfAbsent(a.dayNumber, () => []).add(a);
    }
    // 每天内按时间和顺序排序
    for (final list in byDay.values) {
      list.sort((a, b) {
        if (a.startTime.isNotEmpty && b.startTime.isNotEmpty) {
          return a.startTime.compareTo(b.startTime);
        }
        return a.orderIndex.compareTo(b.orderIndex);
      });
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        build: (context) => [
          _buildHeader(trip, ttf),
          pw.SizedBox(height: 18),
          ...List.generate(trip.totalDays, (i) {
            final dayNum = i + 1;
            final date = trip.startDate.add(Duration(days: i));
            final list = byDay[dayNum] ?? [];
            return _buildDaySection(dayNum, date, list, ttf);
          }),
          pw.SizedBox(height: 12),
          _buildFooter(trip, ttf),
        ],
      ),
    );

    final bytes = await pdf.save();

    // 调用系统分享面板（Mac 上是预览/打印，iOS 上是分享菜单）
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFilename(trip.title)}.pdf',
    );
  }

  static pw.Widget _buildHeader(Trip trip, pw.Font ttf) {
    final fmt = DateFormat('yyyy年M月d日');
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF26215C), width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TRIP ITINERARY',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF888780),
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            trip.title,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1C1B19),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${fmt.format(trip.startDate)} – ${fmt.format(trip.endDate)} · 共 ${trip.totalDays} 天'
            '${trip.totalBudget > 0 ? ' · 预算 ¥ ${trip.totalBudget.toStringAsFixed(0)}' : ''}',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 11,
              color: const PdfColor.fromInt(0xFF5F5E5A),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDaySection(
    int dayNum,
    DateTime date,
    List<TripActivity> activities,
    pw.Font ttf,
  ) {
    final dateFmt = DateFormat('M月d日 EEEE', 'zh_CN');
    final totalCost =
        activities.fold(0.0, (sum, a) => sum + a.estimatedCost);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 日期标题
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 28,
                height: 28,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF26215C),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'D$dayNum',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 12,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  dateFmt.format(date),
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1C1B19),
                  ),
                ),
              ),
              if (totalCost > 0)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '当日支出',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF888780),
                      ),
                    ),
                    pw.Text(
                      '¥ ${totalCost.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1C1B19),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 10),
          // 活动列表
          if (activities.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 38),
              child: pw.Text(
                '（此日无活动安排）',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xFF888780),
                ),
              ),
            )
          else
            ...activities.map((a) => _buildActivityRow(a, ttf)),
        ],
      ),
    );
  }

  static pw.Widget _buildActivityRow(TripActivity a, pw.Font ttf) {
    final color = _typeColorPdf(a.type);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 38, top: 6, bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 时间
          pw.SizedBox(
            width: 44,
            child: pw.Text(
              a.startTime.isEmpty ? '--:--' : a.startTime,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 10,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          // 圆点
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 8),
          // 内容
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        a.title,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1C1B19),
                        ),
                      ),
                    ),
                    if (a.estimatedCost > 0)
                      pw.Text(
                        '¥ ${a.estimatedCost.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: const PdfColor.fromInt(0xFF5F5E5A),
                        ),
                      ),
                  ],
                ),
                if (a.location.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      a.location,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF5F5E5A),
                      ),
                    ),
                  ),
                if (a.note.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      a.note,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF888780),
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Trip trip, pw.Font ttf) {
    final exportDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColor.fromInt(0xFFD3D1C7)),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '由 旅行伴侣 生成',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF888780),
              ),
            ),
            pw.Text(
              '$exportDate 导出',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF888780),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PdfColor _typeColorPdf(ActivityType t) {
    return switch (t) {
      ActivityType.scenic => const PdfColor.fromInt(0xFF534AB7),
      ActivityType.diningBreakfast => const PdfColor.fromInt(0xFFEF9F27),
      ActivityType.diningMain => const PdfColor.fromInt(0xFF1D9E75),
      ActivityType.transport => const PdfColor.fromInt(0xFF888780),
      ActivityType.lodging => const PdfColor.fromInt(0xFF185FA5),
      ActivityType.shopping => const PdfColor.fromInt(0xFFD4537E),
      ActivityType.free => const PdfColor.fromInt(0xFF888780),
    };
  }

  static String _safeFilename(String s) {
    return s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  }
}