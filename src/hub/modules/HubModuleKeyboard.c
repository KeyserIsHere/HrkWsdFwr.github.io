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

#include "HubModuleKeyboard.h"

typedef struct {
    CCQueue(uint8_t) input;
    uint8_t key;
    _Bool cleared;
} HKHubModuleKeyboardState;

static HKHubArchPortResponse HKHubModuleKeyboardGetKey(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    HKHubModuleKeyboardState *State = Device->internal;
    
    if (!State->cleared)
    {
        *Message = (HKHubArchPortMessage){
            .memory = &State->key,
            .offset = 0,
            .size = 1
        };
        
        if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
        
        State->cleared = TRUE;
        
        return HKHubArchPortResponseSuccess;
    }
    
    CCQueueNode *Node = CCQueuePop(State->input);
    if (Node)
    {
        State->cleared = FALSE;
        State->key = *(uint8_t*)CCQueueGetNodeData(Node);
        
        *Message = (HKHubArchPortMessage){
            .memory = &State->key,
            .offset = 0,
            .size = 1
        };
        
        CCQueueDestroyNode(Node);
        
        if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
        
        State->cleared = TRUE;
        
        return HKHubArchPortResponseSuccess;
    }
    
    return HKHubArchPortResponseTimeout;
}

static void HKHubModuleKeyboardStateDestructor(HKHubModuleKeyboardState *State)
{
    CCQueueDestroy(State->input);
    CCFree(State);
}

HKHubModule HKHubModuleKeyboardCreate(CCAllocatorType Allocator)
{
    HKHubModuleKeyboardState *State = CCMalloc(Allocator, sizeof(HKHubModuleKeyboardState), NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (State)
    {
        *State = (HKHubModuleKeyboardState){
            .input = CCQueueCreate(Allocator),
            .cleared = TRUE
        };
        
        return HKHubModuleCreate(Allocator, (HKHubArchPortTransmit)HKHubModuleKeyboardGetKey, NULL, State, (HKHubModuleDataDestructor)HKHubModuleKeyboardStateDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create keyboard module due to allocation failure: allocation of size (%zu)", sizeof(HKHubModuleKeyboardState));
    
    return NULL;
}

void HKHubModuleKeyboardEnterKey(HKHubModule Module, uint8_t Key)
{
    CCAssertLog(Module, "Module must not be null");
    
    CCQueuePush(((HKHubModuleKeyboardState*)Module->internal)->input, CCQueueCreateNode(CC_STD_ALLOCATOR, sizeof(uint8_t), &Key));
}
