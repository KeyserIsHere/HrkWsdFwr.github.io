/*
 *  Copyright (c) 2019, Stefan Johnson
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
#import "HubArchInstruction.h"
#import "HubArchJIT.h"

#define HKHubArchAssemblyPrintError(err) if (Errors) { HKHubArchAssemblyPrintError(err); CCCollectionDestroy(err); err = NULL; }

void HKHubArchJITCall(HKHubArchJIT JIT, HKHubArchProcessor Processor);

@interface HubArchJITTests : XCTestCase

@end

@implementation HubArchJITTests

-(void) run: (const char*)source
{
    CCOrderedCollection AST = HKHubArchAssemblyParse(source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchExecutionGraph Graph = HKHubArchExecutionGraphCreate(CC_STD_ALLOCATOR, Binary->data, Binary->entrypoint);
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary), ProcessorNormal = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchJIT JIT = HKHubArchJITCreate(CC_STD_ALLOCATOR, Graph);
    HKHubArchExecutionGraphDestroy(Graph);
    
    HKHubArchProcessorSetCycles(Processor, 1000);
    HKHubArchJITCall(JIT, Processor);
    
    HKHubArchJITDestroy(JIT);
    
    HKHubArchProcessorSetCycles(ProcessorNormal, 1000);
    HKHubArchProcessorRun(ProcessorNormal);
    
    XCTAssertEqual(Processor->state.r[0], ProcessorNormal->state.r[0], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[1], ProcessorNormal->state.r[1], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[2], ProcessorNormal->state.r[2], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[3], ProcessorNormal->state.r[3], "Should have the correct value");
    XCTAssertEqual(Processor->state.pc, ProcessorNormal->state.pc, "Should have the correct value");
    XCTAssertEqual(Processor->state.flags, ProcessorNormal->state.flags, "Should have the correct value");
    
    for (size_t Loop = 0; Loop < 256; Loop++) XCTAssertEqual(Processor->memory[Loop], ProcessorNormal->memory[Loop], "Should have the correct value");
    
    HKHubArchProcessorDestroy(Processor);
    HKHubArchProcessorDestroy(ProcessorNormal);
}

-(void) testAddition
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "add [0], 4\n"
        "hlt\n",
        
        "add r0, 4\n"
        "add r0, 5\n"
        "hlt\n",
        
        "add r0, 0\n"
        "hlt\n",
        
        "add r0, 1\n"
        "add r1, 2\n"
        "add r2, 3\n"
        "add r3, 4\n"
        "add r0, r1\n"
        "add r2, r3\n"
        "add r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "add r1, 1\n"
        "add r0, [r1]\n"
        "add r0, [r1+r0]\n"
        "add r0, [r1+1]\n"
        "add [r1], [r1-1]\n"
        "add [r1+r1], [r1+r1]\n"
        "hlt\n",
        
        "add r0, 127\n"
        "add r0, 1\n"
        "hlt\n",
        
        "add r0, -1\n"
        "add r0, -2\n"
        "hlt\n",
        
        "add r0, 128\n"
        "add r0, 2\n"
        "hlt\n",
        
        "add r0, 255\n"
        "add r0, 1\n"
        "hlt\n",
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

@end
