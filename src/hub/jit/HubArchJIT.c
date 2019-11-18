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

#include "HubArchJIT.h"

#if CC_PLATFORM_OS_X
#include <mach/mach.h>
#include <mach/mach_vm.h>

#if CC_HARDWARE_ARCH_X86_64
#define HK_HUB_ARCH_JIT 1
#endif
#endif

extern _Bool HKHubArchJITGenerateBlock(HKHubArchJIT JIT, HKHubArchJITBlock *JITBlock, void *Ptr, CCLinkedList(HKHubArchExecutionGraphInstruction) Block);

static void *HKHubArchJITAllocateExecutable(size_t Size)
{
#if CC_PLATFORM_OS_X
    //TODO: Setup an allocator, then allocate a large chunk and reference check the blocks (so any that can be shared will be).
    mach_vm_address_t Address = 0;
    mach_error_t err = mach_vm_allocate(mach_task_self(), &Address, Size, VM_FLAGS_ANYWHERE);
    if (err == KERN_SUCCESS)
    {
        err = mach_vm_protect(mach_task_self(), Address, Size, FALSE, VM_PROT_ALL);
        if (err == KERN_SUCCESS)
        {
            return (void*)Address;
        }
        
        else
        {
            mach_error("mach_vm_protect", err);
            CC_LOG_ERROR("Failed to allocate executable memory, due to memory protection error (%u)", err);
            
            mach_vm_deallocate(mach_task_self(), Address, Size);
        }
    }
    
    else
    {
        mach_error("mach_vm_allocate", err);
        CC_LOG_ERROR("Failed to allocate executable memory, due to allocation failure (%zu)", Size);
    }
#endif
    
    return NULL;
}

static void HKHubArchJITDeallocateExecutable(void *Ptr, size_t Size)
{
#if CC_PLATFORM_OS_X
    mach_vm_deallocate(mach_task_self(), (mach_vm_address_t)Ptr, Size);
#endif
}

static void HKHubArchJITGenerate(HKHubArchJIT JIT, HKHubArchExecutionGraph Graph)
{
    for (size_t Loop = 0, Count = CCArrayGetCount(Graph->block); Loop < Count; Loop++)
    {
        const size_t Size = 1024; // TODO: calculate size required
        void *Ptr = HKHubArchJITAllocateExecutable(Size);
        if (Ptr)
        {
            HKHubArchJITBlock Block = { .code = (uintptr_t)Ptr, .map = CCArrayCreate(CC_STD_ALLOCATOR, sizeof(HKHubArchJITBlockRelativeEntry), 4) };
            
            CCLinkedList(HKHubArchExecutionGraphInstruction) Instruction = *(CCLinkedList*)CCArrayGetElementAtIndex(Graph->block, Loop);
            
#if CC_HARDWARE_ARCH_X86_64
            const _Bool Generated = HKHubArchJITGenerateBlock(JIT, &Block, Ptr, Instruction);
#endif
            
            if (Generated)
            {
                CCArrayAppendElement(JIT->blocks, &Block);
                
                for (size_t Loop = 0, Index = 0, Count = CCArrayGetCount(Block.map); Loop < Count; Loop++)
                {
                    const HKHubArchJITBlockRelativeEntry *Entry = CCArrayGetElementAtIndex(Block.map, Loop);
                    for ( ; Entry->index != Index; Index++) Instruction = CCLinkedListEnumerateNext(Instruction);
                    
                    CCDictionarySetValue(JIT->map, &(uint8_t){ ((HKHubArchExecutionGraphInstruction*)CCLinkedListGetNodeData(Instruction))->offset }, &Entry->entry);
                }
            }
            
            else
            {
                CCArrayDestroy(Block.map);
                HKHubArchJITDeallocateExecutable(Ptr, Size);
            }
        }
    }
}

static void HKHubArchJITDestructor(HKHubArchJIT JIT)
{
    CCDictionaryDestroy(JIT->map);
    CCArrayDestroy(JIT->blocks);
}

HKHubArchJIT HKHubArchJITCreate(CCAllocatorType Allocator, HKHubArchExecutionGraph Graph)
{
    CCAssertLog(Graph, "Graph must not be null");
    
#if HK_HUB_ARCH_JIT
    HKHubArchJIT JIT = CCMalloc(Allocator, sizeof(HKHubArchJITInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (JIT)
    {
        *JIT = (HKHubArchJITInfo){
            .map = CCDictionaryCreate(Allocator, CCDictionaryHintSizeMedium | CCDictionaryHintConstantElements | CCDictionaryHintConstantLength | CCDictionaryHintHeavyFinding, sizeof(uint8_t), sizeof(uintptr_t), NULL),
            .blocks = CCArrayCreate(Allocator, sizeof(HKHubArchJITBlock), CCArrayGetCount(Graph->block))
        };
        
        HKHubArchJITGenerate(JIT, Graph);
        
        CCMemorySetDestructor(JIT, (CCMemoryDestructorCallback)HKHubArchJITDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create the jit native block, due to allocation failure (%zu)", sizeof(HKHubArchJITInfo));
    
    return JIT;
#else
    return NULL;
#endif
}

void HKHubArchJITDestroy(HKHubArchJIT Block)
{
    CCAssertLog(Block, "Block must not be null");
    
    CCFree(Block);
}
