import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SA'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            
          },
          child: Text('Start Game'),
        ),
      ),
    );
  }
}
