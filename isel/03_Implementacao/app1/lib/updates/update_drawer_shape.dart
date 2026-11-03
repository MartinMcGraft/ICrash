// ┌──────────────────────────────────────────────────────────────────┐
// │ LEGACY-V1 - old app; not used by the new app (lib/src).          │
// │                                                                  │
// │ Only reachable through the legacy button ("Previous              │
// │ application (reference)") in                                     │
// │ src/ui/shells/profile_menu.dart (Perfil menu).                   │
// │                                                                  │
// │ Kept for reference only. Candidate for removal.                  │
// │                                                                  │
// │ Closest new equivalent (by purpose):                             │
// │   src/ui/features/dashboard/grid_editor_screen.dart              │
// └──────────────────────────────────────────────────────────────────┘
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';

import 'package:icrash_app/grids/grid_slots.dart';
import 'package:icrash_app/request_handler/request_handler.dart';

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class UpdateDrawerShape extends StatefulWidget {
  final String drawerName;
  final RequestHandler handler;

  const UpdateDrawerShape({
    super.key,
    required this.drawerName,
    required this.handler,
  });

  @override
  UpdateDrawerShapeState createState() => UpdateDrawerShapeState();
}

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class UpdateDrawerShapeState extends State<UpdateDrawerShape> {
  late int numCols;
  late int numLins;

  @override
  void initState() {
    super.initState();
    numCols = 7;
    numLins = 5;
  }

  Future<void> startGelha() async {
    if (await widget.handler.getDrawerID(widget.drawerName)) {
      if (await widget.handler.updateDrawerShape(
        numLins.toString(),
        numCols.toString(),
      )) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GridSlots(
              numCols: numCols,
              numLins: numLins,
              handler: widget.handler,
              flag: false,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drawer Shape')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select the number of lines and columns of this drawer:',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Columns: '),
                DropdownButton<int>(
                  value: numCols,
                  onChanged: (value) {
                    setState(() {
                      numCols = value!;
                    });
                  },
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                      .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Lines: '),
                DropdownButton<int>(
                  value: numLins,
                  onChanged: (value) {
                    setState(() {
                      numLins = value!;
                    });
                  },
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                      .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: startGelha, child: const Text('Saved')),
          ],
        ),
      ),
    );
  }
}
