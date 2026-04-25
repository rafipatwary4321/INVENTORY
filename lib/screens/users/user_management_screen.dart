import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: Text('Access denied')),
      );
    }

    if (!auth.isFirebaseEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Demo mode users',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
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
            Card(
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
      appBar: AppBar(title: const Text('Team management')),
      body: Column(
        children: [
          if (auth.isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                  return const Center(child: Text('No team members'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(u.displayName),
                        subtitle: Text('${u.email}\n${u.role.name} · ${u.isActive ? 'active' : 'inactive'}'),
                        isThreeLine: true,
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
