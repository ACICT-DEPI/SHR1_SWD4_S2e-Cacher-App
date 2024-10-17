import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController _thresholdController = TextEditingController();
  TextEditingController _thankYouMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int threshold = prefs.getInt('lowStockThreshold') ?? 10;
    String thankYouMessage = prefs.getString('thankYouMessage') ??
        'شكراً لزيارتكم ونتمني تكرار الزيارة مرة أخري';
    
    setState(() {
      _thresholdController.text = threshold.toString();
      _thankYouMessageController.text = thankYouMessage;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int threshold = int.tryParse(_thresholdController.text) ?? 10;
    String thankYouMessage = _thankYouMessageController.text;

    prefs.setInt('lowStockThreshold', threshold);
    prefs.setString('thankYouMessage', thankYouMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات',
              style: TextStyle(color: Colors.white, fontFamily: 'font1')),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر الكمية التي تريد عرض المنتجات على وشك النفاذ بناءً عليها:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const Text('رسالة الشكر عند نهاية الفاتورة:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _thankYouMessageController,
                  decoration: const InputDecoration(
                    labelText: 'رسالة الشكر',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    onPressed: () {
                      _saveSettings();
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ',style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
