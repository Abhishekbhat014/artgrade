import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Real-time overview",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
                // ✅ Added bottom padding for Floating Navbar
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOP STATS ROW
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewCard(
                            label: "Total Students",
                            value: totalStudents.toString(),
                            asset: AppIcons.user_group,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _OverviewCard(
                            label: "Active Courses",
                            value: activeCourses.toString(),
                            asset: AppIcons.book,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Trend Indicator
                    _TrendHint(
                      label: "students joined",
                      diff: studentTrend,
                      color: studentTrend >= 0
                          ? Colors.green
                          : Colors.redAccent,
                    ),

                    const SizedBox(height: 32),

                    // 2. STUDENT ACTIVITY CHART
                    const _SectionHeader(title: "Student Activity"),
                    const SizedBox(height: 16),

                    _CardContainer(
                      child: Row(
                        children: [
                          // Donut Chart
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: _UsersDonutChart(
                              active: activeStudents,
                              disabled: disabledStudents,
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Legend
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ChartLegend(
                                  color: Colors.green,
                                  label: "Active Accounts",
                                  value: activeStudents.toString(),
                                ),
                                const SizedBox(height: 12),
                                _ChartLegend(
                                  color: Colors.redAccent,
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

                    // 3. MINI STATS ROW
                    _CardContainer(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                            label: "New (7d)",
                            value: newThisWeek.toString(),
                            color: Colors.blueAccent,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: cs.outlineVariant.withOpacity(0.5),
                          ),
                          _MiniStat(
                            label: "Active Today",
                            value: activeStudents.toString(),
                            color: Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: cs.outlineVariant.withOpacity(0.5),
                          ),
                          _MiniStat(
                            label: "Total Courses",
                            value: courses.length.toString(),
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 4. COURSE STATUS BAR CHART
                    const _SectionHeader(title: "Course Status"),
                    const SizedBox(height: 16),

                    _CardContainer(
                      height: 280,
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      child: _CoursesBarChart(
                        active: activeCourses,
                        inactive: inactiveCourses,
                        theme: theme,
                      ),
                    ),

                    const SizedBox(height: 40),
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

/* =======================================================
   UI HELPERS (M3 COMPLIANT)
======================================================= */

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    );
  }
}

// ✅ UPDATED: Replaced custom Container with Standard M3 Card
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
    // Card widget automatically handles shadows (light) and surface tint (dark)
    return SizedBox(
      height: height,
      child: Card(
        elevation: 2, // Standard M3 Elevation
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final String asset;
  final Color color;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.asset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Uses the new M3 Card Container
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppSvgIcon(asset: asset, size: 24, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Row(
      children: [
        AppSvgIcon(
          asset: diff > 0 ? AppIcons.trend_up : AppIcons.trend_down,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          "${diff > 0 ? '+' : ''}$diff $label this week",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final cs = Theme.of(context).colorScheme;
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
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* =======================================================
   CHARTS (LOGIC UNCHANGED)
======================================================= */

class _UsersDonutChart extends StatelessWidget {
  final int active;
  final int disabled;

  const _UsersDonutChart({required this.active, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final total = active + disabled;
    final cs = Theme.of(context).colorScheme;

    if (total == 0) {
      return PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: cs.outlineVariant.withOpacity(0.3),
              value: 1,
              radius: 15,
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
            sectionsSpace: 4,
            sections: [
              PieChartSectionData(
                value: active.toDouble(),
                color: Colors.green,
                radius: 15,
                showTitle: false,
              ),
              PieChartSectionData(
                value: disabled.toDouble(),
                color: Colors.redAccent,
                radius: 15,
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              "Total",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.5),
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
    final cs = theme.colorScheme;
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
                  space: 8,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
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
              FlLine(color: cs.outlineVariant.withOpacity(0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: active.toDouble(),
                width: 48,
                color: Colors.orange,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMaxY,
                  color: cs.outlineVariant.withOpacity(0.1),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: inactive.toDouble(),
                width: 48,
                color: cs.outline,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMaxY,
                  color: cs.outlineVariant.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
