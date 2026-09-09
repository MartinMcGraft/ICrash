import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';

class TesteDataMatrix extends StatefulWidget {
  const TesteDataMatrix({super.key});

  @override
  State<TesteDataMatrix> createState() => _TesteDataMatrixState();
}

class _TesteDataMatrixState extends State<TesteDataMatrix> {
  CameraController? _controller;
  String _result = 'Nenhum código encontrado';
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  // Inicializa a câmera
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller?.initialize();
      setState(() {}); // Atualiza a interface após a inicialização
    } catch (e) {
      debugPrint('Erro ao inicializar a câmera: $e');
    }
  }

  // Processa a imagem quando o botão é pressionado
  Future<void> detectBarcode() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isDetecting) {
      return;
    }

    setState(() {
      _isDetecting =
          true; // Marca como detectando para evitar múltiplos cliques
    });

    try {
      // Captura uma imagem usando o controlador
      final XFile pictureFile = await _controller!.takePicture();

      // Decodifica o código usando Google ML Kit
      final result = await processImage(pictureFile);

      setState(() {
        _result = result ?? 'Nenhum código encontrado'; // Atualiza o resultado
      });

      // Se um DataMatrix for detectado, extraia os dados
      if (_result.contains('01')) {
        _extractGS1Data(_result);
      } else {
        setState(() {
          _isDetecting = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao processar a imagem: $e');
      setState(() {
        _result = 'Ocorreu um erro inesperado';
        _isDetecting = false;
      });
    }
  }

  // Processa a imagem e tenta decodificar o código
  Future<String?> processImage(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      for (Barcode barcode in barcodes) {
        if (barcode.rawValue != null) {
          return barcode.rawValue; // Retorna o conteúdo decodificado
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar a imagem: $e');
    } finally {
      barcodeScanner.close();
    }
    return null;
  }

  // Função para extrair dados GS1 do conteúdo do DataMatrix
  void _extractGS1Data(String dataMatrix) {
    String? productCode;
    String? serialNumber;
    String? batchNumber;
    String? expirationDate;
    String? registrationNumber;
    String? isvalid;

    // Expressões regulares para identificar e extrair dados
    final regexProductCode = RegExp(r"01(\d{14})"); // GTIN de 14 dígitos
    final regexSerialNumber = RegExp(
      r"21([A-Za-z0-9]{1,20})",
    ); // Número de série alfanumérico de até 20 caracteres
    final regexBatchNumber = RegExp(
      r"10([A-Za-z0-9]{1,20})",
    ); // Lote alfanumérico de até 20 caracteres
    final regexExpirationDate = RegExp(
      r"17(\d{6})",
    ); // Data de validade no formato YYMMDD
    final regexRegistrationNumber = RegExp(
      r"714(\d{7})",
    ); // Número de registro nacional de 7 dígitos

    // Extrai código do produto (GTIN)
    final productCodeMatch = regexProductCode.firstMatch(dataMatrix);
    if (productCodeMatch != null) productCode = productCodeMatch.group(1);

    // Extrai número de série
    final serialNumberMatch = regexSerialNumber.firstMatch(dataMatrix);
    if (serialNumberMatch != null) serialNumber = serialNumberMatch.group(1);

    // Extrai número do lote
    final batchNumberMatch = regexBatchNumber.firstMatch(dataMatrix);
    if (batchNumberMatch != null) batchNumber = batchNumberMatch.group(1);

    // Extrai data de validade
    final expirationDateMatch = regexExpirationDate.firstMatch(dataMatrix);
    if (expirationDateMatch != null) {
      String expirationDateStr = expirationDateMatch.group(1)!;
      String year = "20${expirationDateStr.substring(0, 2)}";
      String month = expirationDateStr.substring(2, 4);
      String day = expirationDateStr.substring(4, 6);
      expirationDate = "$day/$month/$year";
    }

    // Extrai número de registro nacional
    final registrationNumberMatch = regexRegistrationNumber.firstMatch(
      dataMatrix,
    );
    if (registrationNumberMatch != null) {
      registrationNumber = registrationNumberMatch.group(1);
    }

    DateTime currentDate = DateTime.now();
    DateTime expirationDateTime = DateFormat('dd/MM/yyyy')
        .parse(expirationDate!);
    int differenceInDays = expirationDateTime.difference(currentDate).inDays;

    if (differenceInDays > 30) {
      isvalid = 'O produto tem mais de 1 mês de validade';
    } else if (differenceInDays > 0 && differenceInDays <= 30) {
      isvalid = 'O produto tem menos de 1 mês de validade';
    } else {
      isvalid = 'O produto já está expirado.';
    }

    // Mostra os dados extraídos em um AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalhes do DataMatrix'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Código do Produto (GTIN): $productCode'),
              Text('Número de Série: $serialNumber'),
              Text('Número do Lote: $batchNumber'),
              Text('Data de Validade: $expirationDate'),
              Text('Número de Registro Nacional: $registrationNumber'),
              Text('Validade: $isvalid'),
            ],
          ),
          actions: <Widget>[],
        );
      },
    ).then((_) {
      setState(() {
        _isDetecting = false; // Reinicia a busca após fechar o popup
        _result = 'Nenhum código encontrado';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de Códigos')),
      body: Column(
        children: [
          // Garante que _controller não é nulo antes de usá-lo
          if (_controller != null && _controller!.value.isInitialized)
            Expanded(
              child: CameraPreview(
                _controller!,
              ), // Mostra a pré-visualização da câmera
            )
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Resultado: $_result'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!_isDetecting) {
                detectBarcode(); // Inicia a detecção ao pressionar o botão
              }
            },
            child: const Text('Scan DataMatrix'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
