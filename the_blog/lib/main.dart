import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_blog/widgets/notification_overlay.dart';
import 'package:the_blog/services/crypto_service.dart';

void main() {
  runApp(const TheBlogApp());
}

class TheBlogApp extends StatefulWidget {
  const TheBlogApp({super.key});

  @override
  State<TheBlogApp> createState() => _TheBlogAppState();
}

class _TheBlogAppState extends State<TheBlogApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tHe_BlOg',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00C853), // Darker Green for light mode
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF00C853),
          selectionColor: const Color(0xFF00C853).withValues(alpha: 0.3),
          selectionHandleColor: const Color(0xFF00C853),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676), // Vibrant Green
          onPrimary: Colors.black,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF00E676),
          selectionColor: const Color(0xFF00E676).withValues(alpha: 0.3),
          selectionHandleColor: const Color(0xFF00E676),
        ),
      ),
      home: MarkdownEditorPage(
        onThemeChanged: _changeTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MarkdownEditorPage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const MarkdownEditorPage({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _markdownText = "Hey there user, what are we about to write today?";
  String? _apiKey;
  String? _apiUrl;
  bool _isValidating = false;
  bool _isCheckingSpelling = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller.text = _markdownText;
    _loadCredentials();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start fully visible
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final encKey = prefs.getString('api_key');
    final encUrl = prefs.getString('api_url');
    setState(() {
      try {
        _apiKey = encKey != null ? CryptoService.decryptText(encKey) : null;
      } catch (_) {
        _apiKey = encKey;
      }
      try {
        _apiUrl = encUrl != null ? CryptoService.decryptText(encUrl) : null;
      } catch (_) {
        _apiUrl = encUrl;
      }
    });
  }

  String _maskValue(String value) {
    if (value.length <= 8) return value;
    final first4 = value.substring(0, 4);
    final last4 = value.substring(value.length - 4);
    return '$first4........$last4';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Settings",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<ThemeMode>(
                groupValue: widget.currentThemeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) widget.onThemeChanged(value);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("Dark Theme"),
                      leading: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ListTile(
                      title: const Text("Light Theme"),
                      leading: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isPreviewVisible = true;

  void _togglePreview() {
    setState(() {
      _isPreviewVisible = !_isPreviewVisible;
      if (_isPreviewVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onPublish() {
    _showPublishDialog();
  }

  void _showPublishDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final TextEditingController slugController = TextEditingController();
        final TextEditingController titleController = TextEditingController();
        final TextEditingController excerptController = TextEditingController();
        final TextEditingController categoryController =
            TextEditingController();
        final TextEditingController readingTimeController =
            TextEditingController();
        bool isFeatured = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                "Publish Post",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField("Title", titleController, isDark),
                      const SizedBox(height: 12),
                      _buildTextField("Slug", slugController, isDark),
                      const SizedBox(height: 12),
                      _buildTextField("Category", categoryController, isDark),
                      const SizedBox(height: 12),
                      _buildTextField(
                        "Reading Time (e.g. 5 min read)",
                        readingTimeController,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField("Excerpt", excerptController, isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: isFeatured,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (val) =>
                                setDialogState(() => isFeatured = val ?? false),
                          ),
                          Text(
                            "Featured Post",
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final postData = {
                      "slug": slugController.text,
                      "title": titleController.text,
                      "excerpt": excerptController.text,
                      "content": _controller.text,
                      "category": categoryController.text,
                      "readingTime": readingTimeController.text,
                      "fatured": isFeatured,
                    };

                    Navigator.pop(context);
                    await _submitPost(postData);
                  },
                  child: Text(
                    "Publish",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPost(Map<String, dynamic> data) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      NotificationManager.show(
        context,
        "Error",
        "No API key set. Connect first.",
      );
      return;
    }

    if (_apiUrl == null || _apiUrl!.isEmpty) {
      NotificationManager.show(
        context,
        "Error",
        "No API URL set. Connect first.",
      );
      return;
    }

    NotificationManager.show(context, "Publishing", "Uploading your post...");

    try {
      final response = await http.post(
        Uri.parse('${_apiUrl!}/api/v1/upload/post'),
        headers: {"Content-Type": "application/json", "X-API-KEY": _apiKey!},
        body: jsonEncode(data),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        NotificationManager.show(
          context,
          "Success",
          "Your post has been published successfully.",
        );
      } else {
        NotificationManager.show(
          context,
          "Error",
          "Failed to publish: ${response.statusCode}",
        );
        debugPrint("API Error: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      NotificationManager.show(
        context,
        "Error",
        "Connection failed. Please check your network.",
      );
      debugPrint("Request Exception: $e");
    }
  }

  Future<void> _checkSpelling() async {
    if (_controller.text.trim().isEmpty) {
      NotificationManager.show(
        context,
        "Check",
        "Nothing to check. Start typing first.",
      );
      return;
    }

    if (_apiUrl == null || _apiUrl!.isEmpty) {
      NotificationManager.show(
        context,
        "Error",
        "No API URL set. Connect first.",
      );
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      NotificationManager.show(
        context,
        "Error",
        "No API key set. Connect first.",
      );
      return;
    }

    setState(() => _isCheckingSpelling = true);

    try {
      final response = await http
          .post(
            Uri.parse('${_apiUrl!}/api/v1/check/spelling'),
            headers: {
              "Content-Type": "application/json",
              "X-API-KEY": _apiKey!,
            },
            body: jsonEncode({"content": _controller.text}),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool changed = data['Changed'] ?? false;
        final String? correctedContent = data['Content'];

        if (changed && correctedContent != null) {
          _showSpellingDialog(correctedContent);
        } else {
          NotificationManager.show(
            context,
            "Spelling Check",
            "No spelling issues found.",
          );
        }
      } else {
        NotificationManager.show(
          context,
          "Error",
          "Spelling check failed: ${response.statusCode}",
        );
        debugPrint("Spelling API Error: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      NotificationManager.show(
        context,
        "Error",
        "Connection failed. Check if the spelling API is running.",
      );
      debugPrint("Spelling Check Exception: $e");
    } finally {
      if (mounted) setState(() => _isCheckingSpelling = false);
    }
  }

  void _showSpellingDialog(String correctedContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.spellcheck, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                "Spelling Corrections",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: SelectableText(
                correctedContent,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _controller.text = correctedContent;
                  _markdownText = correctedContent;
                });
                Navigator.pop(context);
                NotificationManager.show(
                  context,
                  "Done",
                  "Content replaced with corrections.",
                );
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text("Replace", style: GoogleFonts.outfit()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConnectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final TextEditingController urlController = TextEditingController(
          text: _apiUrl ?? '',
        );
        final TextEditingController keyController = TextEditingController(
          text: _apiKey ?? '',
        );
        final bool hasExistingUrl = _apiUrl != null && _apiUrl!.isNotEmpty;
        final bool hasExistingKey = _apiKey != null && _apiKey!.isNotEmpty;
        bool showUrl = !hasExistingUrl;
        bool showKey = !hasExistingKey;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bolt,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Connect",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // API URL field
                      if (hasExistingUrl && !showUrl)
                        _buildMaskedField(
                          "API",
                          _maskValue(_apiUrl!),
                          isDark,
                          onEdit: () => setDialogState(() => showUrl = true),
                        )
                      else
                        _buildTextField("API", urlController, isDark),
                      const SizedBox(height: 12),
                      // API Key field
                      if (hasExistingKey && !showKey)
                        _buildMaskedField(
                          "API Key",
                          _maskValue(_apiKey!),
                          isDark,
                          onEdit: () => setDialogState(() => showKey = true),
                        )
                      else
                        _buildTextField("API Key", keyController, isDark),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isValidating
                      ? null
                      : () async {
                          final newUrl = urlController.text.trim();
                          final newKey = keyController.text.trim();
                          final parentContext = this.context;

                          if (newUrl.isEmpty) {
                            Navigator.pop(context);
                            if (!mounted) return;
                            setState(() {
                              _apiUrl = null;
                              _apiKey = null;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('api_url');
                            await prefs.remove('api_key');
                            if (!parentContext.mounted) return;
                            NotificationManager.show(
                              parentContext,
                              "Disconnected",
                              "Credentials cleared.",
                            );
                            return;
                          }

                          setDialogState(() => _isValidating = true);

                          final result = await _validateApiUrl(newUrl);

                          if (!result['success']) {
                            setDialogState(() => _isValidating = false);
                            if (!context.mounted) return;
                            NotificationManager.show(
                              context,
                              "Invalid API",
                              result['message'],
                            );
                            return;
                          }

                          final validBaseUrl = result['baseUrl'] as String;
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (!mounted) return;
                          setState(() {
                            _apiUrl = validBaseUrl;
                            _apiKey = newKey.isNotEmpty ? newKey : null;
                          });

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            'api_url',
                            CryptoService.encryptText(validBaseUrl),
                          );
                          if (newKey.isNotEmpty) {
                            await prefs.setString(
                              'api_key',
                              CryptoService.encryptText(newKey),
                            );
                          } else {
                            await prefs.remove('api_key');
                          }

                          if (!parentContext.mounted) return;
                          NotificationManager.show(
                            parentContext,
                            "Connected",
                            "API validated and credentials saved.",
                          );
                        },
                  child: _isValidating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Text(
                          "Connect",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _validateApiUrl(String url) async {
    try {
      String processedUrl = url.trim();
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      final uri = Uri.parse(processedUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return {'success': false, 'message': 'Invalid URL format.'};
      }

      final pingUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: '/api/v1/ping',
      );
      final response = await http
          .get(pingUri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final baseUrl = uri.hasPort
            ? '${uri.scheme}://${uri.host}:${uri.port}'
            : '${uri.scheme}://${uri.host}';
        return {'success': true, 'baseUrl': baseUrl};
      } else {
        return {
          'success': false,
          'message': 'Server returned status ${response.statusCode}.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection failed. Check the URL.'};
    }
  }

  Widget _buildMaskedField(
    String label,
    String maskedValue,
    bool isDark, {
    required VoidCallback onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  maskedValue,
                  style: GoogleFonts.jetBrainsMono(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                onPressed: onEdit,
                tooltip: "Edit $label",
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyFormat(String prefix, String suffix) {
    if (_controller.selection.isValid) {
      final String text = _controller.text;
      final TextSelection selection = _controller.selection;

      final String newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix${text.substring(selection.start, selection.end)}$suffix',
      );

      final int newSelectionIndex = selection.start + prefix.length;
      final int newSelectionEnd = selection.end + prefix.length;

      setState(() {
        _markdownText = newText;
        _controller.value = TextEditingValue(
          text: newText,
          selection: selection.isCollapsed
              ? TextSelection.collapsed(offset: newSelectionIndex)
              : TextSelection(
                  baseOffset: newSelectionIndex,
                  extentOffset: newSelectionEnd,
                ),
        );
      });
    }
  }

  Widget _buildFormattingToolbar(bool isDark, Color primaryColor) {
    return Container(
      height: 48, // Slightly taller for better touch target
      margin: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ), // Match input padding
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildToolbarButton(Icons.format_bold, "**", "**", "Bold", isDark),
            _buildToolbarButton(
              Icons.format_italic,
              "_",
              "_",
              "Italic",
              isDark,
            ),
            _buildToolbarButton(
              Icons.format_strikethrough,
              "~",
              "~",
              "Strikethrough",
              isDark,
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            _buildToolbarButton(Icons.code, "`", "`", "Code", isDark),
            _buildToolbarButton(
              Icons.data_object,
              "```\n",
              "\n```",
              "Code Block",
              isDark,
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            _buildToolbarButton(Icons.link, "[", "](url)", "Link", isDark),
            _buildToolbarButton(Icons.image, "![", "](url)", "Image", isDark),
            _buildToolbarButton(
              Icons.format_list_bulleted,
              "- ",
              "",
              "List",
              isDark,
            ),
            _buildToolbarButton(Icons.format_quote, "> ", "", "Quote", isDark),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            _isCheckingSpelling
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _checkSpelling,
                    icon: Icon(Icons.spellcheck, size: 16, color: primaryColor),
                    label: Text(
                      "Check",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String prefix,
    String suffix,
    String tooltip,
    bool isDark,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: isDark ? Colors.white70 : Colors.black87,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => _applyFormat(prefix, suffix),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Toolbar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _showConnectDialog,
                        child: Text(
                          "Connect",
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _onPublish,
                        icon: Icon(
                          Icons.send,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        tooltip: "Publish",
                      ),
                      IconButton(
                        onPressed: _showSettingsDialog,
                        icon: Icon(
                          Icons.settings,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        tooltip: "Settings",
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121212).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                children: [
                                  // Left: Editor
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHeader(
                                          "INPUT",
                                          primaryColor,
                                          isDark,
                                          trailing: IconButton(
                                            icon: Icon(
                                              _isPreviewVisible
                                                  ? Icons.crop_free
                                                  : Icons.close_fullscreen,
                                              size: 18,
                                            ),
                                            color: primaryColor,
                                            onPressed: _togglePreview,
                                            tooltip: _isPreviewVisible
                                                ? "Maximize Editor"
                                                : "Show Preview",
                                          ),
                                        ),
                                        _buildFormattingToolbar(
                                          isDark,
                                          primaryColor,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0,
                                              vertical: 10.0,
                                            ),
                                            child: TextField(
                                              controller: _controller,
                                              onChanged: (value) {
                                                setState(() {
                                                  _markdownText = value;
                                                });
                                              },
                                              maxLines: null,
                                              expands: true,
                                              style: GoogleFonts.jetBrainsMono(
                                                color: isDark
                                                    ? const Color(0xFFEEEEEE)
                                                    : const Color(0xFF333333),
                                                fontSize: 15,
                                                height: 1.6,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: "Start typing...",
                                                hintStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.2,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.2,
                                                        ),
                                                ),
                                              ),
                                              cursorColor: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Animated Preview Section
                                  SizeTransition(
                                    sizeFactor: _slideAnimation,
                                    axis: Axis.horizontal,
                                    axisAlignment: 1.0, // Slide towards right
                                    child: SizedBox(
                                      width:
                                          constraints.maxWidth /
                                          2, // Fixed width to prevent squishing
                                      child: Row(
                                        children: [
                                          // Vertical Divider
                                          Container(
                                            width: 1,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                          ),

                                          // Right: Preview
                                          Expanded(
                                            child: Container(
                                              color: isDark
                                                  ? Colors.black.withValues(
                                                      alpha: 0.3,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: 0.4,
                                                    ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildHeader(
                                                    "PREVIEW",
                                                    primaryColor,
                                                    isDark,
                                                  ),
                                                  Expanded(
                                                    child: Markdown(
                                                      data: _markdownText,
                                                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                                        // Body text
                                                        p: GoogleFonts.inter(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFFCCCCCC,
                                                                )
                                                              : const Color(
                                                                  0xFF444444,
                                                                ),
                                                          fontSize: 16,
                                                          height: 1.6,
                                                        ),
                                                        // Headers (White in dark mode, Black in light)
                                                        h1: GoogleFonts.outfit(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 32,
                                                        ),
                                                        h2: GoogleFonts.outfit(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 24,
                                                        ),
                                                        h3: GoogleFonts.outfit(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        // Blockquote (Dark bg in dark mode, Light bg in light)
                                                        blockquote:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  Colors.grey,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                        blockquoteDecoration: BoxDecoration(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF1E1E1E,
                                                                )
                                                              : const Color(
                                                                  0xFFF0F0F0,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border(
                                                            left: BorderSide(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black,
                                                              width: 4,
                                                            ),
                                                          ),
                                                        ),
                                                        // Code (Dark bg in dark mode, Light bg in light)
                                                        code: GoogleFonts.jetBrainsMono(
                                                          backgroundColor:
                                                              isDark
                                                              ? const Color(
                                                                  0xFF1E1E1E,
                                                                )
                                                              : const Color(
                                                                  0xFFE0E0E0,
                                                                ),
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFFEEEEEE,
                                                                )
                                                              : const Color(
                                                                  0xFF333333,
                                                                ),
                                                        ),
                                                        codeblockDecoration: BoxDecoration(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF1E1E1E,
                                                                )
                                                              : const Color(
                                                                  0xFFF5F5F5,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: isDark
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      )
                                                                : Colors.black
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String title,
    Color primaryColor,
    bool isDark, {
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              color: primaryColor, // Green Header Text keeps accent
              fontSize: 12,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
