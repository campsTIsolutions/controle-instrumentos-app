# Guia de Contribuição — Controle de Instrumentos

Este documento define as regras de organização, desenvolvimento e colaboração do projeto.

O objetivo é manter o código limpo, organizado e evitar conflitos entre os membros da equipe.

---

# 1. Estrutura do Projeto

Estrutura principal:

lib/
  core/
  features/
  app.dart
  main.dart

database/

---

## lib/core/

Contém código global do sistema.

Exemplos:
- Configuração do Supabase
- Rotas
- Widgets reutilizáveis
- Constantes
- Utilitários

Responsáveis:
- Arquitetura e integração: Murilo
- UI global e tema: Rodrigo

⚠️ Não alterar o core sem Pull Request e alinhamento.

---

## lib/features/

Cada pasta representa um módulo independente do sistema.

### auth/
Responsável: Guilherme

Contém:
- Login
- Sessão
- Permissões

---

### instrumentos/
Responsável: Letícia

Contém:
- CRUD de instrumentos
- Busca
- Filtro

---

### chamada/
Responsável: Dennis

Contém:
- Presença
- Frequência

---

## database/

Responsável: Leandro

Contém:
- schema.sql
- rls_policies.sql

⚠️ Ninguém altera o banco sem aprovação do responsável.

---

# 2. Padrões de Nomeação

## 2.1 Arquivos e Pastas — snake_case

snake_case significa:
- Letras minúsculas
- Palavras separadas por underline (_)

Exemplos corretos:

login_page.dart  
auth_repository.dart  
instrument_repository.dart  

Exemplos incorretos:

LoginPage.dart  
loginPage.dart  

---

## 2.2 Classes — PascalCase

PascalCase significa:
- Primeira letra de cada palavra maiúscula
- Sem underline

Exemplos:

LoginPage  
AuthRepository  
ChamadaController  

---

## 2.3 Variáveis e Funções — camelCase

camelCase significa:
- Primeira palavra minúscula
- Próximas palavras com inicial maiúscula

Exemplos:

fetchInstrumentos()  
signInUser()  
selectedCategoria  

---

# 3. Como Trabalhar com Git

## 3.1 Nunca trabalhar diretamente na main

Sempre criar uma nova branch:

git checkout -b feature/nome-da-feature

Exemplos:

feature/login  
feature/estoque  
feature/chamada  

---

## 3.2 Commits Pequenos

Um commit deve representar UMA alteração clara.

Exemplo bom:

feat(auth): cria tela de login

Exemplo ruim:

fiz tudo  
finalizei app  

---

## 3.3 Prefixos de Commit

feat — nova funcionalidade  
fix — correção de erro  
refactor — melhoria interna sem alterar comportamento  
docs — alteração de documentação  
chore — ajustes técnicos  

---

# 4. Pull Request

Todo código deve entrar na main via Pull Request.

Antes de abrir um PR:

- Verificar se o projeto compila
- Testar a funcionalidade implementada
- Remover prints de debug
- Garantir que não quebrou outra parte do sistema

O PR deve explicar:

- O que foi feito
- Como testar

---

# 5. Regras Importantes

- Não alterar módulo de outro integrante sem alinhar.
- Não alterar banco sem aprovação do responsável.
- Não adicionar dependência sem discutir com o time.
- Não alterar arquitetura sem consenso.

---

# 6. Ordem Inicial de Desenvolvimento

1. Configuração do Supabase
2. Implementação do Login
3. CRUD de Instrumentos
4. Sistema de Chamada
5. Ajustes finais de UI

---

Seguindo essas regras, mantemos o projeto organizado, escalável e colaborativo.
