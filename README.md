# robo-control-app — App Android (Bluetooth) para o robô seguidor de linha

Pasta criada **fora** do repositório do firmware (`ES670-2026-GrupoA2`), de propósito.

- `AGENTS.md` → cole no **Antigravity** para gerar o app (vibecoding).
- Stack alvo: **Flutter + Bluetooth Clássico SPP (flutter_bluetooth_serial)**, Android.

---

## ⚠️ Compatibilidade do firmware (estado ATUAL do robô)

Verifiquei o firmware. O **protocolo** (comandos ASCII) já está pronto e é o mesmo
descrito no prompt. **Porém o transporte ainda não é Bluetooth:**

| Item | Estado hoje | Para o app funcionar |
|---|---|---|
| Comandos ASCII (`MOTOR`, `AUTO`, `SET_PID`...) | ✅ Implementados (`vTaskUART`) | OK, nada a mudar |
| Telemetria a cada 1 s | ✅ Implementada | OK |
| Baud 115200 8N1 | ✅ | OK |
| **Porta de comunicação** | ❌ **LPUART1 = USB (VCP do ST-Link)** | Precisa de **HC-05** numa UART |

**O que falta no firmware (lado do robô), feito por vocês depois:**
1. Conectar um módulo **HC-05** (Bluetooth Clássico) a uma UART do STM32
   (o plano do projeto era a **USART3**, pinos PB10/PB11).
2. Apontar o firmware para essa UART (hoje ele lê/escreve em `hlpuart1`; passaria a
   usar `huart3`), e configurar o HC-05 para **115200 bps**.
3. Enquanto o HC-05 não estiver montado, dá para **testar o protocolo via USB**: abrir
   um terminal serial no PC (115200) e digitar os comandos — o robô já responde igual.

> Resumo: o **app pode ser desenvolvido e o protocolo é compatível desde já**. A ligação
> Bluetooth real depende de montar o HC-05 e redirecionar a UART no firmware.

---

## 🧪 Como testar o app

### ❗ Aviso sobre simulador Android (leia primeiro)
O **emulador de Android NÃO tem Bluetooth** (nenhum emulador oficial simula rádio
Bluetooth). No emulador você consegue testar **só a interface** (telas, joystick, layout),
**não** a conexão real com o robô.

➡️ **O teste de Bluetooth de verdade exige um celular Android físico** (com Depuração USB
ligada). Não tem como contornar isso num Mac com simulador.

### Caminho de teste recomendado (em 2 camadas)
1. **Protocolo (sem app, agora):** robô por USB + terminal serial no PC (115200) →
   digite `MANUAL`, `MOTOR 0.3 0.3`, `STOP`, `AUTO`, etc. Valida o lado do robô.
2. **App + Bluetooth (depois):** HC-05 montado no robô + **celular Android físico** →
   rodar o app pelo cabo USB (`flutter run`).

### Simulador Android no Mac — caminho OFICIAL (quando você decidir instalar)
> **NÃO instalei nada disto.** Deixo só o passo a passo para quando for SEU Mac / autorizado.

- O simulador oficial é o **Android Emulator**, que vem com o **Android Studio**
  (gratuito, oficial do Google; roda em Apple Silicon).
- No VS Code, a extensão oficial **"Flutter"** (e **"Dart"**) detecta e inicia o emulador
  criado no Android Studio — você roda/depura direto do VS Code.
- Não existe um "simulador Android puro" só de extensão do VS Code sem o SDK do Android;
  o emulador sempre vem do Android SDK (via Android Studio ou command-line tools).
- Lembrando: mesmo instalando, o emulador serve para a **UI**, não para o Bluetooth.

---

## 🚀 Quando for rodar de fato (passos — NÃO execute agora, só referência)

> Tudo abaixo **baixa coisas** (SDKs). Só faça num Mac seu / com autorização.

1. Instalar **Flutter SDK** (inclui Dart) + **Android Studio** (para o Android SDK e o emulador).
2. `flutter doctor` → seguir o que faltar (aceitar licenças do Android SDK).
3. Gerar o app: deixe o **Antigravity** criar a partir do `AGENTS.md`,
   **ou** rode `flutter create .` nesta pasta e peça ao Antigravity para preencher.
4. `flutter pub get` (baixa as dependências, ex. `flutter_bluetooth_serial`).
5. **Parear o HC-05** nas configurações de Bluetooth do celular (senha padrão `1234` ou `0000`).
6. Celular Android no cabo USB (Depuração USB ON) → `flutter run`.

---

## Estado desta pasta
- ✅ `AGENTS.md` e `README.md` criados (arquivos de texto).
- ✅ Esqueleto mínimo (`pubspec.yaml`, `lib/main.dart`) como ponto de partida.
- ❌ Nada foi baixado/instalado. Sem SDKs, sem emulador, sem dependências.
