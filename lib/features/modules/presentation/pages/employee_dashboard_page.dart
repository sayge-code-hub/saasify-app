import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/pdf_saver.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_message_dialog.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../hrms/domain/entities/employee.dart';
import '../../../hrms/presentation/bloc/employees/employees_bloc.dart';
import '../../../hrms/presentation/widgets/employee_avatar.dart';
import '../../../hrms/presentation/widgets/employee_documents_section.dart';
import '../../../payroll/domain/services/payslip_period.dart';
import '../../../payroll/presentation/bloc/payroll_bloc.dart';
import '../../data/employee_id_card_pdf_builder.dart';

/// Employee self-service: profile, salary slips and a non-sensitive ID card.
class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({
    super.key,
    this.showSalarySlips = false,
    this.showIdCard = false,
    this.showDocuments = false,
  });

  final bool showSalarySlips;
  final bool showIdCard;
  final bool showDocuments;

  @override
  Widget build(BuildContext context) {
    if (showSalarySlips) {
      return BlocProvider(
        create: (_) => sl<PayrollBloc>()..add(const PayrollStarted()),
        child: const _DashboardBody(
          isSlips: true,
          isIdCard: false,
          isDocuments: false,
        ),
      );
    }
    return _DashboardBody(
      isSlips: false,
      isIdCard: showIdCard,
      isDocuments: showDocuments,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.isSlips,
    required this.isIdCard,
    required this.isDocuments,
  });

  final bool isSlips;
  final bool isIdCard;
  final bool isDocuments;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      builder: (context, empState) {
        if (empState.status == EmployeesStatus.loading ||
            empState.status == EmployeesStatus.initial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.text),
          );
        }

        final user = sl<AuthSession>().user;
        final id = user?.employeeId?.trim();
        Employee? me;
        if (id != null && id.isNotEmpty) {
          for (final e in empState.employees) {
            if (e.employeeId == id) {
              me = e;
              break;
            }
          }
        }

        if (isSlips) {
          return _SalarySlipsView(employee: me);
        }
        if (isIdCard) {
          return _EmployeeIdCardView(employee: me, user: user);
        }
        if (isDocuments) {
          return _EmployeeDocumentsView(employee: me);
        }
        return _ProfileView(employee: me, user: user);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({this.employee, this.user});

  final Employee? employee;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final horizontal = isDesktop ? 32.0 : 16.0;
    final linked = employee != null;
    final dateFormat = AppDates.compact;

    final displayName = linked
        ? employee!.employeeName
        : (user?.name?.trim().isNotEmpty == true
              ? user!.name!.trim()
              : (user?.email ?? 'Profile'));

    final fields = linked
        ? <({String label, String value})>[
            (label: 'Employee ID', value: employee!.employeeId),
            (label: 'Client', value: employee!.client),
            (label: 'Grade', value: employee!.grade),
            (label: 'Email', value: user?.email ?? '—'),
            (label: 'Department', value: employee!.department),
            (
              label: 'Joining date',
              value: dateFormat.format(employee!.dateOfJoining),
            ),
            (
              label: 'Birth date',
              value: employee!.dateOfBirth == null
                  ? '—'
                  : dateFormat.format(employee!.dateOfBirth!),
            ),
          ]
        : <({String label, String value})>[
            (label: 'Email', value: user?.email ?? '—'),
            (label: 'Role', value: user?.roleLabel ?? '—'),
          ];

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          isDesktop ? 16 : 12,
          horizontal,
          40,
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 720 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHero(
                  name: displayName,
                  photoUrl: linked ? employee!.photoUrl : null,
                  employeeId: linked ? employee!.employeeId : null,
                  isDesktop: isDesktop,
                ),
                if (linked) ...[
                  const SizedBox(height: 16),
                  _IdCardShortcut(employee: employee!),
                ],
                const SizedBox(height: 16),
                _DetailsGrid(fields: fields, isDesktop: isDesktop),
                if (!linked) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Your profile is not linked to an employee record yet. '
                    'Ask an owner to link your account, then you can view your '
                    'details and salary slips here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textLight,
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDocumentsView extends StatelessWidget {
  const _EmployeeDocumentsView({this.employee});

  final Employee? employee;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final horizontal = isDesktop ? 32.0 : 16.0;
    final employee = this.employee;
    if (employee == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
        child: Text(
          'Your profile is not linked to an employee record yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          isDesktop ? 24 : 16,
          horizontal,
          40,
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 880 : double.infinity,
            ),
            child: EmployeeDocumentsSection(
              employeeId: employee.employeeId,
              employeeName: employee.employeeName,
              isDesktop: isDesktop,
              // Employee self-service is read-only. Uploading or viewing other
              // employees' records remains an owner/staff action in HRMS/DMS.
              canUpload: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalarySlipsView extends StatelessWidget {
  const _SalarySlipsView({this.employee});

  final Employee? employee;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final horizontal = isDesktop ? 32.0 : 16.0;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textLight,
      fontSize: 13,
      height: 1.45,
    );

    if (employee == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
        child: Text(
          'Your profile is not linked to an employee record yet.',
          style: textStyle,
        ),
      );
    }

    final options = PayslipPeriod.optionsForEmployee(
      employee!.dateOfJoining,
      dateOfExit: employee!.dateOfExit,
    );
    if (options.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
        child: Text(
          'No salary slips are available yet. Slips unlock after the month ends.',
          style: textStyle,
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          isDesktop ? 24 : 16,
          horizontal,
          32,
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 420 : double.infinity,
            ),
            child: _SalarySlipDownload(monthOptions: options),
          ),
        ],
      ),
    );
  }
}

