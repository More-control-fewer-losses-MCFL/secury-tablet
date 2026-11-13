# Acesso de professor por usuário e senha

Pedido explícito do usuário em 2026-11-13. SEC-004: adicionar credencial individual
sem substituir RFID/terminal supervisionado ou conceder privilégios administrativos.
Branch feat/professor-password-login, base e08b5b1 (PR #14); estado em revisão.

Escopo: credencial vinculada ao professor no MySQL via Alembic; cadastro/redefinição
somente pela administração; hash com salt; login/sessão curta de professor no backend;
formulário Flutter próprio em verde; crachá permanece opcional. Para a retirada por
senha, o backend identifica o cadastro pela sessão e não solicita/exibe UID ao navegador.
Conta de demonstração criada somente em runtime local isolado com hardware simulado.

Critérios BDD:
- Dado professor ativo com credencial, usuário/senha válidos abrem apenas o seu portal.
- Senha incorreta, usuário desconhecido ou cadastro inativo não criam sessão.
- Visitante/professor não criam/redefinem credenciais nem acessam dados administrativos.
- Professor por senha consulta somente seu histórico e opera apenas em seu nome.
- Redefinir senha ou desativar o cadastro invalida o uso de sessões anteriores.
- Hash/senha não aparecem em respostas de API, validação, Flutter Web ou logs.
- Acesso RFID continua exigindo autorização do terminal e preserva permissões existentes.
- Login funciona em celular/texto ampliado; admin mantém seu formulário separado.

Validação planejada: unitários de autenticação/autorização e regressões Python;
Ruff/formatação; migrações e integração em MySQL novo/isolado com sufixo _test e
credenciais exclusivas; Flutter analyze/test/build Web; smoke do login demonstrativo.
Nenhuma senha real será versionada. CI e PR serão referenciados ao publicar.

## Uso

Acesso: http://localhost:8082/#/professor/login. Também há “Entrar como professor”
no login administrativo e “Entrar com usuário e senha” no leitor de crachá.
No ambiente demonstrativo isolado, usuário `professor.demo`, associado à Professora
Ana (demo), matrícula DEMO-001. Senha gerada e guardada em arquivo privado no perfil
do usuário, fora do repositório; não existe senha padrão ou bypass no código.
O banco/API anteriores não foram migrados ou substituídos. Apenas a prévia 8082
aponta para o novo runtime e banco `secury_professor_demo_test`.

Administrador: Professores → localizar cadastro → Configurar usuário e senha.
Salvar cria ou redefine a credencial e revoga sessões anteriores por senha.
O usuário aceita 3–80 caracteres ASCII (letras, números, ponto, _ e -), sem distinguir
maiúsculas. A senha preserva caracteres/espaços e aceita 12–256 caracteres.
Não há autocadastro ou recuperação automática; a administração redefine o acesso.
Planilha de professores não recebe senhas e não cria credenciais individuais.

## Contrato e persistência

- POST /auth/professor/login: username/password, sessão de professor, padrão 10 minutos.
- GET /auth/professor/session: identidade autenticada, sem UID/hash/senha.
- POST /admin/professors/{id}/credentials: somente administrador, resposta professor_id/username.
- Migração 0004 cria professor_credentials (FK/PK por professor, username único,
  hash, revisão de revogação e updated_at); não modifica cadastros existentes.
- Senha usa scrypt N=16384/r=8/p=5, salt aleatório de 16 bytes, digest de 32 bytes,
  comparação constante. Configuração equivalente de 16 MiB documentada pela
  [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#scrypt).
  Implementação utiliza [hashlib.scrypt](https://docs.python.org/3.12/library/hashlib.html#hashlib.scrypt).
- Token por senha não depende de autorização do terminal; token RFID continua
  vinculado ao cookie/registro do terminal. Cadastro ativo sempre revalidado.
- Redefinição muda revisão e invalida tokens anteriores por senha. Desativação
  bloqueia ambos os acessos. Privilégios administrativos/controlador não se confundem.
- Retirada do professor pode omitir badge_uid: backend resolve do principal e rejeita
  crachá de terceiro. Administração continua obrigada a informar o crachá do alvo.
- Erros de validação não refletem o input de requisição; credenciais inválidas/inativas
  retornam a mesma mensagem. Nginx limita login por senha na zona já existente.

## Validação desta entrega

130 testes unitários Python aprovados; Ruff check/format e git diff --check aprovados.
28 integrações MySQL aprovadas em contêiner novo e banco secury_professor_auth_test,
com credenciais exclusivas, incluindo Alembic 0004, FK, unicidade e persistência/reset
entre conexões. Nunca usar esses testes destrutivos em banco de desenvolvimento.
Flutter 3.47.8: analyze sem problemas, 24 testes e build Web release aprovados.
Cobrem login válido/inválido, verificação de identidade, ausência de UID na retirada,
configuração administrativa, responsive 360px/texto1,5x e regressão RFID/perfis.
Capturas Chrome desktop/móvel conferidas. Smoke real via Nginx: login e sessão 200,
senha errada 401, inventário e sessão administrativa bloqueados ao professor.
Nenhuma retirada real executada; testes de operações usam hardware simulado.
Aviso Starlette/httpx preexistente nos testes Python permanece.

CI remoto e aceite assistivo/manual completos pendentes; sem merge ou produção.
Referência de decisão: ADR 0002. Esta decisão complementa o RFID do ADR 0001,
conforme o novo pedido explícito do usuário.
