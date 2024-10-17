import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showErrorDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('!خطأ',textAlign: TextAlign.end,style: TextStyle(color: Colors.red),),
        content: Text(errorMessage,textDirection: TextDirection.rtl,),
        actionsAlignment: MainAxisAlignment.start,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('تم'),
          ),
        ],
      );
    },
  );
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Loading...'),
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Loading...'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () {
              Navigator.of(context).pop(); // لإغلاق الحوار عند الضغط على زر الإلغاء
            },
          ),
        ],
      );
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}


void showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 20),
              Text('WELL DONE!'),
              Text('\nNow you can login easly'),
            ],
          ),
        ),
      );
    },
  );
}


Future<void> showConfirmationDialog(String txt,
    BuildContext context, Function onConfirm, String prefTxt) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool shouldShowDialog = prefs.getBool(prefTxt) ?? true;

  if (shouldShowDialog) {
    bool dontShowAgain = false;
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تأكيد'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(txt),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: dontShowAgain,
                          onChanged: (bool? value) {
                            setState(() {
                              dontShowAgain = value ?? false;
                            });
                          },
                        ),
                        const Text('لا تظهر مرة أخرى'),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (dontShowAgain) {
                        await prefs.setBool(prefTxt, false);
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('نعم'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      onConfirm();
    }
  } else {
    onConfirm();
  }
}

void showNoInvoicesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('لا توجد فواتير'),
        content: const Text('لا توجد فواتير تجاوزت 30 يوماً للحذف.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('موافق'),
          ),
        ],
      );
    },
  );
}