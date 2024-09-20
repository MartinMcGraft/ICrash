import 'package:app1/grids/grid_drawers.dart';
import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:app1/home_menu.dart';
import 'package:app1/request_handler/request_handler.dart';

import '../grids/grid_slots.dart';
import 'package:intl/intl.dart';

class QRCodeReader extends StatelessWidget {
  const QRCodeReader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QRCodeScannerScreen(),
    );
  }
}

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final RequestHandler handler = RequestHandler();
  bool dailyManagement = true;
  int contador = 0;
  String nomef = "";
  int maxf = 0;
  int resultado = 0;
  Map<String, int> counters = {};
  bool flagMensal = false;

  QRViewController? controller;
  int counter = 0;
  String lastScannedMessage = '';
  bool buttonPressed = false;
  String last7Characters = '';
  String fullString = '';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeMenu(),
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeMenu(),
                ),
              );
            },
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'String lida: $fullString',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleButtonPress,
              child: const Row(
                children: [
                  Icon(Icons.add),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _handleButtonPress();

                // Função para extrair os dados da string lida do QR Code
                void extractGS1Data(String dataMatrix) {
                  String? productCode;
                  String? serialNumber;
                  String? batchNumber;
                  String? expirationDate;
                  String? registrationNumber;

                  // Expressões regulares para identificar e extrair os dados
                  final regexProductCode =
                      RegExp(r"01(\d{14})"); // GTIN de 14 dígitos
                  final regexSerialNumber = RegExp(
                      r"21([A-Za-z0-9]{1,20})"); // Número de Série alfanumérico de até 20 caracteres
                  final regexBatchNumber = RegExp(
                      r"10([A-Za-z0-9]{1,20})"); // Número do Lote alfanumérico de até 20 caracteres
                  final regexExpirationDate = RegExp(
                      r"17(\d{6})"); // Data de Validade em formato AAMMDD
                  final regexRegistrationNumber = RegExp(
                      r"714(\d{7})"); // Número de Registo Nacional de 7 dígitos

                  // Extrair o código do produto (GTIN)
                  final productCodeMatch =
                      regexProductCode.firstMatch(dataMatrix);
                  if (productCodeMatch != null) {
                    productCode = productCodeMatch.group(1);
                  }

                  // Extrair o número de série
                  final serialNumberMatch =
                      regexSerialNumber.firstMatch(dataMatrix);
                  if (serialNumberMatch != null) {
                    serialNumber = serialNumberMatch.group(1);
                  }

                  // Extrair o número do lote
                  final batchNumberMatch =
                      regexBatchNumber.firstMatch(dataMatrix);
                  if (batchNumberMatch != null) {
                    batchNumber = batchNumberMatch.group(1);
                  }

                  // Extrair a data de validade
                  final expirationDateMatch =
                      regexExpirationDate.firstMatch(dataMatrix);
                  if (expirationDateMatch != null) {
                    String expirationDateStr = expirationDateMatch.group(1)!;
                    // Converter para o formato legível (AAAA-MM-DD)
                    String year = "20" + expirationDateStr.substring(0, 2);
                    String month = expirationDateStr.substring(2, 4);
                    String day = expirationDateStr.substring(4, 6);
                    expirationDate = "$day/$month/$year";
                  }

                  // Extrair o número de registo nacional
                  final registrationNumberMatch =
                      regexRegistrationNumber.firstMatch(dataMatrix);
                  if (registrationNumberMatch != null) {
                    registrationNumber = registrationNumberMatch.group(1);
                  }

                  // Mostrar os dados extraídos em um AlertDialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Dados do QR Code'),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('Código do Produto (GTIN): $productCode'),
                            Text('Número de Série: $serialNumber'),
                            Text('Número do Lote: $batchNumber'),
                            Text('Data de Validade: $expirationDate'),
                            Text(
                                'Número de Registo Nacional: $registrationNumber'),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Fechar'),
                          ),
                        ],
                      );
                    },
                  );
                }

                // Chamando a função de extração com a string lida
                extractGS1Data(fullString);
              },
              child: const Row(
                children: [
                  SizedBox(width: 8),
                  Text('Verificar Data'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Produtos usados:'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (String nome in counters.keys)
                            Text('$nome ${counters[nome]}'),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Fechar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Row(
                children: [
                  SizedBox(width: 8),
                  Text('Relatorio final'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      setState(() {
        lastScannedMessage = scanData.code!;
      });
    });
  }

  void _handleButtonPress() async {
    buttonPressed = true;
    if (buttonPressed) {
      List<String> code = fullString.split('/');
      //print(code);
      if (code.length == 2) {
        String data = await handler.getNumDrawers(code[0], code[1]);
        if (data.isNotEmpty) {
          counter++;
        }
        print(data);
        int numD = int.parse(data);
        int numB = int.parse(code[1]);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GridDrawers(
              blockNumber: numB,
              numDs: numD,
              handler: handler,
            ),
          ),
        );
      }
      if (code.length == 3) {
        List<String> shape =
            await handler.getDrawerShape(code[0], code[1], code[2]);
        int nLins = int.parse(shape[0]);
        int nCols = int.parse(shape[1]);
        List<Map<String, dynamic>> slots =
            await handler.getSlots(code[0], code[1], code[2]);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GridSlots(
              numCols: nCols,
              numLins: nLins,
              handler: handler,
              flag: true,
              list: slots,
            ),
          ),
        );
      }

      if (code.length == 4) {
        List<String> resultados = [];
        List<String> nameMaxQ = await handler.updateSlotQuantity(
            code[0], code[1], code[2], code[3]);
        String nome = nameMaxQ[0];
        if (!counters.containsKey(nome)) {
          counters[nome] = 0;
        }

        counters[nome] = (counters[nome] ?? 0) - 1;

        resultados.add('$nome ${counters[nome]!}');
      }

      setState(() {
        fullString = lastScannedMessage;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
