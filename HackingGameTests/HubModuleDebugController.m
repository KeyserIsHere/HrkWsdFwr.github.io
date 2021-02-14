/*
 *  Copyright (c) 2021, Stefan Johnson
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
#import "HubModuleDebugController.h"
#import "HubModuleKeyboard.h"

#define HKHubArchAssemblyPrintError(err) if (Errors) { HKHubArchAssemblyPrintError(err); CCCollectionDestroy(err); err = NULL; }

@interface HubModuleDebugController : XCTestCase

@end

@implementation HubModuleDebugController

-(void) testQueryAPI
{
    HKHubArchScheduler Scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    HKHubModule DebugController = HKHubModuleDebugControllerCreate(CC_STD_ALLOCATOR);
    
    const char *Source =
        "loop:\n"
        "add r0, 1\n"
        "jmp loop\n"
    ;
    
    CCOrderedCollection AST = HKHubArchAssemblyParse(Source);
    
    CCOrderedCollection Errors = NULL;
    HKHubArchBinary Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor TempProcessor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchSchedulerAddProcessor(Scheduler, TempProcessor);
    
    for (int Loop = 0; Loop < 5; Loop++)
    {
        Binary->data[2] += Loop;
        
        HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
        
        HKHubModuleDebugControllerConnectProcessor(DebugController, Processor);
        
        HKHubArchSchedulerAddProcessor(Scheduler, Processor);
        HKHubArchProcessorDestroy(Processor);
    }
    
    HKHubArchBinaryDestroy(Binary);
    
    HKHubModule Keyboard = HKHubModuleKeyboardCreate(CC_STD_ALLOCATOR);
    HKHubModuleDebugControllerConnectModule(DebugController, Keyboard);
    HKHubModuleKeyboardEnterKey(Keyboard, 1);
    HKHubModuleKeyboardEnterKey(Keyboard, 2);
    HKHubModuleKeyboardEnterKey(Keyboard, 3);
    HKHubModuleKeyboardEnterKey(Keyboard, 4);
    for (int Loop = 0; Loop < 251; Loop++) HKHubModuleKeyboardEnterKey(Keyboard, 0);
    HKHubModuleKeyboardEnterKey(Keyboard, 5);
    HKHubModuleKeyboardEnterKey(Keyboard, 6);
    HKHubModuleKeyboardEnterKey(Keyboard, 7);
    HKHubModuleKeyboardEnterKey(Keyboard, 8);
    HKHubModuleKeyboardEnterKey(Keyboard, 9);
    
     //[0:4] device count (count:16)
    Source =
        "device_count:\n"
        ".byte -1, -1\n"
        "device_count_query:\n"
        ".byte 0\n"
        ".entrypoint\n"
        "send r0, 1, [device_count_query]\n"
        "recv r0, [device_count]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessor Processor = HKHubArchProcessorCreate(CC_STD_ALLOCATOR, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchPortConnection Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor, 0), HKHubModuleGetPort(DebugController, HK_HUB_MODULE_DEBUG_CONTROLLER_QUERY_PORT | 0));
    
    HKHubArchProcessorConnect(Processor, 0, Conn);
    HKHubModuleConnect(DebugController, HK_HUB_MODULE_DEBUG_CONTROLLER_QUERY_PORT | 0, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    HKHubArchSchedulerAddProcessor(Scheduler, Processor);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //device_count
    XCTAssertEqual(Processor->memory[0], 0, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[1], 6, @"Should be the correct value");
    
    
    //[1:4] [device:12] memory size (size:16)
    Source =
        "proc_memory_size:\n"
        ".byte -1, -2\n"
        "mod_memory_size:\n"
        ".byte -1, -2\n"
        "null_memory_size:\n"
        ".byte -1, -2\n"
        "proc_memory_size_query:\n"
        ".byte (1 << 4) | 0, 0\n"
        "mod_memory_size_query:\n"
        ".byte (1 << 4) | 0, 5\n"
        "null_memory_size_query:\n"
        ".byte (1 << 4) | 0xf, 0xff\n"
        ".entrypoint\n"
        "send r0, 2, [proc_memory_size_query]\n"
        "recv r0, [proc_memory_size]\n"
        "send r0, 2, [mod_memory_size_query]\n"
        "recv r0, [mod_memory_size]\n"
        "send r0, 2, [null_memory_size_query]\n"
        "recv r0, [null_memory_size]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_memory_size
    XCTAssertEqual(Processor->memory[0], 1, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[1], 0, @"Should be the correct value");
    //mod_memory_size
    XCTAssertEqual(Processor->memory[2], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[3], 0xff, @"Should be the correct value");
    //null_memory_size
    XCTAssertEqual(Processor->memory[4], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[5], 0xfe, @"Should be the correct value");
    
    
    //[2:4] [device:12] read memory [offset:8] [size:8] ... (bytes:sum sizes)
    Source =
        "proc_read_memory:\n"
        ".byte -1, -2, -3, -4\n"
        "mod_read_memory:\n"
        ".byte -1, -2, -3, -4\n"
        "null_read_memory:\n"
        ".byte -1, -2, -3, -4\n"
        "split_proc_read_memory:\n"
        ".byte -1, -2, -3, -4\n"
        "split_mod_read_memory:\n"
        ".byte -1, -2, -3, -4\n"
        "proc_read_memory_query:\n"
        ".byte (2 << 4) | 0, 0, 0, 4\n"
        "mod_read_memory_query:\n"
        ".byte (2 << 4) | 0, 5, 0, 4\n"
        "null_read_memory_query:\n"
        ".byte (2 << 4) | 0, 0xff, 0, 4\n"
        "split_proc_read_memory_query:\n"
        ".byte (2 << 4) | 0, 0, 1, 1, 2, 0, 0xff, 3\n"
        "split_mod_read_memory_query:\n"
        ".byte (2 << 4) | 0, 5, 1, 1, 2, 0, 0xff, 3\n"
        ".entrypoint\n"
        "send r0, 4, [proc_read_memory_query]\n"
        "recv r0, [proc_read_memory]\n"
        "send r0, 4, [mod_read_memory_query]\n"
        "recv r0, [mod_read_memory]\n"
        "send r0, 4, [null_read_memory_query]\n"
        "recv r0, [null_read_memory]\n"
        "send r0, 8, [split_proc_read_memory_query]\n"
        "recv r0, [split_proc_read_memory]\n"
        "send r0, 8, [split_mod_read_memory_query]\n"
        "recv r0, [split_mod_read_memory]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_read_memory
    XCTAssertEqual(Processor->memory[0], TempProcessor->memory[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[1], TempProcessor->memory[1], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[2], TempProcessor->memory[2], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[3], TempProcessor->memory[3], @"Should be the correct value");
    //mod_read_memory
    XCTAssertEqual(Processor->memory[4], 1, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[5], 2, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[6], 3, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[7], 4, @"Should be the correct value");
    //null_read_memory
    XCTAssertEqual(Processor->memory[8], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[9], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[10], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[11], 0xfc, @"Should be the correct value");
    //split_proc_read_memory
    XCTAssertEqual(Processor->memory[12], TempProcessor->memory[1], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[13], TempProcessor->memory[255], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[14], TempProcessor->memory[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[15], TempProcessor->memory[1], @"Should be the correct value");
    //split_mod_read_memory
    XCTAssertEqual(Processor->memory[16], 2, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[17], 5, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[18], 6, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[19], 7, @"Should be the correct value");
    
    
    //[3:4] [device:12] read memory [offset:16] [size:8] ... (bytes:sum sizes)
    Source =
        "proc_read_memory16:\n"
        ".byte -1, -2, -3, -4\n"
        "mod_read_memory16:\n"
        ".byte -1, -2, -3, -4\n"
        "null_read_memory16:\n"
        ".byte -1, -2, -3, -4\n"
        "split_proc_read_memory16:\n"
        ".byte -1, -2, -3, -4\n"
        "split_mod_read_memory16:\n"
        ".byte -1, -2, -3, -4\n"
        "proc_read_memory_query16:\n"
        ".byte (3 << 4) | 0, 0, 1, 0, 4\n"
        "mod_read_memory_query16:\n"
        ".byte (3 << 4) | 0, 5, 1, 0, 4\n"
        "null_read_memory_query16:\n"
        ".byte (3 << 4) | 0, 0xff, 0, 0, 4\n"
        "split_proc_read_memory_query16:\n"
        ".byte (3 << 4) | 0, 0, 1, 1, 1, 0, 2, 0, 0, 0xff, 3\n"
        "split_mod_read_memory_query16:\n"
        ".byte (3 << 4) | 0, 5, 0, 1, 1, 0, 2, 0, 1, 0, 3\n"
        ".entrypoint\n"
        "send r0, 5, [proc_read_memory_query16]\n"
        "recv r0, [proc_read_memory16]\n"
        "send r0, 5, [mod_read_memory_query16]\n"
        "recv r0, [mod_read_memory16]\n"
        "send r0, 5, [null_read_memory_query16]\n"
        "recv r0, [null_read_memory16]\n"
        "send r0, 11, [split_proc_read_memory_query16]\n"
        "recv r0, [split_proc_read_memory16]\n"
        "send r0, 11, [split_mod_read_memory_query16]\n"
        "recv r0, [split_mod_read_memory16]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_read_memory16
    XCTAssertEqual(Processor->memory[0], TempProcessor->memory[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[1], TempProcessor->memory[1], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[2], TempProcessor->memory[2], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[3], TempProcessor->memory[3], @"Should be the correct value");
    //mod_read_memory16
    XCTAssertEqual(Processor->memory[4], 6, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[5], 7, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[6], 8, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[7], 9, @"Should be the correct value");
    //null_read_memory16
    XCTAssertEqual(Processor->memory[8], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[9], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[10], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[11], 0xfc, @"Should be the correct value");
    //split_proc_read_memory16
    XCTAssertEqual(Processor->memory[12], TempProcessor->memory[1], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[13], TempProcessor->memory[255], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[14], TempProcessor->memory[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[15], TempProcessor->memory[1], @"Should be the correct value");
    //split_mod_read_memory16
    XCTAssertEqual(Processor->memory[16], 2, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[17], 6, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[18], 7, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[19], 8, @"Should be the correct value");
    
    HKHubArchProcessorDestroy(TempProcessor);
    HKHubArchProcessorDestroy(Processor);
    HKHubModuleDestroy(Keyboard);
    HKHubModuleDestroy(DebugController);
    HKHubArchSchedulerDestroy(Scheduler);
}

@end
