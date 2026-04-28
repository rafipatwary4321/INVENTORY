import 'package:flutter/material.dart';

import 'report_card.dart';

class POSCartCard extends StatelessWidget {
  const POSCartCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReportCard(child: child);
  }
}
