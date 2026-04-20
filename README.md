# Controle de Instrumentos

Aplicativo Flutter para gestao de:

- instrumentos
- alunos
- chamada/presenca
- historico de exclusoes

Backend: Supabase (Auth, Postgres, Storage).

## Visao Geral

O app inicia validando as chaves do Supabase em tempo de execucao.  
Se existir sessao autenticada, abre em Instrumentos; sem sessao, abre no Login.

Rotas principais:

- `/instrumentos`
- `/alunos`
- `/chamada`
- `/historico`

Arquivo de entrada: [main.dart](/home/murilo/controle_instrumentos/lib/main.dart)

## Tecnologias

- Flutter / Dart
- `supabase_flutter`
- `file_picker`
- `image_picker`

## Estrutura do Projeto

Diretorio base: `lib/`

- `core/`
- `features/`
- `shared/`

Organizacao por feature (padrao):

- `models/`
- `repository/`
- `widgets/`
- `<feature>_page.dart`

## Funcionalidades por Modulo

### Login

- autenticacao por e-mail e senha (Supabase Auth)
- recuperacao de senha
- cadastro de usuario

### Instrumentos

- listar instrumentos
- criar/editar/excluir instrumento
- vincular instrumento a aluno
- upload de imagem do instrumento para storage

### Alunos

- listagem paginada
- busca e filtros
- criacao/edicao/exclusao
- upload de foto do aluno para storage
- ao excluir aluno, registra evento no historico (`logs`)

### Chamada

- gestao de aulas por data
- presenca por aluno (`P`, `A`, `F`)
- persistencia em lote por `upsert`

### Historico

- listagem de logs de exclusao
- filtros e dashboard de motivos
- exclusao de registro do historico

## Configuracao de Ambiente (Obrigatorio)

As chaves **nao** ficam hardcoded no app.  
Passe via `--dart-define`.

Arquivo de configuracao: [supabase_config.dart](/home/murilo/controle_instrumentos/lib/core/config/supabase_config.dart)

Execucao local:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SEU_ANON_KEY
```

Se faltar chave, o app falha no boot com:

- `Supabase nao configurado. Rode com --dart-define...`

## Supabase: Tabelas Utilizadas

O app consulta/grava nas tabelas:

- `alunos`
- `instrumentos`
- `logs`
- `aulas`
- `chamadas`
- `usuarios`

Colunas usadas diretamente no codigo:

- `alunos`: `id_aluno`, `numero_aluno`, `nome_completo`, `setor`, `categoria_usuario`, `nivel`, `telefone`, `imagem_url`, `idade`
- `instrumentos`: `id_instrumento`, `numero_patrimonio`, `nome_instrumento`, `disponivel`, `propriedade_instrumento`, `leva_instrumento`, `observacoes`, `imagem_url`, `id_aluno`
- `logs`: `id_log`, `id_aluno`, `numero_aluno`, `nome_completo`, `setor`, `categoria_usuario`, `nivel`, `telefone`, `imagem_url`, `idade`, `motivo_exclusao`, `data_exclusao`
- `aulas`: `id`, `data`
- `chamadas`: `id`, `aula_id`, `id_aluno`, `status`, `comprovante_url`

## Storage (Bucket e Pastas)

Bucket usado: `alunos-fotos`

Pastas logicas:

- fotos de alunos em `alunos/...`
- imagens de instrumentos em `instrumentos/...`

Configuracao centralizada em: [storage_paths.dart](/home/murilo/controle_instrumentos/lib/core/config/storage_paths.dart)

Importante: no Supabase Storage, pasta e virtual. Ela aparece quando houver arquivo dentro.

## Policies Recomendadas (RLS)

### Tabelas (exemplo basico para `authenticated`)

```sql
alter table if exists public.instrumentos enable row level security;
alter table if exists public.logs enable row level security;

drop policy if exists instrumentos_select_auth on public.instrumentos;
create policy instrumentos_select_auth
on public.instrumentos for select to authenticated
using (true);

drop policy if exists instrumentos_insert_auth on public.instrumentos;
create policy instrumentos_insert_auth
on public.instrumentos for insert to authenticated
with check (true);

drop policy if exists instrumentos_update_auth on public.instrumentos;
create policy instrumentos_update_auth
on public.instrumentos for update to authenticated
using (true) with check (true);

drop policy if exists instrumentos_delete_auth on public.instrumentos;
create policy instrumentos_delete_auth
on public.instrumentos for delete to authenticated
using (true);
```

### Storage (upload restrito por pasta)

```sql
drop policy if exists storage_insert_alunos_fotos_auth on storage.objects;
create policy storage_insert_alunos_fotos_auth
on storage.objects for insert to authenticated
with check (
  bucket_id = 'alunos-fotos'
  and (storage.foldername(name))[1] in ('alunos', 'instrumentos')
);
```

Se o bucket for publico, remova policy ampla de `SELECT` em `storage.objects` para evitar alerta:

- `Clients can list all files in this bucket`

## Build APK (Release)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SEU_ANON_KEY
```

APK gerado:

- `build/app/outputs/flutter-apk/app-release.apk`

## Instalar no Android via USB (ADB)

```bash
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Compartilhar com Outras Pessoas

Fluxo simples:

1. gerar `app-release.apk`
2. enviar arquivo (Drive, WhatsApp, Telegram, e-mail)
3. usuario ativa permissao de instalar app desconhecido
4. usuario instala o APK

Para atualizar:

1. aumentar versao no `pubspec.yaml` (ex.: `1.0.2+3`)
2. gerar novo APK
3. instalar por cima (`adb install -r`) ou reenviar

## Qualidade e Padronizacao

Comandos recomendados antes de publicar:

```bash
dart format .
flutter analyze
flutter test
```

Checklist rapido:

1. usar tokens de tema em `lib/core/theme/`
2. evitar regra de negocio na UI quando houver repository
3. tratar loading/erro/sucesso em chamadas async
4. validar filtros/paginacao nas telas principais

## Troubleshooting

### Erro: `Supabase nao configurado`

Causa: build/run sem `--dart-define`.  
Correcao: gerar novamente passando `SUPABASE_URL` e `SUPABASE_ANON_KEY`.

### Erro: `StorageException ... row-level security policy ... status 403`

Causa: policy de `INSERT` ausente/incorreta no `storage.objects`.  
Correcao: aplicar policy de upload para bucket `alunos-fotos` com pastas permitidas.

### Listas vazias em telas (instrumentos/historico)

Causa comum: falta de policy `SELECT` nas tabelas ou sessao invalida.  
Correcao: revisar RLS das tabelas e refazer login.

### Alerta: `Clients can list all files in this bucket`

Causa: policy ampla de `SELECT` em bucket publico.  
Correcao: remover policy ampla ou restringir por regra.

## Observacoes

- Projeto pode conter alteracoes locais nao commitadas durante testes em dispositivo.
- Ao trocar regras de RLS, reiniciar sessao (logout/login) ajuda a refletir permissao atual.
