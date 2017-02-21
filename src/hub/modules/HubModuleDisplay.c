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
static CCData HKHubModuleDisplayBufferConversion_UniformColourRGB888(CCAllocatorType Allocator, const uint8_t Buffer[256]);
static CCData HKHubModuleDisplayBufferConversion_DirectColourRGB888(CCAllocatorType Allocator, const uint8_t Buffer[256]);


const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer = HKHubModuleDisplayBufferConversion_None;
const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer_UniformColourRGB888 = HKHubModuleDisplayBufferConversion_UniformColourRGB888;
const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer_DirectColourRGB888 = HKHubModuleDisplayBufferConversion_DirectColourRGB888;


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

static CCData HKHubModuleDisplayBufferConversion_UniformColourRGB888(CCAllocatorType Allocator, const uint8_t Buffer[256])
{
    /*
     ffrrggbb
     
     r = red
     g = green
     b = blue
     f = scale factor
     
     Channel values are in multiples of 68. e.g. r = 1 (red = 68)
     Scale factor is a multiple of 17. e.g. r = 1 (red = 68), sf = 2 (scale factor = 34) = red = 68+34 = 102
     
     The scale factor is applied to each channel.
     
     Pros:
     Good colour distribution (equal reds, greens, blues), mixed channels, good selection of greys.
     
     Cons:
     No absolute red, green, or blue.
     */
    
    size_t DataSize = 256 * sizeof(uint8_t) * 3;
    uint8_t *Data = CCMalloc(Allocator, DataSize, NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (!Data)
    {
        CC_LOG_ERROR("Failed to create data buffer. Allocation failure of size (%zu)", DataSize);
        return NULL;
    }
    
    for (size_t Loop = 0; Loop < 256; Loop++)
    {
        const uint8_t b = Buffer[Loop] & (3 << 0);
        const uint8_t g = (Buffer[Loop] & (3 << 2)) >> 2;
        const uint8_t r = (Buffer[Loop] & (3 << 4)) >> 4;
        const uint8_t f = (Buffer[Loop] & (3 << 6)) >> 6;
        
        Data[Loop * 3] = ((r * 4) + f) * 17; //red
        Data[(Loop * 3) + 1] = ((g * 4) + f) * 17; //green
        Data[(Loop * 3) + 2] = ((b * 4) + f) * 17; //blue
    }
    
    return CCDataBufferCreate(Allocator, CCDataBufferHintFree, DataSize, Data, NULL, NULL);
}

static CCData HKHubModuleDisplayBufferConversion_DirectColourRGB888(CCAllocatorType Allocator, const uint8_t Buffer[256])
{
    /*
     RGB332
     rrrgggbb
     
     r = red
     g = green
     b = blue
     
     Channel values are evenly spread across range from 0 mapping to absolute zero, and max mapping to absolute
     one.
     
     Pros:
     Distributes colour in-favour of human sight, where blues are weakest so less depth is given to it.
     Decent colour distribution across channels and mixed channels.
     
     Cons:
     Poor selection of greys and blues.
     */
    
    size_t DataSize = 256 * sizeof(uint8_t) * 3;
    uint8_t *Data = CCMalloc(Allocator, DataSize, NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (!Data)
    {
        CC_LOG_ERROR("Failed to create data buffer. Allocation failure of size (%zu)", DataSize);
        return NULL;
    }
    
    for (size_t Loop = 0; Loop < 256; Loop++)
    {
        const uint8_t b = Buffer[Loop] & (3 << 0);
        const uint8_t g = (Buffer[Loop] & (7 << 2)) >> 2;
        const uint8_t r = (Buffer[Loop] & (7 << 5)) >> 5;
        
        Data[Loop * 3] = (float)r * 36.428571429f; //red
        Data[(Loop * 3) + 1] = (float)g * 36.428571429f; //green
        Data[(Loop * 3) + 2] = b * 85; //blue
    }
    
    return CCDataBufferCreate(Allocator, CCDataBufferHintFree, DataSize, Data, NULL, NULL);
}
