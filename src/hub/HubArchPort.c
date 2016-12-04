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

#include "HubArchPort.h"

static void HKHubArchPortConnectionContainerElementDestructor(void *Container, HKHubArchPortConnection *Element);

const CCCollectionElementDestructor HKHubArchPortConnectionDestructorForCollection = (CCCollectionElementDestructor)HKHubArchPortConnectionContainerElementDestructor;
const CCDictionaryElementDestructor HKHubArchPortConnectionDestructorForDictionary = (CCDictionaryElementDestructor)HKHubArchPortConnectionContainerElementDestructor;

static void HKHubArchPortConnectionContainerElementDestructor(void *Container, HKHubArchPortConnection *Element)
{
    HKHubArchPortConnectionDestroy(*Element);
}

static void HKHubArchPortConnectionDestructor(HKHubArchPortConnection Connection)
{
    HKHubArchPortConnectionDisconnect(Connection);
    
    if ((Connection->port[0].device) && (Connection->port[0].destructor)) Connection->port[0].destructor(Connection->port[0].device);
    if ((Connection->port[1].device) && (Connection->port[1].destructor)) Connection->port[1].destructor(Connection->port[1].device);
}

HKHubArchPortConnection HKHubArchPortConnectionCreate(CCAllocatorType Allocator, HKHubArchPort PortA, HKHubArchPort PortB)
{
    HKHubArchPortConnection Connection;
    CC_SAFE_Malloc(Connection, sizeof(HKHubArchPortConnectionInfo),
                   CC_LOG_ERROR("Failed to create port connection, due to allocation failure (%zu)", sizeof(HKHubArchPortConnectionInfo));
                   return NULL;
                   );
    
    *Connection = (HKHubArchPortConnectionInfo){ .port = { PortA, PortB } };
    
    CCMemorySetDestructor(Connection, (CCMemoryDestructorCallback)HKHubArchPortConnectionDestructor);
    
    return Connection;
}

void HKHubArchPortConnectionDestroy(HKHubArchPortConnection Connection)
{
    CCAssertLog(Connection, "Connection must not be null");
    
    CCFree(Connection);
}

void HKHubArchPortConnectionDisconnect(HKHubArchPortConnection Connection)
{
    CCAssertLog(Connection, "Connection must not be null");
    
    if (Connection->port[0].disconnect) Connection->port[0].disconnect(Connection->port[0].id);
    if (Connection->port[1].disconnect) Connection->port[1].disconnect(Connection->port[1].id);
    
    Connection->port[0].disconnect = NULL;
    Connection->port[1].disconnect = NULL;
}

