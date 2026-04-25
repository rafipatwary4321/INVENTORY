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
    if (!canView) {
      return const Scaffold(
        appBar: PremiumAppBar(title: 'Team'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only owners and admins can open team management.',
        ),
      );
    }

    if (!auth.isFirebaseEnabled) {
      return Scaffold(
        appBar: const PremiumAppBar(
          title: 'Team',
          subtitle: 'Demo mode',
        ),
        body: ListView(
          padding: PremiumTokens.pagePadding(context),
          children: [
            Text(
              'Demo mode users',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ReportCard(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Demo Owner'),
                subtitle: const Text('Full access'),
                trailing: auth.appUser?.role == UserRole.owner
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => auth.setDemoRole(UserRole.owner),
              ),
            ),
            const SizedBox(height: 10),
            ReportCard(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Demo Staff'),
                subtitle: const Text('Scan/stock/sell only'),
                trailing: auth.appUser?.role == UserRole.staff
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => auth.setDemoRole(UserRole.staff),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Team management',
        subtitle: 'Roles & access',
      ),
      body: Column(
        children: [
          if (auth.isOwner)
            Padding(
              padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
              child: ReportCard(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
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
                        child: FilledButton(
                          onPressed: _busy ? null : _addMember,
                          child: const Text('Save member'),
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
                return ListView.builder(
                  padding: PremiumTokens.pagePadding(context),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReportCard(
                        child: ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(u.displayName),
                          subtitle: Text(
                            '${u.email}\n${u.isActive ? 'active' : 'inactive'}',
                          ),
                          isThreeLine: true,
                          trailing: Chip(
                            label: Text(u.role.name),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
