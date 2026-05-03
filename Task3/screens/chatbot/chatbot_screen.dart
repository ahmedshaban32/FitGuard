import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];

  Future<String> getBotResponse(String message) async {
  final response = await http.post(
      Uri.parse("http://192.168.1.2:5000/chat"), // IP جهازك على الشبكة
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );


    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    } else {
      return "Error: Could not reach bot";
    }
  }

  void _sendMessage() async {
    String userMessage = _controller.text;
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add("You: $userMessage");
      _controller.clear();
    });

    String botReply = await getBotResponse(userMessage);

    setState(() {
      _messages.add("Bot: $botReply");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Bot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
