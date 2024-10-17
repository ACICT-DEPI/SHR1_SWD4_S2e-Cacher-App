import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/data/repositories/operation_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/operation_repo.dart';
import 'package:flutter_application_1/domain/utils.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';

import '../widgets/custom_dialogs.dart';

class ViewExpensesScreen extends StatefulWidget {
  const ViewExpensesScreen({super.key});

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ViewExpensesScreen> {
  final String managerId = FirebaseAuth.instance.currentUser!.uid;
  String? filterOption;
  DateTimeRange? dateRange;
  // Controllers for the dialog fields
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;

  bool _isLoading = false; // Loading flag

  // Function to fetch filtered expenses
  Stream<QuerySnapshot> fetchFilteredExpenses() {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    if (filterOption == 'اليوم') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (filterOption == 'الشهر الحالي') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (filterOption == 'السنة الحالية') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
    } else if (filterOption == 'تاريخ مخصص' && dateRange != null) {
      startDate = dateRange!.start;
      endDate = dateRange!.end.add(const Duration(days: 1));
    } else {
      // Default to fetching all expenses if no filter is applied
      startDate = DateTime(2000);
      endDate = DateTime(2100);
    }

    return FirebaseFirestore.instance
        .collection('managers')
        .doc(managerId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Function to open the dialog for editing or deleting an expense
  void _openEditDeleteDialog(DocumentSnapshot expense) {
    _partyController.text = expense['party'];
    _amountController.text = (expense['amount']).toString();
    _selectedDate = expense['date'].toDate();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل أو حذف المصروف'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _partyController,
                    decoration: const InputDecoration(labelText: 'الجهة'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? intl.DateFormat('yyyy-MM-dd').format(_selectedDate!)
                          : '',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => _confirmDelete(expense, _partyController.text),
                child: const Text('حذف'),
              ),
              ElevatedButton(
                onPressed: () => _confirmEdit(expense, _partyController.text),
                child: const Text('تعديل'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to confirm deletion
void _confirmDelete(DocumentSnapshot expense, String name) async {
  setState(() {
    _isLoading = true;
  });

  await showConfirmationDialog(
    'هل تريد بالتأكيد حذف هذا المصروف؟',
    context,
    () async {
      // Only delete after confirmation
      await FirebaseFirestore.instance
          .collection('managers')
          .doc(managerId)
          .collection('expenses')
          .doc(expense.id)
          .delete();

      // Log operation only after confirmation
      OperationRepo operationRepo = OperationRepoImpl();
      await operationRepo.logOperation(
          'حذف مصروف', 'تم حذف مصروف: $name', '', '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المصروف بنجاح')),
      );

      Navigator.pop(context);
    },
    'delete_expense_confirmation',
  );

  setState(() {
    _isLoading = false;
  });
}


  // Function to confirm editing
void _confirmEdit(DocumentSnapshot expense, String oldPartyController) async {
  setState(() {
    _isLoading = true;
  });

  await showConfirmationDialog(
    'هل تريد بالتأكيد تعديل هذا المصروف؟',
    context,
    () async {
      // Only update after confirmation
      await FirebaseFirestore.instance
          .collection('managers')
          .doc(managerId)
          .collection('expenses')
          .doc(expense.id)
          .update({
        'party': _partyController.text,
        'amount': double.parse(_amountController.text),
        'date': _selectedDate,
      });

      // Log operation only after confirmation
      OperationRepo operationRepo = OperationRepoImpl();
      await operationRepo.logOperation(
        'تعديل المصروفات',
        'تم تعديل: $oldPartyController الي التالي:\nجهة الصرف: ${_partyController.text}\n'
        'تاريخ التعديل: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}\n'
        'المبلغ المصروف: ${formattedNumber(double.parse(_amountController.text))} د.ع',
        '',
        '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل المصروف بنجاح')),
      );

      Navigator.pop(context);
    },
    'edit_expense_confirmation',
  );

  setState(() {
    _isLoading = false;
  });
}


  // Function to generate PDF report
  Future<void> _generatePdfReport() async {
    setState(() {
      _isLoading = true;
    });
    final pdf = pw.Document();
    const double textSize = 12.0;

    // Load custom Arabic fonts
    final arabicFont1 = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final arabicFont2 = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final amiriRegular = pw.Font.ttf(arabicFont1);
    final amiriBold = pw.Font.ttf(arabicFont2);

    final expensesSnapshot = await fetchFilteredExpenses().first;

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            pw.Text(
              'تقرير المصروفات',
              style: pw.TextStyle(font: amiriBold, fontSize: 18),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              context: context,
              cellStyle: pw.TextStyle(font: amiriRegular, fontSize: textSize),
              headerStyle: pw.TextStyle(font: amiriBold, fontSize: textSize),
              headers: ['الجهة', 'المبلغ', 'التاريخ'],
              data: expensesSnapshot.docs.map((doc) {
                final expense = doc.data() as Map<String, dynamic>;
                return [
                  expense['party'] ?? 'غير معروف',
                  '${formattedNumber(expense['amount'])} د.ع',
                  intl.DateFormat('yyyy-MM-dd')
                      .format(expense['date'].toDate()),
                ];
              }).toList(),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'نظام مُرونة المحاسبي',
                style: pw.TextStyle(font: amiriBold, fontSize: textSize),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض المصاريف',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, fontFamily: 'font1')),
          backgroundColor: const Color(0xff4e00e8),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: filterOption,
                    hint: const Text('اختر الفترة الزمنية'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: [
                      'اليوم',
                      'الشهر الحالي',
                      'السنة الحالية',
                      'تاريخ مخصص',
                    ]
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        filterOption = value!;
                      });
                      if (value == 'تاريخ مخصص') {
                        DateTimeRange? range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (range != null) {
                          setState(() {
                            dateRange = range;
                          });
                        }
                      }
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: fetchFilteredExpenses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('لا توجد مصروفات حالياً'));
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final expense = snapshot.data!.docs[index];
                            return InkWell(
                              onTap: () {
                                _openEditDeleteDialog(expense);
                              },
                              child: Card(
                                margin: const EdgeInsets.all(8.0),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${expense['party']}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'المبلغ: ${formattedNumber(expense['amount'])} د.ع\nالتاريخ: ${intl.DateFormat('yyyy-MM-dd').format(expense['date'].toDate())}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generatePdfReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4e00e8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تصدير تقرير المصروفات كـ PDF',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



/*
class ViewExpensesScreen extends StatefulWidget {
  const ViewExpensesScreen({super.key});

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ViewExpensesScreen> {
  final String managerId = FirebaseAuth.instance.currentUser!.uid;
  String? filterOption;
  DateTimeRange? dateRange;

  // Controllers for the dialog fields
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;

  // Function to fetch filtered expenses
  Stream<QuerySnapshot> fetchFilteredExpenses() {
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    if (filterOption == 'اليوم') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (filterOption == 'الشهر الحالي') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (filterOption == 'السنة الحالية') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
    } else if (filterOption == 'تاريخ مخصص' && dateRange != null) {
      startDate = dateRange!.start;
      endDate = dateRange!.end.add(const Duration(days: 1));
    } else {
      // Default to fetching all expenses if no filter is applied
      startDate = DateTime(2000);
      endDate = DateTime(2100);
    }

    return FirebaseFirestore.instance
        .collection('managers')
        .doc(managerId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Function to open the dialog for editing or deleting an expense
  void _openEditDeleteDialog(DocumentSnapshot expense) {
    _partyController.text = expense['party'];
    _amountController.text = expense['amount'].toString();
    _selectedDate = expense['date'].toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل أو حذف المصروف'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _partyController,
                  decoration: const InputDecoration(labelText: 'الجهة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'التاريخ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ),
                  controller: TextEditingController(
                    text: _selectedDate != null
                        ? intl.DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => _confirmDelete(expense),
              child: const Text('حذف'),
            ),
            ElevatedButton(
              onPressed: () => _confirmEdit(expense),
              child: const Text('تعديل'),
            ),
          ],
        );
      },
    );
  }

  // Function to confirm deletion
  void _confirmDelete(DocumentSnapshot expense) async {
    await showConfirmationDialog(
      'هل تريد بالتأكيد حذف هذا المصروف؟',
      context,
      () async {
        await FirebaseFirestore.instance
            .collection('managers')
            .doc(managerId)
            .collection('expenses')
            .doc(expense.id)
            .delete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المصروف بنجاح')),
        );
      },
      'delete_expense_confirmation',
    );
  }

  // Function to confirm editing
  void _confirmEdit(DocumentSnapshot expense) async {
    await showConfirmationDialog(
      'هل تريد بالتأكيد تعديل هذا المصروف؟',
      context,
      () async {
        await FirebaseFirestore.instance
            .collection('managers')
            .doc(managerId)
            .collection('expenses')
            .doc(expense.id)
            .update({
          'party': _partyController.text,
          'amount': double.parse(_amountController.text),
          'date': _selectedDate,
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل المصروف بنجاح')),
        );
      },
      'edit_expense_confirmation',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض المصاريف',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, fontFamily: 'font1')),
          backgroundColor: const Color(0xff4e00e8),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                value: filterOption,
                hint: const Text('اختر الفترة الزمنية'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: [
                  'اليوم',
                  'الشهر الحالي',
                  'السنة الحالية',
                  'تاريخ مخصص',
                ]
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    filterOption = value!;
                  });
                  if (value == 'تاريخ مخصص') {
                    DateTimeRange? range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (range != null) {
                      setState(() {
                        dateRange = range;
                      });
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: fetchFilteredExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد مصروفات حالياً'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final expense = snapshot.data!.docs[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              '${expense['party']}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
*/ 