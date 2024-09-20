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
}

/*
Aqui é definida a classe Grelha, que é uma subclasse de StatefulWidget. Esta classe 
representa uma grelha de blocos. Ela possui cinco atributos, numColunas 
(número de colunas), numLinhas (número de linhas), handler (conexão com o servidor), flag 
(deteção se é ou não um registo ou uma leitura de qr code) e list (lista que caso seja uma 
leitura de qr code é pedida essa lista ao servidior esta irá conter as informações 
necessarias para criar a grelha), e um construtor que recebe esses 
atributos como parâmetros. A classe também sobrescreve o método createState, que retorna
uma instância da classe GridSlotsState, responsável por gerenciar o estado da grelha.
*/

class GridSlots extends StatefulWidget {
  final int numCols;
  final int numLins;
  final RequestHandler handler;
  final bool flag;
  final List<dynamic>? list;

  const GridSlots({super.key, 
    required this.numCols,
    required this.numLins,
    required this.handler,
    required this.flag,
    this.list,
  });

  @override
  GridSlotsState createState() => GridSlotsState();
}

/*
A classe GridSlotsState é uma classe publica que possui
dois atributos, grelha e blocoSelecionado.
O método didChangeDependencies é um método de ciclo de vida
do Flutter que é chamado quando o widget recebe novas dependências. 
Neste caso, o método chama a função gerargrelha para gerar a grelha.
A função gerargrelha calcula a largura e altura de cada bloco com base 
na largura e altura da tela, no número de colunas e no número de linhas. 
Em seguida, a função gera uma grelha bidimensional (List<List<Bloco>>)
usando a função generate. Cada bloco na grelha é inicializado com um nome, 
info e formula vazios, a largura e altura calculadas anteriormente, dois counters
inicializados a 1 que identificão quantas vezes foi feito o merge vertival e horizontal,
um maximo inicializado a 0 e por fim um booleano que tem como objetivo identificar se um bloco
esta selecionado ou não.
*/

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

  /*
  O método splitBlocos é responsável por fazer split de um bloco na grelha,
  tendo em conta o numero que esta guardado na variavel mergeCounth, ou na
  variavel mergeCountv. Apartir do bloco que é dado é realizado o split caso 
  uma ou as duas variaveis mergeCounth e mergeCountv seja maior do que 1 dividindo 
  o bloco por blocos mais pequenos com o tamanho original, é a atualizada a lista com
  os novos blocos.
  */

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

  /*
  O método mergeBlocos é responsável por fazer merge de dois blocos adjacentes 
  na grelha. Ele recebe dois objetos do tipo Bloco como parâmetros. 
  Primeiro, obtém os índices das linhas e das colunas dos blocos
  na grelha usando os métodos indexWhere e indexOf. Em seguida, verifica se 
  os índices são válidos (diferentes de -1) para garantir que os blocos estão
  presentes na grelha. Se os blocos estiverem na mesma linha 
  (indiceLinha1 == indiceLinha2), eles são merged ajustando a largura e 
  concatenando os atributos nome, info e formula. O primeiro bloco é 
  atualizado com a largura e o nome merged, e o segundo bloco é removido 
  da linha. Se os blocos estiverem em linhas diferentes, eles são merged 
  ajustando a altura. Um novo bloco é criado com a altura dos blocos merged
  e a largura do primeiro bloco. Os blocos originais são removidos e o novo 
  bloco é inserido na linha superior. Em seguida, as linhas restantes são
  deslocadas para baixo ajustando a altura dos blocos subsequentes.
  No final do método, os blocos selecionados são redefinidos para por a flag
  que indica que estão selecionados a false.
  */

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
        if (bloco1.altura == bloco2.altura) {
          final nomeMerged = '${bloco1.nome}${bloco2.nome}';
          final infoMerged = '${bloco1.info}${bloco2.info}';
          final formulaMerged = '${bloco1.formula}${bloco2.formula}';
          final larguraFundida = bloco1.largura + bloco2.largura;

          bloco1.largura = larguraFundida;
          bloco1.nome = nomeMerged;
          bloco1.info = infoMerged;
          bloco1.formula = formulaMerged;
          bloco1.mergeCounth++;
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
          blocoMerged.mergeCountv++;
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

  /* 
  O método selecionarBloco é chamado quando um bloco é pressionado 
  longamente. Ele recebe um objeto Bloco como parâmetro. Se já houver um 
  bloco selecionado (blocoSelecionado != null), verifica se é o mesmo bloco. 
  Se for o mesmo bloco, ele retorna a flag de selecionado para false. Caso contrário, os blocos são 
  merged chamando o método mergeBlocos e o estado é atualizado usando o 
  método setState. Se não houver um bloco selecionado, o bloco tocado é marcado
  como selecionado e atribuído à variável blocoSelecionado. 
  */

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

  /*
  O método construirgrelha retorna um widget que constrói a interface da grelha. 
  Ele usa os widgets SingleChildScrollView, Column, Row, GestureDetector, 
  Container e Text para criar a estrutura da grelha. A grelha é construída 
  usando os dados da lista bidimensional grelha. Para cada linha na grelha,
  um widget Row é criado, que contém uma lista de widgets Container, 
  representando os blocos. Cada bloco é envolvido em um GestureDetector 
  para detectar toques e pressionamentos longos. Quando um bloco é tocado, 
  uma dialog box que contem os detalhes do slot é exibida chamando o widget 
  DetalhesProdutoDialog. O estado é atualizado após a diolog box ser fechada. 
  Os atributos do bloco são usados para configurar o estilo e o conteúdo dos widgets 
  Text exibidos dentro do bloco.
  */

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
                  builder: (context) => const HomeMenu(),
                ),
              );
            },
            child: const Text('Terminar'),
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
