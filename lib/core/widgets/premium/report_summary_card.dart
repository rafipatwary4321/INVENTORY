import 'package:flutter/material.dart';

import 'report_card.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ),
    );
  }
}
