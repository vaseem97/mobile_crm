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
  bool _needsShopInfo = false;
  List<String> _missingFields = [];

  @override
  void initState() {
    super.initState();
    _checkShopInfoAndGenerateInvoice();
  }

  Future<void> _checkShopInfoAndGenerateInvoice() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _needsShopInfo = false;
        _missingFields.clear();
      });

      // Validate shop information first
      final validationResult = await _invoiceService.validateShopInfo();

      if (!validationResult.isValid) {
        setState(() {
          _isLoading = false;
          _needsShopInfo = true;
          _missingFields = validationResult.missingFields;
        });
        return;
      }

      // Proceed with invoice generation
      await _generateInvoice();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
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
                final fileName =
                    'invoice_${_invoiceNumber.replaceAll('-', '_')}.pdf';
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

    if (_needsShopInfo) {
      return _buildMissingShopInfoView();
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
              onPressed: _checkShopInfoAndGenerateInvoice,
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

  Widget _buildMissingShopInfoView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.store_rounded,
                size: 64,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Shop Information Needed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'To generate a professional invoice, please complete your shop profile first.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missing Information:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _missingFields.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _missingFields[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.push('/dashboard?tab=3').then((_) {
                    _checkShopInfoAndGenerateInvoice();
                  });
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Update Shop Profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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
                final fileName =
                    'invoice_${_invoiceNumber.replaceAll('-', '_')}.pdf';
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
