import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_message_dialog.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_purchase_order.dart';
import '../../domain/usecases/employee_purchase_order_usecases.dart';
import '../bloc/employees/employees_bloc.dart';

/// Finance-wide PO register. The employee detail remains the place to manage
/// a PO; this page makes renewal dates and the linked employee easy to scan.
class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  Future<List<EmployeePurchaseOrder>>? _orders;

  @override
  void initState() {
    super.initState();
    _orders = _load();
  }

  Future<List<EmployeePurchaseOrder>> _load() async {
    final result = await sl<GetAllEmployeePurchaseOrdersUseCase>()();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );
  }

  Future<void> _open(EmployeePurchaseOrder order) async {
    final result = await sl<GetEmployeePurchaseOrderDownloadUrlUseCase>()(
      order,
    );
    await result.fold(
      (failure) => showAppMessageDialog(
        context,
        title: 'Purchase order',
        message: failure.message,
      ),
      (url) async {
        final opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          await showAppMessageDialog(
            context,
            title: 'Purchase order',
            message: 'Could not open the PO PDF.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      builder: (context, employeeState) {
        final employees = {
          for (final employee in employeeState.employees)
            employee.employeeId: employee,
        };
        return FutureBuilder<List<EmployeePurchaseOrder>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.text),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load purchase orders. ${snapshot.error}',
                ),
              );
            }
            final orders = [...?snapshot.data]
              ..sort((a, b) => a.endDate.compareTo(b.endDate));
            if (orders.isEmpty) {
              return const Center(
                child: Text('No purchase orders uploaded yet.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => setState(() => _orders = _load()),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _PurchaseOrderCard(
                  order: orders[index],
                  employee: employees[orders[index].employeeId],
                  onOpen: orders[index].hasFile
                      ? () => _open(orders[index])
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({
    required this.order,
    required this.employee,
    this.onOpen,
  });

  final EmployeePurchaseOrder order;
  final Employee? employee;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final (color, icon, status) = switch ((
      order.isExpired,
      order.needsRenewal,
    )) {
      (true, _) => (AppColors.error, Icons.error_outline, 'Expired'),
      (false, true) => (
        Colors.orange.shade800,
        Icons.schedule_outlined,
        'Renew in ${order.daysUntilEnd} days',
      ),
      _ => (
        AppColors.success,
        Icons.verified_outlined,
        'Active through ${AppDates.compact.format(order.endDate)}',
      ),
    };
    final name = employee?.employeeName ?? 'Employee ${order.employeeId}';
    return InkWell(
      onTap: () => context.go(AppRoutes.employeeDetail(order.employeeId)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.poNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$name · ${order.employeeId}',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${AppDates.compact.format(order.startDate)} — ${AppDates.compact.format(order.endDate)}',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpen,
              tooltip: 'Open PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
