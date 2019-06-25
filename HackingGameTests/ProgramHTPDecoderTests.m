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
#import "ProgramHTPDecoderTests.h"

@interface ProgramHTPDecoderTests ()

@property HKHubArchProcessor processor;
@property HKHubArchScheduler scheduler;

@end


@implementation ProgramHTPDecoderTests
@synthesize processor, scheduler;

-(const char*) program
{
    CCAssertLog(0, "Should be redefined by the subclass");
    return "";
}

static uint8_t *EncodedPackets = NULL;
static size_t EncodedPacketCount = 0, EncodedPacketIndex = 0;

-(void) setEncodedPackets: (uint8_t*)encodedPackets
{
    EncodedPackets = encodedPackets;
}

-(uint8_t*) encodedPackets
{
    return EncodedPackets;
}

-(void) setEncodedPacketCount: (size_t)encodedPacketCount
{
    EncodedPacketCount = encodedPacketCount;
}

-(size_t) encodedPacketCount
{
    return EncodedPacketCount;
}

-(size_t) encodedPacketIndex
{
    return EncodedPacketIndex;
}

static HKHubArchPortResponse InPort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    if (EncodedPacketIndex == EncodedPacketCount) return HKHubArchPortResponseTimeout;
    
    *Message = (HKHubArchPortMessage){
        .memory = EncodedPackets,
        .offset = EncodedPacketIndex,
        .size = 1
    };
    
    if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
    
    EncodedPacketIndex++;
    
    return HKHubArchPortResponseSuccess;
}

static CCQueue DecodedPackets = NULL;

-(CCQueue) decodedPackets
{
    return DecodedPackets;
}

static HKHubArchPortResponse OutPort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
    
    if (HKHubArchPortIsReady(OppositePort))
    {
        CCQueuePush(DecodedPackets, CCQueueCreateNode(CC_STD_ALLOCATOR, Message->size, Message->memory + Message->offset));
    }
    
    return HKHubArchPortResponseSuccess;
}

+(void) setUp
{
    if (HKHubArchAssemblyIncludeSearchPaths) CCCollectionDestroy(HKHubArchAssemblyIncludeSearchPaths);
    
    HKHubArchAssemblyIncludeSearchPaths = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(FSPath), FSPathComponentDestructorForCollection);
    
    CCOrderedCollectionAppendElement(HKHubArchAssemblyIncludeSearchPaths, &(FSPath){ FSPathCreate("assets/logic/programs/") });
}

-(void) setUp
{
    FSPath Path = FSPathCreate(self.program);
    
    FSHandle Handle;
    if (FSHandleOpen(Path, FSHandleTypeRead, &Handle) == FSOperationSuccess)
    {
        size_t Size = FSManagerGetSize(Path);
        char *Source;
        CC_SAFE_Malloc(Source, sizeof(char) * (Size + 1));
        
        FSHandleRead(Handle, &Size, Source, FSBehaviourDefault);
        Source[Size] = 0;
        
        FSHandleClose(Handle);
        
        CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
        
        CCOrderedCollection Errors = NULL;
        HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors);
        CCCollectionDestroy(AST);
        
        if (Binary)
        {
            processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
            HKHubArchBinaryDestroy(Binary);
        }
        
        CC_SAFE_Free(Source);
    }
    
    FSPathDestroy(Path);
    
    scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    HKHubArchSchedulerAddProcessor(scheduler, processor);
    
    
    EncodedPacketIndex = 0;
    EncodedPacketCount = 0;
    
    
    DecodedPackets = CCQueueCreate(CC_STD_ALLOCATOR);
    
    
    HKHubArchPortConnection Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(processor, 0), (HKHubArchPort){
        .sender = InPort,
        .receiver = NULL,
        .device = NULL,
        .destructor = NULL,
        .disconnect = NULL,
        .id = 0
    });
    
    HKHubArchProcessorConnect(processor, 0, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(processor, 1), (HKHubArchPort){
        .sender = NULL,
        .receiver = OutPort,
        .device = NULL,
        .destructor = NULL,
        .disconnect = NULL,
        .id = 0
    });
    
    HKHubArchProcessorConnect(processor, 1, Conn);
    HKHubArchPortConnectionDestroy(Conn);
}

-(void)tearDown
{
    if (processor) HKHubArchProcessorDestroy(processor);
    if (scheduler) HKHubArchSchedulerDestroy(scheduler);
    if (DecodedPackets) CCQueueDestroy(DecodedPackets);
}

@end

