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

#include "HubSystem.h"
#include <threads.h>
#include "HubProcessorComponent.h"
#include "HubArchScheduler.h"
#include "HubArchInstruction.h"

static _Bool HKHubSystemTryLock(void);
static void HKHubSystemLock(void);
static void HKHubSystemUnlock(void);
static _Bool HKHubSystemHandlesComponent(CCComponentID id);
static void HKHubSystemUpdate(double DeltaTime, CCCollection Components);

static HKHubArchScheduler Scheduler;
static mtx_t Lock;
void HKHubSystemRegister(void)
{
    int err;
    if ((err = mtx_init(&Lock, mtx_plain | mtx_recursive)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to create hub system lock (%d)", err);
        exit(EXIT_FAILURE); //TODO: How should we handle this?
    }
    
    Scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    
    CCComponentSystemRegister(HK_HUB_SYSTEM_ID, CCComponentSystemExecutionTypeUpdate, (CCComponentSystemUpdateCallback)HKHubSystemUpdate, NULL, HKHubSystemHandlesComponent, NULL, NULL, HKHubSystemTryLock, HKHubSystemLock, HKHubSystemUnlock);
}

void HKHubSystemDeregister(void)
{
    mtx_destroy(&Lock);
    
    CCComponentSystemDeregister(HK_HUB_SYSTEM_ID, CCComponentSystemExecutionTypeUpdate);
}

static _Bool HKHubSystemTryLock(void)
{
    int err = mtx_trylock(&Lock);
    if ((err != thrd_success) && (err != thrd_busy))
    {
        CC_LOG_ERROR("Failed to lock hub system (%d)", err);
    }
    
    return err == thrd_success;
}

static void HKHubSystemLock(void)
{
    int err;
    if ((err = mtx_lock(&Lock)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to lock hub system (%d)", err);
    }
}

static void HKHubSystemUnlock(void)
{
    int err;
    if ((err = mtx_unlock(&Lock)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to unlock hub system (%d)", err);
    }
}

static _Bool HKHubSystemHandlesComponent(CCComponentID id)
{
    return (id & 0x7f000000) == HK_HUB_COMPONENT_FLAG;
}

static GUIObject GUIObjectWithNamespace(CCString Namespace)
{
    CC_COLLECTION_FOREACH(GUIObject, UI, GUIManagerGetObjects())
    {
        CCExpression Name = CCExpressionGetStateStrict(GUIObjectGetExpressionState(UI), CC_STRING("@namespace"));
        if ((Name) && (CCExpressionGetType(Name) == CCExpressionValueTypeAtom) && (CCStringEqual(CCExpressionGetAtom(Name), Namespace))) return UI;
        
        GUIObjectWithNamespace(Namespace);
    }
    
    return NULL;
}

static CCString BreakpointType[] = {
    0,
    CC_STRING(":read"),
    CC_STRING(":write"),
    CC_STRING(":read-write")
};

static void HKHubSystemInitDebugger(GUIObject Debugger, HKHubArchProcessor Processor)
{
    //TODO: Set target processor? so it can message back
    CCExpression State = GUIObjectGetExpressionState(Debugger);
    
    CCExpression Memory = CCExpressionCreateList(CC_STD_ALLOCATOR);
    for (size_t Loop = 0; Loop < sizeof(Processor->memory) / sizeof(typeof(*Processor->memory)); Loop++)
    {
        CCOrderedCollectionAppendElement(CCExpressionGetList(Memory), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->memory[Loop]) });
    }
    
    CCExpressionSetState(State, CC_STRING(".memory"), Memory, FALSE);
    CCExpressionSetState(State, CC_STRING(".memory-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
    CCExpressionSetState(State, CC_STRING(".memory-modified"), CCExpressionCreateList(CC_STD_ALLOCATOR), FALSE);
    
    
    CCExpressionSetState(State, CC_STRING(".r0"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.r[0]), FALSE);
    CCExpressionSetState(State, CC_STRING(".r1"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.r[1]), FALSE);
    CCExpressionSetState(State, CC_STRING(".r2"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.r[2]), FALSE);
    CCExpressionSetState(State, CC_STRING(".r3"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.r[3]), FALSE);
    CCExpressionSetState(State, CC_STRING(".r0-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r1-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r2-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r3-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    
    CCExpressionSetState(State, CC_STRING(".flags"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.flags), FALSE);
    CCExpressionSetState(State, CC_STRING(".flags-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    
    CCExpressionSetState(State, CC_STRING(".pc"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.pc), FALSE);
    CCExpressionSetState(State, CC_STRING(".pc-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    
    
    CCExpression Breakpoints = CCExpressionCreateList(CC_STD_ALLOCATOR);
    if (Processor->state.debug.breakpoints)
    {
        CC_DICTIONARY_FOREACH_KEY(uint8_t, Offset, Processor->state.debug.breakpoints)
        {
            HKHubArchProcessorDebugBreakpoint *Bp = CCDictionaryGetValue(Processor->state.debug.breakpoints, &Offset);
            
            if (BreakpointType[*Bp])
            {
                CCExpression Breakpoint = CCExpressionCreateList(CC_STD_ALLOCATOR);
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoint), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Offset) });
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoint), &(CCExpression){ CCExpressionCreateAtom(CC_STD_ALLOCATOR, BreakpointType[*Bp], TRUE) });
                
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoints), &Breakpoint);
            }
        }
    }
    
    CCExpressionSetState(State, CC_STRING(".breakpoints"), Breakpoints, FALSE);
    CCExpressionSetState(State, CC_STRING(".breakpoints-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
    
    
    CCExpression Ports = CCExpressionCreateList(CC_STD_ALLOCATOR);
    //TODO: Get list of open ports (so it can display connected/disconnected)
    
    CCExpressionSetState(State, CC_STRING(".ports"), Ports, FALSE);
    CCExpressionSetState(State, CC_STRING(".ports-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
}

static void HKHubSystemDebuggerInstructionHook(HKHubArchProcessor Processor, const HKHubArchInstructionState *Instruction)
{
    //TODO: Send update message (instead of update here/avoid locking UI)
    GUIManagerLock();
    
    CCExpression State = GUIObjectGetExpressionState(Processor->state.debug.context);
    
    CCExpressionSetState(State, CC_STRING(".r0-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r1-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r2-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    CCExpressionSetState(State, CC_STRING(".r3-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, FALSE), FALSE);
    
    CCExpressionSetState(State, CC_STRING(".flags"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.flags), FALSE); //TODO: Workout how to convey changed flags
    CCExpressionSetState(State, CC_STRING(".flags-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
    
    CCExpressionSetState(State, CC_STRING(".pc"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.pc), FALSE);
    CCExpressionSetState(State, CC_STRING(".pc-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
    
    CCExpression Modified = CCExpressionGetStateStrict(State, CC_STRING(".memory-modified"));
    CCExpressionSetState(State, CC_STRING(".memory-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, ((Modified) && (CCExpressionGetType(Modified) == CCExpressionValueTypeInteger) ? !CCExpressionGetInteger(Modified) : TRUE)), FALSE);
    CCExpressionSetState(State, CC_STRING(".memory-modified"), CCExpressionCreateList(CC_STD_ALLOCATOR), FALSE);
    
    
    HKHubArchInstructionMemoryOperation MemoryOp = HKHubArchInstructionGetMemoryOperation(Instruction);
    for (size_t Loop = 0; Loop < 3; Loop++)
    {
        if (Instruction->operand[Loop].type == HKHubArchInstructionOperandM)
        {
            //TODO: Calculating offset could be wrong as processor state has changed, implement better alternative to get changed state
            if ((MemoryOp >> (Loop * 2)) & HKHubArchInstructionMemoryOperationDst)
            {
                if (Instruction->operand[Loop].type == HKHubArchInstructionOperandM)
                {
                    uint8_t Offset = 0;
                    switch (Instruction->operand[Loop].memory.type)
                    {
                        case HKHubArchInstructionMemoryOffset:
                            Offset = Instruction->operand[Loop].memory.offset;
                            break;
                            
                        case HKHubArchInstructionMemoryRegister:
                            Offset = Processor->state.r[Instruction->operand[Loop].memory.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                            break;
                            
                        case HKHubArchInstructionMemoryRelativeOffset:
                            Offset = Instruction->operand[Loop].memory.relativeOffset.offset + Processor->state.r[Instruction->operand[Loop].memory.relativeOffset.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                            break;
                            
                        case HKHubArchInstructionMemoryRelativeRegister:
                            Offset = Processor->state.r[Instruction->operand[Loop].memory.relativeReg[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask] + Processor->state.r[Instruction->operand[Loop].memory.relativeReg[1] & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                            break;
                    }
                    
                    CCExpression Memory = CCExpressionCreateList(CC_STD_ALLOCATOR);
                    for (size_t Loop = 0; Loop < sizeof(Processor->memory) / sizeof(typeof(*Processor->memory)); Loop++)
                    {
                        CCOrderedCollectionAppendElement(CCExpressionGetList(Memory), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->memory[Loop]) });
                    }
                    
                    CCExpressionSetState(State, CC_STRING(".memory"), Memory, FALSE);
                    CCExpressionSetState(State, CC_STRING(".memory-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
                    //TODO: Change modified range to work for variable recv's (only instruction that may modify more than 1 byte)
                    CCExpression ModifiedMemory = CCExpressionCreateList(CC_STD_ALLOCATOR);
                    CCExpression ModifiedRange = CCExpressionCreateList(CC_STD_ALLOCATOR);
                    CCOrderedCollectionAppendElement(CCExpressionGetList(ModifiedRange), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Offset) });
                    CCOrderedCollectionAppendElement(CCExpressionGetList(ModifiedRange), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Offset + 1) });
                    
                    CCOrderedCollectionAppendElement(CCExpressionGetList(ModifiedMemory), &ModifiedRange);
                    
                    CCExpressionSetState(State, CC_STRING(".memory-modified"), ModifiedMemory, FALSE);
                }
            }
        }
        
        else if (Instruction->operand[Loop].type == HKHubArchInstructionOperandR)
        {
            if ((MemoryOp >> (Loop * 2)) & HKHubArchInstructionMemoryOperationDst)
            {
                CCString Reg[][2] = {
                    { CC_STRING(".r0"), CC_STRING(".r0-changed") },
                    { CC_STRING(".r1"), CC_STRING(".r1-changed") },
                    { CC_STRING(".r2"), CC_STRING(".r2-changed") },
                    { CC_STRING(".r3"), CC_STRING(".r3-changed") },
                    { CC_STRING(".flags"), CC_STRING(".flags-changed") },
                    { CC_STRING(".pc"), CC_STRING(".pc-changed") }
                };
                
                if (Instruction->operand[Loop].reg & HKHubArchInstructionRegisterGeneralPurpose)
                {
                    const size_t Index = Instruction->operand[Loop].reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask;
                    
                    CCExpressionSetState(State, Reg[Index][0], CCExpressionCreateInteger(CC_STD_ALLOCATOR, Processor->state.r[Index]), FALSE);
                    CCExpressionSetState(State, Reg[Index][1], CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
                }
                
                else if (Instruction->operand[Loop].reg & HKHubArchInstructionRegisterSpecialPurpose)
                {
                    const size_t Index = (Instruction->operand[Loop].reg &  HKHubArchInstructionRegisterSpecialPurposeIndexMask) + 4;
                    
                    CCExpressionSetState(State, Reg[Index][0], CCExpressionCreateInteger(CC_STD_ALLOCATOR, Index == 4 ? Processor->state.flags : Processor->state.pc), FALSE);
                    CCExpressionSetState(State, Reg[Index][1], CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
                }
            }
        }
    }
    
    GUIManagerUnlock();
}

static void HKHubSystemDebuggerBreakpointChangeHook(HKHubArchProcessor Processor)
{
    //TODO: Send update message (instead of update here/avoid locking UI)
    GUIManagerLock();
    
    CCExpression State = GUIObjectGetExpressionState(Processor->state.debug.context);
    
    CCExpression Breakpoints = CCExpressionCreateList(CC_STD_ALLOCATOR);
    if (Processor->state.debug.breakpoints)
    {
        CC_DICTIONARY_FOREACH_KEY(uint8_t, Offset, Processor->state.debug.breakpoints)
        {
            HKHubArchProcessorDebugBreakpoint *Bp = CCDictionaryGetValue(Processor->state.debug.breakpoints, &Offset);
            
            if (BreakpointType[*Bp])
            {
                CCExpression Breakpoint = CCExpressionCreateList(CC_STD_ALLOCATOR);
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoint), &(CCExpression){ CCExpressionCreateInteger(CC_STD_ALLOCATOR, Offset) });
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoint), &(CCExpression){ CCExpressionCreateAtom(CC_STD_ALLOCATOR, BreakpointType[*Bp], TRUE) });
                
                CCOrderedCollectionAppendElement(CCExpressionGetList(Breakpoints), &Breakpoint);
            }
        }
    }
    
    CCExpressionSetState(State, CC_STRING(".breakpoints"), Breakpoints, FALSE);
    CCExpressionSetState(State, CC_STRING(".breakpoints-changed"), CCExpressionCreateInteger(CC_STD_ALLOCATOR, TRUE), FALSE);
    
    GUIManagerUnlock();
}

static void HKHubSystemAttachDebugger(CCComponent Debugger)
{
    CC_COLLECTION_FOREACH(CCComponent, Component, CCEntityGetComponents(CCComponentGetEntity(Debugger)))
    {
        if ((CCComponentGetID(Component) & HKHubTypeMask) == HKHubTypeProcessor)
        {
            HKHubArchProcessor Target = HKHubProcessorComponentGetProcessor(Component);
            HKHubArchProcessorSetDebugMode(Target, HKHubArchProcessorDebugModePause);
            
            Target->state.debug.operation = HKHubSystemDebuggerInstructionHook;
            Target->state.debug.breakpointChange = HKHubSystemDebuggerBreakpointChangeHook;
            
            GUIManagerLock();
            Target->state.debug.context = GUIObjectWithNamespace(CC_STRING(":debugger"));
            HKHubSystemInitDebugger(Target->state.debug.context, Target);
            GUIManagerUnlock();
            
            break;
        }
    }
}

static void HKHubSystemDetachDebugger(CCComponent Debugger)
{
    CCEntity Entity = CCComponentGetEntity(Debugger);
    CC_COLLECTION_FOREACH(CCComponent, Component, CCEntityGetComponents(Entity))
    {
        if ((CCComponentGetID(Component) & HKHubTypeMask) == HKHubTypeProcessor)
        {
            HKHubArchProcessor Target = HKHubProcessorComponentGetProcessor(Component);
            HKHubArchProcessorSetDebugMode(Target, HKHubArchProcessorDebugModeContinue);
            
            GUIManagerLock();
            GUIObjectSetEnabled(Target->state.debug.context, FALSE);
            GUIManagerUnlock();
            
            Target->state.debug.context = NULL;
            Target->state.debug.operation = NULL;
            
            break;
        }
    }
    
    CCEntityDetachComponent(Entity, Debugger);
}

typedef struct {
    void (*processor)(HKHubArchScheduler, HKHubArchProcessor);
    void (*debugger)(CCComponent);
} HKHubSystemUpdater;

static void HKHubSystemUpdateScheduler(CCCollection Components, HKHubSystemUpdater Update)
{
    CC_COLLECTION_FOREACH(CCComponent, Hub, Components)
    {
        const HKHubType Type = CCComponentGetID(Hub) & HKHubTypeMask;
        if (Type == HKHubTypeProcessor)
        {
            Update.processor(Scheduler, HKHubProcessorComponentGetProcessor(Hub));
        }
        
        else if (Type == HKHubTypeDebugger)
        {
            Update.debugger(Hub);
        }
    }
    
    CCCollectionDestroy(Components);
}

static void HKHubSystemUpdate(double DeltaTime, CCCollection Components)
{
    HKHubSystemUpdateScheduler(CCComponentSystemGetAddedComponentsForSystem(HK_HUB_SYSTEM_ID), (HKHubSystemUpdater){
        .processor = HKHubArchSchedulerAddProcessor,
        .debugger = HKHubSystemAttachDebugger
    });
    HKHubSystemUpdateScheduler(CCComponentSystemGetRemovedComponentsForSystem(HK_HUB_SYSTEM_ID), (HKHubSystemUpdater){
        .processor = HKHubArchSchedulerRemoveProcessor,
        .debugger = HKHubSystemDetachDebugger
    });
    
    HKHubArchSchedulerRun(Scheduler, DeltaTime);
}

HKHubArchScheduler HKHubSystemGetScheduler(void)
{
    return Scheduler;
}
