import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hugeicons/hugeicons.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final prevWeek = now.subtract(const Duration(days: 14));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3142),
              ),
            ),
            Text(
              "Real-time overview",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, usersSnap) {
          if (!usersSnap.hasData) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final users = usersSnap.data!.docs;

          final totalStudents = users.length;
          final disabledStudents = users
              .where((u) => u['active'] == false)
              .length;
          final activeStudents = totalStudents - disabledStudents;

          final newThisWeek = users.where((u) {
            final ts = (u['createdAt'] as Timestamp?)?.toDate();
            return ts != null && ts.isAfter(lastWeek);
          }).length;

          final newPrevWeek = users.where((u) {
            final ts = (u['createdAt'] as Timestamp?)?.toDate();
            return ts != null && ts.isAfter(prevWeek) && ts.isBefore(lastWeek);
          }).length;

          final studentTrend = newThisWeek - newPrevWeek;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('courses')
                .snapshots(),
            builder: (context, courseSnap) {
              if (!courseSnap.hasData) return const SizedBox();

              final courses = courseSnap.data!.docs;
              final activeCourses = courses
                  .where((c) => c['active'] == true)
                  .length;
              final inactiveCourses = courses
                  .where((c) => c['active'] == false)
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =============================
                    // OVERVIEW
                    // =============================
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewCard(
                            label: "Total Students",
                            value: totalStudents.toString(),
                            icon: HugeIcons.strokeRoundedUserGroup,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _OverviewCard(
                            label: "Active Courses",
                            value: activeCourses.toString(),
                            icon: HugeIcons.strokeRoundedBookOpen01,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _TrendHint(
                      label: "students joined",
                      diff: studentTrend,
                      color: studentTrend >= 0
                          ? const Color(0xFF00C853)
                          : const Color(0xFFFF5252),
                    ),

                    const SizedBox(height: 24),

                    // =============================
                    // STUDENT ACTIVITY
                    // =============================
                    const _SectionHeader(title: "Student Activity"),
                    const SizedBox(height: 12),

                    _CardContainer(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: _UsersDonutChart(
                              active: activeStudents,
                              disabled: disabledStudents,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ChartLegend(
                                  color: const Color(0xFF00C853),
                                  label: "Active Accounts",
                                  value: activeStudents.toString(),
                                ),
                                const SizedBox(height: 12),
                                _ChartLegend(
                                  color: const Color(0xFFFF5252),
                                  label: "Disabled Accounts",
                                  value: disabledStudents.toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _CardContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                            label: "New (7d)",
                            value: newThisWeek.toString(),
                            color: cs.primary,
                          ),
                          _MiniStat(
                            label: "Active Today",
                            value: activeStudents.toString(),
                            color: const Color(0xFF00C853),
                          ),
                          _MiniStat(
                            label: "Courses",
                            value: courses.length.toString(),
                            color: Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =============================
                    // COURSE STATUS
                    // =============================
                    const _SectionHeader(title: "Course Status"),
                    const SizedBox(height: 12),

                    _CardContainer(
                      height: 250,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                      child: _CoursesBarChart(
                        active: activeCourses,
                        inactive: inactiveCourses,
                        theme: theme,
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* =========================================================
   SMALL ADDITIONS
========================================================= */

class _TrendHint extends StatelessWidget {
  final String label;
  final int diff;
  final Color color;

  const _TrendHint({
    required this.label,
    required this.diff,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (diff == 0) return const SizedBox.shrink();

    final isUp = diff > 0;

    return Row(
      children: [
        Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          "${isUp ? '+' : ''}$diff $label this week",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/* =========================================================
   EXISTING HELPERS (UNCHANGED)
========================================================= */

// _OverviewCard
// _SectionHeader
// _CardContainer
// _ChartLegend
// _UsersDonutChart
// _CoursesBarChart

// ⛔ intentionally not duplicated here to avoid noise
// ⛔ keep your existing implementations exactly as-is

// ===================================================================
// SHARED UI HELPERS (NO VISUAL CHANGE)
// ===================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  const _CardContainer({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final Color color;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, size: 24, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===================================================================
// CHARTS (UNCHANGED VISUALLY)
// ===================================================================

class _UsersDonutChart extends StatelessWidget {
  final int active;
  final int disabled;

  const _UsersDonutChart({required this.active, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final total = active + disabled;

    if (total == 0) {
      return PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.grey.shade200,
              value: 1,
              radius: 20,
              showTitle: false,
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: -90,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: active.toDouble(),
                color: const Color(0xFF00C853),
                radius: 20,
                showTitle: false,
              ),
              PieChartSectionData(
                value: disabled.toDouble(),
                color: const Color(0xFFFF5252),
                radius: 18,
                showTitle: false,
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              total.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Text(
              "Total",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoursesBarChart extends StatelessWidget {
  final int active;
  final int inactive;
  final ThemeData theme;

  const _CoursesBarChart({
    required this.active,
    required this.inactive,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = ((active > inactive ? active : inactive) * 1.2).toDouble();
    final safeMaxY = maxY == 0 ? 5.0 : maxY;

    return BarChart(
      BarChartData(
        maxY: safeMaxY,
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final text = value.toInt() == 0 ? 'Active' : 'Inactive';
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMaxY / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: active.toDouble(),
                width: 40,
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: inactive.toDouble(),
                width: 40,
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
