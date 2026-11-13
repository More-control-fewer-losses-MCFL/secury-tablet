# ADR 0002 — Credencial individual opcional para professor

Data: 2026-11-13. Decisão autorizada pelo pedido explícito do usuário:
“crie um login de professor com usuario e senha”. Implementação em revisão.
Complementa ADR 0001, cujo mecanismo RFID supervisionado continua válido.

Contexto: professores precisam entrar por credencial própria além do crachá.
Não usar o domínio administrativo, UID, campo de planilha ou controle visual como
prova de identidade. Preservar monólito modular, MySQL/Alembic e interfaces existentes.

Decisão: credencial opcional vinculada a cadastro existente e ativo. Somente admin
cria/redefine usuário/senha; username normalizado/único e hash scrypt salted em tabela
própria. Utilizar configuração OWASP equivalente de 16 MiB (N=2^14, r=8, p=5) por
hashlib, sem dependência nova. Senhas nunca trafegam em respostas ou arquivos Web.
Fonte: [OWASP Password Storage](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#scrypt).

Sessão curta assinada com role professor, identidade do cadastro, método password
e revisão da credencial. Revalidar cadastro e revisão em cada operação; redefinir
revoga sessões por senha. A senha permite login sem preparação administrativa do
terminal; o fluxo RFID mantém exigência de terminal autorizado, sem autenticação
forte do portador. Login e permissões administrativas/controlador permanecem separados.
Retirada por senha resolve o proprietário no servidor; não expõe UID ao navegador.

Alternativas: compartilhar senha administrativa (rejeitada); senha fixa no Flutter
(rejeitada); exigir senha adicional a todo RFID (não solicitado); provedor institucional
(fora deste pedido); dependência Argon2id (não adotada neste incremento, scrypt já
está disponível no runtime padrão). Não cria autocadastro ou recuperação automática.

Consequências: Alembic 0004 adiciona tabela opcional sem migrar ou exigir senha de
professores existentes. Administração passa a gerenciar credenciais e pode revogar
sessões por redefinição; deativar cadastro bloqueia ambos os métodos. Interface verde
própria de professor. Nginx aplica limitação do login existente e validação de API não
ecoa inputs. Hardware permanece simulado; nenhum domínio/HTTPS/deploy é aprovado
implicitamente. Uso fora de loopback exige a revisão operacional já prevista no projeto.

Evidências e limitações: docs/professor-password-login.md. Decisão do mecanismo foi
solicitada pelo usuário; CI, revisão técnica e aceite assistivo continuam pendentes.
