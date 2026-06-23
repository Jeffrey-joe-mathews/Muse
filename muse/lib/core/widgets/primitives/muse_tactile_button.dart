import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../theme/app_colors.dart';

class MuseTactileButton extends StatefulWidget {
  final bool isPrimaryRecord;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double width;
  final double height;

  const MuseTactileButton({
    super.key,
    this.isPrimaryRecord = false,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
    required this.child,
    this.width = 46,
    this.height = 28,
  });

  @override
  State<MuseTactileButton> createState() => _MuseTactileButtonState();
}

class _MuseTactileButtonState extends State<MuseTactileButton> {
  bool _isPressed = false;

  void _triggerHaptic (bool isHeavy) async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      isHeavy ? Vibration.vibrate(duration: 50, amplitude: 255) : Vibration.vibrate(duration: 30);
    }
    else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isPrimaryRecord
      ? (widget.isActive ? AppColors.ledRedActive : AppColors.ledRedStandby)
      : (widget.isActive ? AppColors.hardwareSurface : AppColors.hardwareSurfaceDepressed);
    
    final isDown = _isPressed || widget.isActive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _triggerHaptic(false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () {
        if (widget.onLongPress != null) {
          setState(() => _isPressed = false);
          _triggerHaptic(true);
          widget.onLongPress!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(top: isDown ? 4.0 : 0.0, bottom: isDown ? 0.0 : 4.0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.hardwareBorder, width: 1.5),
          boxShadow: isDown ? [] : [
            const BoxShadow(color: AppColors.hardwareBorder, offset: Offset(0, 4), blurRadius: 0)
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}