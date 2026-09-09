import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class TesteDataMatrix extends StatefulWidget {
  const TesteDataMatrix({super.key});

  @override
  State<TesteDataMatrix> createState() => _TesteDataMatrixState();
}

class _TesteDataMatrixState extends State<TesteDataMatrix> {
  CameraController? _controller;
  String _result = 'Nenhuma data de validade encontrada';

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
  Future<void> detectText() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _result = 'Analisando...'; // Atualiza o estado para mostrar que está processando
    });

    try {
      // Captura uma imagem usando o controlador
      final XFile pictureFile = await _controller!.takePicture();

      // Realiza OCR na imagem capturada
      final result = await processImageForText(pictureFile);

      setState(() {
        _result =
            result ??
            'Nenhuma data de validade encontrada'; // Atualiza o resultado
      });
    } catch (e) {
      debugPrint('Erro ao processar a imagem: $e');
      setState(() {
        _result = 'Ocorreu um erro inesperado';
      });
    }
  }

  // Processa a imagem e tenta reconhecer texto
  Future<String?> processImageForText(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      // Expressões regulares para capturar datas nos formatos comuns, incluindo YYYY-MM, YYYY MM e variantes com espaços
      final regexDate = RegExp(
        r'\b(\d{2}[\\/.,\- ]\d{2}[\\/.,\- ]\d{4}|\d{4}[\\/.,\- ]\d{2}[\\/.,\- ]\d{2}|\d{2}[\\/.,\- ]\d{4}|\d{4}[\\/.,\- ]\d{2}|\d{4}\s\d{2})\b',
      );

      // Busca apenas por datas na imagem
      final matches = regexDate
          .allMatches(text)
          .map((match) => match.group(0))
          .toList();
      if (matches.isNotEmpty) {
        final selectedDate = matches.length > 1
            ? matches[1]
            : matches[0]; // Seleciona a segunda data ou a única disponível

        // Verifica se a data está dentro ou fora do prazo de validade
        final now = DateTime.now();
        DateTime? parsedDate;

        try {
          if (selectedDate!.contains(RegExp(r'[\\/]'))) {
            parsedDate = DateFormat('dd/MM/yyyy')
                .parse(selectedDate.replaceAll(RegExp(r'[.,\- ]'), '/'));
          } else if (selectedDate.contains(RegExp(r'[.,\- ]'))) {
            if (selectedDate.split(RegExp(r'[.,\- ]')).length == 2 ||
                selectedDate.contains(' ')) {
              // Caso especial: Formato YYYY-MM, YYYY MM ou variantes com espaços
              parsedDate = DateFormat('yyyy-MM')
                  .parse(selectedDate.replaceAll(RegExp(r'[.,\- ]'), '-'));
            } else {
              parsedDate = DateFormat('yyyy-MM-dd')
                  .parse(selectedDate.replaceAll(RegExp(r'[.,\- ]'), '-'));
            }
          }
        } catch (e) {
          debugPrint('Erro ao analisar a data: $e');
        }

        if (parsedDate != null) {
          final difference = parsedDate.difference(now).inDays;
          if (difference > 30) {
            return '$selectedDate - Dentro do prazo (mais de 1 mês)';
          } else if (difference > 0) {
            return '$selectedDate - Dentro do prazo (menos de 1 mês)';
          } else {
            return '$selectedDate - Fora do prazo';
          }
        }

        return selectedDate; // Retorna a data selecionada
      }
    } catch (e) {
      debugPrint('Erro ao reconhecer texto: $e');
    } finally {
      textRecognizer.close();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisador de Imagens')),
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
              detectText(); // Inicia a detecção ao pressionar o botão
            },
            child: const Text('Analisar Imagem'),
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
