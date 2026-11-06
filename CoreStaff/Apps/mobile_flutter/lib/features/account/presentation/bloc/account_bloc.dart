import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_resolver.dart';
import '../../../payslip/data/models/payslip_dto.dart';
import '../../../payslip/data/payslip_repository.dart';
import '../../data/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

export 'account_event.dart';
export 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository accountRepository;

  /// Optional so the account tab still works when payslips are unavailable;
  /// when provided, payslips load in parallel with the profile (Expo parity).
  final PayslipRepository? payslipRepository;

  AccountBloc({required this.accountRepository, this.payslipRepository})
      : super(const AccountInitial()) {
    on<AccountProfileRequested>(_onProfileRequested);
  }

  Future<void> _onProfileRequested(
    AccountProfileRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(const AccountLoading());
    }

    try {
      // Mirror Expo `Promise.allSettled([getMyProfile, getMyPayslips])`.
      final profileFuture = accountRepository.getMyProfile();
      final payslipsFuture = _loadPayslips();

      final profile = await profileFuture;
      final payslipResult = await payslipsFuture;
      emit(AccountLoaded(
        profile: profile,
        payslips: payslipResult.payslips,
        errorMessage: payslipResult.error,
      ));
    } catch (e) {
      emit(AccountError(message: _resolveError(e)));
    }
  }

  Future<({List<PayslipDto> payslips, String? error})> _loadPayslips() async {
    final repo = payslipRepository;
    if (repo == null) return (payslips: const <PayslipDto>[], error: null);
    try {
      final payslips = await repo.getMyPayslips();
      return (payslips: payslips, error: null);
    } catch (e) {
      return (payslips: const <PayslipDto>[], error: _resolveError(e));
    }
  }

  String _resolveError(Object e) {
    if (e is ApiException) {
      return ErrorResolver.resolveEmployeeError(e.code, e.message);
    }
    if (e is AppException) {
      return e.message;
    }
    return 'Không thể tải thông tin hồ sơ: ${e.toString()}';
  }
}
