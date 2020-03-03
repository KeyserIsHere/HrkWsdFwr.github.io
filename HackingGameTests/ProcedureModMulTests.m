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

@interface ProcedureModMulTests : ProcedureTests

@end

@implementation ProcedureModMulTests

-(const char*) source
{
    return ".include modmul\nhlt";
}

-(void) runForA: (uint8_t)a B: (uint8_t)b Modulus: (uint8_t)m
{
    self.processor->state.r[0] = a;
    self.processor->state.r[1] = b;
    self.processor->state.r[2] = m;
    HKHubArchProcessorSetCycles(self.processor, 100000);
    HKHubArchSchedulerRun(self.scheduler, 0.0);
    
    XCTAssertEqual(self.processor->state.r[0], m == 0 ? 0 : (a % m), @"Should have the correct value");
    XCTAssertEqual(self.processor->state.r[1], m == 0 ? b : ((a % m) == 0 ? b : 0), @"Should have the correct value");
    XCTAssertEqual(self.processor->state.r[2], m, @"Should have the correct value");
}

-(void) testMultiplyingAllInputs
{
    HKHubArchProcessorCache(self.processor);
    
    for (uint32_t a = 0; a < 256; a++)
    {
        for (uint32_t b = 0; b < 256; b++)
        {
            for (uint32_t m = 0; m < 256; m++)
            {
                self.processor->state.r[0] = 0;
                self.processor->state.r[1] = 0;
                self.processor->state.r[2] = 0;
                self.processor->state.r[3] = 0;
                self.processor->state.pc = 0;
                self.processor->state.flags = 0;
                self.processor->status = HKHubArchProcessorStatusRunning;
                
                [self runForA: a B: b Modulus: m];
                
                const uint32_t Result = m == 0 ? 0 : ((a * b) % m);
                XCTAssertEqual(self.processor->state.r[3], Result, @"Should have the correct value: %u (%u * %u %% %u)", Result, a, b, m);
            }
        }
    }
}

@end
