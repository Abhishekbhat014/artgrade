import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'user_tile.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = "";
  String _roleFilter = "all"; // all | student | admin
  String _statusFilter = "all"; // all | active | disabled

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // FILTER LOGIC
  // --------------------------------------------------
  bool _matchesFilter(Map<String, dynamic> data) {
    final firstName = (data['firstName'] ?? '').toString().toLowerCase();
    final lastName = (data['lastName'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    final role = (data['role'] ?? 'student').toString().toLowerCase();
    final isActive = data['active'] ?? true;

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!('$firstName $lastName'.contains(q)) && !email.contains(q)) {
        return false;
      }
    }

    // Role
    if (_roleFilter != "all" && role != _roleFilter) {
      return false;
    }

    // Status
    if (_statusFilter == "active" && !isActive) return false;
    if (_statusFilter == "disabled" && isActive) return false;

    return true;
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = "";
      _roleFilter = "all";
      _statusFilter = "all";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "User Management",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Reset Filters",
            onPressed: _resetFilters,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // --------------------------------------------------
          // SEARCH BAR
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: _SearchBox(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // --------------------------------------------------
          // FILTER CHIPS
          // --------------------------------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: "All Users",
                  isSelected: _roleFilter == "all" && _statusFilter == "all",
                  onTap: () => setState(() {
                    _roleFilter = "all";
                    _statusFilter = "all";
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Students",
                  isSelected: _roleFilter == "student",
                  onTap: () => setState(() => _roleFilter = "student"),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Admins",
                  isSelected: _roleFilter == "admin",
                  onTap: () => setState(() => _roleFilter = "admin"),
                ),
                const SizedBox(width: 12),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                _FilterChip(
                  label: "Active",
                  isSelected: _statusFilter == "active",
                  onTap: () => setState(() => _statusFilter = "active"),
                  isStatus: true,
                  statusColor: Colors.green,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Disabled",
                  isSelected: _statusFilter == "disabled",
                  onTap: () => setState(() => _statusFilter = "disabled"),
                  isStatus: true,
                  statusColor: Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --------------------------------------------------
          // USERS LIST
          // --------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(theme: theme);
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  return _matchesFilter(doc.data() as Map<String, dynamic>);
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    theme: theme,
                    showHint: _searchQuery.isNotEmpty || _roleFilter != "all",
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        "Found ${filtered.length} users",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return UserTile(
                            userId: doc.id,
                            firstName: data['firstName'] ?? '',
                            lastName: data['lastName'] ?? '',
                            email: data['email'] ?? '',
                            role: data['role'] ?? 'student',
                            active: data['active'] ?? true,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// SUB WIDGETS
// ==================================================

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search by name or email...",
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 22,
              color: Colors.grey.shade400,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final bool showHint;

  const _EmptyState({required this.theme, required this.showHint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No users found",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (showHint)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Try adjusting your filters",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeData theme;
  const _ErrorState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load users",
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isStatus;
  final Color statusColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isStatus = false,
    this.statusColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isStatus
                    ? statusColor.withOpacity(0.1)
                    : primary.withOpacity(0.1))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isStatus ? statusColor : primary)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isStatus ? statusColor : primary)
                : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
