// ┌──────────────────────────────────────────────────────────────────┐
// │ LEGACY-V1 - old app; not used by the new app (lib/src).          │
// │                                                                  │
// │ Only reachable through the legacy button ("Previous              │
// │ application (reference)") in                                     │
// │ src/ui/shells/profile_menu.dart (Perfil menu).                   │
// │ Uses lib/images/ESEL.png and ISEL.png (used only here).          │
// │                                                                  │
// │ Kept for reference only. Candidate for removal.                  │
// │                                                                  │
// │ Closest new equivalent (by purpose):                             │
// │   src/ui/features/carts/carts_screen.dart                        │
// └──────────────────────────────────────────────────────────────────┘
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:icrash_app/qr_code_reader/qr_code_reader.dart';
import 'package:icrash_app/registration/reg_institution_cc.dart';
import 'package:icrash_app/teste/teste.dart';

@Deprecated('LEGACY-V1: not used in the new app (lib/src). Candidate for removal.')
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I-Crash')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Image.asset(
                      'lib/images/ESEL.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Image.asset(
                      'lib/images/ISEL.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegInstitutionCC(),
                    ),
                  );
                },
                child: const Text('Registration'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRCodeReader(),
                    ),
                  );
                },
                child: const Text('QR Code Reader'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TesteDataMatrix()),
                  );
                },
                child: const Text('Data matrix scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
