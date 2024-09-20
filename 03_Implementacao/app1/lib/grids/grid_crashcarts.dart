import 'package:flutter/material.dart';

import 'package:app1/registration/reg_drawers.dart';
import 'package:app1/request_handler/request_handler.dart';

/*

Aqui, é declarada a classe Grid que é uma subclasse de StatelessWidget. Esta classe tem dois atributos, 
numberOfBlocks (número de blocos) e inst (instrução). O construtor da classe recebe estes dois atributos 
como parâmetros, sendo obrigatórios (required).

*/

class GridCrashCarts extends StatelessWidget {
  final int numCCs;
  final String inst;
  final RequestHandler handler;

  const GridCrashCarts(
      {super.key, required this.numCCs,
      required this.inst,
      required String descr,
      required this.handler});

/*

A função build é onde ocorre a construção do widget da classe Grid.

A primeira linha obtém a altura da tela usando o MediaQuery.
Em seguida, é calculado o tamanho de cada bloco (blockSize) dividindo a altura da tela por 10.
spacing é a variável que define o espaçamento entre os blocos.
A função build retorna um Scaffold, que é um widget que fornece uma estrutura básica para as páginas do aplicativo.
No appBar do Scaffold, é definido um AppBar com um título (Text(inst)), 
onde inst é a string passada como parâmetro no construtor.
O corpo (body) do Scaffold é definido como um GridView.builder, que é um widget do Flutter que 
permite construir uma grelha (grid) com base em uma lista de itens. Neste caso, a quantidade de blocos 
é definida pelo atributo numberOfBlocks, e a implementação de cada bloco é definida pela função itemBuilder.
O gridDelegate define a configuração da grelha, neste caso, é uma grelha com 10 colunas (crossAxisCount: 10),
e as proporções entre largura e altura dos blocos são iguais (childAspectRatio: 1). Também são definidos 
espaçamentos entre as colunas e as linhas (mainAxisSpacing e crossAxisSpacing).
A função itemBuilder é chamada para cada bloco na grelha e retorna um GestureDetector, que permite detectar
gestos como toques. Quando um bloco é tocado, é feito um push para uma nova rota, utilizando o Navigator,
que provavelmente leva a outra página ou tela do aplicativo. O número do bloco é passado como parâmetro para a rota.
Cada bloco é representado por um Container com uma cor de fundo azul (color: Colors.blue). Dentro do Container, 
há um Center que centraliza o conteúdo, e dentro do Center, há um Text que mostra a string 'Carro' seguida pelo 
número do bloco ('Carro ${index + 1}'). O estilo do texto é definido com uma cor branca (color: Colors.white) 
e um peso de fonte em negrito (fontWeight: FontWeight.bold).

*/
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double blockSize = screenHeight / 10;
    double spacing = 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(inst),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          childAspectRatio: 1,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
        ),
        itemCount: numCCs,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RegDrawers(blockNumber: index, handler: handler),
                ),
              );
            },
            child: Container(
              width: blockSize - spacing,
              height: blockSize - spacing,
              color: Colors.blue,
              child: Center(
                child: Text(
                  'CrashCart ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
