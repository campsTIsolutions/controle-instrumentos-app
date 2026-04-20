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
