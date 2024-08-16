# Q_Channel_Protocol
Q-Channel Protocol for Low power devices 

The **Q-Channel Protocol** is a communication mechanism used within ARM architectures to manage power and performance states across different components of a System-on-Chip (SoC). It allows efficient control of clock and power domains by facilitating communication between the components and the power controller.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Q-Channel Signals](#q-channel-signals)
- [Protocol Phases](#protocol-phases)
- [Use Cases](#use-cases)
- [Implementation](#implementation)
- [References](#references)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Q-Channel protocol is a key part of ARM's power management strategy. It enables different components of an SoC to request changes in power or clock states, ensuring that power is used efficiently while maintaining performance. The protocol is designed to be simple yet effective, providing a standardized way for components to communicate their power requirements.

## Architecture

In ARM SoCs, the Q-Channel protocol is used to manage the interactions between various IP blocks and the power controller. The protocol supports different types of signals and phases to handle requests and acknowledgments for power and clock state changes.

![TL Schematic](https://github.com/SanidhyaSaxena21/Q_Channel_Protocol/blob/main/docs/RTL_Schematic.png)
### Key Components

- **IP Blocks**: Components within the SoC that generate power or clock state requests.
- **Power Controller**: Manages the overall power state of the SoC based on requests from IP blocks.
- **Q-Channel Interface**: The communication interface that facilitates the exchange of signals between IP blocks and the power controller.

## Q-Channel Signals

The Q-Channel protocol defines several key signals used for communication:

- **qreq_n (Request)**: A signal sent from the power controller to the IP Block indicating a request for a power or clock state change.
- **qaccept (Accept)**: A signal sent from IP block to the the power controller to acknowledge the request.
- **qdeny**: A signal sent from IP block to the the power controller to deny the request.
- **qactive**: A signal sent from IP block to the the power controller indicating the activity of the corresponding IP block.

![Q Channel Signals](https://github.com/SanidhyaSaxena21/Q_Channel_Protocol/blob/main/docs/Q_State_transitions.png)

## Protocol Phases

The Q-Channel protocol operates in the following phases:

1. **Q_RUN**: No request is pending; the system remains in its current state.
2. **Q_REQUEST**: The power controller block sends a REQ signal to request a change in state.
3. **Q_STOPPED**: The Device responds with an qaccept signal.
4. **Q_EXIT**: When the power controller gives a wakeup request to the device.

![State Changes](https://github.com/SanidhyaSaxena21/Q_Channel_Protocol/blob/main/docs/FSM_States.png)


## Use Cases

The Q-Channel protocol is used in various scenarios within ARM-based SoCs:

- **Dynamic Voltage and Frequency Scaling (DVFS)**: Adjusting the voltage and frequency of a processor based on workload.
- **Power Gating**: Turning off power to certain components when they are not in use.
- **Clock Gating**: Disabling the clock signal to idle components to save power.

## Implementation

To implement the Q-Channel protocol in your ARM-based SoC design:

1. **Integrate Q-Channel Interfaces**: Ensure that all relevant IP blocks are connected to the Q-Channel interface.
2. **Configure Power Controller**: Set up the power controller to handle Q-Channel requests and manage power states accordingly.
3. **Validate Communication**: Test the Q-Channel communication using simulation and validation tools to ensure correct operation.

![ARM Implementation](https://github.com/SanidhyaSaxena21/Q_Channel_Protocol/blob/main/docs/Recommended_Implementation.png)

## Simulation
1. When the device comes out of the reset, the write transation starts and master writes on to the FIFO. 

2. When the external low_power_req_i is asserted the qreqn goes low and the state chnages to Q_REQUEST. 

3. The wr_fifo_flush is asserted as we have to go in LP mode. The Write side gave the acknowledgement by asserting wr_done signal. 

4. Since the we need to flush the FIFO, the read side starts reading the data present in the FIFO memory. 

![Simulation](https://github.com/SanidhyaSaxena21/Q_Channel_Protocol/blob/main/docs/Simulations.png)


5. When the FIFO is empty that means it is safe to go in Low power mode, hence the qacceptn goes low and we enter the Q_STOPPED state.

6. In the Q_STOPPED state the clock to the device is gated. 

7. When the external wakeup signal (if_wakeup) is asserted, the qactive goes high and after 5 cycles the qreq_n also goes high indicating the EXIT from the low power state. 

8. In the Q_EXIT state the clock to the device is ensured. 

9. When the qaccept_n is lifted high, it marks the entry of Q_RUN state and the device is back to functional state. 

## References

- [ARM Power Management Techniques](https://developer.arm.com/solutions/power-management](https://www.bing.com/ck/a?!&&p=7659ca635f98647cJmltdHM9MTcyMzc2NjQwMCZpZ3VpZD0zMzBjYTM1Mi0xYTM0LTYwNDEtMWI2Zi1hYzQ5MWIzMjYxYTEmaW5zaWQ9NTIyMQ&ptn=3&ver=2&hsh=3&fclid=330ca352-1a34-6041-1b6f-ac491b3261a1&psq=ARM+Q+channle&u=a1aHR0cHM6Ly9kb2N1bWVudGF0aW9uLXNlcnZpY2UuYXJtLmNvbS9zdGF0aWMvNWY5MTVlNjlmODZlMTY1MTVjZGMzYjNl&ntb=1))


