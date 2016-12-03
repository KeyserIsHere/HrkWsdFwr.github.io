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

-(void) testAddition
{
    const char *Source =
        "add r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 6, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-3, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 130, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "add flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 255;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    
    
    
    Source =
        "add pc,Skip - .\n"
        "hlt\n"
        "Skip: mov r0,123\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[0], 123, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testSubtraction
{
    const char *Source =
        "sub r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 6, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 129, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 255, @"Should have the correct value");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 2, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 126, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    
    
    Source =
        "sub flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    
    Source =
        "sub pc,. - Skip\n"
        "hlt\n"
        "Skip: mov r0,123\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[0], 123, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testMultiplication
{
    const char *Source =
        "mul r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 6, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-2, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 254, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 254, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 254, @"Should have the correct value");
    
    Processor->state.r[0] = -2;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "mul flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 255;
    Processor->state.r[1] = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    
    Source =
        "nop\n"
        "mul pc,Skip\n"
        "hlt\n"
        "Skip: mov r0,123\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[0], 123, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testDivision
{
    const char *Source =
        "sdiv r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 5, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-2, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 63, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-2, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-5, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = -2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 5, @"Should have the correct value");
    
    
    
    Source =
        "sdiv flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    
    
    
    Source =
        "udiv r0,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 5, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 63, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 123, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = -2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "udiv flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testModulo
{
    const char *Source =
        "smod r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 5, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-1, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = -2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "smod flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    
    Source =
        "umod r0,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 5, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 2, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 2;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 2, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 246;
    Processor->state.r[1] = -2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 246, @"Should have the correct value");
    
    
    
    Source =
        "umod flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testLeftShift
{
    const char *Source =
        "shl r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 254, @"Should have the correct value");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 252, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 129, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 2, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 4, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 8;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 9;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "shl flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 0x80;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testRightShift
{
    const char *Source =
        "shr r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 254;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should have the correct value");
    
    Processor->state.r[0] = 254;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 63, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 129, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 64, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 2;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 32, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 8;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 129;
    Processor->state.r[1] = 9;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "shr flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testXor
{
    const char *Source =
        "xor r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 6, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 7;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 0x80;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0x87, @"Should have the correct value");
    
    
    
    Source =
        "xor flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testOr
{
    const char *Source =
        "or r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 7, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 7;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 7, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 0x80;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0x87, @"Should have the correct value");
    
    
    
    Source =
        "or flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 0;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testAnd
{
    const char *Source =
        "and r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 7;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 7, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.r[1] = 0x80;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 0x87;
    Processor->state.r[1] = 0x80;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0x80, @"Should have the correct value");
    
    
    
    Source =
        "and flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 1;
    Processor->state.r[1] = 1;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testNot
{
    const char *Source =
        "not r0\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 255, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0xf8, @"Should have the correct value");
    
    Processor->state.r[0] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0xfe, @"Should have the correct value");
    
    Processor->state.r[0] = 0x88;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0x77, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    
    
    Source =
        "not flags\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 255;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testNeg
{
    const char *Source =
        "neg r0\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 7, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 7;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-7, @"Should have the correct value");
    
    Processor->state.r[0] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], (uint8_t)-1, @"Should have the correct value");
    
    Processor->state.r[0] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should have the correct value");
    
    
    
    Source =
        "neg flags\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = 255;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testComparison
{
    const char *Source =
        "cmp r0,r1\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process add");
    
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 6, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 2, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should be unchanged");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 128, @"Should be unchanged");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should be unchanged");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 255;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 1, @"Should be unchanged");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should be unchanged");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsCarry, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 127, @"Should be unchanged");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jz skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jnz skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "js skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jns skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jo skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jno skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jsl skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jsge skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jsle skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jsg skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jul skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "juge skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jule skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    
    
    Source =
        "mov r2,1\n"
        "cmp r0,r1\n"
        "jug skip\n"
        "mov r2,0\n"
        "skip: hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = -1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 0;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 1;
    Processor->state.r[1] = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -1;
    Processor->state.r[1] = 1;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 128;
    Processor->state.r[1] = 127;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = 127;
    Processor->state.r[1] = 128;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 5;
    Processor->state.r[1] = 20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    Processor->state.r[0] = 20;
    Processor->state.r[1] = 5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -5;
    Processor->state.r[1] = -20;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 1, @"Jump should be taken");
    
    Processor->state.r[0] = -20;
    Processor->state.r[1] = -5;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 20);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.r[2], 0, @"Jump should not be taken");
    
    
    
    Source =
        "cmp flags,r1\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.r[1] = HKHubArchProcessorFlagsZero;
    HKHubArchProcessorSetCycles(Processor, 10);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.flags, HKHubArchProcessorFlagsZero, @"Should have the correct value");
    
    
    HKHubArchProcessorDestroy(Processor);
}

