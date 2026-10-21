# Changelog

Todas as alterações significativas deste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e o projeto segue [SemVer](https://semver.org/lang/pt-BR/).

## [0.3.0] — 2026-10-21

### Corrigido
- O texto da busca não era apagado da tela quando você escolhia um local como
  filtro: a lista passava a mostrar tudo, mas a caixa de busca continuava com o
  texto antigo.
- Fotos órfãs ficavam ocupando espaço no aparelho. Agora são apagadas quando o
  cadastro é excluído, quando a foto é trocada ou removida e quando um backup é
  restaurado. A foto do rascunho em andamento nunca é apagada.
- Salvar o rascunho três vezes seguidas (por exemplo, ao mandar o app para
  segundo plano) disputava o mesmo arquivo temporário e podia perder o
  rascunho. As gravações do rascunho agora são uma fila.
- O listener de ciclo de vida do editor nunca era registrado, então o rascunho
  não era guardado quando o app ia para segundo plano.
- Mensagens de erro ruins: arquivo de backup corrompido, foto que sumiu do
  aparelho e backup sem alguma das fotos agora explicam o que aconteceu em
  português claro.
- O caminho de um local apagado aparecia em branco; agora aparece
  "Local desconhecido".
- A verificação de CI falhava porque o código não estava no formato aceito pelo
  `dart format` atual.

### Adicionado
- Botão para limpar a busca e aviso de recuperação que pode ser dispensado.
- Rascunho salvo automaticamente quando o aplicativo vai para segundo plano.
- O backup avisa quantas fotos ficaram de fora quando alguma não está mais no
  aparelho.
- Limpeza automática de backups temporários que ficaram na pasta do catálogo
  depois de uma exportação interrompida.

### Melhorado
- Fotos são decodificadas em tamanho menor nas miniaturas, o que economiza
  memória e deixa a lista mais leve em aparelhos modestos.
- Busca, contagem de objetos por local e ordenação dos locais ficaram mais
  rápidas em catálogos grandes, com um índice de locais em memória.
- Os locais são ordenados pela hierarquia, sem diferenciar acentos ou caixa,
  de forma igual em todas as telas.
- A busca agora entende mais acentos e caracteres (ç, ñ, ý, ã, ø, ã) e a
  versão do aplicativo tem um único lugar de verdade.
- Testes automatizados novos para limpeza de fotos, backup incompleto, backup
  corrompido, limpeza da busca, rascunho em segundo plano, acentos, contagem e
  ordenação de locais (20 testes no total).

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
