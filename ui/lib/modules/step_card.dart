import 'package:flutter/material.dart';

class StepCard extends StatelessWidget {
  const StepCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(Icons.star_rounded, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "this is a test action",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: add flow control (if statements and stuff)
