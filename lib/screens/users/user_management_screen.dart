import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  UserRole _role = UserRole.staff;
  bool _active = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isOwner) return;
    if (_email.text.trim().isEmpty || _name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final uid = _email.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      await context.read<UserService>().upsertTeamMember(
            businessId: auth.businessId,
            uid: uid,
            email: _email.text.trim(),
            displayName: _name.text.trim(),
            role: _role,
            isActive: _active,
          );
      _email.clear();
      _name.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team member saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canView = auth.isOwner || auth.isAdmin;
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    if (!canView) {
      return const Scaffold(
        appBar: NeonAppBar(title: 'Team'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only owners and admins can open team management.',
        ),
      );
    }

    if (!auth.isFirebaseEnabled) {
      return Scaffold(
        appBar: const NeonAppBar(
          title: 'Team',
          subtitle: 'Demo mode',
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0F1A), Color(0xFF101B32), Color(0xFF162643)],
            ),
          ),
          child: ListView(
            padding: PremiumTokens.pagePadding(context),
            children: [
              const NeonGlassCard(
                child: ListTile(
                  leading: Icon(Icons.groups_2_outlined),
                  title: Text('User Management'),
                  subtitle: Text('Switch demo roles to preview permission differences.'),
                ),
              ),
              const SizedBox(height: 8),
              const _PermissionGuideCard(),
              const SizedBox(height: 12),
              NeonGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Demo Owner'),
                  subtitle: const Text('Full access'),
                  trailing: _RoleSelectionTrailing(
                    role: UserRole.owner,
                    selected: auth.appUser?.role == UserRole.owner,
                  ),
                  onTap: () => auth.setDemoRole(UserRole.owner),
                ),
              ),
              const SizedBox(height: 10),
              NeonGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Demo Admin'),
                  subtitle: const Text('Business operation access'),
                  trailing: _RoleSelectionTrailing(
                    role: UserRole.admin,
                    selected: auth.appUser?.role == UserRole.admin,
                  ),
                  onTap: () => auth.setDemoRole(UserRole.admin),
                ),
              ),
              const SizedBox(height: 10),
              NeonGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Demo Staff'),
                  subtitle: const Text('Scan/stock/sell only'),
                  trailing: _RoleSelectionTrailing(
                    role: UserRole.staff,
                    selected: auth.appUser?.role == UserRole.staff,
                  ),
                  onTap: () => auth.setDemoRole(UserRole.staff),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const NeonAppBar(
        title: 'Team management',
        subtitle: 'Roles & access',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F1A), Color(0xFF101B32), Color(0xFF162643)],
          ),
        ),
        child: Column(
          children: [
          Padding(
            padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
            child: const NeonGlassCard(
              child: ListTile(
                leading: Icon(Icons.groups_rounded),
                title: Text('Business Team'),
                subtitle: Text('Manage members, roles, and access permissions.'),
              ),
            ),
          ),
          Padding(
            padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
            child: const _PermissionGuideCard(),
          ),
          if (auth.isOwner)
            Padding(
              padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
              child: NeonGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person_add_alt_rounded),
                        title: Text('Invite / save member'),
                        subtitle: Text('Owners can assign Admin or Staff access.'),
                      ),
                      NeonTextField(
                        controller: _name,
                        label: 'Display name',
                      ),
                      const SizedBox(height: 8),
                      NeonTextField(
                        controller: _email,
                        label: 'Email',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<UserRole>(
                              initialValue: _role,
                              decoration: const InputDecoration(labelText: 'Role'),
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.admin,
                                  child: Text('Admin'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.staff,
                                  child: Text('Staff'),
                                ),
                              ],
                              onChanged: (v) => setState(() {
                                _role = v ?? UserRole.staff;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SwitchListTile(
                              value: _active,
                              onChanged: (v) => setState(() => _active = v),
                              title: const Text('Active'),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: NeonButton(
                          onPressed: _busy ? null : _addMember,
                          icon: Icons.save_outlined,
                          label: _busy ? 'Saving...' : 'Save member',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: context.read<UserService>().teamStream(auth.businessId),
              builder: (context, snap) {
                final users = snap.data ?? const <AppUser>[];
                if (users.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.group_outlined,
                    title: 'No team members',
                    subtitle: 'Invite people from Firebase Auth or add demo roles above.',
                  );
                }
                if (!isWide) {
                  return ListView.builder(
                    padding: PremiumTokens.pagePadding(context),
                    itemCount: users.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserTeamCard(user: users[i]),
                    ),
                  );
                }
                return GridView.builder(
                  padding: PremiumTokens.pagePadding(context),
                  itemCount: users.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (_, i) => _UserTeamCard(user: users[i]),
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _UserTeamCard extends StatelessWidget {
  const _UserTeamCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 22,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            user.role == UserRole.owner
                ? Icons.workspace_premium_outlined
                : user.role == UserRole.admin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.badge_outlined,
          ),
        ),
        title: Text(user.displayName),
        subtitle: Text(
          '${user.email}\n${user.isActive ? 'active' : 'inactive'}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RolePill(role: user.role),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: user.isActive ? Colors.greenAccent : const Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (role) {
      UserRole.owner => ('Owner', const Color(0xFFA855F7), Icons.workspace_premium_rounded),
      UserRole.admin => ('Admin', const Color(0xFF22D3EE), Icons.admin_panel_settings_rounded),
      UserRole.staff => ('Staff', const Color(0xFF3B82F6), Icons.badge_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelectionTrailing extends StatelessWidget {
  const _RoleSelectionTrailing({
    required this.role,
    required this.selected,
  });

  final UserRole role;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _RolePill(role: role),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            ),
        ],
      ),
    );
  }
}

class _PermissionGuideCard extends StatelessWidget {
  const _PermissionGuideCard();

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_person_outlined),
            title: Text('Role permissions'),
            subtitle: Text('Owner: full control • Admin: operations + reports • Staff: sell/stock only'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Permission explanation'),
            subtitle: Text('Staff cannot change business settings or manage team members.'),
          ),
        ],
      ),
    );
  }
}
