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
    HKHubArchPortConnection Connection = CCMalloc(Allocator, sizeof(HKHubArchPortConnectionInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (Connection)
    {
        *Connection = (HKHubArchPortConnectionInfo){ .port = { PortA, PortB } };
        
        CCMemorySetDestructor(Connection, (CCMemoryDestructorCallback)HKHubArchPortConnectionDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create port connection, due to allocation failure (%zu)", sizeof(HKHubArchPortConnectionInfo));
    
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
    
    const HKHubArchPortDisconnect Disconnect[2] = { Connection->port[0].disconnect, Connection->port[1].disconnect };
    
    Connection->port[0].disconnect = NULL;
    Connection->port[1].disconnect = NULL;
    
    if (Disconnect[0]) Disconnect[0](Connection->port[0].device, Connection->port[0].id);
    if (Disconnect[1]) Disconnect[1](Connection->port[1].device, Connection->port[1].id);
}

HKHubArchPort *HKHubArchPortConnectionGetPort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port)
{
    CCAssertLog(Connection, "Connection must not be null");
    
    for (int Loop = 0; Loop < 2; Loop++)
    {
        if ((Connection->port[Loop].device == Device) && (Connection->port[Loop].id == Port)) return &Connection->port[Loop];
    }
    
    return NULL;
}

HKHubArchPort *HKHubArchPortConnectionGetOppositePort(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port)
{
    CCAssertLog(Connection, "Connection must not be null");
    
    for (int Loop = 0; Loop < 2; Loop++)
    {
        if ((Connection->port[Loop].device != Device) || (Connection->port[Loop].id != Port)) return &Connection->port[Loop];
    }
    
    return NULL;
}
