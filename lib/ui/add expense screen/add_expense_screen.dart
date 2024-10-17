import 'package:connectivity_checker/connectivity_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data/repositories/operation_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/operation_repo.dart';

import '../widgets/custom_dialogs.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false; // Loading flag

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        // Fetch the current manager's UID
        OperationRepo operationRepo = OperationRepoImpl();
        String managerId = FirebaseAuth.instance.currentUser!.uid;

        // Save the expense under the manager's document in a subcollection
        await FirebaseFirestore.instance
            .collection('managers')
            .doc(managerId)
            .collection('expenses')
            .add({
          'party': _partyController.text,
          'amount': double.parse(_amountController.text),
          'date': _selectedDate ?? DateTime.now(),
        });

        operationRepo.logOperation(
            'إضافة مصروفات',
            'جهة الصرف: ${_partyController.text}\nالمبلغ المصروف: ${_amountController.text} د.ع',
            '',
            '');

        // Clear the form after saving
        _partyController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المصروف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة المصروف: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة مصروف',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _partyController,
                      decoration: const InputDecoration(
                        labelText: 'الجهة التي تم الصرف إليها',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الجهة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المصروف (د.ع)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال المبلغ';
                        }
                        if (double.tryParse(value) == null) {
                          return 'الرجاء إدخال مبلغ صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الصرف',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'اختر التاريخ'
                              : _selectedDate!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool isOffline =
                              (await ConnectivityWrapper.instance.isConnected);
                          if (isOffline) {
                            _saveExpense();
                          } else {
                            showErrorDialog(context,
                                'تحقق من اتصالك بالإنترنت ثم اعد المحاولة');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4e00e8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('حفظ',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
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
