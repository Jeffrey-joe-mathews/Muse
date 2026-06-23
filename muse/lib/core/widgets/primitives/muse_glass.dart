import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MuseGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const MuseGlass({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 15.0,
    this.padding,
    this.backgroundColor,
    this.borderColor
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassShell,
            border: Border.all(color: borderColor ?? AppColors.glassBorder, width: 1.0),
            borderRadius: BorderRadius.circular(borderRadius) 
          ),
          child: child,
        ),
      ),
    );
  }
}