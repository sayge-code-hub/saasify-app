import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_message_dialog.dart';
import '../domain/entities/proposal.dart';

/// Opens Invoices with a draft prefilled from [proposal] (quote → invoice).
void openInvoiceFromProposal(BuildContext context, Proposal proposal) {
  if (proposal.poStatus.isMuted) {
    showAppMessageDialog(
      context,
      title: 'Proposal status',
      message:
          'Change this discarded proposal to an active status before converting it to an invoice.',
    );
    return;
  }
  context.go(AppRoutes.invoices, extra: proposal);
}
