# 计算机组成原理课程实验：五级流水线 CPU

本项目使用 Verilog 实现了一个面向教学的 32 位 MIPS 风格五级流水线 CPU，可在 Vivado 2019.2 中进行仿真和综合。

## 已实现功能

- IF、ID、EX、MEM、WB 五级流水线。
- 数据前递和 load-use 冒险暂停。
- `BEQ`、`BNE`、`J`、`JAL`、`JR` 控制流处理及流水线冲刷。
- 静态“不跳转”分支预测，以及分支预测错误统计。
- 数据存储器 `valid/ready` 握手和全流水线等待。
- 有符号算术溢出检测、粘滞溢出状态和显式清除。
- 周期数、退休指令数、分支数、预测错误数、暂停数、存储等待数和冲刷数等性能计数器。

当前支持 16 条指令：

```text
ADD  ADDU  SUB  SUBU  AND  OR
ADDI ADDIU LUI  LW    SW
BEQ  BNE   J    JAL   JR
```

> 动态分支预测暂未实现，目前采用静态不跳转预测。

## 目录结构

```text
rtl/       CPU 和各功能模块的 Verilog 源码
tb/        模块级及 CPU 系统级测试平台
programs/  仿真使用的机器指令 HEX 文件
*.tcl      各阶段源码导入和自动测试脚本
Lab1.xpr   Vivado 工程文件
```

## 运行测试

在 Vivado Tcl Console 中执行：

```tcl
source add_stage9_sources.tcl
source run_stage9_tests.tcl
```

阶段 1～7 与阶段 9 共 15 个测试顶层均已通过。阶段 9 的代表性测试包括：

- `cpu_control_flow_tb`：验证分支、跳转、冲刷和静态预测性能。
- `cpu_overflow_performance_tb`：验证有符号溢出与无符号回绕。
- `cpu_mem_wait_performance_tb`：验证存储器等待期间的流水线冻结和性能计数。

项目综合目标器件为 `xc7a100tcsg324-1`，以 `cpu_core` 为顶层综合通过。
