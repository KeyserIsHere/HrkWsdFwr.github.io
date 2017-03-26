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

@end
