import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/add%20expense%20screen/ViewExpensesScreen.dart';
import 'package:flutter_application_1/ui/reports%20screen/invoices_reports_screen.dart';
import 'operation_screen.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              context,
              title: 'تقارير الفواتير',
              icon: Icons.receipt,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const InvoicesReportsScreen()));
              },
            ),
            _buildCard(
              context,
              title: 'تقارير العمليات',
              icon: Icons.analytics,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const OperationsScreen()));
              },
            ),
            _buildCard(
              context,
              title: 'عرض المصروفات',
              icon: Icons.attach_money,
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ViewExpensesScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height / 5,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
