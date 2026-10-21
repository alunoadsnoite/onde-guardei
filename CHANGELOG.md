# Changelog

Todas as alterações significativas deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e o projeto segue [SemVer](https://semver.org/lang/pt-BR/).

## [0.2.0] — 2026-10-21

### Adicionado
- Arquitetura reorganizada: código separado em `domain/` (models e repositório) e
  `ui/` (telas, helpers e widgets), facilitando manutenção e testes.
- Verificação de `minSdk` e documentação clara da compatibilidade com Android 7+.
- Limpeza de fotos órfâneas: ao excluir um item, a imagem não fica presa no disco
  quando nenhum outro cadastro a referenciar.
- Cadastro de rascunho aprimorado e tela de "continuar cadastro não salvo".
- Bye, no About, a versão do aplicativo é exibida de forma consistente.

### Melhorado
- Tela de busca agora mostra o filtro de local ativo e permite limpá-lo com um
  clique, melhorando a clareza ao buscar por objetos em um cômodo específico.
- Tela de detalhe do objeto com ação "Mudei de lugar" e histórico de mudanças.
- Tela de seleção de local (PlacePicker) com breadcrumb visual e busca.
- Docs atualizados com o novo fluxo de testes no aparelho e os passos de publicação.

### Corrigido
- Workflow de publicação de APK de teste (`publish-preview.yml`) Corrigido para
  publicar a partir da execução correta do workflow de verificações, e não de um
  run-id fixo.
- Atualização das dependências para as versões estáveis mais recentes
  (`image_picker: 1.2.4`, `flutter_lints: 6.0.0`).
- Atualização dos testes automáticos para cobrir o rascunho, movimentos duplicados,
  exclusão de item com foto, backup com fotos repetidas e o fluxo de widget de
  edição de objeto.

### Cruzado
- Todos os testes automatizados passam (`flutter test`).
- `flutter analyze` e `flutter format` não relatam erros.

## [0.1.0] — 2026-10-21

- Versão inicial do aplicativo.
- Catálogo offline de objetos e locais com fotos, busca por palavras-chave e
  palavras, organização em árvore de locais, histórico de "Mudei de lugar",
  rascunho de cadastro e backup com fotos.
- 10 testes automatizados, CI com análise, teste e compilação de release.
