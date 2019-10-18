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
#import "HubArchScheduler.h"

extern size_t RetCallCount;

#define RET(x) \
static _Bool RetDataIndex##x(void){ return DataIndex == x; } \
static _Bool RetDataIndexNot##x(void){ return !RetDataIndex##x(); } \
static _Bool RetOnceCalledDataIndex##x = FALSE; \
static _Bool RetOnceDataIndex##x(void) \
{ \
const _Bool Prev = RetOnceCalledDataIndex##x; \
return (RetDataIndex##x()) && (RetOnceCalledDataIndex##x = TRUE) && (!Prev); \
} \
static _Bool RetCallCount##x(void){ return RetCallCount++ == x; } \
static _Bool RetCallCountNot##x(void){ return !RetCallCount##x(); } \
static _Bool RetCallCountLessThan##x(void){ return RetCallCount++ < x; }

_Bool RetTrue(void);
_Bool RetFalse(void);

@interface ProgramTests : XCTestCase

@property (readonly) HKHubArchProcessor processor;
@property (readonly) HKHubArchScheduler scheduler;
@property (readonly) const char *program;
@property (readonly) const char *defines;

@end
