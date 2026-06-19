# Prompt de contexto — App Android para controle do robô seguidor de linha (Bluetooth)

> Cole este arquivo inteiro como contexto inicial no Antigravity. Ele descreve o
> robô, o protocolo de comunicação e exatamente o app que deve ser construído.

---

## 1. Objetivo

Construir um **aplicativo Android** que se conecta por **Bluetooth Clássico (SPP/RFCOMM)**
a um robô diferencial seguidor de linha (baseado em STM32) e permite:

- Controlar os motores manualmente com um **joystick virtual** (analógico).
- Trocar o modo do robô: **MANUAL / AUTÔNOMO (seguir linha) / parar**.
- Disparar a **calibração** dos sensores.
- Ajustar e ler os ganhos do **PID** (Kp, Ki, Kd).
- Exibir a **telemetria** recebida (posição, ângulo, velocidade, bateria, modo).

## 2. Como o robô se comunica (MUITO IMPORTANTE)

- O robô tem um módulo **Bluetooth Clássico HC-05** (perfil SPP). Do ponto de vista
  do app, é uma **porta serial sem fio**: você pareia com o HC-05 e troca **texto ASCII**.
- **NÃO é BLE (Bluetooth Low Energy).** É **Bluetooth Clássico / SPP (RFCOMM)**.
  Use uma biblioteca de Bluetooth **Classic SPP** (ver stack abaixo).
- Parâmetros da serial (já fixos no firmware): **115200 bps, 8 bits, sem paridade,
  1 stop bit (8N1)**. (No HC-05 o app não precisa setar baud — isso é entre o HC-05
  e o robô; o app só abre o socket SPP.)
- **Todo comando enviado termina com `\n`** (newline). O robô responde/telemetra
  com linhas terminadas em `\r\n`.

## 3. Protocolo — comandos que o app ENVIA (texto ASCII + `\n`)

| Comando | Efeito no robô |
|---|---|
| `MANUAL\n` | Entra em modo manual (joystick passa a controlar os motores) |
| `AUTO\n` | Entra em modo autônomo (robô segue a linha sozinho) |
| `MOTOR <esq> <dir>\n` | Define a velocidade das rodas. `<esq>` e `<dir>` são floats de **-1.0 a 1.0** (negativo = ré). Ex.: `MOTOR 0.35 0.35\n` |
| `STOP\n` | Para os dois motores imediatamente |
| `CALIBRATE\n` | Inicia a calibração dos sensores (durar ~0,2 s) |
| `SET_PID <kp> <ki> <kd>\n` | Define os ganhos do PID. Ex.: `SET_PID 0.50 0.00 0.10\n` |
| `GET_PID\n` | Pede os ganhos atuais (robô responde `PID:<kp> <ki> <kd>\r\n`) |

**Regra crítica do joystick:** os comandos `MOTOR` só têm efeito no modo **MANUAL**.
No modo AUTÔNOMO o robô ignora o joystick (ele mesmo controla os motores). Então, ao
ativar o joystick, o app deve garantir que enviou `MANUAL\n` antes.

## 4. Protocolo — o que o robô ENVIA de volta (o app deve fazer PARSE)

**Telemetria, automática a cada 1 segundo**, uma linha:
```
X=0.12 Y=-0.03 Th=0.45 V=0.20 Vavg=0.18 Dist=1.34 Bat=87% Mode=0 Calib=1
```
Campos:
- `X`, `Y` = posição estimada em metros (float)
- `Th` = ângulo theta em radianos (float, entre -π e π)
- `V` = velocidade atual (m/s), `Vavg` = velocidade média (m/s)
- `Dist` = distância total percorrida (m)
- `Bat` = bateria em % (inteiro)
- `Mode` = `0` (MANUAL) ou `1` (AUTÔNOMO)
- `Calib` = `0` (não calibrado) ou `1` (calibrado)

**Resposta ao `GET_PID`:**
```
PID:0.50 0.00 0.10
```

> Parsing robusto: separe por espaços e por `=`/`:`; ignore linhas que não casem
> com os formatos acima (pode chegar lixo parcial). Acumule bytes até encontrar `\n`.

## 5. Stack técnica recomendada

