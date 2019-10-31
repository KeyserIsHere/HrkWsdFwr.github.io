/*
 *  Copyright (c) 2016, Stefan Johnson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, this list
 *     of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice, this
 *     list of conditions and the following disclaimer in the documentation and/or other
 *     materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef HackingGame_HubArchInstructionType_h
#define HackingGame_HubArchInstructionType_h

#include "Base.h"

typedef enum {
    HKHubArchInstructionOperandNA = (1 << 0),
    HKHubArchInstructionOperandI = (1 << 1),
    HKHubArchInstructionOperandR = (1 << 2),
    HKHubArchInstructionOperandM = (1 << 3),
    HKHubArchInstructionOperandRM = HKHubArchInstructionOperandR | HKHubArchInstructionOperandM,
    HKHubArchInstructionOperandRel = (1 << 4) | HKHubArchInstructionOperandI
} HKHubArchInstructionOperand;

typedef enum {
    HKHubArchInstructionMemoryOperationMask = 3,
    HKHubArchInstructionMemoryOperationSrc = (1 << 0),
    HKHubArchInstructionMemoryOperationDst = (1 << 1),
    
    HKHubArchInstructionMemoryOperationOp1 = 0,
    HKHubArchInstructionMemoryOperationOp2 = 2,
    HKHubArchInstructionMemoryOperationOp3 = 4,
    
    HKHubArchInstructionMemoryOperationNone = 0,
    HKHubArchInstructionMemoryOperationS = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1),
    HKHubArchInstructionMemoryOperationD = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1),
    HKHubArchInstructionMemoryOperationB = ((HKHubArchInstructionMemoryOperationSrc | HKHubArchInstructionMemoryOperationDst) << HKHubArchInstructionMemoryOperationOp1),
    
    HKHubArchInstructionMemoryOperationSS = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2),
    HKHubArchInstructionMemoryOperationSD = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2),
    HKHubArchInstructionMemoryOperationDS = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2),
    HKHubArchInstructionMemoryOperationDD = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2),
    
    HKHubArchInstructionMemoryOperationSSS = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationSSD = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationSDS = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationSDD = (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationDSS = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationDSD = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationDDS = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationSrc << HKHubArchInstructionMemoryOperationOp3),
    HKHubArchInstructionMemoryOperationDDD = (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp1) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp2) | (HKHubArchInstructionMemoryOperationDst << HKHubArchInstructionMemoryOperationOp3)
} HKHubArchInstructionMemoryOperation;

typedef enum {
    HKHubArchInstructionControlFlowEvaluationMask = 1,
    HKHubArchInstructionControlFlowEvaluationUnconditional = (0 << 0),
    HKHubArchInstructionControlFlowEvaluationConditional = (1 << 0),
    
    HKHubArchInstructionControlFlowEffectMask = (3 << 1),
    HKHubArchInstructionControlFlowEffectNone = (0 << 1),
    HKHubArchInstructionControlFlowEffectBranch = (1 << 1),
    HKHubArchInstructionControlFlowEffectPause = (2 << 1),
    HKHubArchInstructionControlFlowEffectIO = (3 << 1)
} HKHubArchInstructionControlFlow;

typedef enum {
    HKHubArchInstructionRegisterSpecialPurpose = (1 << 1),
    HKHubArchInstructionRegisterGeneralPurpose = (1 << 2),
    HKHubArchInstructionRegisterGeneralPurposeIndexMask = 3,
    HKHubArchInstructionRegisterSpecialPurposeIndexMask = 1,
    
    HKHubArchInstructionRegisterR0 = 0 | HKHubArchInstructionRegisterGeneralPurpose,
    HKHubArchInstructionRegisterR1 = 1 | HKHubArchInstructionRegisterGeneralPurpose,
    HKHubArchInstructionRegisterR2 = 2 | HKHubArchInstructionRegisterGeneralPurpose,
    HKHubArchInstructionRegisterR3 = 3 | HKHubArchInstructionRegisterGeneralPurpose,
    
    HKHubArchInstructionRegisterFlags = 0 | HKHubArchInstructionRegisterSpecialPurpose,
    HKHubArchInstructionRegisterPC = 1 | HKHubArchInstructionRegisterSpecialPurpose
} HKHubArchInstructionRegister;

typedef enum {
    HKHubArchInstructionMemoryOffset,           //[0]
    HKHubArchInstructionMemoryRegister,         //[r0]
    HKHubArchInstructionMemoryRelativeOffset,   //[r0+0]
    HKHubArchInstructionMemoryRelativeRegister  //[r0+r0]
} HKHubArchInstructionMemory;

typedef struct {
    HKHubArchInstructionOperand type; //HKHubArchInstructionOperandNA or HKHubArchInstructionOperandI or HKHubArchInstructionOperandR or HKHubArchInstructionOperandM
    union {
        uint8_t value; //type = HKHubArchInstructionOperandI
        HKHubArchInstructionRegister reg; //type = HKHubArchInstructionOperandR
        struct {
            HKHubArchInstructionMemory type;
            union {
                uint8_t offset; //memory.type = HKHubArchInstructionMemoryOffset
                HKHubArchInstructionRegister reg; //memory.type = HKHubArchInstructionMemoryRegister
                struct {
                    uint8_t offset;
                    HKHubArchInstructionRegister reg;
                } relativeOffset; //memory.type = HKHubArchInstructionMemoryRelativeOffset
                HKHubArchInstructionRegister relativeReg[2]; //memory.type = HKHubArchInstructionMemoryRelativeRegister
            };
        } memory; //type = HKHubArchInstructionOperandM
    };
} HKHubArchInstructionOperandValue;

typedef struct {
    int8_t opcode; //-1 = invalid
    HKHubArchInstructionOperandValue operand[3];
} HKHubArchInstructionState;

typedef enum {
    HKHubArchInstructionOperationResultFailure,
    HKHubArchInstructionOperationResultSuccess,
    HKHubArchInstructionOperationResultMask = 1,
    
    HKHubArchInstructionOperationResultFlagSkipPC = (1 << 1),
    HKHubArchInstructionOperationResultFlagPipelineStall = (1 << 2),
    HKHubArchInstructionOperationResultFlagInvalidOp = (1 << 3)
} HKHubArchInstructionOperationResult;

#endif
