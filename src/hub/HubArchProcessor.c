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

static uintmax_t HKHubArchProcessorPortHasher(HKHubArchPortID *Key)
{
    return *Key;
}

static void HKHubArchProcessorDestructor(HKHubArchProcessor Processor)
{
    CC_DICTIONARY_FOREACH_VALUE(HKHubArchPortConnection, Connection, Processor->ports)
    {
        for (int Loop = 0; Loop < 2; Loop++)
        {
            if (Connection->port[Loop].device == Processor) Connection->port[Loop].disconnect = NULL;
        }
        
        HKHubArchPortConnectionDisconnect(Connection);
    }
    
    CCDictionaryDestroy(Processor->ports);
    
    if (Processor->state.debug.breakpoints) CCDictionaryDestroy(Processor->state.debug.breakpoints);
}

HKHubArchProcessor HKHubArchProcessorCreate(CCAllocatorType Allocator, HKHubArchBinary Binary)
{
    CCAssertLog(Binary, "Binary must not be null");
    
    HKHubArchProcessor Processor = CCMalloc(Allocator, sizeof(HKHubArchProcessorInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (Processor)
    {
        Processor->ports = CCDictionaryCreate(Allocator, CCDictionaryHintHeavyFinding, sizeof(HKHubArchPortID), sizeof(HKHubArchPortConnection), &(CCDictionaryCallbacks){
            .getHash = (CCDictionaryKeyHasher)HKHubArchProcessorPortHasher,
            .valueDestructor = HKHubArchPortConnectionDestructorForDictionary
        });
        
        Processor->message.type = HKHubArchProcessorMessageClear;
        Processor->state.r[0] = 0;
        Processor->state.r[1] = 0;
        Processor->state.r[2] = 0;
        Processor->state.r[3] = 0;
        Processor->state.pc = Binary->entrypoint;
        Processor->state.flags = 0;
        Processor->state.debug.mode = HKHubArchProcessorDebugModeContinue;
        Processor->state.debug.step = 0;
        Processor->state.debug.breakpoints = NULL;
        Processor->state.debug.modified.reg = 0;
        Processor->state.debug.modified.size = 0;
        Processor->state.debug.operation = NULL;
        Processor->state.debug.breakpointChange = NULL;
        Processor->state.debug.debugModeChange = NULL;
        Processor->state.debug.context = NULL;
        Processor->cycles = 0;
        Processor->unusedTime = 0.0;
        Processor->complete = FALSE;
        
        memcpy(Processor->memory, Binary->data, sizeof(Processor->memory));
        
        CCMemorySetDestructor(Processor, (CCMemoryDestructorCallback)HKHubArchProcessorDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create processor, due to allocation failure (%zu)", sizeof(HKHubArchProcessorInfo));
    
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
    
    Processor->message.type = HKHubArchProcessorMessageClear;
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 0;
    Processor->state.r[2] = 0;
    Processor->state.r[3] = 0;
    Processor->state.pc = Binary->entrypoint;
    Processor->state.flags = 0;
    Processor->state.debug.modified.reg = 0;
    Processor->state.debug.modified.size = 0;
    Processor->complete = FALSE;
    
    HKHubArchProcessorDebugReset(Processor);
}

void HKHubArchProcessorDebugReset(HKHubArchProcessor Processor)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    Processor->state.debug.mode = HKHubArchProcessorDebugModeContinue;
    Processor->state.debug.step = 0;
    Processor->state.debug.modified.reg = 0;
    Processor->state.debug.modified.size = 0;
    Processor->state.debug.operation = NULL;
    Processor->state.debug.context = NULL;
    
    if (Processor->state.debug.breakpoints)
    {
        CCDictionaryDestroy(Processor->state.debug.breakpoints);
        Processor->state.debug.breakpoints = NULL;
    }
    
    if (Processor->state.debug.breakpointChange) Processor->state.debug.breakpointChange(Processor);
    if (Processor->state.debug.debugModeChange) Processor->state.debug.debugModeChange(Processor);
}

void HKHubArchProcessorSetCycles(HKHubArchProcessor Processor, size_t Cycles)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    Processor->cycles = Cycles;
    Processor->unusedTime = 0.0;
    Processor->complete = FALSE;
}

void HKHubArchProcessorAddProcessingTime(HKHubArchProcessor Processor, double Seconds)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    const double Cycles = (Seconds * HKHubArchProcessorHertz) + Processor->unusedTime;
    Processor->cycles += Cycles;
    Processor->unusedTime = Cycles - (size_t)Cycles;
    Processor->complete = FALSE;
}

static void HKHubArchProcessorDisconnectPort(HKHubArchProcessor Processor, HKHubArchPortID Port)
{
    CCDictionaryRemoveValue(Processor->ports, &Port);
}

static HKHubArchPortResponse HKHubArchProcessorPortSend(HKHubArchPortConnection Connection, HKHubArchProcessor Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, size_t Timestamp, size_t *Wait)
{
    /*
     Timestamp is the beginning of the 8 cycle wait period. While 6 cycles is the min a send/recv can consume to reach its timestamp.
     So if the current cycles is less than (timestamp - 2), then no matter what send/recv it uses, it won't be completed within the
     wait period.
     */
    if ((intmax_t)Device->cycles < ((intmax_t)Timestamp - 2)) return HKHubArchPortResponseTimeout;
    
    if (Device->message.type == HKHubArchProcessorMessageSend)
    {
        if (Device->message.port != Port) return Device->complete ? HKHubArchPortResponseDefer : HKHubArchPortResponseRetry;
        else if (Device->message.timestamp > (Timestamp + 8)) return HKHubArchPortResponseTimeout;
        
        *Message = Device->message.data;
                
        Device->message.wait = Device->message.timestamp > Timestamp ? Device->message.timestamp - Timestamp : 0;
        *Wait = Device->message.timestamp < Timestamp ? Timestamp - Device->message.timestamp : 0;
        
        if ((!HKHubArchPortIsReady(HKHubArchPortConnectionGetPort(Connection, Device, Port))) || (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port)))) return HKHubArchPortResponseDefer;
        
        Device->message.type = HKHubArchProcessorMessageComplete;
        
        return HKHubArchPortResponseSuccess;
    }
    
    else if ((Device->message.type == HKHubArchProcessorMessageReceive) && (Device->message.timestamp <= Timestamp)) return HKHubArchPortResponseTimeout;
    
    return (Device->complete || (Device->state.debug.mode == HKHubArchProcessorDebugModePause && !Device->state.debug.step)) ? HKHubArchPortResponseDefer : HKHubArchPortResponseRetry;
}