- **Framework:** Flutter (Dart). Bom para UI de joystick e ótimo para Bluetooth Clássico.
- **Bluetooth Clássico SPP:** pacote `flutter_bluetooth_serial` (faz scan, pareamento,
  conexão RFCOMM e troca de bytes). *(É só Android — Bluetooth Clássico não existe no iOS;
  está OK, o alvo é Android.)*
- **Joystick:** pacote `flutter_joystick` (ou um joystick custom com GestureDetector).
- **Gerência de estado:** `provider` ou `riverpod` (simples).
- **Plataforma alvo:** Android (minSdk 21+). **Não precisa de iOS.**

> Se preferir, React Native com `react-native-bluetooth-classic` também serve — mas
> a referência abaixo assume Flutter.

## 6. Telas / UX

1. **Tela de Conexão**
   - Botão "Procurar dispositivos" → lista os dispositivos Bluetooth **pareados** (o HC-05
     normalmente aparece como `HC-05`).
   - Tocar no dispositivo → conecta (RFCOMM SPP). Mostrar estado: Desconectado / Conectando / Conectado.
   - Tratar permissões em runtime (ver seção 8).

2. **Tela de Controle** (principal, após conectar)
   - **Joystick analógico** grande (parte de baixo). Saída do joystick: dois eixos `x`,`y`
     em [-1, 1]. Converter para velocidades de roda (mistura diferencial):
     ```
     esq  = clamp(y + x, -1, 1)
     dir  = clamp(y - x, -1, 1)
     ```
     Enviar `MOTOR <esq> <dir>\n` a cada **~100 ms** enquanto o joystick estiver ativo
     (throttle/limite de taxa para não inundar a serial). Ao **soltar** o joystick,
     enviar `STOP\n` (ou `MOTOR 0 0\n`).
   - Botões: **MANUAL**, **AUTO**, **STOP (emergência, bem visível)**, **CALIBRAR**.
     Ao começar a usar o joystick, garantir `MANUAL\n` antes.
   - **Painel de telemetria**: mostrar X, Y, θ, V, bateria (com ícone/%), modo (MANUAL/AUTO),
     calibrado (sim/não). Atualizar conforme chegam as linhas de telemetria.

3. **Tela/aba de PID** (configuração)
   - 3 campos numéricos (Kp, Ki, Kd) + botão "Enviar" → `SET_PID kp ki kd\n`.
   - Botão "Ler atuais" → `GET_PID\n` e preencher os campos com a resposta `PID:...`.

## 7. Requisitos de robustez

- Reconectar com feedback claro se a conexão cair.
- Throttle do envio do joystick (máx. ~10–20 msg/s).
- Buffer de recepção: acumular até `\n`, depois parsear linha a linha.
- Nunca travar a UI esperando Bluetooth (usar async/streams).
- Botão STOP sempre acessível e com destaque.

## 8. Permissões Android (não esquecer)

No `AndroidManifest.xml`:
- Android 12+ (API 31+): `BLUETOOTH_CONNECT` e `BLUETOOTH_SCAN` (pedir em runtime).
- Android ≤ 11: `BLUETOOTH`, `BLUETOOTH_ADMIN` e `ACCESS_FINE_LOCATION` (scan clássico
  exige permissão de localização em runtime).
- Pedir as permissões em runtime antes de escanear/conectar.

## 9. Entregáveis esperados do Antigravity

- Projeto Flutter Android compilável.
- Conexão SPP funcional com HC-05.
- Joystick → `MOTOR`, botões de modo, painel de telemetria, aba de PID.
- Código organizado (camada de Bluetooth separada da UI) e comentado.
- README com como rodar (`flutter pub get`, `flutter run`) e as permissões.

---

### Resumo de uma linha para o agente
> "Crie um app **Flutter para Android** que conecta por **Bluetooth Clássico SPP** a um
> HC-05, com **joystick** que envia `MOTOR <esq> <dir>\n` (mistura diferencial, só em modo
> MANUAL), botões MANUAL/AUTO/STOP/CALIBRAR, ajuste de PID via `SET_PID`/`GET_PID`, e um
> painel que faz parse da telemetria `X=.. Y=.. Th=.. V=.. Bat=..% Mode=.. Calib=..`."
