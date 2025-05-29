import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:project_ai_latest/api_services/model.dart';


class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  TextEditingController promptController = TextEditingController();
  static final String apiKey = 'APIKEy';
  final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

  final List<ModelMessage> prompt = [];

  Future<void> sendMessage() async {
    final message = promptController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      promptController.clear();
      prompt.add(ModelMessage(
          isPrompt: true, message: message, time: DateTime.now()));
    });

    final content = [
      Content.text(
          """You are a professional financial and food nutrition advisor AI. 
Your job is to help users make smart, budget-friendly decisions about their finances and food. 
When giving advice about food, always consider the user's financial situation. 
Give practical, simple, and summarized suggestions.

Examples:
- Recommend affordable yet nutritious meals.
- Suggest budget-friendly grocery shopping tips.
- Give simple financial or budgeting guidance when needed.
- Avoid expensive ingredients or complicated plans.

Now respond to the user query below in a friendly, practical, and helpful way.

User: $message"""
      )
    ];

    final response = await model.generateContent(content);

    setState(() {
      prompt.add(ModelMessage(
        isPrompt: false,
        message: response.text ?? "Sorry, I couldn't generate a response.",
        time: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color navy = const Color(0xFF1A1F36);
    final Color lightGrey = const Color(0xFFF1F3F6);

    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text(
          "ChatBot Advisor",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: prompt.length,
              itemBuilder: (context, index) {
                final message = prompt[index];
                return chatBubble(
                  isPrompt: message.isPrompt,
                  message: message.message,
                  time: DateFormat('hh:mm a').format(message.time),
                  navy: navy,
                );
              },
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promptController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Ask your financial question...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      filled: true,
                      fillColor: lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: navy,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget chatBubble({
    required bool isPrompt,
    required String message,
    required String time,
    required Color navy,
  }) {
    return Align(
      alignment: isPrompt ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 10,
          bottom: 4,
          left: isPrompt ? 50 : 10,
          right: isPrompt ? 10 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrompt ? Colors.white : navy,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isPrompt
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isPrompt
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isPrompt ? navy : Colors.white,
                fontSize: 16,
                fontWeight:
                isPrompt ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color:
                isPrompt ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
