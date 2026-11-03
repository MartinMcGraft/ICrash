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
// │   src/ui/features/auth/institution_picker_screen.dart            │
// │   src/ui/features/dashboard/cart_form_dialog.dart                │
// └──────────────────────────────────────────────────────────────────┘
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:icrash_app/grids/grid_crashcarts.dart';
import 'package:icrash_app/request_handler/request_handler.dart';

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class RegInstitutionCC extends StatefulWidget {
  const RegInstitutionCC({super.key});

  @override
  RegInstitutionCCState createState() => RegInstitutionCCState();
}

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class RegInstitutionCCState extends State<RegInstitutionCC> {
  //Criação das variaveis globais
  int numCC = 1;
  String institution = "";
  String description = "";

  RequestHandler handler = RequestHandler();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: ListView(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Criação de zona de input para o nome da instituição
                SizedBox(
                  width: 200.0,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Institution Name',
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      setState(() {
                        institution = value;
                      });
                    },
                  ),
                ),
                //Criação de zona de input para a descrição da instituição
                SizedBox(
                  width: 200.0,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Institution Description',
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      setState(() {
                        description = value;
                      });
                    },
                  ),
                ),
                //Criação de zona de input para digitar o numero de carros que são pretendidos para cada instituição.
                SizedBox(
                  width: 200.0,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Number of CrashCarts',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        numCC = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    //registo do nome, descrição e numero de carros de uma instituição no servidor ao clicar no botão de registar.
                    if (await handler.createInstitution(
                      institution,
                      description,
                    )) {
                      if (await handler.getInstitutionID()) {
                        if (await handler.createCrashCarts(numCC.toString())) {
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GridCrashCarts(
                                numCCs: numCC,
                                inst: institution,
                                descr: description,
                                handler: handler,
                              ),
                            ),
                          );
                        }
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
