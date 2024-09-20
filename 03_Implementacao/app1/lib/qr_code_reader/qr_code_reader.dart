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
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String dataCodigoQR = fullString;

                    // Define uma expressão regular para o formato desejado (por exemplo, 'yyyy-MM-dd')
                    RegExp formatoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

                    // Verifica se a string está no formato desejado
                    if (!formatoData.hasMatch(dataCodigoQR)) {
                      return AlertDialog(
                        title: Text('Formato Inválido'),
                        content:
                            Text('A string lida não está no formato correto.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Fechar'),
                          ),
                        ],
                      );
                    }

                    DateTime dataAtual = DateTime.now();
                    String dataAtualFormatada =
                        DateFormat('yyyy-MM-dd').format(dataAtual);

                    // Converte as datas para DateTime
                    DateTime dataAtualDateTime =
                        DateTime.parse(dataAtualFormatada);
                    DateTime dataCodigoQRDateTime =
                        DateTime.parse(dataCodigoQR);

                    // Calcula a diferença entre as datas
                    Duration diferenca =
                        dataCodigoQRDateTime.difference(dataAtualDateTime);

                    if (diferenca.inDays > 30) {
                      return AlertDialog(
                        title: Text('Validade'),
                        content:
                            Text('O produto tem mais de um mês de validade.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Fechar'),
                          ),
                        ],
                      );
                    } else {
                      return AlertDialog(
                        title: Text('Validade'),
                        content:
                            Text('O produto tem menos de um mês de validade.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Fechar'),
                          ),
                        ],
                      );
                    }
                  },
                );
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
                      title: Text('Produtos usados:'),
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
                          child: Text('Fechar'),
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
        if (data.length != 0) {
          counter++;
        }
        print(data);
        int numD = int.parse(data);
        int numB = int.parse(code[1]);

        // Navigate to GridDrawers
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

      /*DateTime dataAtual = DateTime.now();
      String dataAtualFormatada = DateFormat('yyyy-MM-dd').format(dataAtual);
      String dataCodigoQR = fullString;
      if (flagMensal) {
        if (dataCodigoQR.compareTo(dataAtualFormatada) >= 0) {
          // A data do código QR é posterior ou igual à data atual
          print("Produto válido!");
        } else {
          // A data do código QR é anterior à data atual
          print("Produto expirado!");
        }
      }*/

      if (code.length == 4) {
        List<String> resultados = [];
        List<String> nameMaxQ = await handler.updateSlotQuantity(
            code[0], code[1], code[2], code[3]);
        String nome = nameMaxQ[0];
        //int max = int.parse(nameMaxQ[1]);

        // Check if the name exists in the map, if not, initialize the counter to 0
        if (!counters.containsKey(nome)) {
          counters[nome] = 0;
        }

        // Decrease the counter for this name
        //counters[nome] = (counters[nome] ?? 0) - 1;
        counters[nome] = (counters[nome] ?? 0) - 1;

        // Add the result to the list (for display purposes)
        resultados.add('$nome ${counters[nome]!}');
        /*
        if (dailyManagement) {
          await handler.updateSlotQuantity(code[0], code[1], code[2], code[3]);
        } else {
          // TODO: Monthly management
        }*/
      }

      setState(() {
        // Update other state variables if needed
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
