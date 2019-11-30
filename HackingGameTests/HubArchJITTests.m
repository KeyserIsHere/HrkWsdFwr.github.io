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
    for (size_t PrevCycles = 0; PrevCycles != Processor->cycles; )
    {
        PrevCycles = Processor->cycles;
        HKHubArchJITCall(JIT, Processor);
    }
    
    HKHubArchJITDestroy(JIT);
    
    HKHubArchProcessorSetCycles(ProcessorNormal, 1000);
    HKHubArchProcessorRun(ProcessorNormal);
    
    XCTAssertEqual(Processor->state.r[0], ProcessorNormal->state.r[0], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[1], ProcessorNormal->state.r[1], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[2], ProcessorNormal->state.r[2], "Should have the correct value");
    XCTAssertEqual(Processor->state.r[3], ProcessorNormal->state.r[3], "Should have the correct value");
    XCTAssertEqual(Processor->state.pc, ProcessorNormal->state.pc, "Should have the correct value");
    XCTAssertEqual(Processor->state.flags, ProcessorNormal->state.flags, "Should have the correct value");
    XCTAssertEqual(Processor->cycles ? (Processor->cycles - 1) : 0, ProcessorNormal->cycles, "Should have the correct value");
    
    for (size_t Loop = 0; Loop < 256; Loop++) XCTAssertEqual(Processor->memory[Loop], ProcessorNormal->memory[Loop], "Should have the correct value");
    
    HKHubArchProcessorDestroy(Processor);
    HKHubArchProcessorDestroy(ProcessorNormal);
}

