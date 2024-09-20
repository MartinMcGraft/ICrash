import 'package:app1/home_menu.dart';
import 'package:flutter/material.dart';
import 'package:app1/registration/reg_slot_prod.dart';
import 'package:app1/request_handler/request_handler.dart';

class Bloco {
  String nome;
  String info;
  String formula;
  double largura;
  double altura;
  int maximo;
  bool selecionado;
  int mergeCounth;
  int mergeCountv;

  Bloco({
    required this.nome,
    required this.info,
    required this.formula,
    required this.largura,
    required this.altura,
    this.maximo = 0,
    this.selecionado = false,
    this.mergeCounth = 1,
    this.mergeCountv = 1,
  });

  void splitBlocos(List<List<Bloco>> grelha) {
    final mergeCounth = this.mergeCounth;
    final mergeCountv = this.mergeCountv;
    final larguraOriginal = this.largura;
    final alturaOriginal = this.altura;
    final larguraNovoBloco = larguraOriginal / mergeCounth;
    final alturaNovoBloco = alturaOriginal / mergeCountv;

    final novosBlocos = List.generate(
      mergeCounth * mergeCountv,
      (index) {
        return Bloco(
          nome: this.nome,
          info: this.info,
          formula: this.formula,
          largura: larguraNovoBloco,
          altura: alturaNovoBloco,
          maximo: this.maximo,
        );
      },
    );

    final indiceLinha = grelha.indexWhere((linha) => linha.contains(this));
    final indiceColuna = grelha[indiceLinha].indexOf(this);

    if (indiceLinha != -1 && indiceColuna != -1) {
      // Split Horizontal
      grelha[indiceLinha].removeAt(indiceColuna);

      for (var i = 0; i < mergeCounth; i++) {
        grelha[indiceLinha].insert(indiceColuna + i, novosBlocos[i]);
      }

      // Split Vertical
      for (var i = 1; i < mergeCountv; i++) {
        final novaLinha = grelha[indiceLinha + i];

        for (var j = 0; j < mergeCounth; j++) {
          novaLinha.insert(indiceColuna + j, novosBlocos[i * mergeCounth + j]);
        }
      }
    }
  }
}

class GridSlots extends StatefulWidget {
  final int numCols;
  final int numLins;
  final RequestHandler handler;
  final bool flag;
  final List<dynamic>? list;

  const GridSlots({
    required this.numCols,
    required this.numLins,
    required this.handler,
    required this.flag,
    this.list,
  });

  @override
  GridSlotsState createState() => GridSlotsState();
}

