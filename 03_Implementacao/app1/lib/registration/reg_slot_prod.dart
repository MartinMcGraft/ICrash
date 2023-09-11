import 'package:flutter/material.dart';

import 'package:app1/grids/grid_slots.dart';
import 'package:app1/request_handler/request_handler.dart';

class ProductDetails extends StatefulWidget {
  final Bloco bloco;
  final int mergev;
  final int mergeh;
  final RequestHandler handler;

  ProductDetails(
      {required this.bloco,
      required this.mergev,
      required this.mergeh,
      required this.handler});

  @override
  ProductDetailsState createState() => ProductDetailsState();
}

class ProductDetailsState extends State<ProductDetails> {
  late TextEditingController _nomeProdutoController;
  late TextEditingController _infoProdutoController;
  late TextEditingController _formulaProdutoController;
  late TextEditingController _maximoProdutoController;

  late String novoNomeProduto = '';
  late String novoinfoProduto = '';
  late String novoformulaProduto = '';
  late int novoMaximoProduto = 0;

  @override
  void initState() {
    super.initState();
    _nomeProdutoController = TextEditingController(text: widget.bloco.nome);
    _infoProdutoController = TextEditingController(text: widget.bloco.info);
    _formulaProdutoController =
        TextEditingController(text: widget.bloco.formula);
    _maximoProdutoController =
        TextEditingController(text: widget.bloco.maximo.toString());
  }

  @override
  void dispose() {
    _nomeProdutoController.dispose();
    _infoProdutoController.dispose();
    _formulaProdutoController.dispose();
    _maximoProdutoController.dispose();
    super.dispose();
  }

  void _salvarDetalhes() {
    final novoNomeProduto = _nomeProdutoController.text;
    final novoinfoProduto = _infoProdutoController.text;
    final novoformulaProduto = _formulaProdutoController.text;
    final novoMaximoProduto = int.tryParse(_maximoProdutoController.text) ?? 0;

    setState(() {
      widget.bloco.nome = novoNomeProduto;
      widget.bloco.info = novoinfoProduto;
      widget.bloco.formula = novoformulaProduto;
      widget.bloco.maximo = novoMaximoProduto;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Detalhes do Produto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeProdutoController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                ),
              ),
              TextField(
                controller: _infoProdutoController,
                decoration: const InputDecoration(
                  labelText: 'Volume/peso',
                ),
              ),
              TextField(
                controller: _formulaProdutoController,
                decoration: const InputDecoration(
                  labelText: 'Forma de aplicação',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maximoProdutoController,
                decoration: const InputDecoration(
                  labelText: 'Máximo do Produto',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      _salvarDetalhes();
                      print('mergev: ${widget.mergev.toStringAsFixed(2)}');
                      print('mergeh: ${widget.mergeh.toStringAsFixed(2)}');
                      print(_nomeProdutoController.text);
                      print(_infoProdutoController.text);
                      print(_formulaProdutoController.text);
                      print(_maximoProdutoController.text);
                      await widget.handler.createSlot(
                        widget.mergeh.toString(),
                        widget.mergev.toString(),
                        _nomeProdutoController.text,
                        _infoProdutoController.text,
                        _formulaProdutoController.text,
                        _maximoProdutoController.text,
                      );
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
