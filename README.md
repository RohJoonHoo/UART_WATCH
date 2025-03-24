# UART-Controlled Watch & Stopwatch System on FPGA

## 📝 Overview
본 프로젝트는 **UART 통신을 통해 PC에서 명령어를 받아 디지털 시계 및 스톱워치 기능을 제어**하는 FPGA 시스템입니다.  
명령은 FIFO를 통해 안정적으로 처리되며, Verilog로 구현된 여러 모듈들이 유기적으로 동작하여 시계 모드와 스톱워치 모드를 전환 및 제어합니다.

## 🎯 Features
- **UART 통신 지원**: PC에서 보낸 명령(R, C, H, M, S)을 수신 및 처리
- **FIFO 버퍼링**: 수신 데이터의 안정적 처리
- **명령어 처리기 (CMD_PROCESSOR)**: 명령 해석 및 버튼 신호 생성
- **Watch & Stopwatch 기능 통합**
- **디지털 디스플레이(FND) 출력**

## 🛠️ Architecture
- `UART_RX`: PC로부터 데이터를 수신
- `UART_TX`: FPGA에서 데이터를 송신 (테스트용)
- `UART_FIFO`: 수신 데이터를 저장하는 FIFO 버퍼
- `CMD_PROCESSOR`: FIFO에서 데이터를 읽어 명령을 해석하고 제어 신호로 변환
- `command_to_btn`: 명령에 대응하는 버튼 시그널 출력 (run, clear, hour, min, sec)
- `watch`, `stopwatch`: 실시간 시계 및 스톱워치 동작 담당

## 📡 Supported Commands (via UART)
| Command | 기능          | 출력 신호 |
|---------|---------------|-----------|
| `R`     | 스톱워치 시작 | `run`     |
| `C`     | 스톱워치 초기화 | `clear`   |
| `H`     | 시 설정       | `hour`    |
| `M`     | 분 설정       | `min`     |
| `S`     | 초 설정       | `sec`     |

> 각 명령은 ASCII 코드로 입력됩니다. (`R` = 0x52, `C` = 0x43, ...)

## 🖼️ Block Diagram
```
[ PC Terminal ]
      |
      v
[ UART_RX ] --> [ UART_FIFO ] --> [ CMD_PROCESSOR ] --> [ Watch / Stopwatch ]
                                                    --> [ 7-Segment Display ]
```

## 🧪 Simulation
Vivado 시뮬레이션을 통해 각 명령에 대한 동작을 검증하였습니다.  
각 명령어(R, C, H, M, S)에 대해 FIFO에서 데이터를 읽고, 해당 기능이 정상 동작함을 파형으로 확인했습니다.

## 🧹 개선 사항
- 초기 버전에서 FIFO가 empty 상태여도 이전 데이터를 읽는 오류가 발생
- 개선 후: **empty 신호 확인 후에만 읽기 동작 수행** → 잘못된 명령 실행 방지

## 📁 File Structure
```
├── uart_rx.v
├── uart_tx.v
├── uart_fifo.v
├── command_to_btn.v
├── cmd_processor.v
├── stopwatch.v
├── watch.v
├── top_module.v
└── simulation_tb.v
```

## 🎥 Demo
프로젝트의 동작 영상은 PPT에 첨부된 데모 영상을 참고하세요.
