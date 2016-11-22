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
#import "HubArchAssembly.h"

@interface HubArchAssemblyTests : XCTestCase

@end

@implementation HubArchAssemblyTests

-(void) testParsing
{
    const char *Source =
        "label: .byte 0x55, 0x33, 34\n" //label<label>(), directive<.byte>(operand< 0x55>(integer<0x55>()), operand< 0x33>(integer<0x33>()), operand< 34>(integer<34>()))
        "other: .byte . - label\n" //label<other>(), directive<.byte>(operand< . - label>(offset<.>(), minus<->(), symbol<label>()))
        "add r0,r1 #comment\n" //instruction<add>(operand< r0>(symbol<r0>()), operand<r1 >(symbol<r1>()))
        "sub r0,[other]\n" //instruction<sub>(operand< r0>(symbol<r0>()), memory(operand<other>(symbol<other>())))
        "xor r0,[r3+5]\n" //instruction<xor>(operand< r0>(symbol<r0>()), memory(operand<r3+5>(symbol<r3>(), plus<+>(), integer<5>())))
        "\n"
        " ,, ,, ,,   ,, , , , , ,add r0, r0\n" //instruction<add>(operand< r0>(symbol<r0>()), operand< r0>(symbol<r0>()))
        "nop#goood\n" //instruction<nop>()
        "nop\n" //instruction<nop>()
        "nop $43, 54k(4)\n" //instruction<nop>(operand< $43>(unknown<$>(), integer<43>()), operand< 54k(4)>(symbol<54k>(), unknown<(>(), integer<4>(), unknown<)>()))
        "l: %%,%,,5,,54<,,5,[,,\n" //label<l>(), instruction<%%>(operand<%>(unknown<%>()), operand<5>(integer<5>()), operand<54<>(integer<54>(), unknown<<>()), operand<5>(integer<5>()), memory())
        "nop" //instruction<nop>()
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    XCTAssertEqual(CCCollectionGetCount(AST), 14, @"Should have the correct number of command nodes");
    
    //label<label>()
    HKHubArchAssemblyASTNode *Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 0);
    XCTAssertEqual(Command->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeLabel, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("label")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have any child nodes");
    
    //directive<.byte>(operand< 0x55>(integer<0x55>()), operand< 0x33>(integer<0x33>()), operand< 34>(integer<34>()))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 1);
    XCTAssertEqual(Command->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeDirective, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING(".byte")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 3, @"Should have the correct number of operand nodes");
    
    //operand< 0x55>(integer<0x55>())
    HKHubArchAssemblyASTNode *Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    HKHubArchAssemblyASTNode *Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
        XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("0x55")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 0x55, @"Should be the correct value");
    
    //operand< 0x33>(integer<0x33>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("0x33")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 0x33, @"Should be the correct value");
    
    //operand< 34>(integer<34>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 2);
    XCTAssertEqual(Operand->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 0, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("34")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 34, @"Should be the correct value");
    
    //label<other>()
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 2);
    XCTAssertEqual(Command->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeLabel, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("other")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have any child nodes");
    
    //directive<.byte>(operand< . - label>(offset<.>(), minus<->(), symbol<label>()))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 3);
    XCTAssertEqual(Command->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeDirective, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING(".byte")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 1, @"Should have the correct number of operand nodes");
    
    //operand< . - label>(offset<.>(), minus<->(), symbol<label>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 3, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeOffset, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING(".")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 1);
    XCTAssertEqual(Node->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeMinus, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("-")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 2);
    XCTAssertEqual(Node->line, 1, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("label")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //instruction<add>(operand< r0>(symbol<r0>()), operand<r1 >(symbol<r1>()))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 4);
    XCTAssertEqual(Command->line, 2, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("add")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 2, @"Should have the correct number of operand nodes");
    
    //operand< r0>(symbol<r0>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 2, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 2, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r0")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //operand<r1 >(symbol<r1>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 2, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 2, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r1")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //instruction<sub>(operand< r0>(symbol<r0>()), memory(operand<other>(symbol<other>())))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 5);
    XCTAssertEqual(Command->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("sub")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 2, @"Should have the correct number of operand nodes");
    
    //operand< r0>(symbol<r0>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r0")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //memory(operand<other>(symbol<other>()))
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeMemory, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Operand->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 3, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("other")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //instruction<xor>(operand< r0>(symbol<r0>()), memory(operand<r3+5>(symbol<r3>(), plus<+>(), integer<5>())))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 6);
    XCTAssertEqual(Command->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("xor")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 2, @"Should have the correct number of operand nodes");
    
    //operand< r0>(symbol<r0>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r0")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //memory(operand<r3+5>(symbol<r3>(), plus<+>(), integer<5>()))
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeMemory, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Operand->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 3, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r3")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 1);
    XCTAssertEqual(Node->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypePlus, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("+")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 2);
    XCTAssertEqual(Node->line, 4, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("5")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 5, @"Should be the correct value");
    
    //instruction<add>(operand< r0>(symbol<r0>()), operand< r0>(symbol<r0>()))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 7);
    XCTAssertEqual(Command->line, 6, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("add")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 2, @"Should have the correct number of operand nodes");
    
    //operand< r0>(symbol<r0>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 6, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 6, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r0")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //operand< r0>(symbol<r0>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 6, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 6, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("r0")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //instruction<nop>()
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 8);
    XCTAssertEqual(Command->line, 7, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("nop")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have child nodes because it detects a comment (and so cannot have any)");
    
    //instruction<nop>()
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 9);
    XCTAssertEqual(Command->line, 8, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("nop")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have child nodes because it detects end of line (and so cannot have any)");
    
    //instruction<nop>(operand< $43>(unknown<$>(), integer<43>()), operand< 54k(4)>(symbol<54k>(), unknown<(>(), integer<4>(), unknown<)>()))
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 10);
    XCTAssertEqual(Command->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("nop")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 2, @"Should have the correct number of operand nodes");
    
    //operand< $43>(unknown<$>(), integer<43>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 2, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeUnknown, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("$")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 1);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("43")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 43, @"Should be the correct value");
    
    //operand< 54k(4)>(symbol<54k>(), unknown<(>(), integer<4>(), unknown<)>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 4, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeSymbol, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("54k")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 1);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeUnknown, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("(")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 2);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("4")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 4, @"Should be the correct value");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 3);
    XCTAssertEqual(Node->line, 9, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeUnknown, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING(")")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //label<l>()
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 11);
    XCTAssertEqual(Command->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeLabel, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("l")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have any child nodes");
    
    //instruction<%%>(operand<%>(unknown<%>()), operand<5>(integer<5>()), operand<54<>(integer<54>(), unknown<<>()), operand<5>(integer<5>()), memory())
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 12);
    XCTAssertEqual(Command->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("%%")), @"Should capture the correct string");
    XCTAssertNotEqual(Command->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Command->childNodes), 5, @"Should have the correct number of operand nodes");
    
    //operand<%>(unknown<%>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
    XCTAssertEqual(Operand->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeUnknown, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("%")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //operand<5>(integer<5>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
    XCTAssertEqual(Operand->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("5")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 5, @"Should be the correct value");
    
    //operand<54<>(integer<54>(), unknown<<>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 2);
    XCTAssertEqual(Operand->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 2, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("54")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 54, @"Should be the correct value");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 1);
    XCTAssertEqual(Node->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeUnknown, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("<")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    
    //operand<5>(integer<5>())
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 3);
    XCTAssertEqual(Operand->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeOperand, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 1, @"Should have the correct number of sub nodes");
    
    Node = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
    XCTAssertEqual(Node->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Node->type, HKHubArchAssemblyASTTypeInteger, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Node->string, CC_STRING("5")), @"Should capture the correct string");
    XCTAssertEqual(Node->childNodes, NULL, @"Should not have child nodes");
    XCTAssertEqual(Node->integer.value, 5, @"Should be the correct value");
    
    //memory()
    Operand = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(Command->childNodes, 4);
    XCTAssertEqual(Operand->line, 10, @"Should be on the correct line");
    XCTAssertEqual(Operand->type, HKHubArchAssemblyASTTypeMemory, @"Should be the correct type");
    XCTAssertNotEqual(Operand->childNodes, NULL, @"Should have child nodes");
    
    XCTAssertEqual(CCCollectionGetCount(Operand->childNodes), 0, @"Should have the correct number of sub nodes");
    
    //instruction<nop>()
    Command = (HKHubArchAssemblyASTNode*)CCOrderedCollectionGetElementAtIndex(AST, 13);
    XCTAssertEqual(Command->line, 11, @"Should be on the correct line");
    XCTAssertEqual(Command->type, HKHubArchAssemblyASTTypeInstruction, @"Should be the correct type");
    XCTAssertTrue(CCStringEqual(Command->string, CC_STRING("nop")), @"Should capture the correct string");
    XCTAssertEqual(Command->childNodes, NULL, @"Should not have child nodes because it detects end of file (and so cannot have any)");
    
    CCCollectionDestroy(AST);
}

