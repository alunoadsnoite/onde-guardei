# Onde Guardei?

Aplicativo Android para encontrar objetos guardados em casa. Cadastre uma foto, um
nome ou ambos e informe onde o objeto está: quarto → armário → caixa, por exemplo.

## Recursos

- Cadastro e edição de objetos com fotos, observações e palavras-chave.
- Locais organizados dentro de outros locais.
- Busca sem distinção de acentos, inclusive pelo caminho do local.
- Ação **Mudei de lugar**, com histórico das mudanças.
- Rascunho para continuar um cadastro depois.
- Exportação e restauração de backup com as fotos incluídas.
- Filtro de local com chip explícito e limpeza de fotos órfãs.

Os dados ficam no aparelho. Não há conta, anúncios, rastreamento, reconhecimento
automático de imagens ou serviço de nuvem. Faça backups antes de desinstalar:
a desinstalação remove os dados privados do aplicativo.

## Desenvolvimento

Flutter 3.47.7 / Dart 3.13.5. A revisão do SDK está em `.flutter-version`. Java 17,
Android SDK e NDK 28.2.13676358 são necessários para compilar.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

O APK de teste é gerado em `build/app/outputs/flutter-apk/app-release.apk`. O
caminho `dist/` fica fora do controle de versão.

## Organização

- `lib/domain/`: modelos de dados (`models.dart`) e repositório de persistência
  (`repository.dart`).
- `lib/ui/`: telas e componentes de interface (`app.dart`, `home.dart`,
  `editing.dart`, `widgets.dart`, `helpers.dart`).
- `lib/main.dart`: ponto de entrada do aplicativo.
- `android/`: integração Android, seletor de arquivos e ícone.
- `test/`: testes automatizados.
- `docs/`: privacidade e roteiro de teste no aparelho.
- `dist/`: APKs locais, fora do controle de versão.

## Backup

Em **Backup e informações**, exporte o arquivo para uma pasta escolhida. A
restauração substitui os cadastros atuais após confirmação. Nesta versão cada
foto pode ter até 15 MiB, o conjunto de fotos exportadas até 70 MiB e o arquivo
importado até 100 MiB. O aplicativo mantém também uma versão anterior do catálogo
para recuperação de falhas de leitura; isso não substitui um backup externo.

Licença MIT. Bibliotecas de terceiros mantêm suas respectivas licenças,
disponíveis também em **Licenças** no aplicativo.
