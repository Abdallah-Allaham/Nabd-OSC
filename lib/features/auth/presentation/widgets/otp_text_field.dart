import 'package:flutter/material.dart';
import 'package:navia/core/theme/app_theme.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpTextField extends StatefulWidget {
  final TextEditingController controller;
  final int length;

  const OtpTextField({super.key, required this.controller, this.length = 6});

  @override
  State<OtpTextField> createState() => _OtpTextFieldState();
}

class _OtpTextFieldState extends State<OtpTextField> with CodeAutoFill {
  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void codeUpdated() {
    if (mounted) {
      widget.controller.text = code ?? '';
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>();

    return PinFieldAutoFill(
      controller: widget.controller,
      decoration: BoxLooseDecoration(
        strokeColorBuilder: FixedColorBuilder(
          colors!.textLight.withValues(alpha: 0.5),
        ),
        textStyle: Theme.of(context).textTheme.bodyLarge,
        gapSpace: 10,
        radius: const Radius.circular(8),
      ),
      currentCode: widget.controller.text,
      onCodeChanged: (code) {},
      codeLength: widget.length,
    );
  }
}
