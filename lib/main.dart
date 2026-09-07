import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/action_model.dart';
import 'services/text_parser_service.dart';

void main() {
  runApp(const QuickActionsApp());
}

class QuickActionsApp extends StatelessWidget {
  const QuickActionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.tealAccent,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickActions',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: colorScheme.copyWith(
          primary: Colors.tealAccent,
          onPrimary: Colors.black,
          surface: const Color(0xFF101010),
          surfaceContainerHighest: const Color(0xFF1A1A1A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF292929)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
        ),
      ),
      home: const QuickActionsHomePage(),
    );
  }
}

class QuickActionsHomePage extends StatefulWidget {
  const QuickActionsHomePage({super.key});

  @override
  State<QuickActionsHomePage> createState() => _QuickActionsHomePageState();
}

class _QuickActionsHomePageState extends State<QuickActionsHomePage> {
  static const _historyKey = 'quick_actions_history';

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _history = <String>[];
  List<SmartAction> _actions = const <SmartAction>[];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_handleTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {
      _actions = TextParserService.getActionsForText(_textController.text);
    });
  }

  Future<void> _loadHistory() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedItems = preferences.getStringList(_historyKey) ?? <String>[];
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(savedItems.take(3));
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _rememberInput() async {
    final value = _textController.text.trim();
    if (value.isEmpty) return;

    _history
      ..remove(value)
      ..insert(0, value);
    if (_history.length > 3) _history.removeLast();
    if (mounted) setState(() {});

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_historyKey, _history);
    } catch (_) {
      // The in-memory history remains available if storage is unavailable.
    }
  }

  Future<void> _runAction(SmartAction action) async {
    await _rememberInput();
    await action.onTapCallback();
    if (!mounted) return;
    if (action.title == 'Copy to Clipboard') {
      _showMessage('Copied to clipboard');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearInput() {
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _restoreHistory(String value) {
    _textController
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _focusNode.requestFocus();
  }

  IconData _iconForName(String iconName) {
    const icons = <String, IconData>{
      'open_in_new': Icons.open_in_new,
      'map_outlined': Icons.map_outlined,
      'phone_outlined': Icons.phone_outlined,
      'chat_outlined': Icons.chat_outlined,
      'local_shipping_outlined': Icons.local_shipping_outlined,
      'search': Icons.search,
      'copy_outlined': Icons.copy_outlined,
      'share_outlined': Icons.share_outlined,
    };
    return icons[iconName] ?? Icons.bolt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'QuickActions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 720 ? 680.0 : double.infinity;
            return Center(
              child: SizedBox(
                width: contentWidth,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      minLines: 4,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Paste text, a link, address, phone number...',
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                        suffixIcon: _textController.text.isEmpty
                            ? null
                            : TextButton(
                                onPressed: _clearInput,
                                child: const Text('Clear'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_actions.isNotEmpty) ...[
                      const Text(
                        'Suggested Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ..._actions.map(_buildActionCard),
                    ] else
                      const _EmptyState(),
                    const SizedBox(height: 28),
                    _buildHistory(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(SmartAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: const Color(0xFF111111),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF292929)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _runAction(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(_iconForName(action.iconName), color: Colors.tealAccent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_isLoadingHistory)
          const LinearProgressIndicator(minHeight: 2)
        else if (_history.isEmpty)
          const Text('Processed text will appear here.', style: TextStyle(color: Colors.white54))
        else
          ..._history.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history, color: Colors.white54),
              title: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _restoreHistory(item),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 34, color: Colors.white38),
          SizedBox(height: 10),
          Text('Paste something to see useful actions.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}