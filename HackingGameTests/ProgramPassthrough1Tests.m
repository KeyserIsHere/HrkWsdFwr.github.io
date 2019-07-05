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
#import "ProgramTests.h"

@interface ProgramPassthrough1Tests : ProgramTests

@end

@implementation ProgramPassthrough1Tests

-(const char*) program
{
    return "assets/logic/programs/passthrough_1.chasm";
}

-(const char*) defines
{
    return ".define count, 255\n";
}

static uint8_t *InData = NULL;
static size_t DataCount = 0, DataIndex = 0;

static HKHubArchPortResponse InPort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    if (DataIndex == DataCount) return HKHubArchPortResponseTimeout;
    
    *Message = (HKHubArchPortMessage){
        .memory = &InData[DataIndex],
        .offset = 0,
        .size = 1
    };
    
    if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
    
    DataIndex++;
    
    return HKHubArchPortResponseSuccess;
}

static CCQueue Pool[255] = {NULL};
static size_t PoolIndex = 0;
static HKHubArchPortResponse OutPort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    if (Port != PoolIndex) return HKHubArchPortResponseTimeout;
    
    const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
    
    if (HKHubArchPortIsReady(OppositePort))
    {
        CCQueuePush(Pool[Port], CCQueueCreateNode(CC_STD_ALLOCATOR, Message->size, Message->memory + Message->offset));
        
        return HKHubArchPortResponseSuccess;
    }
    
    return HKHubArchPortResponseDefer;
}

-(void) setUp
{
    [super setUp];
    
    InData = NULL;
    DataCount = 0;
    DataIndex = 0;
    
    PoolIndex = 0;
    for (size_t Loop = 0; Loop < sizeof(Pool) / sizeof(typeof(*Pool)); Loop++)
    {
        Pool[Loop] = CCQueueCreate(CC_STD_ALLOCATOR);
        
        HKHubArchPortConnection Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(self.processor, Loop), (HKHubArchPort){
            .sender = NULL,
            .receiver = OutPort,
            .device = NULL,
            .destructor = NULL,
            .disconnect = NULL,
            .id = 0
        });
        
        HKHubArchProcessorConnect(self.processor, Loop, Conn);
        HKHubArchPortConnectionDestroy(Conn);
    }
    
    HKHubArchPortConnection Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(self.processor, 255), (HKHubArchPort){
        .sender = InPort,
        .receiver = NULL,
        .device = NULL,
        .destructor = NULL,
        .disconnect = NULL,
        .id = 0
    });
    
    HKHubArchProcessorConnect(self.processor, 255, Conn);
    HKHubArchPortConnectionDestroy(Conn);
}

-(void)tearDown
{
    for (size_t Loop = 0; Loop < sizeof(Pool) / sizeof(typeof(*Pool)); Loop++)
    {
        if (Pool[Loop]) CCQueueDestroy(Pool[Loop]);
    }
    
    [super tearDown];
}

-(void) testPassingToBusyPool
{
    uint8_t Data[] = {
        1, 2, 3, 4, 5
    };
    
    InData = Data;
    DataCount = sizeof(Data) / sizeof(typeof(*Data));
    DataIndex = 0;
    PoolIndex = 256;
    
    HKHubArchProcessorSetCycles(self.processor, 100000);
    HKHubArchSchedulerRun(self.scheduler, 0.0);
    
    XCTAssertEqual(DataIndex, 1, @"Should consume only the first chunk");
    
    for (size_t Loop = 0; Loop < sizeof(Pool) / sizeof(typeof(*Pool)); Loop++)
    {
        CCQueueNode *Node = CCQueuePop(Pool[Loop]);
        XCTAssertEqual(Node, NULL, @"Should not receive any data");
    }
}

-(void) testPassingToSinglePool
{
    uint8_t Data[] = {
        1, 2, 3, 4, 5
    };
    
    InData = Data;
    DataCount = sizeof(Data) / sizeof(typeof(*Data));
    DataIndex = 0;
    PoolIndex = 0;
    
    HKHubArchProcessorSetCycles(self.processor, 100000);
    HKHubArchSchedulerRun(self.scheduler, 0.0);
    
    XCTAssertEqual(DataIndex, DataCount, @"Should consume all the input data");
    
    for (size_t Loop = 0; Loop < DataCount; Loop++)
    {
        CCQueueNode *Node = CCQueuePop(Pool[0]);
        XCTAssertNotEqual(Node, NULL, @"Should have data");
        if (Node)
        {
            XCTAssertEqual(*(uint8_t*)CCQueueGetNodeData(Node), Loop + 1, @"Should have the correct data");
            CCQueueDestroyNode(Node);
        }
    }
    
    for (size_t Loop = 1; Loop < sizeof(Pool) / sizeof(typeof(*Pool)); Loop++)
    {
        CCQueueNode *Node = CCQueuePop(Pool[Loop]);
        XCTAssertEqual(Node, NULL, @"Should not receive any data");
    }
}

@end
