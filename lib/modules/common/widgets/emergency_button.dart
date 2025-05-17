import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_ride/core/animations/animations.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback? onCancel;

  const EmergencyButton({
    Key? key,
    required this.onPressed,
    this.isActive = false,
    this.isExpanded = false,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return _buildExpandedButton(context);
    }
    
    return _buildCompactButton(context);
  }

  Widget _buildCompactButton(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.red : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isActive 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.emergency : Icons.emergency_outlined,
          color: isActive ? Colors.white : Colors.red,
          size: 28,
        ),
      ).animate(
        target: isActive ? 1 : 0,
      ).scaleXY(
        begin: 1,
        end: 1.1,
        duration: 600.ms,
        curve: Curves.easeInOut,
      ).then(

      ).scaleXY(
        begin: 1.1,
        end: 1,
        duration: 600.ms,
        curve: Curves.easeInOut,
      )
    );
  }

  Widget _buildExpandedButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Emergency Active' : 'Emergency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isActive 
                          ? 'Help is on the way'
                          : 'Tap to activate emergency mode',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isActive && onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              if (isActive && onCancel != null)
                const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isActive ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.red.withOpacity(0.6),
                    disabledForegroundColor: Colors.white,
                  ),
                  child: Text(isActive ? 'Active' : 'Activate'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(
      target: isActive ? 1 : 0,
    ).custom(
      duration: 600.ms,
      builder: (context, value, child) {
        final color = Color.lerp(Colors.white, Colors.red.shade50, value)!;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1 * value),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
