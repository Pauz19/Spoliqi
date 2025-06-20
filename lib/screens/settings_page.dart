import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? selectedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    selectedLanguage = locale.languageCode == 'en' ? 'English' : 'Tiếng Việt';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black87;
    final Color divider = Theme.of(context).dividerColor.withOpacity(0.15);

    selectedLanguage ??= context.locale.languageCode == 'en' ? 'English' : 'Tiếng Việt';

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: iconColor),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Thông tin tài khoản
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  backgroundColor: Colors.greenAccent,
                  child: user?.photoURL == null
                      ? Text(
                    (user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0].toUpperCase()
                        : 'U'),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                  )
                      : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "not_set".tr(),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: iconColor), // <-- phải là Icons.edit
                  onPressed: () async {
                    if (user == null) return;
                    final updated = await showDialog(
                      context: context,
                      builder: (_) => EditProfileDialog(
                        currentName: user.displayName,
                        currentPhotoUrl: user.photoURL,
                        currentEmail: user.email,
                      ),
                    );
                    if (updated == true) {
                      await FirebaseAuth.instance.currentUser?.reload();
                      if (context.mounted) Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(color: divider, thickness: 1),

          // Đổi mật khẩu
          ListTile(
            leading: Icon(Icons.lock_reset, color: iconColor),
            title: Text('settings.change_password'.tr(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            trailing: Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.3), size: 18),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              );
            },
          ),
          Divider(color: divider, thickness: 1),

          // Chế độ hiển thị (Dark/Light)
          SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: iconColor),
            title: Text('dark_mode'.tr(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            value: isDarkMode,
            onChanged: (val) {
              context.read<ThemeProvider>().toggleTheme(val);
            },
            activeColor: Colors.greenAccent,
          ),
          Divider(color: divider, thickness: 1),

          // Ngôn ngữ ứng dụng
          ListTile(
            leading: Icon(Icons.language, color: iconColor),
            title: Text('language'.tr(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text(selectedLanguage!, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54)),
            trailing: Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.3), size: 18),
            onTap: () async {
              final lang = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: Text("choose_language".tr()),
                  children: [
                    SimpleDialogOption(
                      child: const Text("Tiếng Việt"),
                      onPressed: () => Navigator.pop(context, "Tiếng Việt"),
                    ),
                    SimpleDialogOption(
                      child: const Text("English"),
                      onPressed: () => Navigator.pop(context, "English"),
                    ),
                  ],
                ),
              );
              if (lang != null) {
                setState(() => selectedLanguage = lang);
                if (lang == "English") {
                  await context.setLocale(const Locale('en'));
                } else {
                  await context.setLocale(const Locale('vi'));
                }
              }
            },
          ),
          Divider(color: divider, thickness: 1),

          // Đăng xuất
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text('logout'.tr(), style: const TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("logout".tr()),
                  content: Text("logout_confirm".tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("cancel".tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("logout".tr()),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          Divider(color: divider, thickness: 1),

          // Xem điều khoản/dịch vụ/hỗ trợ
          ListTile(
            leading: Icon(Icons.info_outline, color: iconColor),
            title: Text('terms_support'.tr(), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            trailing: Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.3), size: 18),
            onTap: () {
              // TODO: Show terms/support dialog or navigate to another page
            },
          ),
        ],
      ),
    );
  }
}