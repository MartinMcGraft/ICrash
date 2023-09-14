# ICrash
Projecto final da Licenciatura em Engenharia Informática e Multimédia - ISEL

Requisitos de instalação do projeto:

O seguinte ficheiro detalha:
Requesitos backend:
	- Sistema operativo compatível (Windows 11, por exemplo):
	- Instalar Python 3
	- Instalar Django
	- Instalar REST framework
	- Instalar PostgreSQL
Requesitos frontend:
	- Sistema operativo compatível (Windows 11 e Android 13, por exemplo):
	- Instalar Flutter
	- Instalar Android Studio
Requesitos do Visual Studio Code (VSCode):
	- Python 3
	- Flutter
	- Dart
	- Windows CMake tools
	- PostgreSQL

-- Instruções de instalação do sistema de gestão de base de dados --
Download e instalação do programa PostgreSQL, sequir os passos do site.
A escolha de NAME, USER, PASSWORD, HOST e PORT são da preferência do utilizador, aconcelha-se
a trocar apenas a PASSWORD e possívelmente o NOME.
Abrir terminal psql
No terminal psql,
- Entrar no sistema de gestão de base de dados,
- Criar uma nova base de dados, exemplo com o NOME prj11:
	CREATE DATABASE prj11

-- Instruções de instalação do servidor --
O servidor é executado dentro de um ambiente virtual Python.
Assumnindo que o PostreSQL já está instalado e a base de dados criada, bem como os restantes
programas
- Após a validação dos requesitos, copiar a pasta server
- Abrir o ficheiro server/server/settings.py num editor compatível (VSCode, por exemplo)
- Adicionar o host para o da máquina onde o servidor será executado em:
	server/server/settings.py, linha 29 em ALLOWED_HOSTS
	- para obter o host, na consola de comandos correr ipconfig e procurar o IPv4
- Verificar se a referência há base de dados está correta em:
	server/server/settings.py, linha 83 em DATABASES
	NAME, USER, PASSWORD, HOST e PORT devem ser os mesmos do sistema de gestão de base de
dados
- Abrir a consola de comandos ou um terminar na diretoria \server
- Migrar os modelos para o sistema de gestão de base de dados - Executar o comando:
	python manage.py migrate

-- Instruções de instalação da aplicação gráfica --
No Android Studio instalar o mais recente System Development Kit.
Abrir um editor compatível (VSCode, por exemplo),
- Criar um novo projeto flutter com um nome sugestivo (icrash, por exemplo)
- Copiar a pasta lib do projeto e substituir a existente no novo projeto criado
- No ficheiro pubspec.yaml, adicionar as dependências das bilbiotecas http e qr_code_scanner
	- https://pub.dev/packages/http
	- https://pub.dev/packages/qr_code_scanner
- No ficheiro lib/request_handler/requst_handler.dart, linha 17 e 18,
	- Definir o host igual ao da máquina onde está o servidor
	- Definir o port igual ao da máquina onde está o servidor
