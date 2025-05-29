import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class GooglePlaceTestpage extends StatefulWidget {
  const GooglePlaceTestpage({super.key});

  @override
  State<GooglePlaceTestpage> createState() => _GooglePlaceTestpageState();
}

class _GooglePlaceTestpageState extends State<GooglePlaceTestpage> {
  final searchController = TextEditingController();
  final String token = '123456789';
  var uuid = const Uuid();
  List<dynamic>listOfLocation = [];
  @override
  void initState() {
    searchController.addListener(() {
      _onChange();
    });
    super.initState();
  }

  _onChange() {
    placeSuggestion(searchController.text);
  }
  void placeSuggestion(String input) async {
    const String apiKey = "AIzaSyABojR9MRqE3EAO4DwiW5QMPitmULqPFJg";
    try {
      String bassedUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      String request = '$bassedUrl?input=$input&key=$apiKey&sessiontoken=$token';
      var respone = await http.get(Uri.parse(request));
      var data = json.decode(respone.body);
      if(kDebugMode) {
        print(data);
      }
      if(respone.statusCode == 200) {
        setState(() {
          listOfLocation = json.decode(respone.body)['predictions'];
        });
      } else {
        throw Exception("Fail to load");
      }
    }catch(e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Location AutoComplete',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        centerTitle: true,
      ),
      body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search Location...',
                ),
                onChanged: (value) {
                  setState(() {

                  });
                },
              ),
              Visibility(
                visible: searchController.text.isEmpty?false:true,
                child: Expanded(child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listOfLocation.length,
                    itemBuilder: (context, index){
                    return GestureDetector(
                      onTap: () {},
                      child: ListTile(title: Text(listOfLocation[index]["description"],)),
                    );
                }
                ),
                ),
              ),
              Visibility(
                visible: searchController.text.isEmpty?true:false,
                child: Container(
                  margin: const EdgeInsets.only(top:20),
                  child: ElevatedButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "My Location",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          )
                    ],
                  )),
                ),
              )
            ],
          ),
      ),
    );
  }
}
