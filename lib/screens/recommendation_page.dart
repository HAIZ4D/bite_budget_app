import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RecommendationPage extends StatefulWidget {
  final double budget;
  final int days;
  final double latitude;
  final double longitude;

  const RecommendationPage({
    Key? key,
    required this.budget,
    required this.days,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  static final String _apiKey = 'API';
  static final String _geminiApiKey = 'API';

  Map<String, dynamic>? _restaurant;
  Map<String, dynamic>? _groceryStore;

  List<Map<String, dynamic>> _affordableMeals = [];
  List<Map<String, dynamic>> _affordableGroceries = [];
  List<Map<String, dynamic>> _mealPlans = [];
  List<Map<String, dynamic>> _groceryRecipes = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    await fetchNearestRestaurant();
    await fetchNearestGroceryStore();

    if (_affordableMeals.isNotEmpty) {
      final average = widget.budget / widget.days;
      try {
        final plans = await generateMealPlansWithGemini(_affordableMeals, average);
        setState(() => _mealPlans = plans);
      } catch (e) {
        print('Gemini generation error: $e');
      }
    }

    setState(() => _isLoading = false);
    if(_affordableGroceries.isNotEmpty) {
      try {
        final recipes = await generateRecipesWithGemini(_affordableGroceries, widget.budget);
        setState(() => _groceryRecipes = recipes);
      } catch (e) {
        print('Gemini generation error: $e');
      }
    }
  }

  Future<void> fetchNearestRestaurant() async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${widget.latitude},${widget.longitude}&rankby=distance&type=restaurant&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        if (results.isNotEmpty) {
          final nearest = results[0];
          setState(() => _restaurant = nearest);
          await fetchMealsFromFirestore(nearest['name']);
        }
      }
    } catch (e) {
      print('Restaurant fetch error: $e');
    }
  }

  Future<void> fetchNearestGroceryStore() async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${widget.latitude},${widget.longitude}&rankby=distance&type=supermarket&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        if (results.isNotEmpty) {
          final nearest = results[0];
          setState(() => _groceryStore = nearest);
          await fetchGroceriesFromFirestore(nearest['name']);
        }
      }
    } catch (e) {
      print('Grocery store fetch error: $e');
    }
  }

  Future<void> fetchMealsFromFirestore(String restaurantName) async {
    final average = widget.budget / widget.days;
    final query = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', isEqualTo: restaurantName)
        .get();

    if (query.docs.isNotEmpty) {
      final meals = query.docs.first.data()['meals'] as List;
      final filtered = meals
          .where((m) => m['price'] <= average)
          .map<Map<String, dynamic>>((m) => {
        'name': m['name'],
        'price': m['price'],
      })
          .toList();

      setState(() => _affordableMeals = filtered);
    }
  }

  Future<void> fetchGroceriesFromFirestore(String groceryName) async {
    final average = widget.budget / widget.days;
    final query = await FirebaseFirestore.instance
        .collection('groceries')
        .where('name', isEqualTo: groceryName)
        .get();

    if (query.docs.isNotEmpty) {
      final items = query.docs.first.data()['items'] as List;
      final filtered = items
          .where((i) => i['price'] <= average)
          .map<Map<String, dynamic>>((i) => {
        'name': i['name'],
        'price': i['price'],
      })
          .toList();

      setState(() => _affordableGroceries = filtered);
    }
  }

  Future<void> _openGoogleMapsDirection(double lat, double lng) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    if (await canLaunchUrl(url)) {
      final bool success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // important!
      );

      if (!success) {
        throw 'Could not launch $url';
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<List<Map<String, dynamic>>> generateMealPlansWithGemini(
      List<Map<String, dynamic>> meals, double averageBudget) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
    );

    final mealList = meals
        .map((meal) => '${meal['name']} (RM ${meal['price'].toStringAsFixed(2)})')
        .join(', ');

    final prompt = '''
You are a nutritionist. Based on the following affordable meals: $mealList, and an average daily budget of RM ${averageBudget.toStringAsFixed(2)}, create three meal plans (breakfast, lunch, dinner) for a day. Each meal plan should include:

- Meal names
- Nutritional description focusing on macronutrients (carbs, protein, fat)
- Total estimated cost

Format the response as JSON:
[
  {
    "plan": "Plan 1",
    "meals": {
      "breakfast": "Meal Name",
      "lunch": "Meal Name",
      "dinner": "Meal Name"
    },
    "nutrition": "Description...",
    "total_cost": "RM 0.00"
  }
]
''';

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) throw Exception('Gemini returned no content.');

    String raw = response.text!.trim();

    // Remove Markdown code block if present
    if (raw.startsWith('```')) {
      final start = raw.indexOf('\n');
      final end = raw.lastIndexOf('```');
      if (start != -1 && end != -1 && end > start) {
        raw = raw.substring(start + 1, end).trim();
      }
    }

    try {
      final List<dynamic> parsed = json.decode(raw);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      print('JSON decode error: $e\nRaw:\n$raw');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateRecipesWithGemini(
      List<Map<String, dynamic>> groceries, double averageBudget) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
    );

    final groceryList = groceries
        .map((item) => '${item['name']} (RM ${item['price'].toStringAsFixed(2)})')
        .join(', ');

    final prompt = '''
You are a recipe generator. Based on the following grocery items: $groceryList, and an average daily budget of RM ${averageBudget.toStringAsFixed(2)}, generate three simple recipes.

Each recipe must include:
- Recipe name
- List of used grocery items (from the list)
- Nutritional description focusing on macronutrients (carbs, protein, fat)
- Step-by-step instructions on how to cook the recipe (3–6 concise steps)
- Total estimated cost (must not exceed an average daily budget)

Return result in JSON format like this:
[
  {
    "recipe": "Recipe Name",
    "ingredients": ["Item 1", "Item 2"],
    "steps": [
      "Step 1 instruction.",
      "Step 2 instruction.",
      ...
    ],
    "nutrition": "Description...",
    "total_cost": "RM 0.00"
  }
]
''';

    final response = await model.generateContent([Content.text(prompt)]);
    if (response.text == null) throw Exception('Gemini returned no recipe content.');

    String raw = response.text!.trim();

    if (raw.startsWith('```')) {
      final start = raw.indexOf('\n');
      final end = raw.lastIndexOf('```');
      if (start != -1 && end != -1 && end > start) {
        raw = raw.substring(start + 1, end).trim();
      }
    }

    try {
      final List<dynamic> parsed = json.decode(raw);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Recipe JSON decode error: $e\nRaw:\n$raw');
      rethrow;
    }
  }


  // UI BELOW

  @override
  Widget build(BuildContext context) {
    final average = widget.budget / widget.days;
    final Color navyBlue = const Color(0xFF1A1F36);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyBlue,
        title: const Text('Recommendations', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _summaryCard(average),
            const SizedBox(height: 30),
            _section(
              title: 'Nearest Restaurant',
              location: _restaurant,
              items: _affordableMeals,
              itemType: 'Meals',

            ),
            const SizedBox(height: 30),
            _section(
              title: 'Nearest Grocery Store',
              location: _groceryStore,
              items: _affordableGroceries,
              itemType: 'Groceries',
            ),
            const SizedBox(height: 30),
            _buildMealPlans(),
            _buildGroceryRecipes(),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Input'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlans() {
    if (_mealPlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI-Generated Meal Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._mealPlans.map((plan) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan['plan'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Breakfast: ${plan['meals']['breakfast']}'),
                  Text('Lunch: ${plan['meals']['lunch']}'),
                  Text('Dinner: ${plan['meals']['dinner']}'),
                  const SizedBox(height: 8),
                  Text('Nutrition: ${plan['nutrition']}'),
                  const SizedBox(height: 8),
                  Text('Total Cost: ${plan['total_cost']}'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGroceryRecipes() {
    if (_groceryRecipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text('AI-Generated Grocery Recipes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._groceryRecipes.map((recipe) {
          final steps = List<String>.from(recipe['steps'] ?? []);

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe['recipe'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List<String>.from(recipe['ingredients']).map((ingredient) => Text('- $ingredient')),
                  const SizedBox(height: 8),
                  const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...steps.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
                  const SizedBox(height: 8),
                  Text('Total Cost: ${recipe['total_cost']}'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }



  Widget _summaryCard(double average) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Daily Spending Plan:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoRow('Total Budget:', 'RM ${widget.budget.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _infoRow('Duration:', '${widget.days} day(s)'),
                const Divider(height: 24),
                _infoRow('Avg. Daily Spend:', 'RM ${average.toStringAsFixed(2)}',
                    valueColor: Colors.green[700], isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Map<String, dynamic>? location,
    required List<Map<String, dynamic>> items,
    required String itemType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        location != null
            ? Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location['name'] ?? 'No name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(location['vicinity'] ?? 'No address'),
                const SizedBox(height: 8),
                if (location['rating'] != null)
                  Text('Rating: ${location['rating']} ⭐'),
                const SizedBox(height: 12),
                if (location['geometry']?['location'] != null)
                  ElevatedButton.icon(
                    onPressed: () => _openGoogleMapsDirection(
                      location['geometry']['location']['lat'],
                      location['geometry']['location']['lng'],
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
        )
            : const Text('No nearby place found.'),
        const SizedBox(height: 16),
        Text('$itemType under budget:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        items.isNotEmpty
            ? Column(
          children: items
              .map(
                (item) => Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.teal),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('RM ${item['price'].toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
              ),
            ),
          )
              .toList(),
        )
            : Text("No $itemType found under your average daily spend."),
      ],
    );
  }


  Widget _infoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
