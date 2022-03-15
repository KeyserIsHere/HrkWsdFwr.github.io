/*
 *  Copyright (c) 2022, Stefan Johnson
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
#import "ProcedureTests.h"

@interface ProcedureGapTests : ProcedureTests

@end

@implementation ProcedureGapTests

-(const char*) source
{
    return
        ".include \"private/gap\"\n"
        "ldi 0xf\n"
        "dup\n"
        "ldi 4\n"
        "sal\n"
        "or\n"
        "ldi 0, 0, 0, 1\n"
        "ldi 1, 2, 3, 4\n"
        "ldi 0x56\n"
    ;
}

-(void) testProgram
{
    XCTAssertEqual(self.processor->memory[0], (12 << 4) | 0xf, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[1], (8 << 4) | 12, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[2], (4 << 4) | 0, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[3], (4 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[4], (12 << 4) | 1, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[5], (12 << 4) | 4, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[6], (12 << 4) | 8, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[7], (12 << 4) | 3, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[8], (12 << 4) | 8, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[9], (12 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[10], (12 << 4) | 8, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[11], (12 << 4) | 1, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[12], (4 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[13], (4 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[14], (4 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[15], (12 << 4) | 6, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[16], (12 << 4) | 4, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[17], (12 << 4) | 5, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[18], (4 << 4) | 2, @"Should have the correct value");
    XCTAssertEqual(self.processor->memory[19], 0, @"Should have the correct value");
}

@end