static HKHubArchPortResponse HKHubArchProcessorPortReceive(HKHubArchPortConnection Connection, HKHubArchProcessor Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, size_t Timestamp, size_t *Wait)
{
    /*
     Timestamp is the beginning of the 8 cycle wait period. While 6 cycles is the min a send/recv can consume to reach its timestamp. 
     So if the current cycles is less than (timestamp - 2), then no matter what send/recv it uses, it won't be completed within the
     wait period.
     */
    if ((intmax_t)Device->cycles < ((intmax_t)Timestamp - 2)) return HKHubArchPortResponseTimeout;
    
    if (Device->message.type == HKHubArchProcessorMessageReceive)
    {
        if (Device->message.port != Port) return Device->complete ? HKHubArchPortResponseDefer : HKHubArchPortResponseRetry;
        else if (Device->message.timestamp > (Timestamp + 8)) return HKHubArchPortResponseTimeout;
        
        const uint8_t Offset = Device->message.data.offset;
        for (size_t Loop = 0; Loop < Message->size; Loop++)
        {
            Device->memory[Offset + Loop] = Message->memory[Message->offset + Loop];
        }
        
        Device->message.wait = Device->message.timestamp > Timestamp ? Device->message.timestamp - Timestamp : 0;
        *Wait = Device->message.timestamp < Timestamp ? Timestamp - Device->message.timestamp : 0;
        
        if ((!HKHubArchPortIsReady(HKHubArchPortConnectionGetPort(Connection, Device, Port))) || (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port)))) return HKHubArchPortResponseDefer;
        
        Device->message.type = HKHubArchProcessorMessageComplete;
        
        Device->state.debug.modified.offset = Offset;
        Device->state.debug.modified.size = Message->size;
        
        return HKHubArchPortResponseSuccess;
    }
    
    else if ((Device->message.type == HKHubArchProcessorMessageSend) && (Device->message.timestamp <= Timestamp)) return HKHubArchPortResponseTimeout;
    
    return (Device->complete || (Device->state.debug.mode == HKHubArchProcessorDebugModePause && !Device->state.debug.step)) ? HKHubArchPortResponseDefer : HKHubArchPortResponseRetry;
}

