import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await seedFirestoreData();
  print('Seeding complete!');
}

Future<void> seedFirestoreData() async {

  final groceries = [
    {
      'name': 'Super 8 Mini Market',
      'items': [
        {'name': 'White Rice (5kg)', 'price': 25.00},
        {'name': 'Cooking Oil (1L)', 'price': 8.50},
        {'name': 'Sugar (1kg)', 'price': 2.80},
        {'name': 'Salt (1kg)', 'price': 1.20},
        {'name': 'Fresh Chicken (1kg)', 'price': 9.00},
        {'name': 'Fresh Eggs (Grade A, 10 pcs)', 'price': 5.00},
        {'name': 'Instant Noodles (5-pack)', 'price': 4.50},
        {'name': 'Bread (Loaf)', 'price': 2.50},
        {'name': 'Milk (1L)', 'price': 6.00},
        {'name': 'Apples (1kg)', 'price': 6.50},
        {'name': 'Bananas (1kg)', 'price': 4.00},
        {'name': 'Onions (1kg)', 'price': 3.00},
        {'name': 'Potatoes (1kg)', 'price': 3.50},
        {'name': 'Carrots (1kg)', 'price': 3.20},
        {'name': 'Tomatoes (1kg)', 'price': 4.00},
        {'name': 'Sardines in Tomato Sauce (425g)', 'price': 5.50},
        {'name': 'Canned Baked Beans (425g)', 'price': 3.80},
        {'name': 'Milo (1kg)', 'price': 18.50},
        {'name': 'Coffee Powder (200g)', 'price': 9.90},

      ]
    },
  ];

  final restaurants = [
    {
      'name': 'HAURA CAFE',
      'meals': [
        {'name': 'Nasi Arab Ayam', 'price': 25.00},
        {'name': 'Nasi Arab Kambing Bakar', 'price': 35.00},
        {'name': 'Combo Nasi Arab Ayam', 'price': 15.00},
        {'name': 'Combo Nasi Arab Kambing Grill', 'price': 25.00},
        {'name': 'Nasi Arab Ayam Bajet', 'price': 15.90},
        {'name': 'Nasi Ayam Goreng Kunyit', 'price': 13.90},
        {'name': 'Nasi Tomyam Ayam', 'price': 15.90},
        {'name': 'Nasi Ayam Sambal Bali', 'price': 15.90},
        {'name': 'Nasi Ayam Padprik', 'price': 15.90},
        {'name': 'Nasi Ayam Asam Pedas', 'price': 13.90},
        {'name': 'Freezy Chocolate', 'price': 15.90},
        {'name': 'Freezy Cappuccino', 'price': 15.90},
        {'name': 'Freezy Mocha', 'price': 15.90},
        {'name': 'Freezy White Coffee', 'price': 15.90},
        {'name': 'Freezy White Coffee Oreo', 'price': 15.90},
        {'name': 'Teh Tarik Ais', 'price': 4.50},
        {'name': 'Milo Ais', 'price': 5.00},
        {'name': 'Air Lemon Ais', 'price': 3.50},
        {'name': 'Air Sirap Bandung', 'price': 4.00},
        {'name': 'Nasi Goreng Ayam Berempah', 'price': 14.90},
        {'name': 'Spaghetti Bolognese', 'price': 17.00},
        {'name': 'Spaghetti Carbonara', 'price': 17.00},
        {'name': 'Fries with Cheese', 'price': 8.50},
      ]
    },
  ];


  final collection = FirebaseFirestore.instance.collection('groceries');

  for (var grocery in groceries) {
    await collection.add(grocery);
  }
}
