import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../repair/data/repositories/repair_repository_impl.dart';
import '../../data/services/invoice_service.dart';

class InvoicePreviewPage extends StatefulWidget {
  final String repairId;

  const InvoicePreviewPage({
    Key? key,
    required this.repairId,
  }) : super(key: key);

  @override
  State<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<InvoicePreviewPage> {
  final _repairRepository = getService<RepairRepositoryImpl>();
  final _invoiceService = InvoiceService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Uint8List? _pdfBytes;
  String _invoiceNumber = '';

  @override
  void initState() {
    super.initState();
    _generateInvoice();
  }

  Future<void> _generateInvoice() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get repair job
      final repair = await _repairRepository.getRepairJobById(widget.repairId);
      if (repair == null) {
        throw Exception('Repair job not found');
      }

      // Generate invoice
      final invoice = await _invoiceService.generateInvoice(repair);
      _invoiceNumber = invoice.invoiceNumber;

      // Generate PDF
      final pdfBytes = await _invoiceService.generatePdf(invoice);
      
      setState(() {
        _pdfBytes = pdfBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final fileName = 'invoice_${_invoiceNumber.replaceAll('-', '_')}.pdf';
                await _invoiceService.sharePdf(_pdfBytes!, fileName);
              },
              tooltip: 'Share Invoice',
            ),
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                await _invoiceService.printPdf(_pdfBytes!);
              },
              tooltip: 'Print Invoice',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating invoice...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error generating invoice',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateInvoice,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(
        child: Text('No PDF generated'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PdfPreview(
            build: (format) => _pdfBytes!,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            maxPageWidth: 700,
            actions: const [],
            scrollViewDecoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            previewPageMargin: const EdgeInsets.all(10),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final fileName = 'invoice_${_invoiceNumber.replaceAll('-', '_')}.pdf';
                await _invoiceService.sharePdf(_pdfBytes!, fileName);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _invoiceService.printPdf(_pdfBytes!);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
