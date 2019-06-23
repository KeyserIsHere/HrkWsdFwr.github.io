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

@interface ProgramHTPDecoderTests : XCTestCase

@end

@implementation ProgramHTPDecoderTests
{
    HKHubArchBinary binary;
    HKHubArchProcessor processor;
    HKHubArchScheduler scheduler;
}

static uint8_t *EncodedPackets = NULL;
static size_t EncodedPacketCount = 0, EncodedPacketIndex = 0;
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

typedef struct {
    uint8_t size;
    uint8_t data[];
} Packet;

static CCQueue DecodedPackets = NULL;
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
    FSPath Path = FSPathCreate("assets/logic/programs/htp1_decoder.chasm");
    
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
        binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors);
        CCCollectionDestroy(AST);
        
        if (binary) processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, binary);
        
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
    if (binary) HKHubArchBinaryDestroy(binary);
    if (processor) HKHubArchProcessorDestroy(processor);
    if (scheduler) HKHubArchSchedulerDestroy(scheduler);
    if (DecodedPackets) CCQueueDestroy(DecodedPackets);
}

-(void) testDecodingPacket
{
    uint8_t Data[] = {
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3 // 1 bit htp
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
    if (Node)
    {
        Packet *P = CCQueueGetNodeData(Node);
        XCTAssertEqual(P->size, 3, @"Should have the correct size");
        XCTAssertEqual(P->data[0], 2, @"Should have the correct data");
        XCTAssertEqual(P->data[1], 1, @"Should have the correct data");
        XCTAssertEqual(P->data[2], 0xff, @"Should have the correct data");
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingPacketSeries
{
    uint8_t Data[] = {
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9, 3,
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node;
    for (size_t Loop = 0; Loop < 8; Loop++)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 3, @"Should have the correct size");
            XCTAssertEqual(P->data[0], 2, @"Should have the correct data");
            XCTAssertEqual(P->data[1], 1, @"Should have the correct data");
            XCTAssertEqual(P->data[2], 0xff, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingInterleavedPackets
{
    uint8_t Data[] = {
        108, 180, 108, 216, 234, 116, 180, 216, 234, 116, 184, 184, 91, 171, 84, 168, 210, 104, 178, 88, 91, 171, 84, 168, 43, 20, 136,
        210, 194, 96, 104, 174, 86, 42, 20, 9, 178, 88, 43, 20, 136, 194, 96, 3, 174, 86, 42, 20, 9, 3, 127, 189, 127, 189, 93, 45, 93,
        45, 21, 9, 3, 21, 9, 3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node;
    for (size_t Loop = 0; Loop < 2; Loop++)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 3, @"Should have the correct size");
            XCTAssertEqual(P->data[0], 2, @"Should have the correct data");
            XCTAssertEqual(P->data[1], 1, @"Should have the correct data");
            XCTAssertEqual(P->data[2], 0xff, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingPacketsMixed
{
    uint8_t Data[] = {
        136, 194, 96, 174, 86, 42, 20, 9, 130, 64, 158, 78, 38, 18, 8, 3,
        8, 130, 64, 158, 78, 38, 18, 135, 66, 32, 142, 70, 34, 16, 7, 2,
        10, 4, 128, 190, 94, 46, 22, 137, 194, 96, 174, 86, 42, 20, 9, 3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node;
    for (size_t Loop = 0; Loop < 3; Loop++)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 1, @"Should have the correct size");
            XCTAssertEqual(P->data[0], Loop + 1, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testPacketDecay
{
    uint8_t Data[] = {
        136, 194, 96, 174, 86, 42, 20, 9,
        8, 130, 64, 158, 78, 38, 18, 135, 66, 32, 142, 70, 34, 16, 7, 2,
        8, 130, 64, 158, 78, 38, 18, 135, 66, 32, 142, 70, 34, 16, 7, 2,
        130, 64, 158, 78, 38, 18, 8, 3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node;
    for (size_t Loop = 0; Loop < 2; Loop++)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 1, @"Should have the correct size");
            XCTAssertEqual(P->data[0], 2, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testPacketMixedInterleaved
{
    uint8_t Data[] = {
        8, 130, //p2
        8, 130, //p3
        136, 194, 96, 174, 86, 42, 20, 9, 130, //p1
        64, 158, 78, 38, 18, //p2
        64, //p1
        64, 158, //p3
        158, 78, 38, 18, 8, 3, //p1
        135, 66, 32, 142, 70, 34, 16, 7, 2, //p2
        78, 38, 18, 135, 66, 32, 142, 70, 34, 16, 7, 2, //p3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
    if (Node)
    {
        Packet *P = CCQueueGetNodeData(Node);
        XCTAssertEqual(P->size, 1, @"Should have the correct size");
        XCTAssertEqual(P->data[0], 1, @"Should have the correct data");
    }
    
    for (size_t Loop = 0; Loop < 2; Loop++)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 1, @"Should have the correct size");
            XCTAssertEqual(P->data[0], 2, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testPacketHashCollision
{
    uint8_t Data[] = {
        136, 194, 96, 174, 86, //p1
        169,
        42, 20, 9, 130, 64, 158, 78, 38, 18, 8, 3, //p1
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testPacketHashSeeding
{
    uint8_t Data[] = {
        160, 206, 102, 50, 24, //p1
        169,
        138, 68, 33, 142, 70, 34, 16, 134, 66, 32, 15 //p1
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
    if (Node)
    {
        Packet *P = CCQueueGetNodeData(Node);
        XCTAssertEqual(P->size, 1, @"Should have the correct size");
        XCTAssertEqual(P->data[0], 1, @"Should have the correct data");
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testMaxConcurrentPackets
{
    uint8_t Data[] = {
        136, //p1
        8, //p2
        10, //p3
        198, //p4
        200, //p5
        72, //p6
        194, //p1
        130, //p2
        4, //p3
        98, //p4
        226, //p5
        162, //p6
        96, //p1
        64, //p2
        128, //p3
        48, //p4
        112, //p5
        80, //p6
        174, //p1
        158, //p2
        190, //p3
        150, //p4
        182, //p5
        166, //p6
        86, //p1
        78, //p2
        94, //p3
        74, //p4
        90, //p5
        82, //p6
        42, //p1
        38, //p2
        46, //p3
        36, //p4
        44, //p5
        40, //p6
        20, //p1
        18, //p2
        22, //p3
        144, //p4
        148, //p5
        146, //p6
        9, //p1
        135, //p2
        137, //p3
        71, //p4
        73, //p5
        199, //p6
        130, //p1
        66, //p2
        194, //p3
        34, //p4
        162, //p5
        98, //p6
        64, //p1
        32, //p2
        96, //p3
        16, //p4
        80, //p5
        48, //p6
        158, //p1
        142, //p2
        174, //p3
        134, //p4
        166, //p5
        150, //p6
        78, //p1
        70, //p2
        86, //p3
        66, //p4
        82, //p5
        74, //p6
        38, //p1
        34, //p2
        42, //p3
        32, //p4
        40, //p5
        36, //p6
        18, //p1
        16, //p2
        20, //p3
        15, //p4
        19, //p5
        17, //p6
        8, //p1
        7, //p2
        9, //p3
        6, //p4
        8, //p5
        7, //p6
        3, //p1
        2, //p2
        3, //p3
        2, //p4
        3, //p5
        2 //p6
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node;
    for (size_t Loop = 5; Loop > 0; Loop--)
    {
        Node = CCQueuePop(DecodedPackets);
        XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
        if (Node)
        {
            Packet *P = CCQueueGetNodeData(Node);
            XCTAssertEqual(P->size, 1, @"Should have the correct size");
            XCTAssertEqual(P->data[0], Loop, @"Should have the correct data");
        }
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingIncompletePacket
{
    uint8_t Data[] = {
        108, 180, 216, 234, 116, 184, 91, 171, 84, 168, 210, 104, 178, 88, 43, 20, 136, 194, 96, 174, 86, 42, 20, 9, 3, 127, 189, 93, 45, 21, 9 // 1 bit htp
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingPacketLengthUnusedData
{
    uint8_t Data[] = {
        167, 209, 103, 177, 87, 42, 20, 9, 130, 64, 158, 78, 38, 18, 8, 3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
    if (Node)
    {
        Packet *P = CCQueueGetNodeData(Node);
        XCTAssertEqual(P->size, 0xf8 | 1, @"Should have the correct size");
        XCTAssertEqual(P->data[0], 1, @"Should have the correct data");
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingPacketMaxLength
{
    uint8_t Data[] = {
        50, 24, 138, 68, 160, 79, 165, 81, 166, 82, 40, 146, 72, 162, 80, 39, 18, 8,
        130, 64, 158, 78, 165, 208, 230, 114, 56, 154, 76, 164, 81, 39, 18, 8, 130, 64,
        158, 205, 228, 240, 246, 122, 60, 156, 204, 101, 176, 87, 42, 20, 136, 194, 96,
        47, 149, 200, 226, 112, 182, 90, 44, 21, 9, 3
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertNotEqual(Node, NULL, @"Should have a decoded packet");
    if (Node)
    {
        Packet *P = CCQueueGetNodeData(Node);
        XCTAssertEqual(P->size, 7, @"Should have the correct size");
        XCTAssertEqual(P->data[0], 1, @"Should have the correct data");
        XCTAssertEqual(P->data[1], 2, @"Should have the correct data");
        XCTAssertEqual(P->data[2], 3, @"Should have the correct data");
        XCTAssertEqual(P->data[3], 4, @"Should have the correct data");
        XCTAssertEqual(P->data[4], 5, @"Should have the correct data");
        XCTAssertEqual(P->data[5], 6, @"Should have the correct data");
        XCTAssertEqual(P->data[6], 7, @"Should have the correct data");
    }
    
    Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

-(void) testDecodingPacketZeroLength
{
    uint8_t Data[] = {
        2, 254, 126, 62, 30, 14, 6, 2
    };
    
    EncodedPackets = Data;
    EncodedPacketCount = sizeof(Data) / sizeof(typeof(*Data));
    HKHubArchProcessorSetCycles(processor, 100000);
    HKHubArchSchedulerRun(scheduler, 0.0);
    
    XCTAssertEqual(EncodedPacketIndex, EncodedPacketCount, @"Should consume all incoming packets");
    
    CCQueueNode *Node = CCQueuePop(DecodedPackets);
    XCTAssertEqual(Node, NULL, @"Should not have anymore decoded packets");
}

@end
