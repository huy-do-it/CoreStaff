import 'package:flutter_test/flutter_test.dart';
import 'package:corestaff_mobile/core/error/error_resolver.dart';

void main() {
  group('ErrorResolver', () {
    test('resolves known auth error codes to friendly Vietnamese messages', () {
      expect(
        ErrorResolver.resolveAuthError('AUTH_INVALID_CREDENTIALS', 'default'),
        'Tài khoản hoặc mật khẩu không đúng.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_ACCOUNT_DISABLED', 'default'),
        'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ HR.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_ACCOUNT_LOCKED', 'default'),
        'Tài khoản đang bị khóa tạm thời. Vui lòng thử lại sau.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_SESSION_EXPIRED', 'default'),
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_CURRENT_PASSWORD_INVALID', 'default'),
        'Mật khẩu hiện tại không đúng.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_PASSWORD_POLICY_FAILED', 'default'),
        'Mật khẩu mới cần ít nhất 8 ký tự, gồm chữ và số, và không trùng mật khẩu hiện tại.',
      );
      expect(
        ErrorResolver.resolveAuthError('AUTH_RESET_TOKEN_INVALID', 'default'),
        'Mã đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.',
      );
    });

    test('resolves known domain business error codes', () {
      expect(
        ErrorResolver.resolveEmployeeError('ATTENDANCE_ALREADY_CHECKED_IN', 'default'),
        'Bạn đã điểm danh vào ca hôm nay rồi.',
      );
      expect(
        ErrorResolver.resolveEmployeeError('LEAVE_BALANCE_INSUFFICIENT', 'default'),
        'Số ngày phép khả dụng không đủ cho yêu cầu này.',
      );
      expect(
        ErrorResolver.resolveEmployeeError('REQUEST_ALREADY_PROCESSED', 'default'),
        'Yêu cầu này đã được xử lý trước đó.',
      );
    });

    test('maps HTTP 401 without a known code to invalid credentials (Expo parity)', () {
      expect(
        ErrorResolver.resolveAuthError(null, 'Unauthorized', 401),
        'Tài khoản hoặc mật khẩu không đúng.',
      );
      expect(
        ErrorResolver.resolveAuthError('SOME_UNKNOWN', 'raw', 401),
        'Tài khoản hoặc mật khẩu không đúng.',
      );
      // Known auth code still wins over the generic 401 mapping.
      expect(
        ErrorResolver.resolveAuthError('AUTH_SESSION_EXPIRED', 'raw', 401),
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
      // Non-401 unknown errors keep the raw server message.
      expect(ErrorResolver.resolveAuthError(null, 'raw', 500), 'raw');
    });

    test('falls back to provided message or generic fallback when code is unknown', () {
      expect(
        ErrorResolver.resolveAuthError('UNKNOWN_CODE', 'Custom error msg'),
        'Custom error msg',
      );
      expect(
        ErrorResolver.resolveAuthError(null, null),
        'Không thể xử lý yêu cầu. Vui lòng thử lại.',
      );
      expect(
        ErrorResolver.resolveEmployeeError('NON_EXISTENT_CODE', 'Server failed'),
        'Server failed',
      );
    });
  });
}

