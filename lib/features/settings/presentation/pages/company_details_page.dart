import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/branding/company_branding.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_message_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../injection_container.dart';
import '../../../hrms/presentation/widgets/employee_form_layout.dart';
import '../../domain/entities/settings_entities.dart';
import '../../domain/usecases/update_company_logo_usecase.dart';
import '../bloc/company_details/company_details_bloc.dart';

class CompanyDetailsPage extends StatelessWidget {
  const CompanyDetailsPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CompanyDetailsBloc>()..add(const CompanyDetailsStarted()),
      child: _CompanyDetailsBody(onBack: onBack),
    );
  }
}

class _CompanyDetailsBody extends StatefulWidget {
  const _CompanyDetailsBody({this.onBack});

  final VoidCallback? onBack;

  @override
  State<_CompanyDetailsBody> createState() => _CompanyDetailsBodyState();
}

class _CompanyDetailsBodyState extends State<_CompanyDetailsBody> {
  final _displayName = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();
  final _pan = TextEditingController();
  final _sac = TextEditingController();
  final _tel = TextEditingController();
  final _email = TextEditingController();
  final _bankName = TextEditingController();
  final _account = TextEditingController();
  final _branch = TextEditingController();
  final _ifsc = TextEditingController();
  String? _boundId;
  bool _uploadingLogo = false;

