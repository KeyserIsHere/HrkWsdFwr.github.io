/*
 *  Copyright (c) 2017, Stefan Johnson
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

#import <XCTest/XCTest.h>
#import "HubArchProcessor.h"
#import "HubArchAssembly.h"
#import "HubArchScheduler.h"

#define HKHubArchAssemblyPrintError(err) if (Errors) { HKHubArchAssemblyPrintError(err); CCCollectionDestroy(err); err = NULL; }

@interface HubArchDebuggingTests : XCTestCase

@end

@implementation HubArchDebuggingTests

-(void) testInstructionStepping
{
    const char *Source =
        "data: .byte 2\n"
        ".entrypoint\n"
        "mov r0, [data]\n"
        "add r0, 2\n"
        "jmp skip\n"
        "sub r0, 2\n"
        "skip:\n"
        "mov [data], r0\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModePause);
    
    HKHubArchProcessorStep(Processor, 1); //mov r0, [data]
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 2, "Should change");
    
    HKHubArchProcessorStep(Processor, 1); //add r0, 2
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 4, "Should change");
    
    HKHubArchProcessorStep(Processor, 1); //jmp skip
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 4, "Should remain unchanged");
    
    HKHubArchProcessorStep(Processor, 1); //mov [data], r0
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 4, "Should change");
    XCTAssertEqual(Processor->state.r[0], 4, "Should remain unchanged");
    
    HKHubArchProcessorStep(Processor, 1); //hlt
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 4, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 4, "Should remain unchanged");
    
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModePause);
    
    HKHubArchProcessorStep(Processor, 3); //mov r0, [data]; add r0, 2; jmp skip
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should change");
    XCTAssertEqual(Processor->state.r[0], 4, "Should change");
    
    HKHubArchProcessorStep(Processor, 1); //mov [data], r0
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 4, "Should change");
    XCTAssertEqual(Processor->state.r[0], 4, "Should remain unchanged");
    
    HKHubArchProcessorStep(Processor, 1); //hlt
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 4, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 4, "Should remain unchanged");
    
    HKHubArchBinaryDestroy(Binary);
    HKHubArchProcessorDestroy(Processor);
}

-(void) testDebugMode
{
    const char *Source =
        "data: .byte 2\n"
        ".entrypoint\n"
        "mov r0, [data]\n"
        "add r0, 2\n"
        "jmp skip\n"
        "sub r0, 2\n"
        "skip:\n"
        "mov [data], r0\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 4, "Should change");
    XCTAssertEqual(Processor->state.r[0], 4, "Should change");
    
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModePause);
    
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 0, "Should remain unchanged");
    
    HKHubArchProcessorStep(Processor, 1); //mov r0, [data]
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->memory[0], 2, "Should remain unchanged");
    XCTAssertEqual(Processor->state.r[0], 2, "Should change");
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorStep(Processor, 1); //add r0, 2
    HKHubArchProcessorRun(Processor); //jmp skip ; mov [data], r0 ; hlt
    XCTAssertEqual(Processor->memory[0], 4, "Should change");
    XCTAssertEqual(Processor->state.r[0], 4, "Should change");
    
    HKHubArchBinaryDestroy(Binary);
    HKHubArchProcessorDestroy(Processor);
}

-(void) testBreakpoints
{
    const char *Source =
        "data: .byte 2\n" //0:
        ".entrypoint\n"
        "mov r0, [data]\n" //1:
        "add r0, 2\n" //4:
        "jmp skip\n" //7:
        "sub r0, 2\n" //9:
        "skip:\n"
        "mov [data], r0\n" //12:
        "hlt\n" //15:
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorSetBreakpoint(Processor, HKHubArchProcessorDebugBreakpointRead | HKHubArchProcessorDebugBreakpointWrite, 0);
    HKHubArchProcessorSetBreakpoint(Processor, HKHubArchProcessorDebugBreakpointRead, 4);
    
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 1, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 1, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    HKHubArchProcessorStep(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 4, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    HKHubArchProcessorStep(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 7, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 12, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetBreakpoint(Processor, HKHubArchProcessorDebugBreakpointWrite, 0);
    
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 12, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorSetBreakpoint(Processor, HKHubArchProcessorDebugBreakpointRead, 0);
    
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 1, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorStep(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 15, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModeContinue, "Should break at the correct location");
    
    HKHubArchBinaryDestroy(Binary);
    HKHubArchProcessorDestroy(Processor);
}

-(void) testDebuggingCycles
{
    const char *Source =
        "data: .byte 2\n" //0:
        ".entrypoint\n"
        "mov r0, [data]\n" //1:
        "add r0, 2\n" //4:
        "jmp skip\n" //7:
        "sub r0, 2\n" //9:
        "skip:\n"
        "mov [data], r0\n" //12:
        "hlt\n" //15:
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    
    HKHubArchScheduler Scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    HKHubArchSchedulerAddProcessor(Scheduler, Processor);
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchProcessorSetBreakpoint(Processor, HKHubArchProcessorDebugBreakpointRead, 4);
    
    HKHubArchSchedulerRun(Scheduler, 1.0);
    XCTAssertEqual(Processor->state.pc, 4, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    XCTAssertEqual(Processor->cycles, 0, "Should have the correct amount of cycles");
    
    HKHubArchProcessorStep(Processor, 1);
    HKHubArchSchedulerRun(Scheduler, 1.0);
    XCTAssertEqual(Processor->state.pc, 7, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModePause, "Should break at the correct location");
    XCTAssertEqual(Processor->cycles, 0, "Should have the correct amount of cycles");
    
    HKHubArchProcessorStep(Processor, 1);
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
    HKHubArchSchedulerRun(Scheduler, 1.0);
    XCTAssertEqual(Processor->state.pc, 15, "Should break at the correct location");
    XCTAssertEqual(Processor->state.debug.mode, HKHubArchProcessorDebugModeContinue, "Should break at the correct location");
    XCTAssertEqual(Processor->cycles, HKHubArchProcessorHertz - 8 - (_Bool)(Processor->status & HKHubArchProcessorStatusIdle), "Should have the correct amount of cycles");
    
    HKHubArchBinaryDestroy(Binary);
    HKHubArchProcessorDestroy(Processor);
    HKHubArchSchedulerDestroy(Scheduler);
}

@end
