import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_ride/core/animations/animations.dart';

class PayoutRequestForm extends StatefulWidget {
  final double availableBalance;
  final List<String> paymentMethods;
  final Function(double amount, String paymentMethod, Map<String, dynamic> paymentDetails) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const PayoutRequestForm({
    Key? key,
    required this.availableBalance,
    required this.paymentMethods,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PayoutRequestForm> createState() => _PayoutRequestFormState();
}

class _PayoutRequestFormState extends State<PayoutRequestForm> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = '';
  final Map<String, TextEditingController> _detailsControllers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedPaymentMethod = widget.paymentMethods.first;
    }
    
    // Initialize controllers for payment details
    _initializeDetailsControllers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (var controller in _detailsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeDetailsControllers() {
    // Clear existing controllers
    for (var controller in _detailsControllers.values) {
      controller.dispose();
    }
    _detailsControllers.clear();
    
    // Create new controllers based on selected payment method
    switch (_selectedPaymentMethod) {
      case 'bank':
        _detailsControllers['accountName'] = TextEditingController();
        _detailsControllers['accountNumber'] = TextEditingController();
        _detailsControllers['bankName'] = TextEditingController();
        _detailsControllers['ifscCode'] = TextEditingController();
        break;
      case 'paypal':
        _detailsControllers['email'] = TextEditingController();
        break;
      case 'upi':
        _detailsControllers['upiId'] = TextEditingController();
        break;
      default:
        // Default case for other payment methods
        _detailsControllers['details'] = TextEditingController();
    }
  }

  void _handleSubmit() {
    // Validate amount
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
      });
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }
    
    if (amount > widget.availableBalance) {
      setState(() {
        _errorMessage = 'Amount exceeds available balance';
      });
      return;
    }
    
    // Validate payment details
    final paymentDetails = <String, dynamic>{};
    bool isValid = true;
    
    for (var entry in _detailsControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all payment details';
        });
        isValid = false;
        break;
      }
      paymentDetails[entry.key] = value;
    }
    
    if (!isValid) return;
    
    // Clear error message
    setState(() {
      _errorMessage = null;
    });
    
    // Submit request
    widget.onSubmit(amount, _selectedPaymentMethod, paymentDetails);
  }

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Request Payout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Available balance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount to withdraw',
              prefixIcon: const Icon(Icons.attach_money),
              suffixText: 'USD',
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment method selection
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.payment),
            ),
            items: widget.paymentMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(_getPaymentMethodLabel(method)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _selectedPaymentMethod) {
                setState(() {
                  _selectedPaymentMethod = value;
                  _initializeDetailsControllers();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Payment details
          ..._buildPaymentDetailsFields(),
          
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Submit button
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              if (widget.onCancel != null)
                const SizedBox(width: 16),
              Expanded(
                child: AnimatedButton(
                  onPressed: _handleSubmit,
                  isLoading: widget.isLoading,
                  isDisabled: widget.isLoading,
                  child: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().custom(
      duration: 400.ms,
      builder: (context, value, child) => Transform.scale(
        scale: 0.9 + (0.1 * value),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildPaymentDetailsFields() {
    final List<Widget> fields = [];
    
    switch (_selectedPaymentMethod) {
      case 'bank':
        fields.add(
          TextField(
            controller: _detailsControllers['accountName'],
            decoration: const InputDecoration(
              labelText: 'Account Holder Name',
            ),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextField(
            controller: _detailsControllers['accountNumber'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Account Number',
            ),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextField(
            controller: _detailsControllers['bankName'],
            decoration: const InputDecoration(
              labelText: 'Bank Name',
            ),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextField(
            controller: _detailsControllers['ifscCode'],
            decoration: const InputDecoration(
              labelText: 'IFSC/SWIFT Code',
            ),
          ),
        );
        break;
        
      case 'paypal':
        fields.add(
          TextField(
            controller: _detailsControllers['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'PayPal Email',
            ),
          ),
        );
        break;
        
      case 'upi':
        fields.add(
          TextField(
            controller: _detailsControllers['upiId'],
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'example@upi',
            ),
          ),
        );
        break;
        
      default:
        fields.add(
          TextField(
            controller: _detailsControllers['details'],
            decoration: const InputDecoration(
              labelText: 'Payment Details',
            ),
          ),
        );
    }
    
    return fields;
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'bank':
        return 'Bank Transfer';
      case 'paypal':
        return 'PayPal';
      case 'upi':
        return 'UPI';
      default:
        return method.toUpperCase();
    }
  }
}