-(void) testAssembling
{
    const char *Source = "label: .byte 0x55, 0x33, 34, label, . - label\n";
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x55);
    XCTAssertEqual(Binary->data[1], 0x33);
    XCTAssertEqual(Binary->data[2], 34);
    XCTAssertEqual(Binary->data[3], 0);
    XCTAssertEqual(Binary->data[4], 4);
    
    for (size_t Loop = 5; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = ".define test, 15\n.byte test, ., ., . + test\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 15);
    XCTAssertEqual(Binary->data[1], 1);
    XCTAssertEqual(Binary->data[2], 2);
    XCTAssertEqual(Binary->data[3], 3 + 15);
    
    for (size_t Loop = 4; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = ".define test, here\n.byte 0,0\nhere: .byte here, test\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0);
    XCTAssertEqual(Binary->data[1], 0);
    XCTAssertEqual(Binary->data[2], 2);
    XCTAssertEqual(Binary->data[3], 2);
    
    for (size_t Loop = 4; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = ".byte .-2,.-3,0-.,here\nhere:\n";
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual((int8_t)Binary->data[0], (int8_t)-2);
    XCTAssertEqual((int8_t)Binary->data[1], (int8_t)-2);
    XCTAssertEqual((int8_t)Binary->data[2], (int8_t)-2);
    XCTAssertEqual(Binary->data[3], 4);
    
    for (size_t Loop = 4; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source =
        ".byte 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f\n"
        ".byte 0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f\n"
        ".byte 0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f\n"
        ".byte 0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f\n"
        ".byte 0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f\n"
        ".byte 0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x5b,0x5c,0x5d,0x5e,0x5f\n"
        ".byte 0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f\n"
        ".byte 0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x7b,0x7c,0x7d,0x7e,0x7f\n"
        ".byte 0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f\n"
        ".byte 0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f\n"
        ".byte 0xa0,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xab,0xac,0xad,0xae,0xaf\n"
        ".byte 0xb0,0xb1,0xb2,0xb3,0xb4,0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xbb,0xbc,0xbd,0xbe,0xbf\n"
        ".byte 0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xcb,0xcc,0xcd,0xce,0xcf\n"
        ".byte 0xd0,0xd1,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xdf\n"
        ".byte 0xe0,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,0xee,0xef\n"
        ".byte 0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfd,0xfe,0xff\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    for (size_t Loop = 0; Loop < 256; Loop++) XCTAssertEqual(Binary->data[Loop], Loop);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source =
        ".byte 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f\n"
        ".byte 0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f\n"
        ".byte 0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f\n"
        ".byte 0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f\n"
        ".byte 0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f\n"
        ".byte 0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x5b,0x5c,0x5d,0x5e,0x5f\n"
        ".byte 0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f\n"
        ".byte 0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x7b,0x7c,0x7d,0x7e,0x7f\n"
        ".byte 0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f\n"
        ".byte 0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f\n"
        ".byte 0xa0,0xa1,0xa2,0xa3,0xa4,0xa5,0xa6,0xa7,0xa8,0xa9,0xaa,0xab,0xac,0xad,0xae,0xaf\n"
        ".byte 0xb0,0xb1,0xb2,0xb3,0xb4,0xb5,0xb6,0xb7,0xb8,0xb9,0xba,0xbb,0xbc,0xbd,0xbe,0xbf\n"
        ".byte 0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca,0xcb,0xcc,0xcd,0xce,0xcf\n"
        ".byte 0xd0,0xd1,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xdf\n"
        ".byte 0xe0,0xe1,0xe2,0xe3,0xe4,0xe5,0xe6,0xe7,0xe8,0xe9,0xea,0xeb,0xec,0xed,0xee,0xef\n"
        ".byte 0xf0,0xf1,0xf2,0xf3,0xf4,0xf5,0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfd,0xfe,0xff\n"
        ".byte 1"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertEqual(Binary, NULL, @"Should fail to create binary");
    
    CCCollectionDestroy(Errors); Errors = NULL;
    
    
    
    Source =
        ".byte 1, 2\n"
        ".byte 3, 4\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->entrypoint, 0, @"Should use default entrypoint");
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source =
        ".byte 1, 2\n"
        ".entrypoint\n"
        ".byte 3, 4\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->entrypoint, 2, @"Should use custom entrypoint");
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "add r1,r0\n"; //00000010 11000000 : 0x02 0xc0
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x02);
    XCTAssertEqual(Binary->data[1], 0xc0);
    
    for (size_t Loop = 2; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "add flags,r0\n"; //00000001 01000000 : 0x01 0x40
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x01);
    XCTAssertEqual(Binary->data[1], 0x40);
    
    for (size_t Loop = 2; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "add r1,5\n"; //00001010 10000010 10000000 : 0x0a 0x82 0x80
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x0a);
    XCTAssertEqual(Binary->data[1], 0x82);
    XCTAssertEqual(Binary->data[2], 0x80);
    
    for (size_t Loop = 3; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "jmp 8\n"; //11111100 00100000 : 0xfc 0x20
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0xfc);
    XCTAssertEqual(Binary->data[1], 0x20);
    
    for (size_t Loop = 2; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "nop\n"; //11111000 : 0xf8
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0xf8);
    
    for (size_t Loop = 1; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "add r1,[5]\n"; //00000110 10000000 00101000 : 0x06 0x80 0x28
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x06);
    XCTAssertEqual(Binary->data[1], 0x80);
    XCTAssertEqual(Binary->data[2], 0x28);
    
    for (size_t Loop = 3; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
    
    
    
    Source = "add r1,[r1+r2]\n"; //00000110 01101100 : 0x06 0x6c
    
    AST = HKHubArchAssemblyParse(Source);
    
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    XCTAssertNotEqual(Binary, NULL, @"Should not fail to create binary");
    XCTAssertEqual(Binary->data[0], 0x06);
    XCTAssertEqual(Binary->data[1], 0x9b);
    XCTAssertEqual(Binary->data[2], 0x00);
    
    for (size_t Loop = 2; Loop < 255; Loop++) XCTAssertEqual(Binary->data[Loop], 0);
    
    HKHubArchBinaryDestroy(Binary);
}

@end
