import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:project_ai_latest/screens/recommendation_page.dart';
import 'chatbot_page.dart';


class InputPage extends StatefulWidget {
  const InputPage({Key? key}) : super(key: key);

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Offset _chatbotOffset = const Offset(300, 500); // Initial position
  bool _showChatDialog = false;
  Timer? _dialogTimer;

  final String _sessionToken = const Uuid().v4();
  static final String _apiKey = 'API';

  List<dynamic> _placeList = [];

  double? _selectedLat;
  double? _selectedLng;

  void _resetFields() {
    _budgetController.clear();
    _daysController.clear();
    _locationController.clear();
    setState(() {
      _placeList.clear();
      _selectedLat = null;
      _selectedLng = null;
    });
  }

  void _onLocationChanged(String input) async {
    if (input.isEmpty) {
      setState(() => _placeList.clear());
      return;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=$_sessionToken";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _placeList = data['predictions']);
      }
    } catch (e) {
      print("Error fetching autocomplete: $e");
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];
        setState(() {
          _selectedLat = location['lat'];
          _selectedLng = location['lng'];
        });
      }
    } catch (e) {
      print("Error fetching place details: $e");
    }
  }

  void _goToRecommendation() {
    final budget = double.tryParse(_budgetController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 1;

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid location from the suggestions.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationPage(
          budget: budget,
          days: days,
          latitude: _selectedLat!,
          longitude: _selectedLng!,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _chatbotButton() {
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Color(0xFF1A1F36),
      child: Icon(Icons.chat, color: Colors.black, size: 30),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _daysController.dispose();
    _locationController.dispose();
    super.dispose();
    _dialogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color navyBlue = const Color(0xFF1A1F36);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyBlue,
        centerTitle: true,
        title: const Text(
          'Bite Budget',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: navyBlue,
                  child: const Padding(
                    padding: EdgeInsets.all(50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Your Meals and Groceries Budget with AI!',
                          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enter your details below:',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  label: 'Total Budget (RM)',
                  hint: 'Enter amount',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildTextField(
                  label: 'Number of Days',
                  hint: 'Enter days',
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildTextField(
                  label: 'Enter Location',
                  hint: 'City, place or address',
                  controller: _locationController,
                  suffixIcon: Icons.location_on_outlined,
                  onChanged: _onLocationChanged,
                ),
                if (_placeList.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _placeList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(_placeList[index]['description']),
                          onTap: () async {
                            final selectedPlace = _placeList[index];
                            _locationController.text = selectedPlace['description'];
                            setState(() => _placeList.clear());
                            await _getPlaceDetails(selectedPlace['place_id']);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _goToRecommendation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.recommend),
                          label: const Text('Get Recommendation'),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _resetFields,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 135, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          // Draggable Chatbot + Sticky Dialog
// Draggable Chatbot + Sticky Dialog
          Positioned(
            left: _chatbotOffset.dx,
            top: _chatbotOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _chatbotOffset += details.delta;
                });
              },
              onTap: () {
                setState(() => _showChatDialog = true);

                // Auto-hide after 3 seconds
                _dialogTimer?.cancel();
                _dialogTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() => _showChatDialog = false);
                  }
                });

                // Delay a bit to let dialog show, then navigate
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatbotPage()),
                  );
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_showChatDialog)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Text(
                        'Get advices here',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.android, color: Colors.white, size: 32), // Robot icon
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
