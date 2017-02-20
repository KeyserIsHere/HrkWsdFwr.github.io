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

#include "HubModuleDisplay.h"
#include "HubArchProcessor.h"

typedef struct {
    uint8_t buffer[256];
} HKHubModuleDisplayState;


static CCData HKHubModuleDisplayBufferConversion_None(CCAllocatorType Allocator, const uint8_t Buffer[256]);

const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer = HKHubModuleDisplayBufferConversion_None;


static HKHubArchPortResponse HKHubModuleDisplaySetBuffer(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
    
    if (HKHubArchPortIsReady(OppositePort))
    {
        if (Message->size > 1)
        {
            HKHubModuleDisplayState *State = Device->internal;
            
            uint8_t Offset = Message->memory[Message->offset];
            for (uint8_t Size = Message->size; Size-- > 1; )
            {
                State->buffer[Offset + (Size - 1)] = Message->memory[Message->offset + Size];
            }
        }
    }
    
    return HKHubArchPortResponseTimeout;
}

HKHubModule HKHubModuleDisplayCreate(CCAllocatorType Allocator)
{
    HKHubModuleDisplayState *State = CCMalloc(Allocator, sizeof(HKHubModuleDisplayState), NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (State)
    {
        memset(State->buffer, 0, sizeof(State->buffer));
        
        return HKHubModuleCreate(Allocator, NULL, (HKHubArchPortTransmit)HKHubModuleDisplaySetBuffer, State, CCFree);
    }
    
    else CC_LOG_ERROR("Failed to create display module due to allocation failure: allocation of size (%zu)", sizeof(HKHubModuleDisplayState));
    
    return NULL;
}

CCData HKHubModuleDisplayConvertBuffer(CCAllocatorType Allocator, HKHubModule Module, HKHubModuleDisplayBufferConverter Converter)
{
    CCAssertLog(Converter, "Converter must not be null");
    
    return Converter(Allocator, ((HKHubModuleDisplayState*)Module->internal)->buffer);
}

#pragma mark - Buffer Converters

static CCData HKHubModuleDisplayBufferConversion_None(CCAllocatorType Allocator, const uint8_t Buffer[256])
{
    return CCDataBufferCreate(Allocator, CCDataBufferHintCopy, 256, Buffer, NULL, NULL);
}
