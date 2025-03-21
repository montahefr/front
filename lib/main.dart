import 'package:flutter/material.dart';
import 'package:front/pages/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:front/pages/dashboard.dart';

void main ()async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp( MyApp(token : prefs.getString('token') ,));
}

class MyApp extends StatelessWidget {
  final token;
  const MyApp({
    @required this.token,
    Key? key,

  }):super(key:key);
 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
       home: (token != null && JwtDecoder.isExpired(token) == false )?Dashboard(token: token):LoginScreen()
    );
  }
}
    