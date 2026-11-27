import 'package:flutter/widgets.dart';

class Card extends StatelessWidget {
  const Card({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class Notice extends StatelessWidget {
  const Notice({super.key});

  String label() => 'Notice';

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
