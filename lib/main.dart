import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TravelAIApp());
}

class TravelAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: TravelChatScreen(),
    );
  }
}

class TravelChatScreen extends StatefulWidget {
  @override
  _TravelChatScreenState createState() => _TravelChatScreenState();
}

class _TravelChatScreenState extends State<TravelChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': input});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final url = Uri.parse('https://travel-ai-mobile-backend.onrender.com/ask');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'messages': _messages}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add({'role': 'ai', 'content': data['reply']});
        });
      } else {
        final error = json.decode(response.body);
        _showSnackbar(error['error'] ?? 'Unexpected server error');
      }
    } catch (e) {
      _showSnackbar('Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
      await Future.delayed(Duration(milliseconds: 100));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message['content'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈️ Travel Planner AI'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about your trip...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}