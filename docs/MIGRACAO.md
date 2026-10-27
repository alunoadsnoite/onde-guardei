# Atualização e migração

Verificado em 27/10/2026. O identificador permanece `br.com.valdenor.ondeguardei`.

## Canal estável

A 0.3.1 estável usa o mesmo certificado da release 0.2.0:
`7a12dd994b7a0b308a21dcb99a545f4f5b51a227bef05a00fb601716b0101b81` (SHA-256).
A chave histórica foi preservada em uma cópia privada protegida; nenhum segredo é publicado.

No Motorola Edge 70 Fusion / Android 17, a instalação vazia recebeu o APK público 0.2.0. Um objeto fictício com imagem artificial foi criado pela interface e exportado pelo seletor Android. A instalação da 0.3.1 estável por cima passou, sem desinstalação ou limpeza. O objeto continuou visível e os backups antes/depois foram integralmente iguais, incluindo os bytes da foto. A versão instalada foi confirmada como 0.3.1 / 3. O objeto e os arquivos fictícios foram removidos depois; o app permaneceu instalado.

O APK estável 0.3.1 mantém o conteúdo do APK 0.3.1-preview do commit `b5256a393bd4af0a87f8878ef90edb967bd77e41`; os arquivos internos foram comparados, excluindo apenas as assinaturas. Apenas a assinatura de distribuição foi substituída para preservar o canal estável. Os resultados não comprovam todos os catálogos nem todos os aparelhos.

## Prévias e versões com outra assinatura

O certificado da prévia 0.3.1 é
`0f77605b4e3a37ebe42ecff4f91d477f3b5096a7e4f511cdc089ba405328975c`.
O Android recusa atualização direta entre esses certificados.

1. Na instalação antiga, use **Backup e informações → Criar backup com fotos** e guarde o arquivo fora do app.
2. Confira que a exportação terminou e mantenha uma cópia do arquivo. Se o app avisar sobre foto ausente, corrija a referência antes de continuar.
3. Preserve a instalação antiga enquanto não tiver um backup válido. Não use desinstalação como tentativa de correção.
4. Ao optar pela troca de canal, instale o APK estável e use **Restaurar backup**. A restauração substitui o catálogo existente no destino após confirmação.

A atualização de uma instalação 0.1.0 não foi validada nesta rodada. Não se presume que seu certificado corresponda ao da 0.2.0. Se o Android recusar, preserve os dados e use o caminho de backup compatível; não há recuperação automática de dados já apagados por desinstalação.
