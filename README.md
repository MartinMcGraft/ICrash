#I-Crash
Projeto de Licenciatura em Engenharia Informaática e Multimédia - ISEL
Alunos:
- Martim Pinheiro Alves, n46286
- Pedro Jorge, n47498


O seguinte ficheiro detalha:
Requesitos backend:
	- Sistema operativo compatível (Windows 11, por exemplo):
	- Python 3
	- Django
	- REST framework
	- PostgreSQL
Requesitos frontend:
	- Sistema operativo compatível (Windows 11 e Android 13, por exemplo):
	- Flutter
	- Android Studio
Requesitos do Visual Studio Code (VSCode):
	- Python 3
	- Flutter
	- Dart
	- Windows CMake tools
	- PostgreSQL


Aconselha-se o seguinte sistema de pastas:
prj_11_i_crash (nome sugestivo)
\_app    (nome sugestivo)
\_server (pasta enviada com o projeto)


-- Instruções de instalação do sistema de gestão de base de dados --
1. Download e instalação do programa PostgreSQL, seguir os passos do site
2. A escolha de NAME, USER, PASSWORD, HOST e PORT são da preferência do utilizador, aconcelha-se
	a trocar apenas a PASSWORD e possívelmente o NOME.
3. Abrir SQL Shell (psql)
4. No terminal psql,
4.1 Primir tecla ENTER para Server, Database, Port e Username e no fim colocar a Password préviamnete 	definida,
4.2 Criar uma nova base de dados, exemplo com o NOME prj11:
	CREATE DATABASE prj11
4.3 Sair do terminal:
	\q


-- Instruções de instalação do servidor --
1. O servidor é executado dentro de um ambiente virtual Python.
2. Assumnindo que o PostgreSQL já está instalado e a base de dados criada, bem como os restantes
	programas
3. Após a validação dos requesitos, copiar a pasta server para o ficheiro de pastas aconselhado acima
4. Abrir o ficheiro server/server/settings.py num editor compatível (VSCode, por exemplo)
5. Adicionar o host para o da máquina onde o servidor será executado em:
	server/server/settings.py, linha 29 em ALLOWED_HOSTS
	- para obter o host, na consola de comandos correr ipconfig e procurar o IPv4 Address
6. Verificar se a referência há base de dados está correta em:
	server/server/settings.py, linha 83 em DATABASES
	NAME, USER, PASSWORD, HOST e PORT devem ser os mesmos do sistema de gestão de base de
	dados
7. Abrir a consola de comandos ou um terminar na diretoria \server
8. Migrar os modelos para o sistema de gestão de base de dados - Executar o comando:
	python manage.py migrate


-- Instruções de instalação da aplicação gráfica --
1. No Android Studio instalar o mais recente System Development Kit.
2. Abrir um editor compatível (VSCode, por exemplo),
3. Criar um novo projeto flutter com um nome sugestivo (icrash, por exemplo)
4. Copiar a pasta lib do projeto e substituir a existente no novo projeto criado
5. No ficheiro pubspec.yaml, adicionar as dependências das bilbiotecas http e qr_code_scanner
	na secção dependencies, linha 30
	- https://pub.dev/packages/http
	- https://pub.dev/packages/qr_code_scanner
6. No ficheiro lib/request_handler/requst_handler.dart, linha 17 e 18,
	- Definir o host igual ao da máquina onde está o servidor
	- Definir o port igual ao da máquina onde está o servidor