class _IdCardShortcut extends StatelessWidget {
  const _IdCardShortcut({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(AppRoutes.employeeIdCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: AppColors.text),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My ID Card',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View your employee identity card',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeIdCardView extends StatefulWidget {
  const _EmployeeIdCardView({this.employee, this.user});

  final Employee? employee;
  final User? user;

  @override
  State<_EmployeeIdCardView> createState() => _EmployeeIdCardViewState();
}

class _EmployeeIdCardViewState extends State<_EmployeeIdCardView> {
  bool _showBack = false;
  bool _downloading = false;

  Future<void> _downloadCard(Employee employee, bool isSayge) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await EmployeeIdCardPdfBuilder.build(
        employee: employee,
        user: widget.user,
        isSayge: isSayge,
      );
      await savePdfBytes(
        bytes: bytes,
        filename: 'ID_Card_${employee.employeeId}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      await showAppMessageDialog(
        context,
        title: 'Could not download ID card',
        message: 'Please try again. If the issue continues, contact your administrator.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final horizontal = isDesktop ? 32.0 : 16.0;
    final employee = widget.employee;
    if (employee == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
        child: Text(
          'Your profile is not linked to an employee record yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
        ),
      );
    }

    final isSayge = widget.user?.companyId?.trim() == 'company_sayge';
    final front = _EmployeeIdCardFace(
      employee: employee,
      user: widget.user,
      isSayge: isSayge,
      isBack: false,
    );
    final back = _EmployeeIdCardFace(
      employee: employee,
      user: widget.user,
      isSayge: isSayge,
      isBack: true,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          isDesktop ? 28 : 20,
          horizontal,
          40,
        ),
        children: [
          if (isDesktop)
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 24,
                children: [front, back],
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 310,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.97,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<bool>(_showBack),
                    child: _showBack ? back : front,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showBack = !_showBack),
                icon: const Icon(Icons.flip_camera_android_outlined, size: 18),
                label: Text(_showBack ? 'Show front' : 'Show back'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: _downloading
                  ? null
                  : () => _downloadCard(employee, isSayge),
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 19),
              label: Text(_downloading ? 'Preparing PDF…' : 'Download PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeIdCardFace extends StatelessWidget {
  const _EmployeeIdCardFace({
    required this.employee,
    required this.user,
    required this.isSayge,
    required this.isBack,
  });

  final Employee employee;
  final User? user;
  final bool isSayge;
  final bool isBack;

  static const _saygeOrange = Color(0xFFFF6A4B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 522,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF36363A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: isBack ? _buildBack(context) : _buildFront(context),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final role = employee.designation.trim().isEmpty
        ? 'Employee'
        : employee.designation.trim();
    final code = employee.employeeId.trim().isEmpty
        ? '—'
        : employee.employeeId.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 28, 19, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                isSayge
                    ? 'assets/images/sayge_logo.png'
                    : 'assets/images/saasify_logo.png',
                width: 111,
                height: 25,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
              const Spacer(),
              Container(
                constraints: const BoxConstraints(maxWidth: 92),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF36363A)),
                ),
                child: Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Employee Code : $code',
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 31),
          Text(
            employee.employeeName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _saygeOrange,
              fontSize: 37,
              height: 0.95,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.phone_in_talk_outlined,
                size: 13,
                color: Color(0xFF2B3F6C),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  employee.contactNo.trim().isEmpty
                      ? '—'
                      : employee.contactNo.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(child: _IdCardPhoto(employee: employee)),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    if (isSayge) {
      // Approved Sayge reverse-card artwork. It contains the official contact
      // details (+91 - 8788681499 and humans@sayge.in) as outlined artwork so
      // the exact layout is preserved at every device size.
      return ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: SvgPicture.asset(
          'assets/images/id_cards/sayge_id_card_back.svg',
          fit: BoxFit.fill,
          width: 310,
          height: 522,
        ),
      );
    }
    final companyName = isSayge ? 'Sayge' : 'Saasify';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              isSayge
                  ? 'assets/images/sayge_logo.png'
                  : 'assets/images/saasify_logo.png',
              width: 136,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 50),
          const Icon(Icons.badge_outlined, size: 74, color: _saygeOrange),
          const SizedBox(height: 24),
          Text(
            'Employee identity card',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'This card is issued by $companyName and remains company property. '
            'Please return it when your employment ends.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  employee.employeeId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'If found, please return this card to the issuing company.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _IdCardPhoto extends StatelessWidget {
  const _IdCardPhoto({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final photoUrl = employee.photoUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: ColoredBox(
        color: const Color(0xFFF0E2D5),
        child: photoUrl == null || photoUrl.isEmpty
            ? Center(
                child: Text(
                  employee.employeeName.isEmpty
                      ? '—'
                      : employee.employeeName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6E5547),
                    fontWeight: FontWeight.w800,
                    fontSize: 72,
                  ),
                ),
              )
            : Image.network(
                photoUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => Center(
                  child: Text(
                    employee.employeeName.isEmpty
                        ? '—'
                        : employee.employeeName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF6E5547),
                      fontWeight: FontWeight.w800,
                      fontSize: 72,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.isDesktop,
    this.photoUrl,
    this.employeeId,
  });

  final String name;
  final String? photoUrl;
  final String? employeeId;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final id = employeeId?.trim();
    final avatarRadius = isDesktop ? 28.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 22 : 16,
        isDesktop ? 20 : 16,
        isDesktop ? 22 : 16,
        isDesktop ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          EmployeeAvatar(
            name: name,
            photoUrl: photoUrl,
            radius: avatarRadius,
            fontSize: isDesktop ? 18 : 16,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: isDesktop ? 20 : 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (id != null && id.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'ID $id',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.fields, required this.isDesktop});

  final List<({String label, String value})> fields;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final columns = isDesktop && fields.length > 1 ? 2 : 1;

    Widget cell(({String label, String value}) field) {
      final value = field.value.trim().isEmpty ? '—' : field.value.trim();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: columns == 1
          ? Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  cell(fields[i]),
                ],
              ],
            )
          : Column(
              children: [
                for (var i = 0; i < fields.length; i += 2) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cell(fields[i])),
                        Container(width: 1, color: AppColors.border),
                        Expanded(
                          child: i + 1 < fields.length
                              ? cell(fields[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SalarySlipDownload extends StatelessWidget {
  const _SalarySlipDownload({required this.monthOptions});

  final List<DateTime> monthOptions;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    return BlocConsumer<PayrollBloc, PayrollState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message != null) {
          showAppMessageDialog(context, message: message);
        }
      },
      builder: (context, state) {
        final generating = state.status == PayrollStatus.generating;
        final options = monthOptions;
        final selected = DateTime(state.year, state.month, 1);
        final value =
            options.any(
              (d) => d.year == selected.year && d.month == selected.month,
            )
            ? selected
            : options.last;

        if (value.year != state.year || value.month != state.month) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<PayrollBloc>().add(
              PayrollMonthChanged(month: value.month, year: value.year),
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<DateTime>(
              label: 'Month',
              value: value,
              items: options,
              itemLabel: (d) => DateFormat('MMMM yyyy').format(d),
              enabled: !generating,
              onChanged: (picked) {
                if (picked == null) return;
                context.read<PayrollBloc>().add(
                  PayrollMonthChanged(month: picked.month, year: picked.year),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: isDesktop ? Alignment.centerRight : Alignment.center,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: generating || state.employees.isEmpty
                      ? null
                      : () => context.read<PayrollBloc>().add(
                          const PayrollDownloadSelected(),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.textLight,
                    disabledForegroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.background,
                            ),
                          ),
                        )
                      : const Text(
                          'Download slip',
                          style: TextStyle(fontSize: 13),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
