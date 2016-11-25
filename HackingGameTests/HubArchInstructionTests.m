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
