import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/csv_export.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_message_dialog.dart';
import '../../../../core/widgets/app_filter_dropdown.dart';
import '../../../../core/widgets/app_list_search_field.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_purchase_order.dart';
import '../../domain/usecases/employee_purchase_order_usecases.dart';
import '../bloc/employees/employees_bloc.dart';
import '../../../settings/presentation/widgets/client_name_label.dart';

/// Finance-wide PO register matching the employee register's familiar table.
class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

enum _PurchaseOrderFilter { all, active, renewalDue, expired }

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  Future<List<EmployeePurchaseOrder>>? _orders;
  String _query = '';
  _PurchaseOrderFilter _statusFilter = _PurchaseOrderFilter.all;
  String? _clientFilter;

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
    final isDesktop = Breakpoints.isDesktop(context);
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      builder: (context, employeeState) {
        final employees = {
          for (final employee in employeeState.employees)
            employee.employeeId: employee,
        };
        final clients =
            employees.values
                .map((employee) => employee.client)
                .where((client) => client.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final clientFilter = clients.contains(_clientFilter)
            ? _clientFilter
            : null;

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

            final orders = [...?snapshot.data];
            final filtered = orders.where((order) {
              final employee = employees[order.employeeId];
              final query = _query.trim().toLowerCase();
              final matchesQuery =
                  query.isEmpty ||
                  order.poNumber.toLowerCase().contains(query) ||
                  order.employeeId.toLowerCase().contains(query) ||
                  (employee?.employeeName.toLowerCase().contains(query) ??
                      false) ||
                  (employee?.client.toLowerCase().contains(query) ?? false);
              final matchesClient =
                  clientFilter == null || employee?.client == clientFilter;
              final matchesStatus = switch (_statusFilter) {
                _PurchaseOrderFilter.all => true,
                _PurchaseOrderFilter.active =>
                  !order.isExpired && !order.needsRenewal,
                _PurchaseOrderFilter.renewalDue => order.needsRenewal,
                _PurchaseOrderFilter.expired => order.isExpired,
              };
              return matchesQuery && matchesClient && matchesStatus;
            }).toList();

            Future<void> exportCsv() => CsvExport.download(
              filename: 'purchase_orders.csv',
              headers: const [
                'PO Number',
                'Employee',
                'Employee ID',
                'Client',
                'Start date',
                'End date',
                'Status',
              ],
              rows: [
                for (final order in filtered)
                  [
                    order.poNumber,
                    employees[order.employeeId]?.employeeName ?? '',
                    order.employeeId,
                    employees[order.employeeId]?.client ?? '',
                    AppDates.compact.format(order.startDate),
                    AppDates.compact.format(order.endDate),
                    _statusLabel(order),
                  ],
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 16,
                    isDesktop ? 12 : 8,
                    isDesktop ? 32 : 16,
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppListSearchField(
                              hintText: 'Search purchase orders…',
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Export CSV',
                            onPressed: filtered.isEmpty ? null : exportCsv,
                            icon: const Icon(Icons.download),
                            color: AppColors.text,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final filter in _PurchaseOrderFilter.values)
                              _StatusChip(
                                label: _filterLabel(filter),
                                selected: _statusFilter == filter,
                                onSelected: () =>
                                    setState(() => _statusFilter = filter),
                              ),
                            if (clients.isNotEmpty)
                              SizedBox(
                                width: isDesktop ? 220 : double.infinity,
                                child: AppFilterDropdown<String?>(
                                  value: clientFilter,
                                  options: [
                                    const AppFilterOption<String?>(
                                      value: null,
                                      label: 'All clients',
                                    ),
                                    for (final client in clients)
                                      AppFilterOption<String?>(
                                        value: client,
                                        label: client,
                                      ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _clientFilter = value),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No purchase orders found.'))
                      : isDesktop
                      ? _PurchaseOrdersTable(
                          orders: filtered,
                          employees: employees,
                          onOpen: _open,
                        )
                      : _PurchaseOrdersMobileList(
                          orders: filtered,
                          employees: employees,
                          onOpen: _open,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PurchaseOrdersTable extends StatefulWidget {
  const _PurchaseOrdersTable({
    required this.orders,
    required this.employees,
    required this.onOpen,
  });

  final List<EmployeePurchaseOrder> orders;
  final Map<String, Employee> employees;
  final ValueChanged<EmployeePurchaseOrder> onOpen;

  @override
  State<_PurchaseOrdersTable> createState() => _PurchaseOrdersTableState();
}

class _PurchaseOrdersTableState extends State<_PurchaseOrdersTable> {
  static const _pageSize = 10;
  int _page = 0;
  String? _sortColumn;
  bool _sortAscending = true;

  List<EmployeePurchaseOrder> get _sorted {
    final values = [...widget.orders];
    int compare(EmployeePurchaseOrder a, EmployeePurchaseOrder b) {
      final employeeA = widget.employees[a.employeeId];
      final employeeB = widget.employees[b.employeeId];
      switch (_sortColumn) {
        case 'po':
          return a.poNumber.compareTo(b.poNumber);
        case 'employee':
          return (employeeA?.employeeName ?? a.employeeId).compareTo(
            employeeB?.employeeName ?? b.employeeId,
          );
        case 'client':
          return (employeeA?.client ?? '').compareTo(employeeB?.client ?? '');
        case 'start':
          return a.startDate.compareTo(b.startDate);
        case 'end':
          return a.endDate.compareTo(b.endDate);
        case 'status':
          return _statusRank(a).compareTo(_statusRank(b));
        default:
          return a.endDate.compareTo(b.endDate);
      }
    }

    values.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return values;
  }

  List<EmployeePurchaseOrder> get _pageItems {
    final start = _page * _pageSize;
    final values = _sorted;
    if (start >= values.length) return const [];
    return values.sublist(start, (start + _pageSize).clamp(0, values.length));
  }

  int get _pageCount => ((widget.orders.length - 1) / _pageSize).floor() + 1;

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final page = _page.clamp(0, _pageCount - 1);
    if (page != _page) _page = page;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.sizeOf(context).width - 248 - 64,
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 48,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
                      horizontalMargin: 20,
                      columnSpacing: 28,
                      dividerThickness: 0.6,
                      headingTextStyle: textTheme.labelLarge?.copyWith(
                        color: AppColors.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle: textTheme.bodyLarge?.copyWith(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                      columns: [
                        _sortableHeader('P.O. NUMBER', 'po'),
                        _sortableHeader('EMPLOYEE', 'employee'),
                        _sortableHeader('CLIENT', 'client'),
                        _sortableHeader('START DATE', 'start'),
                        _sortableHeader('END DATE', 'end'),
                        _sortableHeader('STATUS', 'status'),
                        const DataColumn(label: Text('DOCUMENT')),
                      ],
                      rows: _pageItems.map((order) {
                        final employee = widget.employees[order.employeeId];
                        return DataRow(
                          onSelectChanged: (_) => context.go(
                            AppRoutes.employeeDetail(order.employeeId),
                          ),
                          cells: [
                            DataCell(
                              Text(
                                order.poNumber,
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              _EmployeeCell(
                                name:
                                    employee?.employeeName ??
                                    'Employee ${order.employeeId}',
                                employeeId: order.employeeId,
                              ),
                            ),
                            DataCell(
                              employee == null || employee.client.trim().isEmpty
                                  ? const Text('—')
                                  : ClientNameLabel(
                                      name: employee.client,
                                      logoRadius: 7,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                            DataCell(
                              Text(AppDates.medium.format(order.startDate)),
                            ),
                            DataCell(
                              Text(AppDates.medium.format(order.endDate)),
                            ),
                            DataCell(_StatusLabel(order: order)),
                            DataCell(
                              IconButton(
                                tooltip: order.hasFile
                                    ? 'Open PDF'
                                    : 'No PDF uploaded',
                                onPressed: order.hasFile
                                    ? () => widget.onOpen(order)
                                    : null,
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: _Pagination(
                  page: _page,
                  pageCount: _pageCount,
                  onChanged: (value) => setState(() => _page = value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _sortableHeader(String label, String key) {
    final active = _sortColumn == key;
    return DataColumn(
      label: InkWell(
        onTap: () => _toggleSort(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Icon(
              active
                  ? (_sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: active ? AppColors.highlight : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseOrdersMobileList extends StatelessWidget {
  const _PurchaseOrdersMobileList({
    required this.orders,
    required this.employees,
    required this.onOpen,
  });

  final List<EmployeePurchaseOrder> orders;
  final Map<String, Employee> employees;
  final ValueChanged<EmployeePurchaseOrder> onOpen;

  @override
  Widget build(BuildContext context) {
    final sorted = [...orders]..sort((a, b) => a.endDate.compareTo(b.endDate));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = sorted[index];
        final employee = employees[order.employeeId];
        return InkWell(
          onTap: () => context.go(AppRoutes.employeeDetail(order.employeeId)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.poNumber,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _StatusLabel(order: order),
                  ],
                ),
                const SizedBox(height: 8),
                _EmployeeCell(
                  name:
                      employee?.employeeName ?? 'Employee ${order.employeeId}',
                  employeeId: order.employeeId,
                ),
                const SizedBox(height: 8),
                Text(
                  employee?.client ?? '—',
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppDates.compact.format(order.startDate)} — ${AppDates.compact.format(order.endDate)}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Open PDF',
                      onPressed: order.hasFile ? () => onOpen(order) : null,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.name, required this.employeeId});

  final String name;
  final String employeeId;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
      ),
      const SizedBox(height: 2),
      Text(
        employeeId,
        style: const TextStyle(color: AppColors.textLight, fontSize: 11),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    showCheckmark: false,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppFilterDropdown.radius),
    ),
    selectedColor: AppColors.highlight,
    backgroundColor: AppColors.background,
    side: const BorderSide(color: AppColors.border),
    labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 12,
      height: 1,
      color: selected ? AppColors.background : AppColors.text,
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.order});

  final EmployeePurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusPresentation(order);
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: color, fontSize: 13),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < pageCount; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        InkWell(
          onTap: () => onChanged(i),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i == page ? AppColors.highlight : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i + 1}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: i == page ? AppColors.background : AppColors.text,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

String _filterLabel(_PurchaseOrderFilter filter) => switch (filter) {
  _PurchaseOrderFilter.all => 'All',
  _PurchaseOrderFilter.active => 'Active',
  _PurchaseOrderFilter.renewalDue => 'Renewal due',
  _PurchaseOrderFilter.expired => 'Expired',
};

String _statusLabel(EmployeePurchaseOrder order) =>
    _statusPresentation(order).$1;

int _statusRank(EmployeePurchaseOrder order) {
  if (order.isExpired) return 2;
  if (order.needsRenewal) return 1;
  return 0;
}

(String, Color) _statusPresentation(EmployeePurchaseOrder order) {
  if (order.isExpired) return ('Expired', AppColors.error);
  if (order.needsRenewal) return ('Renewal due', Colors.orange.shade800);
  return ('Active', AppColors.success);
}
