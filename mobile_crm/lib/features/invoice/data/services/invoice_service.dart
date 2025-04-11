import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../repair/domain/entities/repair_job.dart';
import '../../domain/entities/invoice.dart';

class InvoiceService {
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final FirestoreService _firestoreService = getService<FirestoreService>();
  final _uuid = const Uuid();
  
  // Generate a new invoice for a repair job
  Future<Invoice> generateInvoice(RepairJob repairJob) async {
    // Get shop information
    final shopInfo = await _getShopInfo();
    
    // Calculate invoice amounts
    final subtotal = repairJob.estimatedCost;
    final taxRate = 0.18; // 18% GST (can be made configurable)
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount;
    final amountPaid = repairJob.advanceAmount;
    final amountDue = total - amountPaid;
    
    // Generate invoice number
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';
    
    // Create invoice
    return Invoice(
      id: _uuid.v4(),
      invoiceNumber: invoiceNumber,
      invoiceDate: now,
      repairJob: repairJob,
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      amountPaid: amountPaid,
      amountDue: amountDue,
      notes: 'Thank you for your business!',
      termsAndConditions: 'All repair services come with a 30-day warranty. Returns and refunds are subject to our store policy.',
      shopName: shopInfo['shopName'],
      shopAddress: shopInfo['shopAddress'],
      shopPhone: shopInfo['shopPhone'],
      shopEmail: shopInfo['shopEmail'],
      shopLogo: shopInfo['shopLogo'],
    );
  }
  
  // Get shop information from Firestore
  Future<Map<String, String?>> _getShopInfo() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    final docSnapshot = await _firestoreService.getDocument(
      collectionPath: 'users',
      documentId: userId,
    );
    
    if (!docSnapshot.exists) {
      return {
        'shopName': 'Mobile Repair Shop',
        'shopAddress': 'Shop Address',
        'shopPhone': 'Shop Phone',
        'shopEmail': 'shop@email.com',
        'shopLogo': null,
      };
    }
    
    final data = docSnapshot.data() as Map<String, dynamic>;
    
    return {
      'shopName': data['shopName'] as String? ?? 'Mobile Repair Shop',
      'shopAddress': data['shopAddress'] as String? ?? 'Shop Address',
      'shopPhone': data['phone'] as String? ?? 'Shop Phone',
      'shopEmail': data['email'] as String? ?? 'shop@email.com',
      'shopLogo': data['shopLogo'] as String?,
    };
  }
  
  // Generate PDF from invoice
  Future<Uint8List> generatePdf(Invoice invoice) async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();
    
    // Format currency
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    
    // Format date
    final dateFormat = DateFormat('dd MMM yyyy');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
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
                          invoice.shopName ?? 'Mobile Repair Shop',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 24,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (invoice.shopAddress != null)
                          pw.Text(
                            invoice.shopAddress!,
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                        if (invoice.shopPhone != null)
                          pw.Text(
                            'Phone: ${invoice.shopPhone}',
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                        if (invoice.shopEmail != null)
                          pw.Text(
                            'Email: ${invoice.shopEmail}',
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 20,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Invoice #: ${invoice.invoiceNumber}',
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                          pw.Text(
                            'Date: ${dateFormat.format(invoice.invoiceDate)}',
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                          pw.Text(
                            'Repair ID: ${invoice.repairJob.id}',
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Customer Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BILL TO',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              invoice.repairJob.customerName,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                              ),
                            ),
                            pw.Text(
                              'Phone: ${invoice.repairJob.customerPhone}',
                              style: pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                            if (invoice.repairJob.customerEmail.isNotEmpty)
                              pw.Text(
                                'Email: ${invoice.repairJob.customerEmail}',
                                style: pw.TextStyle(font: regularFont, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'DEVICE INFORMATION',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${invoice.repairJob.deviceBrand} ${invoice.repairJob.deviceModel}',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                              ),
                            ),
                            if (invoice.repairJob.deviceColor.isNotEmpty)
                              pw.Text(
                                'Color: ${invoice.repairJob.deviceColor}',
                                style: pw.TextStyle(font: regularFont, fontSize: 10),
                              ),
                            if (invoice.repairJob.deviceImei.isNotEmpty)
                              pw.Text(
                                'IMEI: ${invoice.repairJob.deviceImei}',
                                style: pw.TextStyle(font: regularFont, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Repair Details
                pw.Text(
                  'REPAIR DETAILS',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Table Header
                pw.Container(
                  color: PdfColors.blue100,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Repair Items
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey300),
                      right: pw.BorderSide(color: PdfColors.grey300),
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      // Problem description
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey300),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(
                                'Repair Service: ${invoice.repairJob.problem}',
                                style: pw.TextStyle(font: regularFont, fontSize: 11),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                currencyFormat.format(invoice.subtotal),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(font: regularFont, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Parts replaced (if any)
                      if (invoice.repairJob.partsToReplace.isNotEmpty)
                        ...invoice.repairJob.partsToReplace.map((part) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey300),
                              ),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 5,
                                  child: pw.Text(
                                    'Part: $part',
                                    style: pw.TextStyle(font: regularFont, fontSize: 11),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    'Included',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(font: regularFont, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 10, right: 10),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Subtotal:',
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Text(
                            currencyFormat.format(invoice.subtotal),
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):',
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Text(
                            currencyFormat.format(invoice.taxAmount),
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total:',
                            style: pw.TextStyle(font: boldFont, fontSize: 12),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Text(
                            currencyFormat.format(invoice.total),
                            style: pw.TextStyle(font: boldFont, fontSize: 12),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Amount Paid:',
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Text(
                            currencyFormat.format(invoice.amountPaid),
                            style: pw.TextStyle(font: regularFont, fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Amount Due:',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 12,
                              color: PdfColors.red700,
                            ),
                          ),
                          pw.SizedBox(width: 50),
                          pw.Text(
                            currencyFormat.format(invoice.amountDue),
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 12,
                              color: PdfColors.red700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Notes
                if (invoice.notes != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NOTES',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.notes!,
                          style: pw.TextStyle(font: regularFont, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 20),
                
                // Terms and Conditions
                if (invoice.termsAndConditions != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TERMS & CONDITIONS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.termsAndConditions!,
                          style: pw.TextStyle(font: regularFont, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  // Save PDF to file
  Future<File> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }
  
  // Print PDF
  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
  
  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    final file = await savePdfToFile(pdfBytes, fileName);
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
