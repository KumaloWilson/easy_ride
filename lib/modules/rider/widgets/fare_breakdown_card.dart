import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/models/fare_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FareBreakdownCard extends StatelessWidget {
  final FareModel fare;
  final VoidCallback? onClose;
  final bool showDetailedBreakdown;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const FareBreakdownCard({
    Key? key,
    required this.fare,
    this.onClose,
    this.showDetailedBreakdown = true,
    this.isExpanded = false,
    this.onToggleExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fare Estimate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Ride type and total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getRideTypeIcon(fare.rideType),
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fare.rideType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${fare.totalFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            
            // Ride details
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${fare.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${fare.duration.toStringAsFixed(0)} min',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Surge indicator
            if (fare.surgeFactor > 1.0)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warningColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: AppTheme.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Surge pricing: ${(fare.surgeFactor * 100 - 100).toStringAsFixed(0)}% higher',
                      style: const TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(
                    begin: -0.1,
                    end: 0,
                    curve: Curves.easeOutQuart,
                  ),
            
            // Detailed breakdown
            if (showDetailedBreakdown)
              GestureDetector(
                onTap: onToggleExpand,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded ? 'Hide fare details' : 'View fare details',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            
            if (isExpanded && showDetailedBreakdown)
              Column(
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildFareDetailRow('Base fare', fare.baseFare),
                  _buildFareDetailRow('Distance (${fare.distance.toStringAsFixed(1)} km)', fare.distanceFare),
                  _buildFareDetailRow('Time (${fare.duration.toStringAsFixed(0)} min)', fare.timeFare),
                  if (fare.surgeFactor > 1.0)
                    _buildFareDetailRow(
                      'Surge pricing (${(fare.surgeFactor * 100 - 100).toStringAsFixed(0)}%)',
                      (fare.baseFare + fare.distanceFare + fare.timeFare) * (fare.surgeFactor - 1),
                      isHighlighted: true,
                    ),
                  if (fare.discount > 0)
                    _buildFareDetailRow(
                      'Discount',
                      -fare.discount,
                      isDiscount: true,
                    ),
                  _buildFareDetailRow('Tax', fare.tax),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${fare.totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn().slideY(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutQuart,
                  ),
          ],
        ),
      ),
    ).animate().custom(
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(
        scale: 0.9 + (0.1 * value),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
    );
  }

  Widget _buildFareDetailRow(String title, double amount, {bool isHighlighted = false, bool isDiscount = false}) {
    final formattedAmount = isDiscount ? '-\$${amount.abs().toStringAsFixed(2)}' : '\$${amount.toStringAsFixed(2)}';
    final textColor = isHighlighted 
        ? AppTheme.warningColor 
        : (isDiscount ? AppTheme.successColor : null);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              color: textColor,
              fontWeight: isHighlighted || isDiscount ? FontWeight.w500 : null,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRideTypeIcon(String rideType) {
    switch (rideType) {
      case 'Premium':
        return Icons.star;
      case 'XL':
        return Icons.airport_shuttle;
      case 'Standard':
      default:
        return Icons.directions_car;
    }
  }
}
