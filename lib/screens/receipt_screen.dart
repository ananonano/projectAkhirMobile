import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ReceiptScreen extends StatefulWidget {
  final String namaLapangan;
  final String tanggal;
  final String jam;
  final double totalDibayar;
  final String mataUang;
  final String metodeBayar;

  const ReceiptScreen({
    super.key,
    required this.namaLapangan,
    required this.tanggal,
    required this.jam,
    required this.totalDibayar,
    required this.mataUang,
    required this.metodeBayar,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
    _sendNotifications();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendNotifications() async {
    final notif = NotificationService.instance;
    await notif.showBookingConfirmation(
      namaLapangan: widget.namaLapangan,
      tanggal: widget.tanggal,
      jam: widget.jam,
    );
    final jamMulai = widget.jam.split(',').first.trim();
    await notif.scheduleBookingReminder(
      bookingId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      namaLapangan: widget.namaLapangan,
      tanggal: widget.tanggal,
      jamMulai: jamMulai,
    );
  }

  Future<void> _cetakPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("LAPANG.IN - INVOICE BUKTI BOOKING", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Detail Pesanan:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Lapangan: ${widget.namaLapangan}", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Tanggal: ${widget.tanggal}", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Jam: ${widget.jam}", style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Pembayaran:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Metode: ${widget.metodeBayar}", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Total Lunas: ${widget.mataUang} ${widget.totalDibayar.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
              pw.SizedBox(height: 40),
              pw.Text("Terima kasih telah menggunakan Lapang.in!", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk_Lapangin_${widget.namaLapangan.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: '${widget.mataUang} ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Berhasil'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Animated checkmark
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Booking Sukses!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Lapangan siap menunggumu 🎉', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 14)),

            const SizedBox(height: 28),

            // Receipt card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(widget.namaLapangan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _receiptRow(Icons.calendar_today_rounded, 'Tanggal', widget.tanggal),
                        const Divider(height: 20),
                        _receiptRow(Icons.access_time_rounded, 'Jam', widget.jam),
                        const Divider(height: 20),
                        _receiptRow(Icons.payment_rounded, 'Metode', widget.metodeBayar),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.attach_money_rounded, size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text('Total Bayar', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                            Text(
                              fmt.format(widget.totalDibayar),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // PDF Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _cetakPDF,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text('Download Struk PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        Flexible(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
