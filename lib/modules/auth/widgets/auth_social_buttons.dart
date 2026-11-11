// The Google / Facebook / Apple row under the auth forms.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/auth/services/auth_service.dart';

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SocialButton(
          label: 'G',
          tooltip: 'Google',
          color: const Color(0xFF4285F4),
          onPressed: enabled ? () => onPressed('Google') : null,
        ),
        if (kShowFacebookSignIn) ...[
          const SizedBox(width: 14),
          _SocialButton(
            icon: Icons.facebook,
            tooltip: 'Facebook',
            color: const Color(0xFF1877F2),
            onPressed: enabled ? () => onPressed('Facebook') : null,
          ),
        ],
        if (showAppleSignIn) ...[
          const SizedBox(width: 14),
          _SocialButton(
            icon: Icons.apple,
            tooltip: 'Apple',
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: enabled ? () => onPressed('Apple') : null,
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    this.icon,
    this.label,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData? icon;
  final String? label;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          icon: icon != null
              ? Icon(icon, color: color, size: 27)
              : Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
