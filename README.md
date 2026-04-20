# Controle Instrumentos App

Aplicativo Flutter para controle de instrumentos e alunos.

## Configuracao de ambiente (Supabase)

Passe as chaves por `--dart-define` (nao hardcode no codigo):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SEU_ANON_KEY
```

## Gerar APK para teste local

```bash
flutter build apk --release
```

Saida:

`build/app/outputs/flutter-apk/app-release.apk`

## Gerar APKs menores (recomendado para compartilhar)

```bash
flutter build apk --release --split-per-abi
```

Saidas tipicas:

- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

Para celulares Android atuais, normalmente use `arm64-v8a`.

## Assinatura de release

1. Copie `android/key.properties.example` para `android/key.properties`.
2. Preencha os valores do seu keystore.
3. Gere novamente o APK release.

Quando `android/key.properties` nao existir, o projeto usa assinatura debug como fallback.

## Padronizacao de codigo e UI

### Estrutura por feature

Use o padrao abaixo dentro de `lib/features/<feature>/`:

- `models/`
- `repository/`
- `widgets/`
- `<feature>_page.dart`

Evite colocar acesso a dados direto na page; prefira concentrar no `repository`.

### Design tokens (obrigatorio para telas novas)

Use os tokens centrais em `lib/core/theme/`:

- `AppColors`
- `AppSpacing`
- `AppRadii`
- `AppTextStyles`

Evite valores hardcoded de `Color(...)`, espacamentos e fontes diretamente nas telas.

### Checklist antes de PR/merge

1. Tela usa tokens de `core/theme`.
2. UI evita `Map<String, dynamic>` quando houver model da feature.
3. Estado async cobre loading/saving/error com feedback visual.
4. `dart format .`
5. `flutter analyze`

### Comandos de validacao

```bash
dart format .
flutter analyze
```
