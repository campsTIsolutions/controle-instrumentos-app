import 'package:flutter/material.dart';

class InstrumentosPage extends StatelessWidget {
  const InstrumentosPage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
        "Instrumentos", 
        style:TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        
      ),
    );
  }
}