import 'package:flutter/material.dart';
import '../admin/report_details_page.dart';

// Both staff views use the same workflow; database policies enforce district scope.
class GovernorReportPage extends StatelessWidget {
  final String reportId;
  const GovernorReportPage({super.key, required this.reportId});
  @override
  Widget build(BuildContext context) => ReportDetailsPage(reportId: reportId);
}
