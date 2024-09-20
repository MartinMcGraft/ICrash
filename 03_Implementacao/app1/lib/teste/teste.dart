import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

class TesteDataMatrix extends StatefulWidget {
  const TesteDataMatrix({super.key});

  @override
  _TesteDataMatrixState createState() => _TesteDataMatrixState();
}

class _TesteDataMatrixState extends State<TesteDataMatrix> {
  CameraController? _controller;
  String _result = 'No DataMatrix found';
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  // Initialize the camera
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
      setState(() {}); // Update the UI after initialization
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  // Function to process the image only when button is pressed
  Future<void> detectDataMatrix() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isDetecting) {
      return;
    }

    setState(() {
      _isDetecting = true; // Mark as detecting to avoid multiple clicks
    });

    try {
      // Capture a picture using the controller (this returns a file path)
      final XFile pictureFile = await _controller!.takePicture();

      // Load the image from the file path
      final img.Image image = img.decodeImage(await pictureFile.readAsBytes())!;

      // Process the image and attempt to decode the DataMatrix
      final result = await processImage(image);

      setState(() {
        _result = result ?? 'No DataMatrix found'; // Update the result
      });

      // Extract GS1 data from the result and display it
      if (_result.isNotEmpty) {
        _extractGS1Data(_result);
      }
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _result = 'An unexpected error occurred';
        _isDetecting = false; // Return to waiting state
      });
    }
  }

  // Process the image and try to decode DataMatrix
  Future<String?> processImage(img.Image image) async {
    try {
      // Convert image pixels to grayscale luminance source
      LuminanceSource source = RGBLuminanceSource(
        image.width,
        image.height,
        image.getBytes(format: img.Format.abgr).buffer.asInt32List(),
      );

      // Create a BinaryBitmap using HybridBinarizer
      final BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

      // Initialize the reader and set hints for Data Matrix format
      final Reader reader = MultiFormatReader();
      final DecodeHint hints = DecodeHint()..possibleFormats;

      try {
        // Decode the barcode
        final Result result = reader.decode(bitmap, hints);
        return result.text; // Return the decoded DataMatrix content
      } on NotFoundException {
        return 'No DataMatrix barcode found';
      } on ChecksumException {
        return 'Checksum error when decoding the barcode';
      } on FormatException {
        return 'Format error when decoding the barcode';
      }
    } catch (e) {
      print('Error processing image: $e');
      return 'An unexpected error occurred';
    }
  }

  // Function to extract GS1 data from DataMatrix content
  void _extractGS1Data(String dataMatrix) {
    String? productCode;
    String? serialNumber;
    String? batchNumber;
    String? expirationDate;
    String? registrationNumber;
    String? isvalid;

    // Regular expressions to identify and extract data
    final regexProductCode = RegExp(r"01(\d{14})"); // GTIN of 14 digits
    final regexSerialNumber = RegExp(
        r"21([A-Za-z0-9]{1,20})"); // Alphanumeric Serial Number up to 20 characters
    final regexBatchNumber = RegExp(
        r"10([A-Za-z0-9]{1,20})"); // Alphanumeric Batch Number up to 20 characters
    final regexExpirationDate =
        RegExp(r"17(\d{6})"); // Expiration Date in YYMMDD format
    final regexRegistrationNumber =
        RegExp(r"714(\d{7})"); // National Registration Number of 7 digits

    // Extract product code (GTIN)
    final productCodeMatch = regexProductCode.firstMatch(dataMatrix);
    if (productCodeMatch != null) productCode = productCodeMatch.group(1);

    // Extract serial number
    final serialNumberMatch = regexSerialNumber.firstMatch(dataMatrix);
    if (serialNumberMatch != null) serialNumber = serialNumberMatch.group(1);

    // Extract batch number
    final batchNumberMatch = regexBatchNumber.firstMatch(dataMatrix);
    if (batchNumberMatch != null) batchNumber = batchNumberMatch.group(1);

    // Extract expiration date
    final expirationDateMatch = regexExpirationDate.firstMatch(dataMatrix);
    if (expirationDateMatch != null) {
      String expirationDateStr = expirationDateMatch.group(1)!;
      String year = "20" + expirationDateStr.substring(0, 2);
      String month = expirationDateStr.substring(2, 4);
      String day = expirationDateStr.substring(4, 6);
      expirationDate = "$day/$month/$year";
    }

    // Extract national registration number
    final registrationNumberMatch =
        regexRegistrationNumber.firstMatch(dataMatrix);
    if (registrationNumberMatch != null)
      registrationNumber = registrationNumberMatch.group(1);

    DateTime currentDate = DateTime.now();
    DateTime expirationDateTime =
        DateFormat('dd/MM/yyyy').parse(expirationDate!);
    int differenceInDays = expirationDateTime.difference(currentDate).inDays;

    if (differenceInDays > 30) {
      isvalid = 'O produto tem mais de 1 mes de validade';
    } else if (differenceInDays > 0 && differenceInDays <= 30) {
      isvalid = 'O produto tem menos de 1 mes de validade';
    } else {
      isvalid = 'O produto já está expirado.';
    }

    // Show extracted data in an AlertDialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data Matrix Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Product Code (GTIN): $productCode'),
              Text('Serial Number: $serialNumber'),
              Text('Batch Number: $batchNumber'),
              Text('Expiration Date: $expirationDate'),
              Text('National Registration Number: $registrationNumber'),
              Text('Validation: $isvalid')
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isDetecting = false; // Return to waiting state
                });
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DataMatrix Scanner'),
      ),
      body: Column(
        children: [
          // Ensure _controller is not null before using it
          if (_controller != null && _controller!.value.isInitialized)
            Expanded(
              child: CameraPreview(_controller!), // Show camera preview
            )
          else
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Result: $_result'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!_isDetecting) {
                detectDataMatrix(); // Start detection when button is pressed
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
