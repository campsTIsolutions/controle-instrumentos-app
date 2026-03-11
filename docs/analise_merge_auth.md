# Análise para merge (feature de autenticação)

## Contexto
Esta branch (`work`) já possui fluxo completo de autenticação com:
- tela de login;
- tela de cadastro;
- gate de sessão para decidir entre login e home;
- integração com Supabase Auth e escrita na tabela `usuarios`.

Quando outra branch tiver mudanças parecidas, os conflitos mais prováveis estarão nos mesmos arquivos de auth/UI.

## Arquivos com maior risco de conflito
1. `lib/features/auth/ui/login_page.dart`
   - Estrutura da UI de login, validações e navegação para cadastro.
2. `lib/features/auth/ui/register_page.dart`
   - Fluxo de criação de conta, validações e retorno para login.
3. `lib/features/auth/data/auth_service.dart`
   - Regras de cadastro e insert em `usuarios`.
4. `lib/features/auth/ui/auth_gate.dart`
   - Regras de roteamento por sessão autenticada.
5. `lib/app.dart` e `lib/main.dart`
   - Ponto de entrada e inicialização do Supabase.

## Estratégia recomendada de merge
1. **Escolher uma única fonte de verdade para autenticação**
   - Manter apenas um serviço (`AuthService`) para evitar duplicação de regras de signup/signin.
2. **Priorizar lógica de domínio sobre UI**
   - Primeiro consolidar métodos de auth (`auth_service.dart`), depois ajustar widgets.
3. **Conferir contrato com banco**
   - Garantir que o payload de insert em `usuarios` continue consistente:
     - `id_usuario`
     - `nome_usuario`
     - `login`
     - `tipo_usuario`
4. **Padronizar feedback de erro/sucesso**
   - Evitar mensagens diferentes para o mesmo cenário (ex.: email já cadastrado).
5. **Validar fluxo completo após merge**
   - login válido;
   - login inválido;
   - cadastro novo;
   - cadastro com email existente;
   - logout e retorno ao login.

## Checklist de resolução rápida de conflito
- [ ] Resolver conflitos primeiro em `auth_service.dart`.
- [ ] Revisar imports/navegação entre `login_page.dart` e `register_page.dart`.
- [ ] Confirmar que `AuthGate` continua levando para `HomePage` apenas com sessão ativa.
- [ ] Garantir que `Supabase.initialize(...)` continua sendo chamado uma única vez em `main.dart`.
- [ ] Fazer smoke test manual do fluxo antes de aprovar o merge.

## Observação
Sem Flutter SDK disponível neste ambiente, a validação executável (analyze/test/run) precisa ser feita na máquina/CI com Flutter instalado.