  Future<void> _pickAndUploadLogo(CompanyDetails details) async {
    if (_uploadingLogo) return;
    try {
      // FilePicker supplies bytes on web and native platforms consistently.
      // The earlier ImagePicker-only route could stop before upload when a
      // browser did not support ImageCropper's native dialog.
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty || !mounted) return;
      final selected = files.first;
      final originalBytes = await selected.readAsBytes();
      if (originalBytes.isEmpty) {
        throw StateError('The selected image could not be read.');
      }

      var bytes = originalBytes;
      var fileName = selected.name;
      var mimeType = _mimeFor(selected.extension, selected.name);

      // Native platforms can crop from a local file path. On web, paths are
      // not stable files, so retaining the original still produces a square,
      // cover-fitted logo without blocking the upload.
      final localPath = selected.path;
      if (localPath != null && localPath.isNotEmpty) {
        try {
          final cropped = await ImageCropper().cropImage(
            sourcePath: localPath,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            maxWidth: 1024,
            maxHeight: 1024,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 92,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop company logo',
                toolbarColor: AppColors.text,
                toolbarWidgetColor: AppColors.background,
                lockAspectRatio: true,
                hideBottomControls: true,
                cropStyle: CropStyle.rectangle,
              ),
              IOSUiSettings(
                title: 'Crop company logo',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
                rotateButtonsHidden: false,
              ),
            ],
          );
          if (cropped != null) {
            bytes = await cropped.readAsBytes();
            fileName = 'company_logo.jpg';
            mimeType = 'image/jpeg';
          }
        } catch (_) {
          // Upload the selected image when cropping is unavailable. The
          // square preview/sidebar use BoxFit.cover, so it remains well-fit.
        }
      }
      if (bytes.isEmpty || !mounted) return;

      setState(() => _uploadingLogo = true);
      final result = await sl<UpdateCompanyLogoUseCase>()(
        companyId: details.id,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (!mounted) return;
      setState(() => _uploadingLogo = false);

      await result.fold(
        (failure) => showAppMessageDialog(
          context,
          title: 'Company logo',
          message: failure.message,
        ),
        (updated) async {
          context.read<CompanyDetailsBloc>().add(
            CompanyDetailsLogoUpdated(updated),
          );
          CompanyBranding.refresh();
          if (!mounted) return;
          await showAppMessageDialog(context, message: 'Company logo updated');
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingLogo = false);
      await showAppMessageDialog(
        context,
        title: 'Company logo',
        message:
            'Could not prepare that image. Please select a PNG, JPG, or WebP file.',
      );
    }
  }

  static String _mimeFor(String? extension, String fileName) {
    final ext = (extension ?? '').toLowerCase();
    final normalized = ext.isNotEmpty
        ? ext
        : fileName.split('.').last.toLowerCase();
    return switch (normalized) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  @override
  void dispose() {
    _displayName.dispose();
    _address.dispose();
    _gstin.dispose();
    _pan.dispose();
    _sac.dispose();
    _tel.dispose();
    _email.dispose();
    _bankName.dispose();
    _account.dispose();
    _branch.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  void _bind(CompanyDetails details) {
    if (_boundId == details.id && _displayName.text.isNotEmpty) return;
    _boundId = details.id;
    _displayName.text = details.displayName;
    _address.text = details.address;
    _gstin.text = details.gstin;
    _pan.text = details.pan;
    _sac.text = details.sacCode;
    _tel.text = details.telephone;
    _email.text = details.email;
    _bankName.text = details.bankName;
    _account.text = details.bankAccountNo;
    _branch.text = details.bankBranch;
    _ifsc.text = details.bankIfsc;
  }

  void _pushFields(BuildContext context) {
    context.read<CompanyDetailsBloc>().add(
      CompanyDetailsFieldChanged(
        displayName: _displayName.text,
        address: _address.text,
        gstin: _gstin.text,
        pan: _pan.text,
        sacCode: _sac.text,
        telephone: _tel.text,
        email: _email.text,
        bankName: _bankName.text,
        bankAccountNo: _account.text,
        bankBranch: _branch.text,
        bankIfsc: _ifsc.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final horizontal = isDesktop ? 32.0 : 16.0;

    return BlocConsumer<CompanyDetailsBloc, CompanyDetailsState>(
      listenWhen: (prev, next) =>
          (prev.status != next.status &&
              next.status == CompanyDetailsStatus.success) ||
          (prev.details?.id != next.details?.id && next.details != null),
      listener: (context, state) async {
        final details = state.details;
        if (details != null) _bind(details);
        if (state.status == CompanyDetailsStatus.success) {
          await showAppMessageDialog(context, message: 'Company details saved');
        }
      },
      builder: (context, state) {
        if (state.status == CompanyDetailsStatus.initial ||
            state.status == CompanyDetailsStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.text),
          );
        }

        final details = state.details;
        if (details == null) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Company details unavailable.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          );
        }

        if (_boundId != details.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _bind(details);
          });
        }

        final saving = state.status == CompanyDetailsStatus.saving;
        final logoBusy = _uploadingLogo;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 24),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _SquareCompanyLogoPicker(
                        logoUrl: details.logoUrl,
                        name: details.displayName.isNotEmpty
                            ? details.displayName
                            : details.name,
                        size: isDesktop ? 112 : 96,
                        busy: logoBusy,
                        enabled: !saving && !logoBusy,
                        onTap: () => _pickAndUploadLogo(details),
                      ),
                    ),
                  ),
                  Text(
                    'GST & identity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.highlight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Display name',
                    controller: _displayName,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Address',
                    controller: _address,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'GSTIN',
                    controller: _gstin,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'PAN',
                    controller: _pan,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'SAC code',
                    controller: _sac,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Telephone',
                    controller: _tel,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Email',
                    controller: _email,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bank details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.highlight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Bank name',
                    controller: _bankName,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Account number',
                    controller: _account,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Branch',
                    controller: _branch,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'IFSC',
                    controller: _ifsc,
                    enabled: !saving,
                    onChanged: (_) => _pushFields(context),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            EmployeeStickyActions(
              children: [
                OutlinedButton(
                  onPressed: saving ? null : widget.onBack,
                  child: const Text('Back'),
                ),
                AppButton(
                  label: saving ? 'Saving…' : 'Save',
                  isLoading: saving,
                  enabled: !saving,
                  onPressed: () {
                    _pushFields(context);
                    context.read<CompanyDetailsBloc>().add(
                      const CompanyDetailsSubmitted(),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SquareCompanyLogoPicker extends StatelessWidget {
  const _SquareCompanyLogoPicker({
    required this.logoUrl,
    required this.name,
    required this.size,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String? logoUrl;
  final String name;
  final double size;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim() ?? '';
    return Semantics(
      button: true,
      label: 'Upload and crop company logo',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _LogoFallback(name: name),
                    )
                  : _LogoFallback(name: name),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            if (enabled)
              Positioned(
                right: -8,
                bottom: -8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.highlight,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
                    color: AppColors.background,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? 'C'
        : trimmed.substring(0, 1).toUpperCase();
    return Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
