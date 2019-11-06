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
#import "ProcedureTests.h"

@interface ProcedureModPowTests : ProcedureTests

@end

@implementation ProcedureModPowTests

-(const char*) source
{
    return ".include modpow\nhlt";
}

-(void) runForBase: (uint8_t)base Exponent: (uint8_t)exponent Modulus: (uint8_t)modulus
{
    self.processor->state.r[0] = base;
    self.processor->state.r[1] = exponent;
    self.processor->state.r[2] = modulus;
    HKHubArchProcessorSetCycles(self.processor, 100000);
    HKHubArchSchedulerRun(self.scheduler, 0.0);
    
    XCTAssertEqual(self.processor->state.r[1], 0, @"Should have the correct value");
    XCTAssertEqual(self.processor->state.r[2], modulus, @"Should have the correct value");
}

-(void) testZeroExponent
{
    [self runForBase: 255 Exponent: 0 Modulus: 255];
    XCTAssertEqual(self.processor->state.r[3], 1, @"Should have the correct value");
}

-(void) testOneExponent
{
    [self runForBase: 255 Exponent: 1 Modulus: 255];
    XCTAssertEqual(self.processor->state.r[3], 0, @"Should have the correct value");
}

-(void) testOneExponentBigModulus
{
    [self runForBase: 3 Exponent: 1 Modulus: 255];
    XCTAssertEqual(self.processor->state.r[3], 3, @"Should have the correct value");
}

-(void) testOneExponentSmallModulus
{
    [self runForBase: 255 Exponent: 1 Modulus: 50];
    XCTAssertEqual(self.processor->state.r[3], 5, @"Should have the correct value");
}

-(void) testTwoExponent
{
    [self runForBase: 255 Exponent: 2 Modulus: 255];
    XCTAssertEqual(self.processor->state.r[3], 0, @"Should have the correct value");
}

-(void) testTwoExponentBigModulus
{
    [self runForBase: 255 Exponent: 2 Modulus: 250];
    XCTAssertEqual(self.processor->state.r[3], 25, @"Should have the correct value");
}

-(void) testTwoExponentSmallModulus
{
    [self runForBase: 255 Exponent: 2 Modulus: 10];
    XCTAssertEqual(self.processor->state.r[3], 5, @"Should have the correct value");
}

-(void) testTwoExponentBigModulusSmallBase
{
    [self runForBase: 4 Exponent: 2 Modulus: 250];
    XCTAssertEqual(self.processor->state.r[3], 16, @"Should have the correct value");
}

-(void) testTwoExponentSmallModulusSmallBase
{
    [self runForBase: 4 Exponent: 2 Modulus: 10];
    XCTAssertEqual(self.processor->state.r[3], 6, @"Should have the correct value");
}

-(void) testLargeExponent
{
    [self runForBase: 255 Exponent: 200 Modulus: 255];
    XCTAssertEqual(self.processor->state.r[3], 0, @"Should have the correct value");
}

-(void) testLargeExponentBigModulus
{
    [self runForBase: 255 Exponent: 200 Modulus: 250];
    XCTAssertEqual(self.processor->state.r[3], 125, @"Should have the correct value");
}

-(void) testLargeExponentSmallModulus
{
    [self runForBase: 255 Exponent: 200 Modulus: 10];
    XCTAssertEqual(self.processor->state.r[3], 5, @"Should have the correct value");
}

-(void) testLargeExponentBigModulusSmallBase
{
    [self runForBase: 4 Exponent: 200 Modulus: 250];
    XCTAssertEqual(self.processor->state.r[3], 126, @"Should have the correct value");
}

-(void) testLargeExponentSmallModulusSmallBase
{
    [self runForBase: 4 Exponent: 200 Modulus: 10];
    XCTAssertEqual(self.processor->state.r[3], 6, @"Should have the correct value");
}

@end