class GridSlotsState extends State<GridSlots> {
  late List<List<Bloco>> grelha;
  Bloco? blocoSelecionado;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gerarGrelha();
  }

  void gerarGrelha() {
    final larguraTela = MediaQuery.of(context).size.width;
    final alturaTela = MediaQuery.of(context).size.height;
    final numColunas = widget.numCols;
    final numLinhas = widget.numLins;
    const espacamentoBloco = 5.0;
    final flag = widget.flag;
    final lista = widget.list;

    final larguraBloco =
        (larguraTela - (espacamentoBloco * (numColunas - 1))) / numColunas;
    final alturaBloco =
        (alturaTela - (espacamentoBloco * (numLinhas - 1))) / numLinhas;
    if (flag == true) {
      grelha = List<List<Bloco>>.generate(numLinhas, (indiceLinha) {
        return List<Bloco>.generate(numColunas, (indiceColuna) {
          var slotIndex = indiceLinha * numColunas + indiceColuna;

          // Verifique se ainda há elementos na lista 'lista' antes de acessar o índice
          if (slotIndex < lista!.length) {
            var slot = lista[slotIndex];

            return Bloco(
              nome: slot['name_prod'],
              info: "",
              formula: slot['vol_weight'],
              largura: larguraBloco * slot['s_adj_hor'],
              altura: alturaBloco * slot['s_adj_ver'],
              maximo: slot['max_quant'],
            );
          } else {
            // Se o índice estiver fora do alcance da lista, configure a largura e altura para zero
            return Bloco(
              nome: "",
              info: "",
              formula: "",
              largura: 0,
              altura: 0,
              maximo: 0,
            );
          }
        });
      });
    } else {
      grelha = List<List<Bloco>>.generate(numLinhas, (indiceLinha) {
        return List<Bloco>.generate(numColunas, (indiceColuna) {
          const nomeBloco = "";
          const infoBloco = "";
          const formulaBloco = "";
          const maximo = 0;
          return Bloco(
            nome: nomeBloco,
            info: infoBloco,
            formula: formulaBloco,
            largura: larguraBloco,
            altura: alturaBloco,
            maximo: maximo,
          );
        });
      });
    }
  }

  void splitBlocos(Bloco bloco) {
    final mergeCounth = bloco.mergeCounth;
    final mergeCountv = bloco.mergeCountv;
    final larguraOriginal = bloco.largura;
    final alturaOriginal = bloco.altura;
    final larguraNovoBloco = larguraOriginal / mergeCounth;
    final alturaNovoBloco = alturaOriginal / mergeCountv;

    final novosBlocos = List.generate(
      mergeCounth * mergeCountv,
      (index) {
        return Bloco(
          nome: bloco.nome,
          info: bloco.info,
          formula: bloco.formula,
          largura: larguraNovoBloco,
          altura: alturaNovoBloco,
          maximo: bloco.maximo,
        );
      },
    );

    final indiceLinha = grelha.indexWhere((linha) => linha.contains(bloco));
    final indiceColuna = grelha[indiceLinha].indexOf(bloco);

    if (indiceLinha != -1 && indiceColuna != -1) {
      // Split Horizontal
      grelha[indiceLinha].removeAt(indiceColuna);

      for (var i = 0; i < mergeCounth; i++) {
        grelha[indiceLinha].insert(indiceColuna + i, novosBlocos[i]);
      }

      // Split Vertical
      for (var i = 1; i < mergeCountv; i++) {
        final novaLinha = grelha[indiceLinha + i];

        for (var j = 0; j < mergeCounth; j++) {
          novaLinha.insert(indiceColuna + j, novosBlocos[i * mergeCounth + j]);
        }
      }
    }
  }

  void mergeBlocos(Bloco bloco1, Bloco bloco2) {
    final indiceLinha1 = grelha.indexWhere((linha) => linha.contains(bloco1));
    final indiceLinha2 = grelha.indexWhere((linha) => linha.contains(bloco2));
    final indiceColuna1 = grelha[indiceLinha1].indexOf(bloco1);
    final indiceColuna2 = grelha[indiceLinha2].indexOf(bloco2);

    if (indiceLinha1 != -1 &&
        indiceLinha2 != -1 &&
        indiceColuna1 != -1 &&
        indiceColuna2 != -1) {
      if (indiceLinha1 == indiceLinha2) {
        // Merge blocks in the same row (adjust width)
        if (bloco1.altura == bloco2.altura) {
          final nomeMerged = '${bloco1.nome}${bloco2.nome}';
          final infoMerged = '${bloco1.info}${bloco2.info}';
          final formulaMerged = '${bloco1.formula}${bloco2.formula}';
          final larguraFundida = bloco1.largura + bloco2.largura;

          bloco1.largura = larguraFundida;
          bloco1.nome = nomeMerged;
          bloco1.info = infoMerged;
          bloco1.formula = formulaMerged;
          bloco1.mergeCounth++; // Increment merge count
          grelha[indiceLinha1].remove(bloco2);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text(
                  'The selected blocks must have the same width to perform horizontal merge.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else if (indiceColuna1 == indiceColuna2) {
        // Merge blocks in the same column (adjust height)
        if (bloco1.largura == bloco2.largura) {
          final nomeMerged = '${bloco1.nome}${bloco2.nome}';
          final infoMerged = '${bloco1.info}${bloco2.info}';
          final formulaMerged = '${bloco1.formula}${bloco2.formula}';
          final alturaFundida = bloco1.altura + bloco2.altura;

          final blocoMerged = Bloco(
            nome: nomeMerged,
            info: infoMerged,
            formula: formulaMerged,
            largura: bloco1.largura,
            altura: alturaFundida,
          );

          grelha[indiceLinha1].remove(bloco1);
          grelha[indiceLinha2].remove(bloco2);

          final indiceLinhaSuperior =
              indiceLinha1 < indiceLinha2 ? indiceLinha1 : indiceLinha2;
          grelha[indiceLinhaSuperior].insert(indiceColuna1, blocoMerged);
          blocoMerged.mergeCountv++; // Increment merge count
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text(
                  'The selected blocks must have the same height to perform vertical merge.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text(
                'To merge blocks horizontally, they must be in the same row. To merge blocks vertically, they must be in the same column.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }

    bloco1.selecionado = false;
    bloco2.selecionado = false;
    blocoSelecionado = null;
  }

  void selecionarBloco(Bloco bloco) {
    if (blocoSelecionado != null) {
      if (blocoSelecionado == bloco) {
        blocoSelecionado!.selecionado = false;
        blocoSelecionado = null;
      } else {
        mergeBlocos(blocoSelecionado!, bloco);
        setState(() {});
      }
    } else {
      blocoSelecionado = bloco;
      bloco.selecionado = true;
    }
  }

  Widget construirGrelha() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grelha.map((linha) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: linha.map((bloco) {
                  return GestureDetector(
                    onLongPress: () {
                      selecionarBloco(bloco);
                      setState(() {});
                    },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ProductDetails(
                              bloco: bloco,
                              mergev: bloco.mergeCountv,
                              mergeh: bloco.mergeCounth,
                              handler: widget.handler);
                        },
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    onDoubleTap: () {
                      // Add this onDoubleTap handler
                      splitBlocos(bloco);
                      setState(() {});
                    },
                    child: Container(
                      width: bloco.largura,
                      height: bloco.altura,
                      margin: const EdgeInsets.only(right: 5),
                      color: bloco.selecionado ? Colors.green : Colors.blue,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bloco.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            bloco.info,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            bloco.formula,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Maximo de produtos: ${bloco.maximo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Representação da gaveta'),
        actions: [
          ElevatedButton(
            onPressed: () {
              widget.handler.closeClient();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeMenu(), // Replace with your HomeMenu widget
                ),
              );
            },
            child: Text('Terminar'),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: construirGrelha(),
        ),
      ),
    );
  }
}