_Bool HKHubArchProcessorPortReady(HKHubArchProcessor Device, HKHubArchPortID Port)
{
    size_t Cycles = Device->message.wait + (Device->message.data.size * HKHubArchProcessorSpeedPortTransmission);
    
    switch (Device->message.type)
    {
        case HKHubArchProcessorMessageSend:
            Cycles += Device->message.data.size * HKHubArchProcessorSpeedMemoryRead;
            break;
            
        case HKHubArchProcessorMessageReceive:
            Cycles += Device->message.data.size * HKHubArchProcessorSpeedMemoryWrite;
            break;
            
        default:
            CCAssertLog(0, "Should not be called unless operation is possible");
            break;
    }
    
    return Cycles <= Device->message.timestamp;
}

HKHubArchPort HKHubArchProcessorGetPort(HKHubArchProcessor Processor, HKHubArchPortID Port)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    return (HKHubArchPort){
        .device = Processor,
        .id = Port,
        .disconnect = NULL,
        .sender = (HKHubArchPortTransmit)HKHubArchProcessorPortSend,
        .receiver = (HKHubArchPortTransmit)HKHubArchProcessorPortReceive,
        .ready = (HKHubArchPortReady)HKHubArchProcessorPortReady
    };
}

static inline void HKHubArchProcessorSetConnectionDisconnectCallback(HKHubArchProcessor Processor, HKHubArchPortID Port, HKHubArchPortConnection Connection, HKHubArchPortDisconnect Disconnect)
{
    for (int Loop = 0; Loop < 2; Loop++)
    {
        if ((Connection->port[Loop].device == Processor) && (Connection->port[Loop].id == Port))
        {
            Connection->port[Loop].disconnect = Disconnect;
        }
    }
}

void HKHubArchProcessorConnect(HKHubArchProcessor Processor, HKHubArchPortID Port, HKHubArchPortConnection Connection)
{
    CCAssertLog(Processor, "Processor must not be null");
    CCAssertLog(Connection, "Connection must not be null");
    
    CCDictionaryEntry Entry = CCDictionaryEntryForKey(Processor->ports, &Port);
    
    if (CCDictionaryEntryIsInitialized(Processor->ports, Entry))
    {
        HKHubArchPortConnection OldConnection = *(HKHubArchPortConnection*)CCDictionaryGetEntry(Processor->ports, Entry);
        HKHubArchProcessorSetConnectionDisconnectCallback(Processor, Port, OldConnection, NULL);
        HKHubArchPortConnectionDisconnect(OldConnection);
    }
    
    HKHubArchProcessorSetConnectionDisconnectCallback(Processor, Port, Connection, (HKHubArchPortDisconnect)HKHubArchProcessorDisconnectPort);
    
    CCDictionarySetEntry(Processor->ports, Entry, &(HKHubArchPortConnection){ CCRetain(Connection) });
}

