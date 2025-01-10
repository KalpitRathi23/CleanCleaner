// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pw2;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'client_model.dart';
import 'package:client_manage/client/client_util.dart';
import 'package:client_manage/utils/global_state.dart';
import 'package:client_manage/utils/notification_service.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({
    super.key,
    required this.client,
  });

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  late String selectedAgent;
  late String selectedCategory;
  late String selectedDescription;
  late String selectReminder;
  late String selectCurrentDate;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    _loadSelectedAgent();
    selectedCategory = widget.client.category;
    selectedDescription = widget.client.description;
    selectReminder = widget.client.reminder;
    selectCurrentDate = widget.client.currentDate;
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final agentFromPrefs = prefs.getString('selectedAgent') ?? 'unknown';
    setState(() {
      if (agentFromPrefs == 'Owner') {
        selectedAgent =
            Provider.of<GlobalState>(context, listen: false).selectedOwnerAgent;
      } else {
        selectedAgent = agentFromPrefs;
      }
    });
  }

  Future<void> _updateCategory(String newCategory) async {
    try {
      await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgent)
          .collection('clients')
          .doc(widget.client.clientID)
          .update({'category': newCategory});

      setState(() {
        selectedCategory = newCategory;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category: $e')),
      );
    }
  }

  Future<void> _updateDescription(String newDescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgent)
          .collection('clients')
          .doc(widget.client.clientID)
          .update({'description': newDescription});

      setState(() {
        selectedDescription = newDescription;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update description: $e')),
      );
    }
  }

  Future<void> _updateReminder(String newReminder) async {
    try {
      DateTime now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgent)
          .collection('clients')
          .doc(widget.client.clientID)
          .update({
        'reminder': newReminder,
        'currentDate': now.toIso8601String(),
      });

      setState(() {
        selectReminder = newReminder;
        selectCurrentDate = now.toString();
      });

      DateTime reminderDate = DateTime.parse(newReminder);
      NotificationService.scheduleNotification(
        id: widget.client.clientID.hashCode,
        title: widget.client.name,
        body: selectedDescription == '0'
            ? "Closing Balance: ${widget.client.balance}"
            : "Description: $selectedDescription",
        scheduledTime: reminderDate,
        clientId: widget.client.clientID,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder set successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set reminder: $e')),
      );
    }
  }

  Future<void> _resetField(String field) async {
    try {
      if (field == 'category' && selectedCategory == '0') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category is empty')),
          );
        }
        return;
      } else if (field == 'reminder' && selectReminder == '0') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder is empty')),
          );
        }
        return;
      } else if (field == 'description' && selectedDescription == '0') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Description is empty')),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgent)
          .collection('clients')
          .doc(widget.client.clientID)
          .update({field: '0'});

      if (mounted) {
        setState(() {
          if (field == 'category') {
            selectedCategory = '0';
          } else if (field == 'reminder') {
            selectReminder = '0';
          } else if (field == 'description') {
            selectedDescription = '0';
          }
        });
      }

      if (field == 'reminder') {
        NotificationService.cancelNotification(widget.client.clientID.hashCode);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field reset successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset field: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCodeVerified = Provider.of<GlobalState>(context).isCodeVerified;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.client.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'share_pdf') {
                _generateAndSharePDF(context);
              } else {
                _resetField(value);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'category',
                child: Text(
                  'Delete Category',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reminder',
                child: Text(
                  'Delete Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'description',
                child: Text(
                  'Delete Description',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'share_pdf',
                child: Text(
                  'Share Details',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 50),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.grey.shade200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientUtil.buildDetailRow("Mobile",
                    widget.client.mobile == '0' ? "NA" : widget.client.mobile),
                const Divider(thickness: 1),
                ClientUtil.buildDetailRow(
                    "Address",
                    widget.client.address == '0'
                        ? "NA"
                        : widget.client.address),
                if (isCodeVerified) ...[
                  const Divider(thickness: 1),
                  ClientUtil.buildDetailRow(
                      "Bill Amount", "₹${widget.client.billAmt}"),
                  const Divider(thickness: 1),
                  ClientUtil.buildDetailRow("Payment",
                      ClientUtil.formatDetailValue(widget.client.debit)),
                  const Divider(thickness: 1),
                  ClientUtil.buildDetailRowWithColor(
                    "Closing Balance",
                    ClientUtil.formatDetailValue(widget.client.balance),
                    ClientUtil.getBalanceColor(widget.client.balance),
                  ),
                ],
                const Divider(thickness: 1),
                _buildCategoryRow(),
                const Divider(thickness: 1),
                ClientUtil.buildDetailRow(
                  "Reminder Created On",
                  selectCurrentDate == '0'
                      ? "NA"
                      : "${ClientUtil.formatDate(DateTime.parse(selectCurrentDate))}, ${ClientUtil.formatTime(DateTime.parse(selectCurrentDate), context)}",
                ),
                const Divider(thickness: 1),
                _buildReminderRow(),
                const Divider(thickness: 1),
                _buildDescriptionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    if (selectedCategory == '0') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Category",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                value: selectedCategory == '0' ? null : selectedCategory,
                hint: const Text("Select"),
                items: ['Good', 'Normal', 'Bad']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateCategory(value);
                  }
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Category",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ClientUtil.buildBadge(selectedCategory),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDescriptionRow() {
    if (selectedDescription == '0') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: descriptionController,
                  maxLines: null,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    hintText: "Enter here...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      final newDescription = descriptionController.text.trim();
                      if (newDescription.isNotEmpty) {
                        FocusScope.of(context).unfocus();
                        await _updateDescription(newDescription);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Description cannot be empty.'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Text(
              selectedDescription,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReminderRow() {
    if (selectReminder == '0') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Reminder",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () async {
                  DateTime? pickedDate =
                      await ClientUtil.pickCustomDate(context);
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime =
                        await ClientUtil.pickCustomTime(context);
                    if (pickedTime != null) {
                      DateTime reminderDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      String formattedReminder =
                          reminderDateTime.toIso8601String();

                      await _updateReminder(formattedReminder);
                    }
                  }
                },
                child: const Text(
                  "Set Reminder",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      DateTime reminderDate = DateTime.parse(selectReminder);

      String formattedReminder =
          "${ClientUtil.formatDate(reminderDate)}, ${ClientUtil.formatTime(reminderDate, context)}";

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 1,
            child: Text(
              "Reminder",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Text(
              formattedReminder,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    final isCodeVerified =
        Provider.of<GlobalState>(context, listen: false).isCodeVerified;
    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final headingStyle = pw.TextStyle(
      font: ttf,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: pw2.PdfColor.fromHex("000000"),
    );

    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 21,
      color: pw2.PdfColor.fromHex("000000"),
    );

    final contentStyle = pw.TextStyle(
      font: ttf,
      fontSize: 21,
      fontWeight: pw.FontWeight.bold,
      color: pw2.PdfColor.fromHex("0000FF"),
    );

    final divider = pw.Divider(
      thickness: 1.5,
      color: pw2.PdfColor.fromHex("808080"),
    );

    final now = DateTime.now();
    final formattedDate = ClientUtil.formatDate(now);
    final formattedTime = ClientUtil.formatTime(now, context);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('${widget.client.name} Details',
                    style: headingStyle),
              ),
              divider,
              pw.SizedBox(height: 30),
              pw.Row(
                children: [
                  pw.Text('Name: ', style: headerStyle),
                  pw.Text(widget.client.name, style: contentStyle),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Text('Mobile: ', style: headerStyle),
                  pw.Text(
                      widget.client.mobile == '0' ? "NA" : widget.client.mobile,
                      style: contentStyle),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Text('Address: ', style: headerStyle),
                  pw.Text(
                      widget.client.address == '0'
                          ? "NA"
                          : widget.client.address,
                      style: contentStyle),
                ],
              ),
              if (isCodeVerified) ...[
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Text('Bill Amount: ', style: headerStyle),
                    pw.Text('₹${widget.client.billAmt}', style: contentStyle),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Text('Payment Given: ', style: headerStyle),
                    pw.Text('₹${widget.client.debit}', style: contentStyle),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Text('Closing Balance: ', style: headerStyle),
                    pw.Text('₹${widget.client.balance}', style: contentStyle),
                  ],
                ),
              ],
              pw.SizedBox(height: 30),
              divider,
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Generated on: $formattedDate at $formattedTime',
                  style: pw.TextStyle(font: ttf, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${widget.client.name}.pdf');
      await file.writeAsBytes(await pdf.save());

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Here is the ${widget.client.name} details',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }
}
