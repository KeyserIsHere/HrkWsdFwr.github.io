/*
 *  Copyright (c) 2016, Stefan Johnson
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

#include "HubArchBinary.h"

static void HKHubArchBinaryNamedPortElementDestructor(CCCollection Collection, HKHubArchBinaryNamedPort *Element)
{
    CCStringDestroy(Element->name);
}

static void HKHubArchBinaryDestructor(HKHubArchBinary Binary)
{
    CCCollectionDestroy(Binary->namedPorts);
}

HKHubArchBinary HKHubArchBinaryCreate(CCAllocatorType Allocator)
{
    HKHubArchBinary Binary = CCMalloc(Allocator, sizeof(HKHubArchBinaryInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (Binary)
    {
        memset(Binary, 0, sizeof(HKHubArchBinaryInfo));
        
        Binary->namedPorts = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintSizeSmall, sizeof(HKHubArchBinaryNamedPort), (CCCollectionElementDestructor)HKHubArchBinaryNamedPortElementDestructor);
        
        CCMemorySetDestructor(Binary, (CCMemoryDestructorCallback)HKHubArchBinaryDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create binary object, due to allocation failure (%zu)", sizeof(HKHubArchBinaryInfo));
    
    return Binary;
}

void HKHubArchBinaryDestroy(HKHubArchBinary Binary)
{
    CCAssertLog(Binary, "Binary must not be null");
    
    CCFree(Binary);
}