void HKHubArchProcessorDisconnect(HKHubArchProcessor Processor, HKHubArchPortID Port)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    HKHubArchPortConnection *Connection = CCDictionaryGetValue(Processor->ports, &Port);
    
    if (Connection) HKHubArchPortConnectionDisconnect(*Connection);
}

static HKHubArchProcessorDebugBreakpoint HKHubArchProcessorGetBreakpoint(HKHubArchProcessor Processor, uint8_t Offset)
{
    HKHubArchProcessorDebugBreakpoint *Breakpoint = CCDictionaryGetValue(Processor->state.debug.breakpoints, &Offset);
    
    return Breakpoint ? *Breakpoint : HKHubArchProcessorDebugBreakpointNone;
}

static _Bool HKHubArchProcessorShouldBreakForRange(HKHubArchProcessor Processor, uint8_t From, uint8_t Till, HKHubArchProcessorDebugBreakpoint Breakpoint)
{
    for ( ; From != Till; From++)
    {
        if (HKHubArchProcessorGetBreakpoint(Processor, From) & Breakpoint) return TRUE;
    }
    
    return FALSE;
}

void HKHubArchProcessorRun(HKHubArchProcessor Processor)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    while ((!Processor->complete) && !(Processor->complete = !Processor->cycles) && (((Processor->state.debug.mode != HKHubArchProcessorDebugModePause) || (Processor->state.debug.step))))
    {
        HKHubArchInstructionState Instruction;
        uint8_t NextPC = HKHubArchInstructionDecode(Processor->state.pc, Processor->memory, &Instruction);
        
        if (Instruction.opcode != -1)
        {
            if ((Processor->state.debug.breakpoints) && (Processor->state.debug.step == 0))
            {
                if (HKHubArchProcessorShouldBreakForRange(Processor, Processor->state.pc, NextPC, HKHubArchProcessorDebugBreakpointRead))
                {
                    Processor->state.debug.mode = HKHubArchProcessorDebugModePause;
                    if (Processor->state.debug.debugModeChange) Processor->state.debug.debugModeChange(Processor);
                    continue;
                }
                
                _Bool TriggeredBP = FALSE;
                HKHubArchInstructionMemoryOperation MemoryOp = HKHubArchInstructionGetMemoryOperation(&Instruction);
                for (size_t Loop = 0; Loop < 3; Loop++)
                {
                    if (Instruction.operand[Loop].type == HKHubArchInstructionOperandM)
                    {
                        uint8_t Offset = 0;
                        switch (Instruction.operand[Loop].memory.type)
                        {
                            case HKHubArchInstructionMemoryOffset:
                                Offset = Instruction.operand[Loop].memory.offset;
                                break;
                                
                            case HKHubArchInstructionMemoryRegister:
                                Offset = Processor->state.r[Instruction.operand[Loop].memory.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                                break;
                                
                            case HKHubArchInstructionMemoryRelativeOffset:
                                Offset = Instruction.operand[Loop].memory.relativeOffset.offset + Processor->state.r[Instruction.operand[Loop].memory.relativeOffset.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                                break;
                                
                            case HKHubArchInstructionMemoryRelativeRegister:
                                Offset = Processor->state.r[Instruction.operand[Loop].memory.relativeReg[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask] + Processor->state.r[Instruction.operand[Loop].memory.relativeReg[1] & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                                break;
                        }
                        
                        
                        _Static_assert(HKHubArchInstructionMemoryOperationMask == 3 &&
                                       HKHubArchInstructionMemoryOperationSrc == 1 &&
                                       HKHubArchInstructionMemoryOperationDst == 2 &&
                                       HKHubArchInstructionMemoryOperationOp1 == 0 &&
                                       HKHubArchInstructionMemoryOperationOp2 == 2 &&
                                       HKHubArchInstructionMemoryOperationOp3 == 4, "Expects the following operand mask layout");
                        
                        static const HKHubArchProcessorDebugBreakpoint Breakpoint[] = {
                            HKHubArchProcessorDebugBreakpointNone,
                            HKHubArchProcessorDebugBreakpointRead,
                            HKHubArchProcessorDebugBreakpointWrite,
                            HKHubArchProcessorDebugBreakpointRead | HKHubArchProcessorDebugBreakpointWrite
                        };
                        
                        if (HKHubArchProcessorShouldBreakForRange(Processor, Offset, Offset + 1, Breakpoint[(MemoryOp >> (Loop * 2)) & HKHubArchInstructionMemoryOperationMask]))
                        {
                            Processor->state.debug.mode = HKHubArchProcessorDebugModePause;
                            if (Processor->state.debug.debugModeChange) Processor->state.debug.debugModeChange(Processor);
                            
                            TriggeredBP = TRUE;
                            break;
                        }
                    }
                }
                
                if (TriggeredBP) continue;
            }
            
            size_t Cycles = (NextPC - Processor->state.pc) * HKHubArchProcessorSpeedMemoryRead;
            if (Cycles < Processor->cycles)
            {
                Processor->cycles -= Cycles;
                
                HKHubArchInstructionOperationResult Result;
                if (((Result = HKHubArchInstructionExecute(Processor, &Instruction)) & HKHubArchInstructionOperationResultMask) == HKHubArchInstructionOperationResultFailure)
                {
                    Processor->cycles += Cycles;
                    
                    if (Result & HKHubArchInstructionOperationResultFlagPipelineStall) break;
                    
                    Processor->complete = TRUE;
                }
                
                else
                {
                    if (!(Result & HKHubArchInstructionOperationResultFlagSkipPC)) Processor->state.pc = NextPC;
                    
                    if (Processor->state.debug.operation) Processor->state.debug.operation(Processor, &Instruction);
                    
                    Processor->state.debug.modified.reg = 0;
                    Processor->state.debug.modified.size = 0;
                    
                    if ((Processor->state.debug.step) && (--Processor->state.debug.step == 0)) continue;
                }
            }
            
            else Processor->complete = TRUE;
        }
        
        else Processor->complete = TRUE;
    }
}

void HKHubArchProcessorStep(HKHubArchProcessor Processor, size_t Count)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    Processor->state.debug.step = Count;
}

void HKHubArchProcessorSetDebugMode(HKHubArchProcessor Processor, HKHubArchProcessorDebugMode Mode)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    Processor->state.debug.mode = Mode;
    
    if (Processor->state.debug.debugModeChange) Processor->state.debug.debugModeChange(Processor);
}

void HKHubArchProcessorSetBreakpoint(HKHubArchProcessor Processor, HKHubArchProcessorDebugBreakpoint Breakpoint, uint8_t Offset)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    if (!Processor->state.debug.breakpoints) Processor->state.debug.breakpoints = CCDictionaryCreate(CC_STD_ALLOCATOR, CCDictionaryHintHeavyEnumerating | CCDictionaryHintHeavyFinding | CCCollectionHintHeavyInserting | CCCollectionHintHeavyDeleting, sizeof(uint8_t), sizeof(HKHubArchProcessorDebugBreakpoint), NULL);
    
    CCDictionarySetValue(Processor->state.debug.breakpoints, &Offset, &Breakpoint);
    
    if (Processor->state.debug.breakpointChange) Processor->state.debug.breakpointChange(Processor);
}

void HKHubArchProcessorClearBreakpoints(HKHubArchProcessor Processor)
{
    CCAssertLog(Processor, "Processor must not be null");
    
    if (Processor->state.debug.breakpoints)
    {
        CCDictionaryDestroy(Processor->state.debug.breakpoints);
        Processor->state.debug.breakpoints = NULL;
        
        if (Processor->state.debug.breakpointChange) Processor->state.debug.breakpointChange(Processor);
    }
}
