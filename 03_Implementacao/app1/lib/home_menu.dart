import 'package:flutter/material.dart';
import 'package:app1/qr_code_reader/qr_code_reader.dart';
import 'package:app1/registration/reg_institution_cc.dart';
import 'package:app1/teste/teste.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-Crash'),
      ),
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
                        builder: (context) => const QRCodeReader()),
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
