import 'package:flutter/material.dart';

class Excercise extends StatefulWidget {
  const Excercise({Key? key}) : super(key: key);

  @override
  State<Excercise> createState() => ExcerciseState();
}

class ExcerciseState extends State<Excercise> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Excercises'),
      ),
    );
  }
}
