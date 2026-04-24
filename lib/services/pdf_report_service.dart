import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/assessment.dart';
import '../core/constants.dart';

/// Generates a branded PDF report for an assessment.
/// Updated: Phase 4 — TFLite Risk System
/// Replaces Z-score/nutritionPlan/imageUrl with risk probability + DDS + recommendations.
class PdfReportService {
  static Future<void> generateAndShare(
    BuildContext context,
    Assessment assessment,
  ) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        // Risk label and color
        String riskText;
        PdfColor riskColor;
        switch (assessment.riskCategory) {
          case RiskCategory.low:
            riskText = 'LOW RISK';
            riskColor = const PdfColor.fromInt(0xFF2ECC71);
            break;
          case RiskCategory.moderate:
            riskText = 'MODERATE RISK (MAM LIKELY)';
            riskColor = const PdfColor.fromInt(0xFFF39C12);
            break;
          case RiskCategory.high:
            riskText = 'HIGH RISK (SAM LIKELY)';
            riskColor = const PdfColor.fromInt(0xFFE74C3C);
            break;
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
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
                            'Nourish V',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF00897B),
                            ),
                          ),
                          pw.Text(
                            'Predictive Malnutrition Risk Report',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: riskColor,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          riskText,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.Divider(
                      thickness: 2,
                      color: const PdfColor.fromInt(0xFF00897B)),
                  pw.SizedBox(height: 16),

                  // Patient Info
                  pw.Text(
                    'Patient Information',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Name', assessment.patientName),
                  _buildInfoRow('Location', assessment.location),
                  _buildInfoRow(
                    'Assessment Date',
                    '${assessment.assessmentDate.day}/${assessment.assessmentDate.month}/${assessment.assessmentDate.year}',
                  ),

                  pw.SizedBox(height: 20),

                  // Risk Summary
                  pw.Text(
                    'Predictive Risk Assessment (TFLite)',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColor(riskColor.red, riskColor.green,
                          riskColor.blue, 0.08),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: PdfColor(riskColor.red, riskColor.green,
                            riskColor.blue, 0.3),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Risk Probability: ${assessment.riskPercentage}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          assessment.riskContextString,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Dietary Diversity
                  pw.Text(
                    'Dietary Diversity (24-Hour Recall)',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Diversity Score',
                      '${assessment.dietaryDiversityScore}/7 food groups'),
                  _buildInfoRow('Feeding Frequency',
                      '${assessment.feedingFrequency}× per day'),
                  _buildInfoRow('Recent Illness',
                      '${assessment.recentIllnessDays} days (last 2 weeks)'),

                  pw.SizedBox(height: 20),

                  // Preventive care
                  pw.Text(
                    'Preventive Care Status',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Vaccination Status',
                      assessment.vaccinationStatus == 2 ? 'Fully Vaccinated'
                      : assessment.vaccinationStatus == 1 ? 'Partially Vaccinated'
                      : 'Not Vaccinated'),
                  _buildInfoRow('Deworming',
                      assessment.dewormingHistory ? 'Yes' : 'No'),
                  _buildInfoRow('Micronutrient Supplements',
                      assessment.micronutrientSupplements ? 'Yes' : 'No'),

                  // Referral (high risk)
                  if (assessment.riskCategory == RiskCategory.high) ...[
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFDEDED),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFE74C3C),
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '⚠ Medical Referral Required',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFFE74C3C),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'This child is at high risk of severe malnutrition. '
                            'Refer to the nearest Primary Health Centre immediately.',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // Footer
                  pw.Divider(color: PdfColors.grey300),
                  pw.Text(
                    'Generated by Nourish V - TFLite Predictive Risk System | Offline-First',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
      name:
          'NourishV_Report_${assessment.patientName.replaceAll(' ', '_')}',
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
