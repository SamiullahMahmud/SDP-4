import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  int _totalUsers = 0;
  int _totalJobs = 0;
  int _totalApplications = 0;
  int _totalDisputes = 0;
  int _pendingNidVerifications = 0;
  Map<String, int> _userTypeDistribution = {};
  Map<String, int> _jobStatusDistribution = {};
  Map<String, int> _applicationStatusDistribution = {};
  Map<String, int> _disputeStatusDistribution = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch total users
      final usersResponse = await supabase.from('users').select('user_type');
      _userTypeDistribution = {};
      for (var user in usersResponse) {
        final userType = user['user_type'] as String?;
        if (userType != null) {
          _userTypeDistribution[userType] = (_userTypeDistribution[userType] ?? 0) + 1;
        }
      }
      _totalUsers = usersResponse.length;

      // Fetch total jobs
      final jobsResponse = await supabase.from('jobs').select('id');
      _totalJobs = jobsResponse.length;

      // Fetch total applications
      final applicationsResponseCount = await supabase.from('job_applications').select('id');
      _totalApplications = applicationsResponseCount.length;

      // Fetch total disputes
      final disputesResponseCount = await supabase.from('disputes').select('id');
      _totalDisputes = disputesResponseCount.length;

      // Fetch pending NID verifications
      final pendingNidResponse = await supabase.from('users').select('id').eq('verification_status', 'pending');
      _pendingNidVerifications = pendingNidResponse.length;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load dashboard stats: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAdminStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Admin Dashboard',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Theme.of(context).primaryColor.withAlpha(77),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: [
                                  _buildAdminStatCard(
                                    title: 'Total Users',
                                    value: '$_totalUsers',
                                    icon: FontAwesomeIcons.users,
                                    color: Colors.blueAccent,
                                  ),
                                  _buildAdminStatCard(
                                    title: 'Total Jobs',
                                    value: '$_totalJobs',
                                    icon: FontAwesomeIcons.briefcase,
                                    color: Colors.greenAccent,
                                  ),
                                  _buildAdminStatCard(
                                    title: 'Total Applications',
                                    value: '$_totalApplications',
                                    icon: FontAwesomeIcons.fileAlt,
                                    color: Colors.orangeAccent,
                                  ),
                                  _buildAdminStatCard(
                                    title: 'Total Disputes',
                                    value: '$_totalDisputes',
                                    icon: FontAwesomeIcons.gavel,
                                    color: Colors.redAccent,
                                  ),
                                  _buildAdminStatCard(
                                    title: 'Pending NID Verifications',
                                    value: '$_pendingNidVerifications',
                                    icon: FontAwesomeIcons.idCard,
                                    color: Colors.purpleAccent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // User Statistics - Donut Chart
                              _buildChartCard(
                                title: 'User Distribution',
                                icon: FontAwesomeIcons.users,
                                chart: _buildDonutChart(_userTypeDistribution, 'User Types'),
                              ),
                              const SizedBox(height: 20),
                              // Job Status - Pie Chart
                              _buildChartCard(
                                title: 'Job Status Overview',
                                icon: FontAwesomeIcons.briefcase,
                                chart: _buildPieChart(_jobStatusDistribution, 'Job Statuses'),
                              ),
                              const SizedBox(height: 20),
                              // Application Status - Bar Chart
                              _buildChartCard(
                                title: 'Application Status',
                                icon: FontAwesomeIcons.fileAlt,
                                chart: _buildBarChart(_applicationStatusDistribution, 'Application Statuses'),
                              ),
                              const SizedBox(height: 20),
                              // Dispute Status - Stacked Bar Chart
                              _buildChartCard(
                                title: 'Dispute Status',
                                icon: FontAwesomeIcons.gavel,
                                chart: _buildStackedBarChart(_disputeStatusDistribution, 'Dispute Statuses'),
                              ),
                              const SizedBox(height: 30),
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 200),
                                child: Column(
                                  children: [
                                    _buildAdminButton(
                                      context,
                                      icon: FontAwesomeIcons.users,
                                      title: 'Manage Users',
                                      route: '/adminUserManagement',
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAdminButton(
                                      context,
                                      icon: FontAwesomeIcons.briefcase,
                                      title: 'Manage Jobs',
                                      route: '/adminJobManagement',
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAdminButton(
                                      context,
                                      icon: FontAwesomeIcons.gavel,
                                      title: 'Manage Disputes',
                                      route: '/adminDisputeManagement',
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAdminButton(
                                      context,
                                      icon: FontAwesomeIcons.idCard,
                                      title: 'Review NID Verifications',
                                      route: '/adminNidReview',
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget chart,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 100),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(icon, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 10),
              SizedBox(
                height: 200, // Fixed height for charts
                child: chart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title', style: Theme.of(context).textTheme.bodyMedium));
    }
    List<PieChartSectionData> sections = [];
    int total = data.values.fold(0, (sum, count) => sum + count);
    List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
    ];
    int colorIndex = 0;

    data.forEach((key, value) {
      final double percentage = (value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          badgeWidget: FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 50,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              return;
            }
          });
        }),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title', style: Theme.of(context).textTheme.bodyMedium));
    }
    List<PieChartSectionData> sections = [];
    int total = data.values.fold(0, (sum, count) => sum + count);
    List<Color> colors = [
      Colors.cyan.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.lightGreen.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
    ];
    int colorIndex = 0;

    data.forEach((key, value) {
      final double percentage = (value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          badgeWidget: FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 0,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              return;
            }
          });
        }),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title', style: Theme.of(context).textTheme.bodyMedium));
    }
    List<BarChartGroupData> barGroups = [];
    List<Color> barColors = [
      Colors.lightBlue.shade400,
      Colors.amber.shade400,
      Colors.deepOrange.shade400,
      Colors.indigo.shade400,
      Colors.green.shade400,
      Colors.red.shade400,
    ];
    int index = 0;

    data.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: barColors[index % barColors.length],
              width: 20,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(data.keys.elementAt(value.toInt()), style: Theme.of(context).textTheme.bodySmall),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data.keys.elementAt(group.x.toInt())}: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStackedBarChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $title', style: Theme.of(context).textTheme.bodyMedium));
    }

    // For simplicity, assuming 'pending' and 'resolved' for disputes
    // You might need to adjust this based on your actual dispute_status values
    int pending = data['pending'] ?? 0;
    int resolved = data['resolved'] ?? 0;
    int inProgress = data['in_progress'] ?? 0; // Assuming a new status

    List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: (pending + resolved + inProgress).toDouble(),
            color: Colors.grey, // Base for total
            width: 20,
            borderRadius: BorderRadius.circular(6),
            rodStackItems: [
              BarChartRodStackItem(0, pending.toDouble(), Colors.red.shade400),
              BarChartRodStackItem(pending.toDouble(), (pending + inProgress).toDouble(), Colors.orange.shade400),
              BarChartRodStackItem((pending + inProgress).toDouble(), (pending + resolved + inProgress).toDouble(), Colors.green.shade400),
            ],
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    ];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Disputes', style: Theme.of(context).textTheme.bodySmall),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String status = '';
              if (rodIndex == 0) status = 'Pending';
              if (rodIndex == 1) status = 'In Progress';
              if (rodIndex == 2) status = 'Resolved';
              return BarTooltipItem(
                '$status: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      icon: FaIcon(icon, color: Colors.white, size: 24),
      label: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
            backgroundColor: MaterialStateProperty.resolveWith((states) => color),
          ),
    );
  }
}
