import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:project_ai_latest/api_services/model.dart';

class GeminiTestpage extends StatefulWidget {
  const GeminiTestpage({super.key});

  @override
  State<GeminiTestpage> createState() => _GeminiTestpageState();
}

class _GeminiTestpageState extends State<GeminiTestpage> {
  TextEditingController promptController = TextEditingController();
  static const apiKey = "AIzaSyBgubhmPpzKlhrowOk3ocBT6HoPe8RdmNI";
  final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

  final List<ModelMessage> prompt = [];

  Future<void> sendMessage() async {
    final message = promptController.text;
    // for prompt
    setState(() {
      promptController.clear();
      prompt.add(ModelMessage(isPrompt: true, message: message, time: DateTime.now(),
      ),
      );
    });
    //for respond
    final content = [Content.text(message)];
    final response = await model.generateContent(content);
    setState(() {
      prompt.add(ModelMessage(isPrompt: false, message: response.text??"", time: DateTime.now(),
      ),
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.blue[100],
        title: Center(child: Text("AI ChatBot"),
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                itemCount: prompt.length,
                  itemBuilder: (context,index) {
                  final message = prompt[index];
                  return userPrompt(isPrompt: message.isPrompt, message: message.message, date: DateFormat('hh:mm a').format(message.time));
          })),
          Padding(
              padding: EdgeInsets.all(25),
              child: Row(
                children: [
                  Expanded(
                    flex: 20,
                      child: TextField(
                        controller: promptController,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                          ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)
                          ),
                          hintText: "Enter a prompt here!"
                        )
                      ),
                  ),
                  const Spacer(),
                  GestureDetector(onTap: () {
                      sendMessage();
                  },
                    child: const CircleAvatar(
                      radius: 29,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                ],
              ) ,
          )
        ],
      ),
    );
  }
  Container userPrompt({required final bool isPrompt, required String message, required String date}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 15).copyWith(left: isPrompt ?80:15, right: isPrompt?15:80,),
      decoration: BoxDecoration(
        color: isPrompt ? Colors.green:Colors.grey,
        borderRadius : BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isPrompt ? const Radius.circular(20):Radius.zero,
            bottomRight: isPrompt ? Radius.zero:const Radius.circular(20)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // for prompt and respond
          Text(
            message,
            style: TextStyle(
              fontWeight: isPrompt ?
              FontWeight.bold: FontWeight.normal,
              fontSize: 18,
              color: isPrompt ?
              Colors.white:Colors.black,
          ),
          ),
          //for prompt and respond time
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              color: isPrompt ? Colors.white:Colors.black,
          ),
          )
        ],
      ),
    );
  }
}