-(void) testMove
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "mov [0], 4\n"
        "hlt\n",
        
        "mov r0, 4\n"
        "mov r0, 5\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "hlt\n",
        
        "mov r0, 1\n"
        "mov r1, 2\n"
        "mov r2, 3\n"
        "mov r3, 4\n"
        "mov r0, r1\n"
        "mov r2, r3\n"
        "mov r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "mov r1, 1\n"
        "mov r0, [r1]\n"
        "mov r0, [r1+r0]\n"
        "mov r0, [r1+1]\n"
        "mov r0, [1]\n"
        "mov [r1], [r1]\n"
        "mov [r1], [r1-1]\n"
        "mov [r1], [r1+r1]\n"
        "mov [r1], [1]\n"
        "mov [r1], r1\n"
        "mov [r1], 1\n"
        "mov [r1+r1], [r1]\n"
        "mov [r1+r1], [r1-1]\n"
        "mov [r1+r1], [r1+r1]\n"
        "mov [r1+r1], [1]\n"
        "mov [r1+r1], r1\n"
        "mov [r1+r1], 1\n"
        "mov [r1-1], [r1]\n"
        "mov [r1-1], [r1-1]\n"
        "mov [r1-1], [r1+r1]\n"
        "mov [r1-1], [1]\n"
        "mov [r1-1], r1\n"
        "mov [r1-1], 1\n"
        "mov [1], [r1]\n"
        "mov [1], [r1-1]\n"
        "mov [1], [r1+r1]\n"
        "mov [1], [1]\n"
        "mov [1], r1\n"
        "mov [1], 1\n"
        "hlt\n",
        
        "mov r0, 127\n"
        "mov r0, 1\n"
        "hlt\n",
        
        "mov r0, -1\n"
        "mov r0, -2\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r0, 2\n"
        "hlt\n",
        
        "mov r0, 255\n"
        "mov r0, 1\n"
        "hlt\n",
        
        "mov flags, 255\n"
        "hlt\n",
        
        "mov pc, skip\n"
        "mov r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
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
        "add r0, [1]\n"
        "add [r1], [r1]\n"
        "add [r1], [r1-1]\n"
        "add [r1], [r1+r1]\n"
        "add [r1], [1]\n"
        "add [r1], r1\n"
        "add [r1], 1\n"
        "add [r1+r1], [r1]\n"
        "add [r1+r1], [r1-1]\n"
        "add [r1+r1], [r1+r1]\n"
        "add [r1+r1], [1]\n"
        "add [r1+r1], r1\n"
        "add [r1+r1], 1\n"
        "add [r1-1], [r1]\n"
        "add [r1-1], [r1-1]\n"
        "add [r1-1], [r1+r1]\n"
        "add [r1-1], [1]\n"
        "add [r1-1], r1\n"
        "add [r1-1], 1\n"
        "add [1], [r1]\n"
        "add [1], [r1-1]\n"
        "add [1], [r1+r1]\n"
        "add [1], [1]\n"
        "add [1], r1\n"
        "add [1], 1\n"
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
        
        "add flags, 255\n"
        "hlt\n",
        
        "add pc, skip\n"
        "add r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testSubtraction
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "sub [0], 4\n"
        "hlt\n",
        
        "sub r0, 4\n"
        "sub r0, 5\n"
        "hlt\n",
        
        "sub r0, 0\n"
        "hlt\n",
        
        "sub r0, 1\n"
        "sub r1, 2\n"
        "sub r2, 3\n"
        "sub r3, 4\n"
        "sub r0, r1\n"
        "sub r2, r3\n"
        "sub r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "sub r1, 1\n"
        "sub r0, [r1]\n"
        "sub r0, [r1+r0]\n"
        "sub r0, [r1+1]\n"
        "sub r0, [1]\n"
        "sub [r1], [r1]\n"
        "sub [r1], [r1-1]\n"
        "sub [r1], [r1+r1]\n"
        "sub [r1], [1]\n"
        "sub [r1], r1\n"
        "sub [r1], 1\n"
        "sub [r1+r1], [r1]\n"
        "sub [r1+r1], [r1-1]\n"
        "sub [r1+r1], [r1+r1]\n"
        "sub [r1+r1], [1]\n"
        "sub [r1+r1], r1\n"
        "sub [r1+r1], 1\n"
        "sub [r1-1], [r1]\n"
        "sub [r1-1], [r1-1]\n"
        "sub [r1-1], [r1+r1]\n"
        "sub [r1-1], [1]\n"
        "sub [r1-1], r1\n"
        "sub [r1-1], 1\n"
        "sub [1], [r1]\n"
        "sub [1], [r1-1]\n"
        "sub [1], [r1+r1]\n"
        "sub [1], [1]\n"
        "sub [1], r1\n"
        "sub [1], 1\n"
        "hlt\n",
        
        "sub r0, 127\n"
        "sub r0, 1\n"
        "hlt\n",
        
        "sub r0, 127\n"
        "sub r0, -1\n"
        "hlt\n",
        
        "sub r0, 1\n"
        "sub r0, 255\n"
        "hlt\n",
        
        "sub r0, -1\n"
        "sub r0, -2\n"
        "hlt\n",
        
        "sub r0, 0\n"
        "sub r0, 1\n"
        "hlt\n",
        
        "sub r0, 128\n"
        "sub r0, -1\n"
        "hlt\n",
        
        "sub r0, 128\n"
        "sub r0, 1\n"
        "hlt\n",
        
        "sub r0, 255\n"
        "sub r0, 1\n"
        "hlt\n",
        
        "sub flags, 1\n"
        "hlt\n",
        
        "sub pc, -skip\n"
        "sub r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testOr
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "or [0], 4\n"
        "hlt\n",
        
        "or r0, 4\n"
        "or r0, 5\n"
        "hlt\n",
        
        "or r0, 0\n"
        "hlt\n",
        
        "or r0, 1\n"
        "or r1, 2\n"
        "or r2, 3\n"
        "or r3, 4\n"
        "or r0, r1\n"
        "or r2, r3\n"
        "or r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "or r1, 1\n"
        "or r0, [r1]\n"
        "or r0, [r1+r0]\n"
        "or r0, [r1+1]\n"
        "or r0, [1]\n"
        "or [r1], [r1]\n"
        "or [r1], [r1-1]\n"
        "or [r1], [r1+r1]\n"
        "or [r1], [1]\n"
        "or [r1], r1\n"
        "or [r1], 1\n"
        "or [r1+r1], [r1]\n"
        "or [r1+r1], [r1-1]\n"
        "or [r1+r1], [r1+r1]\n"
        "or [r1+r1], [1]\n"
        "or [r1+r1], r1\n"
        "or [r1+r1], 1\n"
        "or [r1-1], [r1]\n"
        "or [r1-1], [r1-1]\n"
        "or [r1-1], [r1+r1]\n"
        "or [r1-1], [1]\n"
        "or [r1-1], r1\n"
        "or [r1-1], 1\n"
        "or [1], [r1]\n"
        "or [1], [r1-1]\n"
        "or [1], [r1+r1]\n"
        "or [1], [1]\n"
        "or [1], r1\n"
        "or [1], 1\n"
        "hlt\n",
        
        "or r0, 127\n"
        "or r0, 1\n"
        "hlt\n",
        
        "or r0, -1\n"
        "or r0, -2\n"
        "hlt\n",
        
        "or r0, 128\n"
        "or r0, 2\n"
        "hlt\n",
        
        "or r0, 255\n"
        "or r0, 1\n"
        "hlt\n",
        
        "or flags, 255\n"
        "hlt\n",
        
        "or pc, skip\n"
        "or r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testXor
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "xor [0], 4\n"
        "hlt\n",
        
        "xor r0, 4\n"
        "xor r0, 5\n"
        "hlt\n",
        
        "xor r0, 0\n"
        "hlt\n",
        
        "xor r0, 1\n"
        "xor r1, 2\n"
        "xor r2, 3\n"
        "xor r3, 4\n"
        "xor r0, r1\n"
        "xor r2, r3\n"
        "xor r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "xor r1, 1\n"
        "xor r0, [r1]\n"
        "xor r0, [r1+r0]\n"
        "xor r0, [r1+1]\n"
        "xor r0, [1]\n"
        "xor [r1], [r1]\n"
        "xor [r1], [r1-1]\n"
        "xor [r1], [r1+r1]\n"
        "xor [r1], [1]\n"
        "xor [r1], r1\n"
        "xor [r1], 1\n"
        "xor [r1+r1], [r1]\n"
        "xor [r1+r1], [r1-1]\n"
        "xor [r1+r1], [r1+r1]\n"
        "xor [r1+r1], [1]\n"
        "xor [r1+r1], r1\n"
        "xor [r1+r1], 1\n"
        "xor [r1-1], [r1]\n"
        "xor [r1-1], [r1-1]\n"
        "xor [r1-1], [r1+r1]\n"
        "xor [r1-1], [1]\n"
        "xor [r1-1], r1\n"
        "xor [r1-1], 1\n"
        "xor [1], [r1]\n"
        "xor [1], [r1-1]\n"
        "xor [1], [r1+r1]\n"
        "xor [1], [1]\n"
        "xor [1], r1\n"
        "xor [1], 1\n"
        "hlt\n",
        
        "xor r0, 127\n"
        "xor r0, 1\n"
        "hlt\n",
        
        "xor r0, -1\n"
        "xor r0, -2\n"
        "hlt\n",
        
        "xor r0, 128\n"
        "xor r0, 2\n"
        "hlt\n",
        
        "xor r0, 255\n"
        "xor r0, 1\n"
        "hlt\n",
        
        "xor flags, 255\n"
        "hlt\n",
        
        "xor pc, skip\n"
        "xor r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testAnd
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "and [0], 4\n"
        "hlt\n",
        
        "and r0, 4\n"
        "and r0, 5\n"
        "hlt\n",
        
        "and r0, 0\n"
        "hlt\n",
        
        "and r0, 1\n"
        "and r1, 2\n"
        "and r2, 3\n"
        "and r3, 4\n"
        "and r0, r1\n"
        "and r2, r3\n"
        "and r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "and r1, 1\n"
        "and r0, [r1]\n"
        "and r0, [r1+r0]\n"
        "and r0, [r1+1]\n"
        "and r0, [1]\n"
        "and [r1], [r1]\n"
        "and [r1], [r1-1]\n"
        "and [r1], [r1+r1]\n"
        "and [r1], [1]\n"
        "and [r1], r1\n"
        "and [r1], 1\n"
        "and [r1+r1], [r1]\n"
        "and [r1+r1], [r1-1]\n"
        "and [r1+r1], [r1+r1]\n"
        "and [r1+r1], [1]\n"
        "and [r1+r1], r1\n"
        "and [r1+r1], 1\n"
        "and [r1-1], [r1]\n"
        "and [r1-1], [r1-1]\n"
        "and [r1-1], [r1+r1]\n"
        "and [r1-1], [1]\n"
        "and [r1-1], r1\n"
        "and [r1-1], 1\n"
        "and [1], [r1]\n"
        "and [1], [r1-1]\n"
        "and [1], [r1+r1]\n"
        "and [1], [1]\n"
        "and [1], r1\n"
        "and [1], 1\n"
        "hlt\n",
        
        "and r0, 127\n"
        "and r0, 1\n"
        "hlt\n",
        
        "and r0, -1\n"
        "and r0, -2\n"
        "hlt\n",
        
        "and r0, 128\n"
        "and r0, 2\n"
        "hlt\n",
        
        "and r0, 255\n"
        "and r0, 1\n"
        "hlt\n",
        
        "and flags, 255\n"
        "hlt\n",
        
        "and pc, skip\n"
        "and r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testCompare
{
    const char *Sources[] = {
        ".byte 4\n"
        ".entrypoint\n"
        "cmp [0], 4\n"
        "hlt\n",
        
        "cmp r0, 4\n"
        "cmp r0, 5\n"
        "hlt\n",
        
        "cmp r0, 0\n"
        "hlt\n",
        
        "cmp r0, 1\n"
        "cmp r1, 2\n"
        "cmp r2, 3\n"
        "cmp r3, 4\n"
        "cmp r0, r1\n"
        "cmp r2, r3\n"
        "cmp r0, r2\n"
        "hlt\n",
        
        ".byte 1,2,3,4\n"
        ".entrypoint\n"
        "cmp r1, 1\n"
        "cmp r0, [r1]\n"
        "cmp r0, [r1+r0]\n"
        "cmp r0, [r1+1]\n"
        "cmp r0, [1]\n"
        "cmp [r1], [r1]\n"
        "cmp [r1], [r1-1]\n"
        "cmp [r1], [r1+r1]\n"
        "cmp [r1], [1]\n"
        "cmp [r1], r1\n"
        "cmp [r1], 1\n"
        "cmp [r1+r1], [r1]\n"
        "cmp [r1+r1], [r1-1]\n"
        "cmp [r1+r1], [r1+r1]\n"
        "cmp [r1+r1], [1]\n"
        "cmp [r1+r1], r1\n"
        "cmp [r1+r1], 1\n"
        "cmp [r1-1], [r1]\n"
        "cmp [r1-1], [r1-1]\n"
        "cmp [r1-1], [r1+r1]\n"
        "cmp [r1-1], [1]\n"
        "cmp [r1-1], r1\n"
        "cmp [r1-1], 1\n"
        "cmp [1], [r1]\n"
        "cmp [1], [r1-1]\n"
        "cmp [1], [r1+r1]\n"
        "cmp [1], [1]\n"
        "cmp [1], r1\n"
        "cmp [1], 1\n"
        "hlt\n",
        
        "cmp r0, 127\n"
        "cmp r0, 1\n"
        "hlt\n",
        
        "cmp r0, -1\n"
        "cmp r0, -2\n"
        "hlt\n",
        
        "cmp r0, 128\n"
        "cmp r0, 2\n"
        "hlt\n",
        
        "cmp r0, 255\n"
        "cmp r0, 1\n"
        "hlt\n",
        
        "cmp flags, 255\n"
        "hlt\n",
        
        "cmp pc, skip\n"
        "cmp r0, 1\n"
        "skip: hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testLeftShift
{
    const char *Sources[] = {
        "mov r0, 5\n"
        "shl r0, 1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shl r0, 2\n"
        "hlt\n",
        
        "mov r0, 64\n"
        "shl r0, 1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "shl r0, 1\n"
        "hlt\n",
        
        "mov r0, 1\n"
        "shl r0, 128\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shl r0, 3\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shl r0, 128\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shl r0, 0\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shl r0, 0\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "shl r0, 0\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 2\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 64\n"
        "mov r1, 1\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 3\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 128\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 0\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 0\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 0\n"
        "shl r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shl r0, r0\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r2, 2\n"
        "shl r0, r2\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r3, 2\n"
        "shl r0, r3\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r0, 2\n"
        "shl r1, r0\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "shl r1, r1\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r2, 2\n"
        "shl r1, r2\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r3, 2\n"
        "shl r1, r3\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r0, 2\n"
        "shl r2, r0\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r1, 2\n"
        "shl r2, r1\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "shl r2, r2\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r3, 2\n"
        "shl r2, r3\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r0, 2\n"
        "shl r3, r0\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r1, 2\n"
        "shl r3, r1\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r2, 2\n"
        "shl r3, r2\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "shl r3, r3\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [0]\n"
        "hlt\n",
        
        ".byte 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shl r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shl r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [r1]\n"
        "hlt\n",
        
        ".byte 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [r1]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shl r0, [r1]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shl r0, [r1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shl r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shl r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shl r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shl r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shl r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "mov r1, 1\n"
        "shl r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shl r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r1, 128\n"
        "mov r0, 1\n"
        "shl r1, [r0+r0]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r2, 128\n"
        "mov r1, 1\n"
        "shl r2, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 128\n"
        "mov r1, 1\n"
        "shl r3, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 1\n"
        "shl r0, [r0+r0]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r1, 1\n"
        "shl r1, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r2, 1\n"
        "shl r2, [r2+r2]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 1\n"
        "shl r3, [r3+r3]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 1\n"
        "shl r3, [r3+0]\n"
        "hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

-(void) testRightShift
{
    const char *Sources[] = {
        "mov r0, 5\n"
        "shr r0, 1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shr r0, 2\n"
        "hlt\n",
        
        "mov r0, 64\n"
        "shr r0, 1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "shr r0, 1\n"
        "hlt\n",
        
        "mov r0, 1\n"
        "shr r0, 128\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shr r0, 3\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shr r0, 128\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shr r0, 0\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "shr r0, 0\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "shr r0, 0\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 2\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 64\n"
        "mov r1, 1\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 3\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 128\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r1, 0\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 0\n"
        "mov r1, 0\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 128\n"
        "mov r1, 0\n"
        "shr r0, r1\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "shr r0, r0\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r2, 2\n"
        "shr r0, r2\n"
        "hlt\n",
        
        "mov r0, 5\n"
        "mov r3, 2\n"
        "shr r0, r3\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r0, 2\n"
        "shr r1, r0\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "shr r1, r1\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r2, 2\n"
        "shr r1, r2\n"
        "hlt\n",
        
        "mov r1, 5\n"
        "mov r3, 2\n"
        "shr r1, r3\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r0, 2\n"
        "shr r2, r0\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r1, 2\n"
        "shr r2, r1\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "shr r2, r2\n"
        "hlt\n",
        
        "mov r2, 5\n"
        "mov r3, 2\n"
        "shr r2, r3\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r0, 2\n"
        "shr r3, r0\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r1, 2\n"
        "shr r3, r1\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "mov r2, 2\n"
        "shr r3, r2\n"
        "hlt\n",
        
        "mov r3, 5\n"
        "shr r3, r3\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [0]\n"
        "hlt\n",
        
        ".byte 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shr r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shr r0, [0]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [r1]\n"
        "hlt\n",
        
        ".byte 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [r1]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shr r0, [r1]\n"
        "hlt\n",
        
        ".byte 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shr r0, [r1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "shr r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "shr r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "shr r0, [r1+1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shr r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 2\n"
        ".entrypoint\n"
        "mov r0, 5\n"
        "mov r1, 1\n"
        "shr r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 64\n"
        "mov r1, 1\n"
        "shr r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 128\n"
        "mov r1, 1\n"
        "shr r0, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r1, 128\n"
        "mov r0, 1\n"
        "shr r1, [r0+r0]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r2, 128\n"
        "mov r1, 1\n"
        "shr r2, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 128\n"
        "mov r1, 1\n"
        "shr r3, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r0, 1\n"
        "shr r0, [r0+r0]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r1, 1\n"
        "shr r1, [r1+r1]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r2, 1\n"
        "shr r2, [r2+r2]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 1\n"
        "shr r3, [r3+r3]\n"
        "hlt\n",
        
        ".byte 0, 0, 1\n"
        ".entrypoint\n"
        "mov r3, 1\n"
        "shr r3, [r3+0]\n"
        "hlt\n"
    };
    
    for (size_t Loop = 0; Loop < sizeof(Sources) / sizeof(typeof(*Sources)); Loop++) [self run: Sources[Loop]];
}

@end
