import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'global_menu.dart';
import 'sidebar_menu.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _userType;
  String? _userId;
  String? _userFullName;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndAnalytics();
  }

  Future<void> _fetchUserDataAndAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      _userId = user.id;

      final userDataResponse = await supabase
          .from('users')
          .select('user_type, full_name, job_completed, global_rating')
          .eq('id', _userId!)
          .maybeSingle();

      if (userDataResponse == null) {
        _userType = 'Unknown'; // Set a default user type
        print('User data not found, setting user type to Unknown.');
        return; // Exit early if user data is not found
      }

      _userType = userDataResponse['user_type'];
      _userFullName = userDataResponse['full_name'] ?? 'User';

      if (_userType == 'Employer') {
        // Employer Data Fetching
        final jobsResponse = await supabase
            .from('jobs')
            .select('id, job_category, status')
            .eq('employer_id', _userId!);
        final jobs = jobsResponse.data as List<dynamic>;

        final applicationsResponse = await supabase
            .from('job_applications')
            .select('id, application_status, payment_status, jobs!inner(salary)')
            .eq('employer_id', _userId!);
        final applications = applicationsResponse.data as List<dynamic>;

        final disputesResponse = await supabase
            .from('disputes')
            .select('dispute_status')
            .filter('job_id', 'in', jobs.map((e) => e['id']).toList());
        final disputes = disputesResponse.data as List<dynamic>;

        final totalSpent = applications
            .where((app) => app['payment_status'] == 'completed')
            .fold<double>(0, (sum, item) => sum + (item['jobs']?['salary'] as num? ?? 0.0).toDouble());

        _analyticsData = {
          'jobs_posted': jobs.length,
          'jobs_by_status': _aggregateStatus(jobs, 'status'),
          'applications_received': applications.length,
          'applications_by_status': _aggregateStatus(applications, 'application_status'),
          'total_spent': totalSpent,
          'job_categories': _aggregateJobCategories(jobs),
          'disputes_by_status': _aggregateStatus(disputes, 'dispute_status'),
          'global_rating': userDataResponse['global_rating']?.toDouble() ?? 0.0, // Employer's own rating
        };
      } else if (_userType == 'Job Seeker') {
        // Job Seeker Data Fetching
        final applications = await supabase
            .from('job_applications')
            .select('id, application_status, payment_status, jobs!inner(job_category, salary)')
            .eq('worker_id', _userId!);

        final earnings = applications
            .where((app) => app['payment_status'] == 'completed')
            .fold<double>(0, (sum, item) => sum + (item['jobs']?['salary'] as num? ?? 0.0).toDouble());

        _analyticsData = {
          'jobs_applied': applications.length,
          'applications_by_status': _aggregateStatus(applications, 'application_status'),
          'jobs_completed': userDataResponse['job_completed'] ?? 0,
          'total_earnings': earnings,
          'application_success_rate': _calculateSuccessRate(applications),
          'job_categories': _aggregateJobCategories(applications),
          'global_rating': userDataResponse['global_rating']?.toDouble() ?? 0.0, // Job Seeker's own rating
        };
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, int> _aggregateJobCategories(List<dynamic> data) {
    final categories = <String, int>{};
    for (var item in data) {
      final category = item['job_category'] ?? item['jobs']?['job_category'] ?? 'Other';
      categories[category] = (categories[category] ?? 0) + 1;
    }
    return categories;
  }

  Map<String, int> _aggregateStatus(List<dynamic> data, String statusKey) {
    final statuses = <String, int>{};
    for (var item in data) {
      final status = item[statusKey] as String?;
      if (status != null) {
        statuses[status] = (statuses[status] ?? 0) + 1;
      }
    }
    return statuses;
  }

  double _calculateSuccessRate(List<dynamic> applications) {
    if (applications.isEmpty) return 0.0;
    final accepted = applications
        .where((app) => app['application_status'] == 'accepted')
        .length;
    return (accepted / applications.length * 100).toDouble();
  }

  void _navigateToScreen(String route) {
    Navigator.pushNamed(context, route);
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color gradientStart,
    required Color gradientEnd,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1), // Use theme color
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FaIcon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70), // Use theme text style
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), // Use theme text style
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> categories, String title) {
    final total = categories.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return const SizedBox.shrink();

    final List<PieChartSectionData> sections = [];
    final colors = [
      Theme.of(context).primaryColor,
      Theme.of(context).colorScheme.secondary,
      Colors.orange,
      Colors.lime,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];

    int i = 0;
    categories.forEach((category, count) {
      final double percentage = (count / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Text(
              category,
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
      i++;
    });

    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data, String title) {
    final List<BarChartGroupData> barGroups = [];
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
              toY: (value as num).toDouble(),
              color: barColors[index % barColors.length],
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });

    return FadeInUp(
      duration: const Duration(milliseconds: 1200),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              data.keys.elementAt(value.toInt()),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                          reservedSize: 20,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0), // Display as integer for simplicity, or adjust as needed
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
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
      drawer: SidebarMenu(
        navigateToScreen: _navigateToScreen,
        logout: _logout,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).colorScheme.surface], // Use theme colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'Welcome ${_userFullName ?? 'User'} to Your ${_userType == 'Employer' ? 'Employer' : 'Worker'} Dashboard',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Theme.of(context).primaryColor.withAlpha(77),
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_userType == 'Employer') ...[
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: [
                                  _buildStatCard(
                                    title: 'Jobs Posted',
                                    value: '${_analyticsData['jobs_posted'] ?? 0}',
                                    icon: FontAwesomeIcons.briefcase,
                                    gradientStart: Theme.of(context).primaryColor,
                                    gradientEnd: Theme.of(context).colorScheme.secondary,
                                  ),
                                  _buildStatCard(
                                    title: 'Applications Received',
                                    value: '${_analyticsData['applications_received'] ?? 0}',
                                    icon: FontAwesomeIcons.users,
                                    gradientStart: Theme.of(context).colorScheme.secondary,
                                    gradientEnd: Theme.of(context).primaryColor,
                                  ),
                                  _buildStatCard(
                                    title: 'Total Spent',
                                    value: '${(_analyticsData['total_spent'] ?? 0).toStringAsFixed(2)}',
                                    icon: FontAwesomeIcons.wallet,
                                    gradientStart: Colors.orange,
                                    gradientEnd: Colors.yellow,
                                  ),
                                  _buildStatCard(
                                    title: 'Disputes',
                                    value: '${(_analyticsData['disputes_by_status']?['pending'] ?? 0) + (_analyticsData['disputes_by_status']?['resolved'] ?? 0)}',
                                    icon: FontAwesomeIcons.gavel,
                                    gradientStart: Colors.red,
                                    gradientEnd: Colors.deepOrange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildPieChart(_analyticsData['job_categories'] ?? {}, 'Job Categories Distribution'),
                              const SizedBox(height: 20),
                              _buildBarChart(_analyticsData['jobs_by_status'] ?? {}, 'Job Status Overview'),
                              const SizedBox(height: 20),
                              _buildBarChart(_analyticsData['applications_by_status'] ?? {}, 'Application Status'),
                            ] else if (_userType == 'Job Seeker') ...[
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: [
                                  _buildStatCard(
                                    title: 'Jobs Applied',
                                    value: '${_analyticsData['jobs_applied'] ?? 0}',
                                    icon: FontAwesomeIcons.briefcase,
                                    gradientStart: Theme.of(context).primaryColor,
                                    gradientEnd: Theme.of(context).colorScheme.secondary,
                                  ),
                                  _buildStatCard(
                                    title: 'Jobs Completed',
                                    value: '${_analyticsData['jobs_completed'] ?? 0}',
                                    icon: FontAwesomeIcons.checkCircle,
                                    gradientStart: Theme.of(context).colorScheme.secondary,
                                    gradientEnd: Theme.of(context).primaryColor,
                                  ),
                                  _buildStatCard(
                                    title: 'Total Earnings',
                                    value: '${(_analyticsData['total_earnings'] ?? 0).toStringAsFixed(2)}',
                                    icon: FontAwesomeIcons.wallet,
                                    gradientStart: Colors.orange,
                                    gradientEnd: Colors.yellow,
                                  ),
                                  _buildStatCard(
                                    title: 'Success Rate',
                                    value: '${(_analyticsData['application_success_rate'] ?? 0).toStringAsFixed(1)}%',
                                    icon: FontAwesomeIcons.chartLine,
                                    gradientStart: Colors.blue,
                                    gradientEnd: Colors.cyan,
                                  ),
                                  _buildStatCard(
                                    title: 'Global Rating',
                                    value: '${(_analyticsData['global_rating'] ?? 0).toStringAsFixed(2)}',
                                    icon: FontAwesomeIcons.star,
                                    gradientStart: Colors.purple,
                                    gradientEnd: Colors.deepPurple,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildPieChart(_analyticsData['job_categories'] ?? {}, 'Job Categories Applied'),
                              const SizedBox(height: 20),
                              _buildBarChart(_analyticsData['applications_by_status'] ?? {}, 'Application Status'),
                              const SizedBox(height: 20),
                              _buildBarChart({'Total Earnings': (_analyticsData['total_earnings'] ?? 0).toInt()}, 'Total Earnings'),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              GlobalMenu(
                navigateToScreen: _navigateToScreen,
                logout: _logout,
                heroTag: 'dashboardGlobalMenuFab',
              ),
            ],
          ),
        ),
      ),
    );
  }
}