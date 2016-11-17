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

@end
