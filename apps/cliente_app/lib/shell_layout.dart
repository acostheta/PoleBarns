import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShellLayout extends ConsumerWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    // We can fetch profile to check role.
    // Ideally, we subscribe or fetch once. For now, let's watch the userProfileProvider

    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : const AsyncValue.loading();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Gilbert'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: profileAsync.asData?.value?['picture'] !=
                            null
                        ? NetworkImage(profileAsync.asData!.value!['picture'])
                        : null,
                    child: profileAsync.asData?.value?['picture'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileAsync.asData?.value?['name'] ?? 'Usuario',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () => context.go('/profile'),
            ),
            // Admin only
            if (profileAsync.asData?.value?['role'] == 'Administrador' ||
                profileAsync.asData?.value?['role'] == 'Admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Usuarios'),
                onTap: () => context.go('/users'),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                // Router handles redirect
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
