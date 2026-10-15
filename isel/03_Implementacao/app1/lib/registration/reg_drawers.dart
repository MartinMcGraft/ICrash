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
// │   src/ui/features/dashboard/drawer_form_dialog.dart              │
// └──────────────────────────────────────────────────────────────────┘
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:icrash_app/grids/grid_drawers.dart';
import 'package:icrash_app/request_handler/request_handler.dart';

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class RegDrawers extends StatefulWidget {
  final int blockNumber;
  final RequestHandler handler;

  const RegDrawers({
    super.key,
    required this.blockNumber,
    required this.handler,
  });

  @override
  RegDrawersState createState() => RegDrawersState();
}

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class RegDrawersState extends State<RegDrawers> {
  int numDrawers = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number of Drawers')),
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
                    if (await widget.handler.getCrashCartID(
                      'CrashCart${widget.blockNumber + 1}',
                    )) {
                      if (await widget.handler.createDrawers(
                        numDrawers.toString(),
                      )) {
                        if (!context.mounted) return;
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
