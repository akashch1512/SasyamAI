import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/app_logo.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../auth/login_screen.dart';
import '../../profile/profile_screen.dart';
import '../../settings/settings_screen.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chat = Provider.of<ChatProvider>(context);
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: AppTheme.backgroundWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(size: 32, fontSize: 18),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  chat.startNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_rounded, color: AppTheme.primaryGreen, size: 20),
                label: const Text(
                  'New Conversation',
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: const BorderSide(color: AppTheme.borderGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.surfaceWhite,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const Divider(color: AppTheme.borderGrey, height: 16),

            // Chat History Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Inquiries',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: chat.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No previous chats yet',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chat.sessions.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        final session = chat.sessions[index];
                        final isSelected = chat.activeSessionId == session.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.paleGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textMuted),
                              onPressed: () {
                                chat.deleteSession(session.id);
                              },
                            ),
                            onTap: () {
                              chat.selectSession(session.id);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),

            const Divider(color: AppTheme.borderGrey, height: 1),

            // Admin Panel Navigation (Available for admin or toggle switch)
            if (user?.isAdmin ?? false) ...[
              ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.paleGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryGreen, size: 18),
                ),
                title: const Text(
                  'Admin Analytics Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryGreen),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryGreen),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
              ),
              const Divider(color: AppTheme.borderGrey, height: 1),
            ],

            // User Profile Section
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.paleGreen,
                backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                child: user?.profileImageUrl == null
                    ? const Icon(Icons.person, size: 18, color: AppTheme.primaryGreen)
                    : null,
              ),
              title: Text(
                user?.fullName ?? 'Farmer',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textDark),
              ),
              subtitle: Text(
                '${user?.state ?? 'India'} • ${user?.landSizeAcres?.toStringAsFixed(1) ?? '5.0'} Acres',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),

            // Settings & Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined, size: 16, color: AppTheme.textMuted),
                    label: const Text('Settings', style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.errorRed),
                    label: const Text('Sign Out', style: TextStyle(fontSize: 12.5, color: AppTheme.errorRed)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
