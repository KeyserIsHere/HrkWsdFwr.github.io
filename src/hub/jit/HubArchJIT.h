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

#ifndef HackingGame_HubArchJIT_h
#define HackingGame_HubArchJIT_h

#include "Base.h"
#include "HubArchExecutionGraph.h"

typedef enum {
	HKHubArchJITOptionsWatchMemory = (1 << 0)
} HKHubArchJITOptions;

typedef struct {
    uintptr_t entry;
    size_t index;
} HKHubArchJITBlockRelativeEntry;

typedef struct {
    CCArray(HKHubArchJITBlockRelativeEntry) map;
    uintptr_t code;
    _Bool cached;
} HKHubArchJITBlock;

typedef struct {
    uintptr_t entry;
    HKHubArchJITBlock *block;
} HKHubArchJITBlockReferenceEntry;

typedef struct {
    CCDictionary(uint8_t, HKHubArchJITBlockReferenceEntry) map;
} HKHubArchJITInfo;

/*!
 * @brief The JIT native block.
 * @description Allows @b CCRetain.
 */
typedef HKHubArchJITInfo *HKHubArchJIT;


/*!
 * @brief Create a JIT native block of executable code for the graph.
 * @param Allocator The allocator to be used.
 * @param Graph The instruction graph.
 * @param Cache Whether the jit block should be cached or not.
 * @return The JIT native block. Must be destroyed to free memory.
 */
CC_NEW HKHubArchJIT HKHubArchJITCreate(CCAllocatorType Allocator, HKHubArchExecutionGraph Graph, _Bool Cache);

/*!
 * @brief Destroy a JIT.
 * @param JIT The JIT to be destroyed.
 */
void HKHubArchJITDestroy(HKHubArchJIT CC_DESTROY(JIT));

#endif
