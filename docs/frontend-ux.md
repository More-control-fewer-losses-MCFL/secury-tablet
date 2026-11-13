# Experiência do frontend Flutter

Revisão de interface dos fluxos SEC-004/SEC-007 e cadastro Google Sheets.
Estado em revisão. Sem alteração de regras de negócio, autenticação ou schema.

## Organização visual

- Azul institucional para ações principais, superfícies claras e bordas suaves.
- Tipografia padrão do Material/SDK, sem pacote de fontes adicional.
- Escala consistente de títulos, textos, espaçamentos e raios de cartão.
- Contraste reforçado nas cores de sucesso, aviso, erro e texto secundário.
- Cartões com altura natural: acomodam quebra de linha e texto ampliado.
- Títulos de seção empilham ações em espaço estreito; ações primárias têm rótulo.

## Navegação e perfis

Desktop: menu lateral com grupos Acompanhar/Gerenciar/Consultar/Sistema.
Celular: drawer que abre por referência ao Scaffold correto; professor também
conta com atalhos inferiores Início/Retirar/Devolver/Histórico. O totem permanece
no menu completo. Não há item selecionado artificialmente quando a rota não
pertence aos atalhos inferiores. O drawer fecha antes de navegar, sem pop da
rota principal em desktop. Estado de conexão tem botão com tooltip e área ampla.

Conta do professor não oferece Configurações. Alerta do administrador abre a
central correta. Guardas do roteador e autorização backend foram preservados.
Sair volta ao login do perfil; nenhuma sessão ou credencial foi incorporada ao UI.

## Fluxos principais

- Login: formulário vem primeiro no celular, sem um banner alto antes dos campos;
  senha tem mostrar/ocultar e preenchimento assistido. Instruções de terminal
  ficam próximas da ação; a explicação completa do RFID continua disponível.
- Professor: saldo disponível em destaque, retirada/devolução fáceis de localizar,
  histórico próprio legível e instruções sobre solicitação/conferência/confirmação.
- Totem: ações com ícones, descrição e altura mínima, adaptadas a largura/texto.
- Retirada: disponibilidade e formulário agrupados, botão principal amplo e
  contadores corretos quando a API omite os detalhes de patrimônio do professor.
  `tablets: []` não significa falta de estoque quando `available > 0`.
- Devolução: cada solicitação tem cartão, contadores e ação próprios. Confirmação
  e pendências permanecem no backend; não apresentar comando como confirmação.
- Administrador: métricas reais, destaque para ocorrências e devoluções,
  movimentações recentes (sem chamá-las de futuras), atalhos de gestão.
- Professores: consulta individual primeiro; sincronização da planilha em seção
  separada e secundária, com confirmação existente preservada.

## Ilustrações, acessibilidade e desempenho

Reutiliza LockerIllustration/BrandMark e ícones Material. A ilustração do armário
fica em área própria com descrição semântica, acompanhando o fluxo operacional;
no celular, orientações compactas substituem o painel alto. Não há imagens de
rede, nova biblioteca de assets ou efeitos de desfoque pesados.

Títulos semânticos, mensagens de erro anunciáveis, rótulos além das cores,
controles do tema com área mínima de 48px e teste de contraste >=4.5:1 nos textos
de status sobre seus fundos. Não limita a escala de texto do sistema.
A presença de ícones não substitui rótulos de operação. Verificação com leitor
de tela real e navegação assistiva manual continuam pendentes.

## Aceitação e evidências

Cenários automatizados: login em 360px com texto 1,5x; drawer do professor;
Retirar/Devolver pela navegação inferior; saldo com patrimônio omitido; diálogo
de devolução cancelado; painel/alertas/consulta/sincronização administrativa em
360px e 1440px com texto ampliado. Cancelar não envia POST de negócio.

Flutter Analyze sem problemas, 17 testes aprovados e Build Web concluído em
Docker com Flutter 3.47.8. Três prévias renderizadas (login móvel, professor móvel
e administrador desktop) foram inspecionadas com dados fictícios e fonte do SDK. Screenshots temporários usam dados fictícios,
não são adicionados ao Git. Nenhum teste real de hardware, importação de cadastro
ou alteração em banco foi executado por esta revisão de interface.

Revisão visual: commit a07204f; PR [#13](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/13) em rascunho sobre feat/google-sheets-professor-sync (dependência PR #12). Runtime local atualizado; CI remoto e aceite assistivo manual pendentes. Sem merge.
