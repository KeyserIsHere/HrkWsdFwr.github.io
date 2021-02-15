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
    HKHubModuleDebugControllerConnectProcessor(DebugController, TempProcessor);
    HKHubArchSchedulerAddProcessor(Scheduler, TempProcessor);
    
    for (int Loop = 1; Loop < 5; Loop++)
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
    
    
    //[4:4] [device:12] read registers [_:2, r0:1?, r1:1?, r2:1?, r3:1?, flags:1?, pc:1?, defaults to 0x3f] (r0:8?, r1:8?, r2:8?, r3:8?, flags:8?, pc:8?)
    Source =
        "proc_all_regs:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "mod_all_regs:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "null_all_regs:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "proc_r0_and_pc:\n"
        ".byte -1, -2\n"
        "mod_r0_and_pc:\n"
        ".byte -1, -2\n"
        "null_r0_and_pc:\n"
        ".byte -1, -2\n"
        "proc_all_regs_query:\n"
        ".byte (4 << 4) | 0, 0\n"
        "mod_all_regs_query:\n"
        ".byte (4 << 4) | 0, 5\n"
        "null_all_regs_query:\n"
        ".byte (4 << 4) | 0, 0xff\n"
        "proc_r0_and_pc_query:\n"
        ".byte (4 << 4) | 0, 0, (1 << 5) | 1 \n"
        "mod_r0_and_pc_query:\n"
        ".byte (4 << 4) | 0, 5, (1 << 5) | 1 \n"
        "null_r0_and_pc_query:\n"
        ".byte (4 << 4) | 0, 0xff, (1 << 5) | 1 \n"
        ".entrypoint\n"
        "send r0, 2, [proc_all_regs_query]\n"
        "recv r0, [proc_all_regs]\n"
        "send r0, 2, [mod_all_regs_query]\n"
        "recv r0, [mod_all_regs]\n"
        "send r0, 2, [null_all_regs_query]\n"
        "recv r0, [null_all_regs]\n"
        "send r0, 4, [proc_r0_and_pc_query]\n"
        "recv r0, [proc_r0_and_pc]\n"
        "send r0, 4, [mod_r0_and_pc_query]\n"
        "recv r0, [mod_r0_and_pc]\n"
        "send r0, 4, [null_r0_and_pc_query]\n"
        "recv r0, [null_r0_and_pc]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    TempProcessor->state.r[0] = 1;
    TempProcessor->state.r[1] = 2;
    TempProcessor->state.r[2] = 3;
    TempProcessor->state.r[3] = 4;
    TempProcessor->state.flags = 5;
    TempProcessor->state.pc = 6;
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_all_regs
    XCTAssertEqual(Processor->memory[0], TempProcessor->state.r[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[1], TempProcessor->state.r[1], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[2], TempProcessor->state.r[2], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[3], TempProcessor->state.r[3], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[4], TempProcessor->state.flags, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[5], TempProcessor->state.pc, @"Should be the correct value");
    //mod_all_regs
    XCTAssertEqual(Processor->memory[6], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[7], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[8], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[9], 0xfc, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[10], 0xfb, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[11], 0xfa, @"Should be the correct value");
    //null_all_regs
    XCTAssertEqual(Processor->memory[12], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[13], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[14], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[15], 0xfc, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[16], 0xfb, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[17], 0xfa, @"Should be the correct value");
    //proc_r0_and_pc
    XCTAssertEqual(Processor->memory[18], TempProcessor->state.r[0], @"Should be the correct value");
    XCTAssertEqual(Processor->memory[19], TempProcessor->state.pc, @"Should be the correct value");
    //mod_r0_and_pc
    XCTAssertEqual(Processor->memory[20], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[21], 0xfe, @"Should be the correct value");
    //null_r0_and_pc
    XCTAssertEqual(Processor->memory[22], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[23], 0xfe, @"Should be the correct value");
    
    TempProcessor->state.r[0] = 0;
    TempProcessor->state.r[1] = 0;
    TempProcessor->state.r[2] = 0;
    TempProcessor->state.r[3] = 0;
    TempProcessor->state.flags = 0;
    TempProcessor->state.pc = 0;
    
    
    //[5:4] [device:12] read breakpoints [offset:8? ... defaults to every offset] (r:1 ..., w:1 ...)
    Source =
        "proc_all_brks:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "mod_all_brks:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "null_all_brks:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "proc_0_and_2:\n"
        ".byte -1\n"
        "mod_0_and_2:\n"
        ".byte -1\n"
        "null_0_and_2:\n"
        ".byte -1\n"
        "proc_all_brks_query:\n"
        ".byte (5 << 4) | 0, 0\n"
        "mod_all_brks_query:\n"
        ".byte (5 << 4) | 0, 5\n"
        "null_all_brks_query:\n"
        ".byte (5 << 4) | 0, 0xff\n"
        "proc_0_and_2_query:\n"
        ".byte (5 << 4) | 0, 0, 0, 2 \n"
        "mod_0_and_2_query:\n"
        ".byte (5 << 4) | 0, 5, 0, 2 \n"
        "null_0_and_2_query:\n"
        ".byte (5 << 4) | 0, 0xff, 0, 2 \n"
        ".entrypoint\n"
        "send r0, 2, [proc_all_brks_query]\n"
        "recv r0, [proc_all_brks]\n"
        "send r0, 2, [mod_all_brks_query]\n"
        "recv r0, [mod_all_brks]\n"
        "send r0, 2, [null_all_brks_query]\n"
        "recv r0, [null_all_brks]\n"
        "send r0, 4, [proc_0_and_2_query]\n"
        "recv r0, [proc_0_and_2]\n"
        "send r0, 4, [mod_0_and_2_query]\n"
        "recv r0, [mod_0_and_2]\n"
        "send r0, 4, [null_0_and_2_query]\n"
        "recv r0, [null_0_and_2]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_all_brks
    for (int Loop = 0; Loop < 4; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], 0, @"Should be the correct value");
        }
    }
    //mod_all_brks
    for (int Loop = 4; Loop < 8; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], (uint8_t)-(Loop2 + 1), @"Should be the correct value");
        }
    }
    //null_all_brks
    for (int Loop = 8; Loop < 12; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], (uint8_t)-(Loop2 + 1), @"Should be the correct value");
        }
    }
    //proc_0_and_2
    XCTAssertEqual(Processor->memory[192], 0, @"Should be the correct value");
    //mod_0_and_2
    XCTAssertEqual(Processor->memory[193], 0xff, @"Should be the correct value");
    //null_0_and_2
    XCTAssertEqual(Processor->memory[194], 0xff, @"Should be the correct value");
    
    HKHubArchProcessorSetBreakpoint(TempProcessor, HKHubArchProcessorDebugBreakpointRead, 0);
    HKHubArchProcessorSetBreakpoint(TempProcessor, HKHubArchProcessorDebugBreakpointWrite | HKHubArchProcessorDebugBreakpointRead, 2);
    HKHubArchProcessorSetBreakpoint(TempProcessor, HKHubArchProcessorDebugBreakpointRead, 255);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_all_brks
    XCTAssertEqual(Processor->memory[0], 76, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[63], 1, @"Should be the correct value");
    //proc_0_and_2
    XCTAssertEqual(Processor->memory[192], 112, @"Should be the correct value");
    
    //[6:4] [device:12] read ports (256 bits)
    //[6:4] [device:12] read ports [port:8 ...] (receiving port:8, device:12)
    Source =
        "proc_all_ports:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "mod_all_ports:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "null_all_ports:\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        ".byte -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16\n"
        "proc_0_and_2:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "mod_0_and_2:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "null_0_and_2:\n"
        ".byte -1, -2, -3, -4, -5, -6\n"
        "proc_all_ports_query:\n"
        ".byte (6 << 4) | 0, 0\n"
        "mod_all_ports_query:\n"
        ".byte (6 << 4) | 0, 5\n"
        "null_all_ports_query:\n"
        ".byte (6 << 4) | 0, 0xff\n"
        "proc_0_and_2_query:\n"
        ".byte (6 << 4) | 0, 0, 0, 2 \n"
        "mod_0_and_2_query:\n"
        ".byte (6 << 4) | 0, 5, 0, 2 \n"
        "null_0_and_2_query:\n"
        ".byte (6 << 4) | 0, 0xff, 0, 2 \n"
        ".entrypoint\n"
        "send r0, 2, [proc_all_ports_query]\n"
        "recv r0, [proc_all_ports]\n"
        "send r0, 2, [mod_all_ports_query]\n"
        "recv r0, [mod_all_ports]\n"
        "send r0, 2, [null_all_ports_query]\n"
        "recv r0, [null_all_ports]\n"
        "send r0, 4, [proc_0_and_2_query]\n"
        "recv r0, [proc_0_and_2]\n"
        "send r0, 4, [mod_0_and_2_query]\n"
        "recv r0, [mod_0_and_2]\n"
        "send r0, 4, [null_0_and_2_query]\n"
        "recv r0, [null_0_and_2]\n"
        "hlt\n"
    ;
    
    AST = HKHubArchAssemblyParse(Source);
    
    Errors = NULL;
    Binary = HKHubArchAssemblyCreateBinary(CC_STD_ALLOCATOR, AST, &Errors); HKHubArchAssemblyPrintError(Errors);
    CCCollectionDestroy(AST);
    
    HKHubArchProcessorReset(Processor, Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_all_brks
    for (int Loop = 0; Loop < 2; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], 0, @"Should be the correct value");
        }
    }
    //mod_all_brks
    for (int Loop = 2; Loop < 4; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], (uint8_t)-(Loop2 + 1), @"Should be the correct value");
        }
    }
    //null_all_brks
    for (int Loop = 4; Loop < 6; Loop++)
    {
        for (int Loop2 = 0; Loop2 < 16; Loop2++)
        {
            XCTAssertEqual(Processor->memory[(Loop * 16) + Loop2], (uint8_t)-(Loop2 + 1), @"Should be the correct value");
        }
    }
    //proc_0_and_2
    XCTAssertEqual(Processor->memory[96], 0, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[97], 0xf, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[98], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[99], 0, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[100], 0xf, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[101], 0xff, @"Should be the correct value");
    //mod_0_and_2
    XCTAssertEqual(Processor->memory[102], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[103], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[104], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[105], 0xfc, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[106], 0xfb, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[107], 0xfa, @"Should be the correct value");
    //null_0_and_2
    XCTAssertEqual(Processor->memory[108], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[109], 0xfe, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[110], 0xfd, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[111], 0xfc, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[112], 0xfb, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[113], 0xfa, @"Should be the correct value");
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubArchProcessorGetPort(Processor, 1), HKHubArchProcessorGetPort(TempProcessor, 0));
    
    HKHubArchProcessorConnect(Processor, 1, Conn);
    HKHubArchProcessorConnect(TempProcessor, 0, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    Conn = HKHubArchPortConnectionCreate(CC_STD_ALLOCATOR, HKHubModuleGetPort(Keyboard, 29), HKHubArchProcessorGetPort(TempProcessor, 2));
    
    HKHubModuleConnect(Keyboard, 29, Conn);
    HKHubArchProcessorConnect(TempProcessor, 2, Conn);
    HKHubArchPortConnectionDestroy(Conn);
    
    HKHubArchProcessorReset(Processor, Binary);
    HKHubArchBinaryDestroy(Binary);
    
    HKHubArchSchedulerRun(Scheduler, 10.0);
    
    //proc_all_brks
    XCTAssertEqual(Processor->memory[0], 160, @"Should be the correct value");
    //proc_0_and_2
    XCTAssertEqual(Processor->memory[96], 1, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[97], 0xf, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[98], 0xff, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[99], 29, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[100], 0, @"Should be the correct value");
    XCTAssertEqual(Processor->memory[101], 5, @"Should be the correct value");
    
    HKHubArchProcessorDestroy(TempProcessor);
    HKHubArchProcessorDestroy(Processor);
    HKHubModuleDestroy(Keyboard);
    HKHubModuleDestroy(DebugController);
    HKHubArchSchedulerDestroy(Scheduler);
}

@end
