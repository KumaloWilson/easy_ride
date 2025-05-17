import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/driver/controllers/driver_controller.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/models/ride_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DriverEarningsView extends GetView<DriverController> {
  const DriverEarningsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    '\$${controller.totalEarnings.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            '\$${controller.todayEarnings.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Week',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            '\$${controller.weeklyEarnings.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rides',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            '${controller.completedRides.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Earnings Chart
            const Text(
              'Earnings Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(() => controller.rideHistory.isEmpty
                ? Center(
                    child: Text(
                      'No earnings data available',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxEarnings(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          //tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '\$${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  '\$${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _getBarGroups(),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Recent Earnings
            const Text(
              'Recent Earnings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => controller.rideHistory.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No earnings yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete rides to start earning',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.rideHistory.length > 5 ? 5 : controller.rideHistory.length,
                  itemBuilder: (context, index) {
                    final ride = controller.rideHistory[index];
                    return _buildEarningItem(ride);
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEarningItem(RideModel ride) {
    final DateTime rideDate = ride.status == 'completed' 
        ? ride.completedAt ?? ride.createdAt
        : ride.cancelledAt ?? ride.createdAt;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ride.status == 'completed' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ride.status == 'completed' ? Icons.check : Icons.close,
              color: ride.status == 'completed' ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.pickup!.name} to ${ride.dropoff!.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(rideDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '\$${ride.fare.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: ride.status == 'completed' ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  double _getMaxEarnings() {
    if (controller.rideHistory.isEmpty) return 100;
    
    double maxEarning = 0;
    for (var ride in controller.rideHistory) {
      if (ride.status == 'completed' && ride.fare > maxEarning) {
        maxEarning = ride.fare;
      }
    }
    
    return (maxEarning + 20).roundToDouble(); // Add some padding
  }
  
  List<BarChartGroupData> _getBarGroups() {
    final List<BarChartGroupData> barGroups = [];
    
    // Get current day of week (0 = Monday, 6 = Sunday)
    final now = DateTime.now();
    final currentDayOfWeek = (now.weekday - 1) % 7;
    
    // Create a map to store earnings by day of week
    final Map<int, double> earningsByDay = {};
    
    // Initialize all days to 0
    for (int i = 0; i < 7; i++) {
      earningsByDay[i] = 0;
    }
    
    // Calculate earnings for each day of the current week
    for (var ride in controller.rideHistory) {
      if (ride.status == 'completed' && ride.completedAt != null) {
        final rideDate = ride.completedAt!;
        final startOfWeek = now.subtract(Duration(days: currentDayOfWeek));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        
        if (rideDate.isAfter(startOfWeekDay)) {
          final dayOfWeek = (rideDate.weekday - 1) % 7;
          earningsByDay[dayOfWeek] = (earningsByDay[dayOfWeek] ?? 0) + ride.fare;
        }
      }
    }
    
    // Create bar groups
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: earningsByDay[i] ?? 0,
              color: i == currentDayOfWeek ? AppTheme.primaryColor : AppTheme.secondaryColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }
}
