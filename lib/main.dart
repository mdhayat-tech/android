import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/action_model.dart';
import 'services/text_parser_service.dart';

void main() {
  runApp(const QuickActionsApp());
}

class QuickActionsApp extends StatelessWidget {
  const QuickActionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickActions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF121212),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SmartAction> _detectedActions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _detectedActions = TextParserService.getActionsForText(_controller.text);
    });
  }

  Future<void> _handleActionClick(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch action link: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching action: $e')),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'link': return Icons.link;
      case 'phone': return Icons.phone;
      case 'message': return Icons.message;
      case 'map': return Icons.map;
      case 'local_shipping': return Icons.local_shipping;
      case 'translate': return Icons.translate;
      default: return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickActions Multi-Tool', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste links, phone numbers, addresses, tracking numbers, or notes here...',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _controller.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _controller.text.isEmpty ? 'Waiting for text...' : 'Suggested Actions',
                style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _detectedActions.isEmpty
                  ? const Center(
                      child: Text(
                        'Pasted content will instantly trigger shortcuts.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _detectedActions.length,
                      itemBuilder: (context, index) {
                        final action = _detectedActions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(_getIconData(action.iconName), color: Colors.white),
                            title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(action.actionUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              // Safely call custom script execution logic
                              if (action.onTapCallback != null) {
                                action.onTapCallback!.call();
                              } else {
                                _handleActionClick(action.actionUrl);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