-(void) testMoving
{
    const char *Source =
        "mov r0,value\n"
        "mov r1,[value]\n"
        "mov r2,[value+1]\n"
        "mov r3,[value+r1]\n"
        "mov [r0+r1],r2\n"
        "mov [r0+r2],r1\n"
        "mov r0,[r0+r2]\n"
        "mov flags,5\n"
        "mov pc,value+4\n"
        "value: .byte 3, 2, 1, 0\n"
        "mov r0,0\n"
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process first move");
    
    HKHubArchProcessorSetCycles(Processor, 100);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->cycles, 54, @"Should have the unused cycles");
    XCTAssertEqual(Processor->state.pc, 34, @"Should have reached the end");
    XCTAssertEqual(Processor->state.flags, 5, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[0], 0, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[1], 3, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[2], 2, @"Should have the correct value");
    XCTAssertEqual(Processor->state.r[3], 0, @"Should have the correct value");
    
    HKHubArchProcessorDestroy(Processor);
}

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
    
    CCOrderedCollection Errors = NULL;
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
    
    
    
    Source = "jz A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //ZF = 1
    _Bool ResultsJZ[16] = {
        //0000  000z  00c0  00cz
        FALSE, TRUE, FALSE, TRUE,
        //0s00  0s0z  0sc0  0scz
        FALSE, TRUE, FALSE, TRUE,
        //o000  o00z  o0c0  o0cz
        FALSE, TRUE, FALSE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, TRUE, FALSE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJZ[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jnz A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = 0;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //ZF = 0
    _Bool ResultsJNZ[16] = {
        //0000  000z  00c0  00cz
        TRUE, FALSE, TRUE, FALSE,
        //0s00  0s0z  0sc0  0scz
        TRUE, FALSE, TRUE, FALSE,
        //o000  o00z  o0c0  o0cz
        TRUE, FALSE, TRUE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, FALSE, TRUE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJNZ[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "js A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //SF = 1
    _Bool ResultsJS[16] = {
        //0000  000z  00c0  00cz
        FALSE, FALSE, FALSE, FALSE,
        //0s00  0s0z  0sc0  0scz
        TRUE, TRUE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        FALSE, FALSE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, TRUE, TRUE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJS[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jns A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = 0;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //SF = 1
    _Bool ResultsJNS[16] = {
        //0000  000z  00c0  00cz
        TRUE, TRUE, TRUE, TRUE,
        //0s00  0s0z  0sc0  0scz
        FALSE, FALSE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        TRUE, TRUE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, FALSE, FALSE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJNS[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jo A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //OF = 1
    _Bool ResultsJO[16] = {
        //0000  000z  00c0  00cz
        FALSE, FALSE, FALSE, FALSE,
        //0s00  0s0z  0sc0  0scz
        FALSE, FALSE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        TRUE, TRUE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        TRUE, TRUE, TRUE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJO[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jno A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = 0;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //OF = 0
    _Bool ResultsJNO[16] = {
        //0000  000z  00c0  00cz
        TRUE, TRUE, TRUE, TRUE,
        //0s00  0s0z  0sc0  0scz
        TRUE, TRUE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        FALSE, FALSE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        FALSE, FALSE, FALSE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJNO[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jsl A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    //SF <> OF
    _Bool ResultsJSL[16] = {
        //0000  000z  00c0  00cz
        FALSE, FALSE, FALSE, FALSE,
        //0s00  0s0z  0sc0  0scz
        TRUE, TRUE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        TRUE, TRUE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, FALSE, FALSE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJSL[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jsge A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //SF = OF
    _Bool ResultsJSGE[16] = {
        //0000  000z  00c0  00cz
        TRUE, TRUE, TRUE, TRUE,
        //0s00  0s0z  0sc0  0scz
        FALSE, FALSE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        FALSE, FALSE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, TRUE, TRUE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJSGE[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jsle A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    //ZF = 1 or SF <> OF
    _Bool ResultsJSLE[16] = {
        //0000  000z  00c0  00cz
        FALSE, TRUE, FALSE, TRUE,
        //0s00  0s0z  0sc0  0scz
        TRUE, TRUE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        TRUE, TRUE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, TRUE, FALSE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJSLE[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jsg A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags |= HKHubArchProcessorFlagsSign;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //ZF = 0 and SF = OF
    _Bool ResultsJSG[16] = {
        //0000  000z  00c0  00cz
        TRUE, FALSE, TRUE, FALSE,
        //0s00  0s0z  0sc0  0scz
        FALSE, FALSE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        FALSE, FALSE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, FALSE, TRUE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJSG[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jul A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsCarry;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //CF = 1
    _Bool ResultsJUL[16] = {
        //0000  000z  00c0  00cz
        FALSE, FALSE, TRUE, TRUE,
        //0s00  0s0z  0sc0  0scz
        FALSE, FALSE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        FALSE, FALSE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, FALSE, TRUE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJUL[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "juge A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = 0;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsCarry;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //CF = 0
    _Bool ResultsJUGE[16] = {
        //0000  000z  00c0  00cz
        TRUE, TRUE, FALSE, FALSE,
        //0s00  0s0z  0sc0  0scz
        TRUE, TRUE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        TRUE, TRUE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, TRUE, FALSE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJUGE[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jule A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsCarry;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags |= HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    //CF = 1 or ZF = 1
    _Bool ResultsJULE[16] = {
        //0000  000z  00c0  00cz
        FALSE, TRUE, TRUE, TRUE,
        //0s00  0s0z  0sc0  0scz
        FALSE, TRUE, TRUE, TRUE,
        //o000  o00z  o0c0  o0cz
        FALSE, TRUE, TRUE, TRUE,
        //os00  os0z  osc0  oscz
        FALSE, TRUE, TRUE, TRUE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJULE[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
    
    
    
    Source = "jug A\nnop\nA: nop\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    
    Processor->state.flags = HKHubArchProcessorFlagsCarry;
    HKHubArchProcessorSetCycles(Processor, 1);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 2);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 0, @"Not enough cycles to process jump");
    
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags |= HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = HKHubArchProcessorFlagsZero;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    
    Processor->state.flags = 0;
    Processor->state.pc = 0;
    HKHubArchProcessorSetCycles(Processor, 3);
    HKHubArchProcessorRun(Processor);
    XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
    
    //CF = 0 and ZF = 0
    _Bool ResultsJUG[16] = {
        //0000  000z  00c0  00cz
        TRUE, FALSE, FALSE, FALSE,
        //0s00  0s0z  0sc0  0scz
        TRUE, FALSE, FALSE, FALSE,
        //o000  o00z  o0c0  o0cz
        TRUE, FALSE, FALSE, FALSE,
        //os00  os0z  osc0  oscz
        TRUE, FALSE, FALSE, FALSE
    };
    
    for (int Loop = 0; Loop < 16; Loop++)
    {
        Processor->state.flags = Loop;
        Processor->state.pc = 0;
        HKHubArchProcessorSetCycles(Processor, 3);
        HKHubArchProcessorRun(Processor);
        if (ResultsJUG[Loop]) XCTAssertEqual(Processor->state.pc, 3, @"Processes jump");
        else XCTAssertEqual(Processor->state.pc, 2, @"Processes jump but doesn't take it");
    }
    
    HKHubArchProcessorDestroy(Processor);
}

@end
