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

#import <XCTest/XCTest.h>
#import "HubArchProcessor.h"
#import "HubArchAssembly.h"

@interface HubArchInstructionTests : XCTestCase

@end

@implementation HubArchInstructionTests

-(void) testBranching
{
    const char *Source =
        "A: jmp C\n"
        "B: jmp D\n"
        "C: jmp B\n"
        "D: jmp F\n"
        "E: jmp A\n"
        "F: jmp E\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process first jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process first jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 4, @"Processes first jump");
    
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 4);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 4, @"Processes first jump but not enough for second jump");
    
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 5);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 4, @"Processes first jump but not enough for second jump");
    
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 6);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes first jump and second jump");
    
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 18);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Processes all jumps once");
    
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 21);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 4, @"Processes all jumps once and first jump");
    
    HKHubArchProcessorDestroy(Processor);
}

@end
