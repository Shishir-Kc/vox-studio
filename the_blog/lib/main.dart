import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_blog/widgets/notification_overlay.dart';

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
          selectionColor: const Color(0xFF00C853).withOpacity(0.3),
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
          selectionColor: const Color(0xFF00E676).withOpacity(0.3),
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

class _MarkdownEditorPageState extends State<MarkdownEditorPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _markdownText = "Hey there user, what are we about to write today?";

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    _controller.text = _markdownText;
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

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'txt'],
        dialogTitle: 'THE BLOG',
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        setState(() {
          _markdownText = content;
          _controller.text = content;
          _currentFilePath = file.path;
        });
      }
    } catch (e) {
      // Ignore errors for now or show snackbar
      debugPrint("Error opening file: $e");
    }
  }

  Future<void> _saveFile() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'THE BLOG - Save As',
        fileName: 'post.mdx',
        type: FileType.custom,
        allowedExtensions: ['mdx'],
      );

      if (outputFile != null) {
        File file = File(outputFile);
        await file.writeAsString(_controller.text);
        
        setState(() {
          _currentFilePath = outputFile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to $outputFile')),
        );
      }
    } catch (e) {
      debugPrint("Error saving file: $e");
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Settings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Dark Theme"),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: widget.currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) widget.onThemeChanged(value);
                    Navigator.pop(context);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              ListTile(
                title: const Text("Light Theme"),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: widget.currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) widget.onThemeChanged(value);
                    Navigator.pop(context);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
    NotificationManager.show(
      context, 
      "Success", 
      "Your post has been published successfully."
    );
  }

  void _showConnectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        String connectionType = 'IPv4'; // Default
        final TextEditingController urlController = TextEditingController();
        final TextEditingController apiController = TextEditingController();
        final TextEditingController userController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  FaIcon(FontAwesomeIcons.bolt, color: isDark ? Colors.white : Colors.black, size: 20),
                  const SizedBox(width: 10),
                  Text("Connect to Supabase", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("Database URL", urlController, isDark),
                    const SizedBox(height: 16),
                    Text("Connection Type", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRadio("IPv4", connectionType, (val) => setState(() => connectionType = val!), isDark),
                        const SizedBox(width: 16),
                        _buildRadio("IPv6", connectionType, (val) => setState(() => connectionType = val!), isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("API", apiController, isDark),
                    const SizedBox(height: 16),
                    _buildTextField("Username", userController, isDark),
                  ],
                ),
              ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Use captured values: _urlController.text, connectionType, _apiController.text, _userController.text
                    NotificationManager.show(context, "Connecting", "Initiating Supabase connection...");
                  },
                  child: Text("Connect", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _applyFormat(String prefix, String suffix) {
    if (_controller.selection.isValid) {
      final String text = _controller.text;
      final TextSelection selection = _controller.selection;
      
      final String newText = text.replaceRange(
        selection.start, 
        selection.end, 
        '$prefix${text.substring(selection.start, selection.end)}$suffix'
      );
      
      final int newSelectionIndex = selection.start + prefix.length;
      final int newSelectionEnd = selection.end + prefix.length;
      
      setState(() {
        _markdownText = newText;
        _controller.value = TextEditingValue(
          text: newText,
          selection: selection.isCollapsed 
            ? TextSelection.collapsed(offset: newSelectionIndex)
            : TextSelection(baseOffset: newSelectionIndex, extentOffset: newSelectionEnd),
        );
      });
    }
  }

  Widget _buildFormattingToolbar(bool isDark, Color primaryColor) {
    return Container(
      height: 48, // Slightly taller for better touch target
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Match input padding
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
             _buildToolbarButton(Icons.format_bold, "**", "**", "Bold", isDark),
             _buildToolbarButton(Icons.format_italic, "_", "_", "Italic", isDark),
             _buildToolbarButton(Icons.format_strikethrough, "~", "~", "Strikethrough", isDark),
             Container(
               width: 1, 
               height: 20, 
               margin: const EdgeInsets.symmetric(horizontal: 8), 
               color: isDark ? Colors.grey[700] : Colors.grey[300]
             ),
             _buildToolbarButton(Icons.code, "`", "`", "Code", isDark),
             _buildToolbarButton(Icons.data_object, "```\n", "\n```", "Code Block", isDark),
             Container(
               width: 1, 
               height: 20, 
               margin: const EdgeInsets.symmetric(horizontal: 8), 
               color: isDark ? Colors.grey[700] : Colors.grey[300]
             ),
             _buildToolbarButton(Icons.link, "[", "](url)", "Link", isDark),
             _buildToolbarButton(Icons.format_list_bulleted, "- ", "", "List", isDark),
             _buildToolbarButton(Icons.format_quote, "> ", "", "Quote", isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String prefix, String suffix, String tooltip, bool isDark) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: isDark ? Colors.white70 : Colors.black87,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => _applyFormat(prefix, suffix),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRadio(String value, String groupValue, Function(String?) onChanged, bool isDark) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black)),
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
                    border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Text("File", style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            onTap: _openFile,
                            child: Row(
                              children: [
                                Icon(Icons.folder_open, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                                const SizedBox(width: 12),
                                Text("Open", style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'save',
                            onTap: _saveFile,
                            child: Row(
                              children: [
                                Icon(Icons.save_as, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                                const SizedBox(width: 12),
                                Text("Save as .mdx", style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {}, // Edit placeholder
                        child: Text("Edit", style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)),
                      ),
                      TextButton(
                        onPressed: () {}, // View placeholder
                        child: Text("View", style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)),
                      ),
                      TextButton(
                        onPressed: _showConnectDialog,
                        child: Text("Connect", style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _onPublish,
                        icon: Icon(Icons.send, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                        tooltip: "Publish",
                      ),
                      IconButton(
                        onPressed: _showSettingsDialog,
                        icon: Icon(Icons.settings, size: 20, color: isDark ? Colors.white70 : Colors.black87),
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
                                ? const Color(0xFF121212).withOpacity(0.6) 
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), 
                              width: 1.0
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ]
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                children: [
                                  // Left: Editor
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildHeader(
                                          "INPUT", 
                                          primaryColor, 
                                          isDark,
                                          trailing: IconButton(
                                            icon: Icon(_isPreviewVisible ? Icons.crop_free : Icons.close_fullscreen, size: 18),
                                            color: primaryColor,
                                            onPressed: _togglePreview,
                                            tooltip: _isPreviewVisible ? "Maximize Editor" : "Show Preview",
                                          )
                                        ),
                                        _buildFormattingToolbar(isDark, primaryColor),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
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
                                                color: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF333333),
                                                fontSize: 15,
                                                height: 1.6,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: "Start typing...",
                                                hintStyle: TextStyle(
                                                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)
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
                                      width: constraints.maxWidth / 2, // Fixed width to prevent squishing
                                      child: Row(
                                        children: [
                                          // Vertical Divider
                                          Container(
                                            width: 1,
                                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                          ),

                                          // Right: Preview
                                          Expanded(
                                            child: Container(
                                              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildHeader("PREVIEW", primaryColor, isDark),
                                                  Expanded(
                                                    child: Markdown(
                                                      data: _markdownText,
                                                      imageDirectory: _currentFilePath != null ? File(_currentFilePath!).parent.path : null,
                                                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                                        // Body text
                                                        p: GoogleFonts.inter(
                                                          color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444),
                                                          fontSize: 16, 
                                                          height: 1.6
                                                        ),
                                                        // Headers (White in dark mode, Black in light)
                                                        h1: GoogleFonts.outfit(
                                                          color: isDark ? Colors.white : Colors.black, 
                                                          fontWeight: FontWeight.bold, fontSize: 32
                                                        ),
                                                        h2: GoogleFonts.outfit(
                                                          color: isDark ? Colors.white : Colors.black, 
                                                          fontWeight: FontWeight.bold, fontSize: 24
                                                        ),
                                                        h3: GoogleFonts.outfit(
                                                          color: isDark ? Colors.white : Colors.black, 
                                                          fontWeight: FontWeight.bold
                                                        ),
                                                        // Blockquote (Dark bg in dark mode, Light bg in light)
                                                        blockquote: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
                                                        blockquoteDecoration: BoxDecoration(
                                                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border(left: BorderSide(color: isDark ? Colors.white : Colors.black, width: 4)),
                                                        ),
                                                        // Code (Dark bg in dark mode, Light bg in light)
                                                        code: GoogleFonts.jetBrainsMono(
                                                          backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0), 
                                                          color: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF333333)
                                                        ),
                                                        codeblockDecoration: BoxDecoration(
                                                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
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

  Widget _buildHeader(String title, Color primaryColor, bool isDark, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
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
