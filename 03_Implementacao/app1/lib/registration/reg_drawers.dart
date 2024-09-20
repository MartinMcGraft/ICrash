import 'package:flutter/material.dart';
import 'package:app1/grids/grid_drawers.dart';
import 'package:app1/request_handler/request_handler.dart';

class RegDrawers extends StatefulWidget {
  final int blockNumber;
  final RequestHandler handler;

  const RegDrawers({super.key, required this.blockNumber, required this.handler});

  @override
  RegDrawersState createState() => RegDrawersState();
}

class RegDrawersState extends State<RegDrawers> {
  int numDrawers = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number of Drawers'),
      ),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CrashCart ${widget.blockNumber + 1}'),
                const SizedBox(height: 8),
                const Text('Insert number of Drawers:'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: 200.0,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          numDrawers = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (await widget.handler
                        .getCrashCartID('CrashCart${widget.blockNumber + 1}')) {
                      if (await widget.handler
                          .createDrawers(numDrawers.toString())) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GridDrawers(
                              blockNumber: widget.blockNumber,
                              numDs: numDrawers,
                              handler: widget.handler,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
