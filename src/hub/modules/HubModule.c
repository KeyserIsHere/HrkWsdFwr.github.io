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

#include "HubModule.h"

static uintmax_t HKHubModulePortHasher(HKHubArchPortID *Key)
{
    return *Key;
}

static void HKHubModuleDestructor(HKHubModule Module)
{
    if (Module->destructor) Module->destructor(Module->internal);
    if (Module->memory) CCDataDestroy(Module->memory);
    
    CC_DICTIONARY_FOREACH_VALUE(HKHubArchPortConnection, Connection, Module->ports)
    {
        for (int Loop = 0; Loop < 2; Loop++)
        {
            if (Connection->port[Loop].device == Module) Connection->port[Loop].disconnect = NULL;
        }
        
        HKHubArchPortConnectionDisconnect(Connection);
    }
    
    CCDictionaryDestroy(Module->ports);
}

HKHubModule HKHubModuleCreate(CCAllocatorType Allocator, HKHubArchPortTransmit Send, HKHubArchPortTransmit Receive, void *Internal, HKHubModuleDataDestructor Destructor, CCData Memory)
{
    HKHubModule Module = CCMalloc(Allocator, sizeof(HKHubModuleInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (Module)
    {
        Module->ports = CCDictionaryCreate(Allocator, CCDictionaryHintHeavyFinding, sizeof(HKHubArchPortID), sizeof(HKHubArchPortConnection), &(CCDictionaryCallbacks){
            .getHash = (CCDictionaryKeyHasher)HKHubModulePortHasher,
            .valueDestructor = HKHubArchPortConnectionDestructorForDictionary
        });
        
        Module->send = Send;
        Module->receive = Receive;
        Module->internal = Internal;
        Module->destructor = Destructor;
        Module->memory = Memory;
        Module->debug.context = NULL;
        Module->debug.extra = 0;
        
        CCMemorySetDestructor(Module, (CCMemoryDestructorCallback)HKHubModuleDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create module, due to allocation failure (%zu)", sizeof(HKHubModuleInfo));
    
    return Module;
}

void HKHubModuleDestroy(HKHubModule Module)
{
    CCAssertLog(Module, "Module must not be null");
    
    CCFree(Module);
}

static void HKHubModuleDisconnectPort(HKHubModule Module, HKHubArchPortID Port)
{
    CCDictionaryRemoveValue(Module->ports, &Port);
}

static inline void HKHubModuleSetConnectionDisconnectCallback(HKHubModule Module, HKHubArchPortID Port, HKHubArchPortConnection Connection, HKHubArchPortDisconnect Disconnect)
{
    for (int Loop = 0; Loop < 2; Loop++)
    {
        if ((Connection->port[Loop].device == Module) && (Connection->port[Loop].id == Port))
        {
            Connection->port[Loop].disconnect = Disconnect;
        }
    }
}

void HKHubModuleConnect(HKHubModule Module, HKHubArchPortID Port, HKHubArchPortConnection Connection)
{
    CCAssertLog(Module, "Module must not be null");
    CCAssertLog(Connection, "Connection must not be null");
    
    CCDictionaryEntry Entry = CCDictionaryEntryForKey(Module->ports, &Port);
    
    if (CCDictionaryEntryIsInitialized(Module->ports, Entry))
    {
        HKHubArchPortConnection OldConnection = *(HKHubArchPortConnection*)CCDictionaryGetEntry(Module->ports, Entry);
        HKHubModuleSetConnectionDisconnectCallback(Module, Port, OldConnection, NULL);
        HKHubArchPortConnectionDisconnect(OldConnection);
    }
    
    HKHubModuleSetConnectionDisconnectCallback(Module, Port, Connection, (HKHubArchPortDisconnect)HKHubModuleDisconnectPort);
    
    CCDictionarySetEntry(Module->ports, Entry, &(HKHubArchPortConnection){ CCRetain(Connection) });
}

void HKHubModuleDisconnect(HKHubModule Module, HKHubArchPortID Port)
{
    CCAssertLog(Module, "Module must not be null");
    
    HKHubArchPortConnection *Connection = CCDictionaryGetValue(Module->ports, &Port);
    
    if (Connection) HKHubArchPortConnectionDisconnect(*Connection);
}

HKHubArchPort HKHubModuleGetPort(HKHubModule Module, HKHubArchPortID Port)
{
    CCAssertLog(Module, "Module must not be null");
    
    return (HKHubArchPort){
        .device = Module,
        .id = Port,
        .disconnect = NULL,
        .sender = (HKHubArchPortTransmit)Module->send,
        .receiver = (HKHubArchPortTransmit)Module->receive,
        .ready = NULL
    };
}

HKHubArchPortConnection HKHubModuleGetPortConnection(HKHubModule Module, HKHubArchPortID Port)
{
    CCAssertLog(Module, "Module must not be null");
    
    HKHubArchPortConnection *Connection = CCDictionaryGetValue(Module->ports, &Port);
    
    return Connection ? *Connection : NULL;
}
