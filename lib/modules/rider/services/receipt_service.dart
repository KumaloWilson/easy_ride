import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:easy_ride/models/ride_model.dart';
import 'package:easy_ride/modules/rider/models/fare_model.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easy_ride/core/utils/logs.dart';

class ReceiptService extends GetxService {
  Future<ReceiptService> init() async {
    return this;
  }

  Future<File> generateReceipt(RideModel ride, FareModel fare, {String? driverName, String? riderName}) async {
    final pdf = pw.Document();

    // Format dates
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final rideDate = ride.completedAt ?? DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Easy Ride',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Receipt #${ride.id.substring(0, 8)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${dateFormat.format(rideDate)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        'Time: ${timeFormat.format(rideDate)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Ride details
              pw.Text(
                'Ride Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              _buildDetailRow('Ride Type', ride.rideType),
              _buildDetailRow('Pickup', ride.pickup?.name ?? ""),
              _buildDetailRow('Dropoff', ride.dropoff?.name ?? ""),
              _buildDetailRow('Distance', '${fare.distance.toStringAsFixed(1)} km'),
              _buildDetailRow('Duration', '${fare.duration.toStringAsFixed(0)} min'),
              _buildDetailRow('Payment Method', ride.paymentMethod.toUpperCase()),

              if (driverName != null)
                _buildDetailRow('Driver', driverName),

              if (riderName != null)
                _buildDetailRow('Rider', riderName),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Fare breakdown
              pw.Text(
                'Fare Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              _buildFareRow('Base Fare', fare.baseFare),
              _buildFareRow('Distance (${fare.distance.toStringAsFixed(1)} km)', fare.distanceFare),
              _buildFareRow('Time (${fare.duration.toStringAsFixed(0)} min)', fare.timeFare),

              if (fare.surgeFactor > 1.0)
                _buildFareRow(
                  'Surge Pricing (${(fare.surgeFactor * 100 - 100).toStringAsFixed(0)}%)',
                  (fare.baseFare + fare.distanceFare + fare.timeFare) * (fare.surgeFactor - 1),
                ),

              if (fare.discount > 0)
                _buildFareRow('Discount', -fare.discount),

              _buildFareRow('Tax', fare.tax),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.Text(
                    '\$${fare.totalFare.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for riding with Easy Ride!',
                      style: const pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'For any inquiries, please contact support@easyride.com',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${ride.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFareRow(String label, double amount) {
    final isNegative = amount < 0;
    final formattedAmount = isNegative
        ? '-\$${amount.abs().toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(2)}';

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
          pw.Text(
            formattedAmount,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareReceipt(File receiptFile) async {
    try {
      await Share.shareXFiles(
        [XFile(receiptFile.path)],
        subject: 'Easy Ride Receipt',
        text: 'Here is your receipt for your recent ride with Easy Ride.',
      );
    } catch (e) {
      DevLogs.error('Failed to share receipt', exception: e);
      Get.snackbar(
        'Error',
        'Failed to share receipt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
