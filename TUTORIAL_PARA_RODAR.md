# 📱 Tutorial — Rodar o app no celular (Samsung S21 FE)

Guia passo a passo para **clonar, montar e rodar o app no seu Android** e
**visualizar a interface**. (A conexão Bluetooth com o robô só funciona com o
robô + módulo HC-05 montado; aqui o foco é **ver o app rodando**.)

> Funciona em **Windows ou Mac**. Onde mudar, há uma nota `(Win)` / `(Mac)`.

---

## 0. O que você vai instalar (uma vez só)

| Ferramenta | Para quê | Link oficial |
|---|---|---|
| **Git** | clonar o repositório | https://git-scm.com/downloads |
| **Flutter SDK** | compilar o app (já inclui o Dart) | https://docs.flutter.dev/get-started/install |
| **Android Studio** | traz o **Android SDK** + drivers + reconhece o celular | https://developer.android.com/studio |
| **VS Code** | editor para abrir e rodar | https://code.visualstudio.com |
| Extensões **Flutter** e **Dart** (no VS Code) | botão de rodar/depurar | (instalar dentro do VS Code) |

> Dica: ao instalar o **Flutter**, siga o guia oficial do seu sistema. No fim,
> rode `flutter doctor` no terminal — ele lista o que falta (geralmente "aceitar
> as licenças do Android SDK": rode `flutter doctor --android-licenses` e aceite tudo).

---

## 1. Clonar o repositório

Abra o terminal numa pasta de sua escolha e rode (troque a URL pela do repositório):

```bash
git clone <URL_DO_REPOSITORIO>
cd robo-control-app
```

---

## 2. Gerar o "scaffolding" de plataforma (passo importante!)

O repositório tem o **código do app** (pasta `lib/`), mas **não** os arquivos de
build do Android (gradle, etc.) — eles são gerados em cada máquina. Rode **uma vez**:

```bash
flutter create . --org com.es670.grupoa2 --project-name robo_control_app --platforms android
```

> Isso **não apaga** o código existente (`lib/`, `pubspec.yaml`, o `AndroidManifest.xml`
> com as permissões) — só cria os arquivos que faltam (pasta `android/`, MainActivity, etc.).

Depois, baixe as dependências:

```bash
flutter pub get
```

---

## 3. Preparar o celular (Samsung S21 FE)

1. **Ativar o modo desenvolvedor**: Configurações → Sobre o telefone → Informações
   do software → toque **7 vezes** em "Número da versão".
2. Voltar em Configurações → **Opções do desenvolvedor** → ligar **Depuração USB**.
3. Conectar o celular no computador por **cabo USB**.
4. No celular, aparecerá "Permitir depuração USB?" → **Permitir** (marque "sempre").

Confirme que o computador vê o celular:
```bash
flutter devices
```
Deve listar algo como `SM-G990... (mobile)`. Se não aparecer, veja o item **Problemas** abaixo.

---

## 4. Rodar o app

**Pelo terminal:**
```bash
flutter run
```
(escolha o celular se ele perguntar; a primeira compilação demora alguns minutos)

**Ou pelo VS Code:**
1. Abrir a pasta `robo-control-app` no VS Code.
2. Instalar as extensões **Flutter** e **Dart** (ele costuma sugerir sozinho).
3. Selecionar o celular no canto inferior direito (onde mostra o dispositivo).
4. Apertar **F5** (Run → Start Debugging).

➡️ O app abre no celular. Você verá a **tela de Conexão**; mesmo sem o robô,
dá para navegar e ver o **joystick, botões e o painel de telemetria** (a conexão
Bluetooth só completa com o HC-05 ligado no robô).

---

## 5. Problemas comuns (troubleshooting)

**O `flutter devices` não mostra o celular**
- Cabo USB ruim/só-carga → use um cabo de dados.
- Reabra a permissão de Depuração USB no celular.
- (Win) instale o "Samsung USB Driver for Mobile Phones".
- Rode `flutter doctor` e resolva o que aparecer em vermelho.

**Erro de build mencionando `Namespace not specified` (plugin Bluetooth)**
O pacote `flutter_bluetooth_serial` é antigo e às vezes quebra com o Gradle novo.
Se acontecer, abra `android/build.gradle` e adicione, **no final do arquivo**:
```gradle
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    namespace project.group
                }
            }
        }
    }
}
```
Depois rode `flutter clean` e `flutter run` de novo.

**Erro de versão do SDK / "Android licenses not accepted"**
```bash
flutter doctor --android-licenses
```
Aceite tudo e rode `flutter doctor` de novo.

---

## Resumo dos comandos
```bash
git clone <URL_DO_REPOSITORIO>
cd robo-control-app
flutter create . --org com.es670.grupoa2 --project-name robo_control_app --platforms android
flutter pub get
flutter devices      # confirmar que o celular aparece
flutter run          # rodar no celular
```
