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

#include "HubArchProcessor.h"
#include "HubArchInstruction.h"

const double HKHubArchProcessorHertz = 400.0;
const size_t HKHubArchProcessorSpeedMemoryRead = 1;
const size_t HKHubArchProcessorSpeedMemoryWrite = 1;
const size_t HKHubArchProcessorSpeedPortTransmission = 4;

HKHubArchProcessor HKHubArchProcessorCreate(CCAllocatorType Allocator, HKHubArchBinary Binary)
{
    CCAssertLog(Binary, "Binary must not be null");
    
    HKHubArchProcessor Processor;
    CC_SAFE_Malloc(Processor, sizeof(HKHubArchProcessorInfo),
                   CC_LOG_ERROR("Failed to create processor, due to allocation failure (%zu)", sizeof(HKHubArchProcessorInfo));
                   return NULL;
                   );
    
    Processor->ports = NULL; //TODO: init dictionary(uint8_t key, HKHubArchProcessor/module value)
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 0;
    Processor->state.r[2] = 0;
    Processor->state.r[3] = 0;
    Processor->state.pc = Binary->entrypoint;
    Processor->state.flags = 0;
    Processor->cycles = 0;
    Processor->complete = FALSE;
    
    memcpy(Processor->memory, Binary->data, sizeof(Processor->memory));
    
    return Processor;
}

void HKHubArchProcessorDestroy(HKHubArchProcessor Processor)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    CCFree(Processor);
}

void HKHubArchProcessorReset(HKHubArchProcessor Processor, HKHubArchBinary Binary)
{
    CCAssertLog(Processor, "Processor must not be null");
    CCAssertLog(Binary, "Binary must not be null");
    
    memcpy(Processor->memory, Binary->data, sizeof(Processor->memory));
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 0;
    Processor->state.r[2] = 0;
    Processor->state.r[3] = 0;
    Processor->state.pc = Binary->entrypoint;
    Processor->state.flags = 0;
    Processor->complete = FALSE;
}

void HKHubArchProcessorAddProcessingTime(HKHubArchProcessor Processor, double Seconds)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    Processor->cycles += Seconds * HKHubArchProcessorHertz;
    Processor->complete = FALSE;
}

void HKHubArchProcessorRun(HKHubArchProcessor Processor)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    while ((Processor->cycles) && (!Processor->complete))
    {
        HKHubArchInstructionState Instruction;
        uint8_t NextPC = HKHubArchInstructionDecode(Processor->state.pc, Processor->memory, &Instruction);
        
        if (Instruction.opcode != -1)
        {
            size_t Cycles = (NextPC - Processor->state.pc) * HKHubArchProcessorSpeedMemoryRead;
            if (Cycles < Processor->cycles)
            {
                Processor->cycles -= Cycles;
                if (!HKHubArchInstructionExecute(Processor, &Instruction))
                {
                    Processor->cycles += Cycles;
                    Processor->complete = TRUE;
                }
                
                else Processor->state.pc = NextPC;
            }
            
            else Processor->complete = TRUE;
        }
        
        else Processor->complete = TRUE;
    }
}
