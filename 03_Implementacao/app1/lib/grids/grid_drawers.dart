import 'package:flutter/material.dart';

import 'package:app1/request_handler/request_handler.dart';
import 'package:app1/updates/update_drawer_shape.dart';

class GridDrawers extends StatelessWidget {
  final int blockNumber;
  final int numDs;
  final RequestHandler handler;

  const GridDrawers({
    required this.blockNumber,
    required this.numDs,
    required this.handler,
  });

  void navigateToInputPage(BuildContext context, String drawerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateDrawerShape(
          drawerName: drawerName,
          handler: handler,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawers'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CrashCart: ${blockNumber + 1}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Text(
                'Number of Drawers: $numDs',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Column(
                children: List.generate(
                  numDs,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: FractionallySizedBox(
                      widthFactor: 0.1,
                      child: ElevatedButton(
                        onPressed: () {
                          navigateToInputPage(context, 'Drawer${index + 1}');
                        },
                        child: Text('Drawer ${index + 1}'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
