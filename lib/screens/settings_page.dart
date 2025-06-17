import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLanguage = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black87;
    final Color divider = Theme.of(context).dividerColor.withOpacity(0.15);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
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
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
                  )
                      : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Chưa đặt tên",
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
                  icon: Icon(Icons.edit, color: iconColor),
                  onPressed: () {
                    // TODO: Show edit profile dialog
                  },
                ),
              ],
            ),
          ),
          Divider(color: divider, thickness: 1),

          // Đổi mật khẩu
          ListTile(
            leading: Icon(Icons.lock_reset, color: iconColor),
            title: Text('Đổi mật khẩu', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            trailing: Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.3), size: 18),
            onTap: () {
              // TODO: Show change password dialog
            },
          ),
          Divider(color: divider, thickness: 1),

          // Chế độ hiển thị
          SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: iconColor),
            title: Text('Chế độ tối', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
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
            title: Text('Ngôn ngữ', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text(selectedLanguage, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54)),
            trailing: Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.3), size: 18),
            onTap: () async {
              final lang = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: const Text("Chọn ngôn ngữ"),
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
                // TODO: Cập nhật ngôn ngữ toàn app
              }
            },
          ),
          Divider(color: divider, thickness: 1),

          // Đăng xuất
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Đăng xuất"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Hủy"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Đăng xuất"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          Divider(color: divider, thickness: 1),

          // Xem điều khoản/dịch vụ/hỗ trợ
          ListTile(
            leading: Icon(Icons.info_outline, color: iconColor),
            title: Text('Điều khoản, dịch vụ & hỗ trợ', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
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