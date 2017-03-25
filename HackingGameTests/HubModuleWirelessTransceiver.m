/*
 *  Copyright (c) 2017, Stefan Johnson
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
#import "HubModuleWirelessTransceiver.h"

@interface HubModuleWirelessTransceiver : XCTestCase

@end

@implementation HubModuleWirelessTransceiver

-(void) testSendingPackets
{
    HKHubModule Transceiver = HKHubModuleWirelessTransceiverCreate(CC_STD_ALLOCATOR);
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 20, .channel = 12 },
        .data = 0xf
    });
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 20, .channel = 12 },
        .data = 0x9
    });
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 20, .channel = 12 },
        .data = 0x10
    });
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 21, .channel = 12 },
        .data = 0xf
    });
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 21, .channel = 13 },
        .data = 0x9
    });
    
    HKHubModuleWirelessTransceiverReceivePacket(Transceiver, (HKHubModuleWirelessTransceiverPacket){
        .sig = { .timestamp = 22, .channel = 12 },
        .data = 0x10
    });
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 19, .channel = 12 }, NULL), @"Should not contain a packet");
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 20, .channel = 11 }, NULL), @"Should not contain a packet");
    
    uint8_t Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 20, .channel = 12 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 0xf ^ 0x9 ^ 0x10, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 21, .channel = 12 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 0xf, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 21, .channel = 13 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 0x9, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceiver, (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 22, .channel = 12 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 0x10, @"Packet should contain the expected data");
    
    HKHubModuleDestroy(Transceiver);
}

static HKHubArchScheduler Scheduler;

static HKHubArchScheduler GetScheduler(HKHubModule Module)
{
    return Scheduler;
}

static HKHubModule Transceivers[3];

static void Broadcast(HKHubModule Transmitter, HKHubModuleWirelessTransceiverPacket Packet)
{
    for (size_t Loop = 0; Loop < sizeof(Transceivers) / sizeof(typeof(*Transceivers)); Loop++)
    {
        if (Transceivers[Loop] != Transmitter) HKHubModuleWirelessTransceiverReceivePacket(Transceivers[Loop], Packet);
    }
}

-(void) testHubCommunication
{
    Scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    HKHubModuleWirelessTransceiverGetScheduler = GetScheduler;
    HKHubModuleWirelessTransceiverBroadcast = Broadcast;
    
    for (size_t Loop = 0; Loop < sizeof(Transceivers) / sizeof(typeof(*Transceivers)); Loop++) Transceivers[Loop] = HKHubModuleWirelessTransceiverCreate(CC_STD_ALLOCATOR);
    
    
    const char *Source =
        ".define channel0, 0\n"
        ".define channel1, 1\n"
        "packet: .byte 1\n"
        ".entrypoint\n"
        "send channel0, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "send channel0, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "nop\n" //cycles(1) = read(1)
        "send channel1, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "hlt\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor0 = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchPortConnection Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor0, 0), HKHubModuleGetPort(Transceivers[0], 0));
    
    HKHubArchProcessorConnect(Processor0, 0, Conn);
    HKHubModuleConnect(Transceivers[0], 0, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor0, 1), HKHubModuleGetPort(Transceivers[0], 1));
    
    HKHubArchProcessorConnect(Processor0, 1, Conn);
    HKHubModuleConnect(Transceivers[0], 1, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    HKHubArchSchedulerAddProcessor(Scheduler, Processor0);
    
    
    
    Source =
        ".define channel0, 0\n"
        ".define channel2, 2\n"
        "packet: .byte 3\n"
        ".entrypoint\n"
        "send channel0, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "nop\n" //cycles(1) = read(1)
        "send channel0, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "send channel2, 1, [packet]\n" //cycles(14) = read(5) + instruction(4) + read(1) + transfer<1>(4)
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor1 = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor1, 0), HKHubModuleGetPort(Transceivers[1], 0));
    
    HKHubArchProcessorConnect(Processor1, 0, Conn);
    HKHubModuleConnect(Transceivers[1], 0, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor1, 2), HKHubModuleGetPort(Transceivers[1], 2));
    
    HKHubArchProcessorConnect(Processor1, 2, Conn);
    HKHubModuleConnect(Transceivers[1], 2, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    HKHubArchSchedulerAddProcessor(Scheduler, Processor1);
    
    
    HKHubArchProcessorSetCycles(Processor0, 100);
    HKHubArchProcessorSetCycles(Processor1, 100);
    HKHubArchSchedulerRun(Scheduler, 0.0);
    
    uint8_t Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 86, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 3, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 86, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 86, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1 ^ 3, @"Packet should contain the expected data");
    
    
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 72, .channel = 0 }, &Data), @"Should contain a packet");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 72, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 72, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1, @"Packet should contain the expected data");
    
    
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 71, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 3, @"Packet should contain the expected data");
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 71, .channel = 0 }, &Data), @"Should contain a packet");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 71, .channel = 0 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 3, @"Packet should contain the expected data");
    
    
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 0 }, &Data), @"Should contain a packet");
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 0 }, &Data), @"Should contain a packet");
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 0 }, &Data), @"Should contain a packet");
    
    
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 1 }, &Data), @"Should contain a packet");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 1 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1, @"Packet should contain the expected data");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 1 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 1, @"Packet should contain the expected data");
    
    
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[0], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 2 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 3, @"Packet should contain the expected data");
    
    XCTAssertFalse(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[1], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 2 }, &Data), @"Should contain a packet");
    
    Data = 0;
    XCTAssertTrue(HKHubModuleWirelessTransceiverInspectPacket(Transceivers[2], (HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = 57, .channel = 2 }, &Data), @"Should contain a packet");
    XCTAssertEqual(Data, 3, @"Packet should contain the expected data");
    
    
    HKHubArchProcessorDestroy(Processor1);
    HKHubArchProcessorDestroy(Processor0);
    HKHubArchSchedulerDestroy(Scheduler);
    
    for (size_t Loop = 0; Loop < sizeof(Transceivers) / sizeof(typeof(*Transceivers)); Loop++) HKHubModuleDestroy(Transceivers[Loop]);
}

@end
