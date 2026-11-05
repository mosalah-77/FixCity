import 'package:flutter/material.dart';
import '../admin/report_details_page.dart';

// Shared details, with district repair actions. The server enforces role and district scope.
class GovernorReportPage extends StatelessWidget {
  final String reportId;
  const GovernorReportPage({super.key, required this.reportId});
  @override
  Widget build(BuildContext context) =>
      ReportDetailsPage(reportId: reportId, districtView: true);
}
