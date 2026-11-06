import '../../../payslip/data/models/payslip_dto.dart';
import '../../data/models/employee_profile_dto.dart';

abstract class AccountState {
  const AccountState();
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final EmployeeProfileDto profile;

  /// Payslips loaded alongside the profile (Expo `AccountScreen` loads both
  /// with `Promise.allSettled`) to drive the "Phiếu lương" menu row
  /// description and the badge of new (`RELEASED`) payslips.
  final List<PayslipDto> payslips;

  /// Non-blocking error (e.g. payslips failed while the profile succeeded).
  final String? errorMessage;

  const AccountLoaded({
    required this.profile,
    this.payslips = const [],
    this.errorMessage,
  });

  int get releasedPayslipCount =>
      payslips.where((p) => p.status == 'RELEASED').length;
}

class AccountError extends AccountState {
  final String message;

  const AccountError({required this.message});
}
