import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/models/fare_model.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RideOptionsCard extends StatelessWidget {
  final List<String>? rideTypes;
  final String selectedRideType;
  final Function(String) onRideTypeSelected;
  final List<String>? paymentMethods;
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodSelected;
  final FareModel? fare;
  final bool isLoading;
  final VoidCallback onRequestRide;
  final VoidCallback? onShowFareBreakdown;
  final VoidCallback? onBack;

  const RideOptionsCard({
    Key? key,
    this.rideTypes,
    required this.selectedRideType,
    required this.onRideTypeSelected,
    this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.fare,
    this.isLoading = false,
    required this.onRequestRide,
    this.onShowFareBreakdown,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> types = rideTypes ?? ['Standard', 'Premium', 'XL'];
    final List<String> methods = paymentMethods ?? ['card', 'cash', 'wallet'];

    return Container(
      margin: const EdgeInsets.all(16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 16,
                      ),
                    ),
                  ),
                if (onBack != null)
                  const SizedBox(width: 16),
                const Text(
                  'Ride Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Ride types
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                final isSelected = type == selectedRideType;

                return GestureDetector(
                  onTap: () => onRideTypeSelected(type),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getRideTypeIcon(type),
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (fare != null)
                          Text(
                            '\$${_getRideTypeFare(type, fare!).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ).animate(
                    target: isSelected ? 1 : 0,
                  ).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuart,
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // Payment method
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedPaymentMethod,
                  underline: const SizedBox(),
                  items: methods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(method),
                            color: Colors.grey[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPaymentMethodLabel(method),
                            style: TextStyle(
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onPaymentMethodSelected(value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Fare
          if (fare != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Fare',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${fare?.totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (onShowFareBreakdown != null)
                    TextButton(
                      onPressed: onShowFareBreakdown,
                      child: const Text('View Breakdown'),
                    ),
                ],
              ),
            ),

          // Request ride button
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedButton(
              onPressed: onRequestRide,
              isLoading: isLoading,
              child: const Text('Request Ride'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(
      begin: 0.1,
      end: 0,
      curve: Curves.easeOutQuart,
    );
  }

  IconData _getRideTypeIcon(String type) {
    switch (type) {
      case 'Premium':
        return Icons.star;
      case 'XL':
        return Icons.airport_shuttle;
      case 'Standard':
      default:
        return Icons.directions_car;
    }
  }

  double _getRideTypeFare(String type, FareModel baseFare) {
    switch (type) {
      case 'Premium':
        return baseFare.totalFare * 1.5;
      case 'XL':
        return baseFare.totalFare * 2.0;
      case 'Standard':
      default:
        return baseFare.totalFare;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'Credit Card';
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      default:
        return method.toUpperCase();
    }
  }
}
