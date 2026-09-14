import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/features/auth/application/auth_success.dart';

/// "Continue with phone": one unified flow (no separate sign-up/sign-in
/// choice) — enter a phone number, receive an SMS code, verify it. The
/// backend transparently signs in an existing phone or creates a new
/// account; either way this page ends with the same applyAuthResult +
/// context.go('/') as email/Google/Apple, so the existing onboarding
/// redirect logic (driven by Profile.onboarding_completed) applies unchanged.
class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

enum _Step { phone, otp }

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  _Step _step = _Step.phone;
  String? _phoneNumber;
  bool _busy = false;
  String? _error;

  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendSecondsLeft -= 1;
        if (_resendSecondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode(String phoneNumber) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ApiClient.I.requestPhoneOtp(phoneNumber: phoneNumber);
      _phoneNumber = phoneNumber;
      final resendAfter = (result['resend_after_seconds'] as num?)?.toInt() ?? 60;
      if (!mounted) return;
      setState(() => _step = _Step.otp);
      _startResendCountdown(resendAfter);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ApiException ? error.message : 'Unable to send the code: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendCode() async {
    final phone = _phoneNumber;
    if (phone == null || _resendSecondsLeft > 0) return;
    await _sendCode(phone);
  }

  void _changePhoneNumber() {
    _resendTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _step = _Step.phone;
      _error = null;
    });
  }

  Future<void> _verifyCode() async {
    final phone = _phoneNumber;
    final code = _otpControllers.map((c) => c.text).join();
    if (phone == null || code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ApiClient.I.verifyPhoneOtp(phoneNumber: phone, code: code);
      await applyAuthResult(ref, result, fallbackUsername: 'Phone account');
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : 'Unable to verify the code: $error';
        for (final controller in _otpControllers) {
          controller.clear();
        }
      });
      _otpFocusNodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content landed in one field — distribute it across the boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpControllers.length; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextEmpty = digits.length.clamp(0, _otpControllers.length - 1);
      _otpFocusNodes[nextEmpty].requestFocus();
      if (digits.length >= 6) _verifyCode();
      return;
    }
    if (value.isNotEmpty && index < _otpControllers.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _onOtpBackspace(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_step == _Step.phone ? 'Continue with phone' : 'Enter verification code'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: _step == _Step.phone ? _buildPhoneStep() : _buildOtpStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    String? completeNumber;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter your phone number',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        IntlPhoneField(
          decoration: const InputDecoration(
            labelText: 'Phone number',
            border: OutlineInputBorder(),
          ),
          onChanged: (phone) => completeNumber = phone.completeNumber,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _busy
                ? null
                : () {
                    final phone = completeNumber;
                    if (phone == null || phone.trim().isEmpty) {
                      setState(() => _error = 'Enter a valid phone number.');
                      return;
                    }
                    _sendCode(phone);
                  },
            child: _busy ? const CircularProgressIndicator() : const Text('Send code'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'We sent a code to ${_phoneNumber ?? 'your phone'}',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 56,
              child: KeyboardListener(
                focusNode: _otpFocusNodes[index],
                onKeyEvent: (event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                    _onOtpBackspace(index);
                  }
                },
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
                  onChanged: (value) => _onOtpDigitChanged(index, value),
                ),
              ),
            );
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _busy ? null : _verifyCode,
            child: _busy ? const CircularProgressIndicator() : const Text('Verify'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _resendSecondsLeft > 0 || _busy ? null : _resendCode,
          child: Text(
            _resendSecondsLeft > 0 ? 'Resend code in ${_resendSecondsLeft}s' : 'Resend code',
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _changePhoneNumber,
          child: const Text('Change phone number'),
        ),
      ],
    );
  }
}
