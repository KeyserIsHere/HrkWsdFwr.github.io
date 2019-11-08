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


static int PowMod(int b, int e, int m)
{
    if (m == 1) return 0;
    
    int r = 1;
    b = b % m;
    while (e > 0)
    {
        if (e % 2 == 1)
        {
            r = (r * b) % m;
        }
        
        e >>= 1;
        b = (b * b) % m;
    }
    
    return r;
}

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
    
    XCTAssertEqual(self.processor->state.r[1], modulus == 1 ? exponent : 0, @"Should have the correct value");
    XCTAssertEqual(self.processor->state.r[2], modulus, @"Should have the correct value");
}

-(void) testAllInputs
{
    for (uint32_t b = 0; b < 256; b++)
    {
        for (uint32_t e = 0; e < 256; e++)
        {
            for (uint32_t m = 1; m < 256; m++)
            {
                self.processor->state.r[0] = 0;
                self.processor->state.r[1] = 0;
                self.processor->state.r[2] = 0;
                self.processor->state.r[3] = 0;
                self.processor->state.pc = 0;
                self.processor->state.flags = 0;
                self.processor->status = HKHubArchProcessorStatusRunning;
                
                [self runForBase: b Exponent: e Modulus: m];
                
                const uint32_t Result = PowMod(b, e, m);
                XCTAssertEqual(self.processor->state.r[3], Result, @"Should have the correct value: %u (pow(%u, %u) %% %u)", Result, b, e, m);
            }
        }
    }
}

@end
