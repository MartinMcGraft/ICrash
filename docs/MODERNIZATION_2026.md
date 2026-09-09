# I-Crash — atualização técnica, 8 setembro 2026

## Resultado
Atualização de ferramentas e compatibilidade concluída com compilações Web, Android debug e Windows release bem-sucedidas. Não foi iniciada a migração para Firebase nem alterado o modelo funcional da base de dados.

## Recuperação
Backup anterior às alterações: C:\Users\Pedro Jorge\Documents\projeto icrash\backup-before-update-20260907.
O Flutter antigo e o Android SDK antigo foram preservados. O projeto não tinha repositório Git.

## Ambiente
- Flutter 3.47.2 / Dart 3.13.2, em C:\Flutter\stable.
- Android Studio 2026.1.4.7; JDK integrado 25.0.3.
- Android SDK em C:\Android\Sdk; API/build-tools 36; platform-tools 37.0.1; emulator 37.1.11; NDK 28.2.13676358; cmdline-tools 23.
- Emulador ICrash_API_36, Android 16, disponível.
- PATH, JAVA_HOME e ANDROID_HOME atualizados no ambiente do utilizador. Reabrir terminais e IDE para os herdarem.
- JDK_JAVA_OPTIONS aponta jdk.net.unixdomain.tmpdir para C:/Flutter/socket-temp, corrigindo a falha de ligação local do Gradle neste Windows.
- Visual Studio 2022 continua em 17.5. A atualização para 17.14.39 terminou com código 1602; o registo indica cancelamento da autorização UAC. A versão instalada conseguiu compilar o projeto Windows.

## Alterações por módulo
- pubspec.yaml / pubspec.lock: SDK e dependências atualizados; qr_code_scanner substituído por mobile_scanner 7.4.0.
- lib/: adaptação do leitor QR, APIs atuais de navegação, verificações de montagem após operações assíncronas, debugPrint e compatibilidade com image 4; correções do analisador e formatação.
- android/: configuração moderna de plugins, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java alvo 17, permissões de câmara/rede e localização dos SDKs.
- web/index.html: inicialização Flutter atual.
- ios/: mínimo 15.5 exigido pelos plugins ML Kit, Podfile e descrição da permissão de câmara.
- macos/: mínimo 12.0, Podfile e permissões de câmara/rede.
- windows/flutter/CMakeLists.txt: migração automática do Flutter durante a compilação.
- test/widget_test.dart: teste da página inicial real.

## Validação
- flutter analyze --no-pub: sem problemas.
- flutter test --no-pub: 1 teste aprovado.
- flutter build web --no-pub: sucesso; página inicial e formulário de registo abertos no navegador sem erros de consola.
- flutter build apk --debug --no-pub: sucesso. APK em build/app/outputs/flutter-apk/app-debug.apk.
- APK instalado no emulator-5554; página inicial observada. Primeiro arranque excedeu o tempo de espera e o Android mostrou “System UI isn't responding”; segunda invocação terminou Status: ok, aplicação já em primeiro plano. Não constitui validação de desempenho nem teste integral do scanner.
- flutter build windows --no-pub: sucesso. Executável e ficheiros necessários em build/windows/x64/runner/Release. Processo iniciado e observado Responding=True; interação gráfica Windows não validada.
- Diagnóstico final: ferramentas, Windows, navegador, dispositivos e rede reconhecidos. Única categoria com aviso: estado de licenças Android desconhecido. sdkmanager 23 encaminha para a nova Android CLI, que devolve que --licenses já não é necessário. Ficheiros de licença preservados; compilação Android passou. Não foi manipulado o diagnóstico para ocultar este aviso.
- iOS, macOS e Linux não compilados nesta máquina Windows.

## Limitações e próxima fase
- mobile_scanner ainda usa o plugin Gradle Kotlin antigo; flags de compatibilidade mantidas. O build avisa sobre versões futuras do Flutter. Reavaliar quando o fornecedor migrar.
- Scanner nativo Windows/Linux não suportado pelo plugin; a aplicação informa essa limitação. Câmara física e leitura de códigos por validar.
- Backend continua a apontar para o servidor HTTP local antigo. Persistência, autenticação e fluxos completos não foram validados.
- Assinatura Android release permanece de desenvolvimento; identificador com.example.app1 mantém-se. Não é uma distribuição comercial pronta.
- Decisões seguintes: confirmar requisitos funcionais, utilização sem rede, instituições/utilizadores e modelo relacional pretendido; só depois definir serviços Firebase e implementação. Não foram criados serviços cloud nem custos.

Registos locais: update-android-build.log, update-windows-build.log, update-doctor-final.log.
