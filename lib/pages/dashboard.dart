import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:front/config.dart';
import 'package:front/pages/acceuil.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';


// Custom FloatingActionButtonLocation to move the button higher
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final double offsetY; // Vertical offset to move the button higher

  CustomFloatingActionButtonLocation({this.offsetY = 0.0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the default endFloat position
    final Offset endFloatOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    
    // Adjust the Y position by subtracting the offsetY
    return Offset(endFloatOffset.dx, endFloatOffset.dy - offsetY);
  }
}

class Dashboard extends StatefulWidget {
  final token;
  const Dashboard({@required this.token, Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String userId;
  TextEditingController hiveTitleController = TextEditingController();
  List? items;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'];
    getHiveList(userId);
  }

  void addHive() async {
    if (hiveTitleController.text.isNotEmpty) {
      var regBody = {
        "userId": userId,
        "title": hiveTitleController.text,
      };

      var response = await http.post(
        Uri.parse(addhive),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse['status']);
      if (jsonResponse['status']) {
        hiveTitleController.clear();
        Navigator.pop(context);
        getHiveList(userId);
      } else {
        print("Something went wrong");
      }
    }
  }

  Future<void> getHiveList(String userId) async {
    try {
      // Include userId as a query parameter in the URL
      final String endpoint = '$getHiVeList?userId=$userId';
      
      print("Fetching hives for userId: $userId");
      print("Calling API: $endpoint");
      
      var response = await http.get(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
      );
      
      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body.substring(0, min(100, response.body.length))}");
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          items = jsonResponse['success'] ?? [];
        });
      } else {
        print("Server error: ${response.statusCode}");
        print("Response body: ${response.body}");
        setState(() {
          items = [];
        });
      }
    } catch (e) {
      print("Error fetching hive list: $e");
      setState(() {
        items = [];
      });
    }
  }
  
  void deleteItem(String id) async {
    try {
      var regBody = {
        "id": id,
      };

      var response = await http.post(
        Uri.parse(deleteHive),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status']) {
          print("Hive deleted successfully");
          getHiveList(userId); // Refresh the list
        } else {
          print("Failed to delete hive: ${jsonResponse['message']}");
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 60.0, left: 30.0, right: 30.0, bottom: 30.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'DASHBOARD:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    spreadRadius: 5,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: items == null
                    ? Center(child: CircularProgressIndicator()) // Show loading indicator
                    : items!.isEmpty
                        ? Center(child: Text("No Hives found."))
                        : ListView.builder(
                            itemCount: items!.length,
                            itemBuilder: (context, int index) {
                              return Slidable(
                                key: const ValueKey(0),
                                endActionPane: ActionPane(
                                  motion: ScrollMotion(),
                                  dismissible: DismissiblePane(onDismissed: () {}),
                                  children: [
                                    SlidableAction(
                                      backgroundColor: Color(0xFFFE4A49),
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                      onPressed: (BuildContext context) {
                                        print('${items![index]['_id']}');
                                        deleteItem('${items![index]['_id']}');
                                      },
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    title: Text('${items![index]['title']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    trailing: Icon(Icons.arrow_forward, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  spreadRadius: 5,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    // Add functionality for Home
                  },
                  icon: Icon(
                    Icons.home,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Add functionality for Alerts
                  },
                  icon: Icon(
                    Icons.notifications,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: () => _displayTextInputDialogLogOut(context),
                  icon: Icon(
                    Icons.logout,
                    size: 30,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        backgroundColor: const Color.fromARGB(255, 255, 216, 97),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Hive',
      ),
      floatingActionButtonLocation: CustomFloatingActionButtonLocation(offsetY: 90.0),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add Hive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hiveTitleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  hintText: "Enter a title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  addHive();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 216, 97),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Add",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      hiveTitleController.clear();
    });
  }

  Future<void> _displayTextInputDialogLogOut(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ARE YOU SURE ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Acceuil()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 216, 97),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "LOG OUT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      hiveTitleController.clear();
    });
  }
}