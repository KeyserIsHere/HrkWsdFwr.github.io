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

#include "HubModuleWirelessTransceiver.h"


HKHubModuleWirelessTransceiverBroadcastCallback HKHubModuleWirelessTransceiverBroadcast = NULL;
HKHubModuleWirelessTransceiverGetSchedulerCallback HKHubModuleWirelessTransceiverGetScheduler = NULL;

static HKHubArchPortResponse HKHubModuleWirelessTransceiverTransmit(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
    
    if (HKHubArchPortIsReady(OppositePort))
    {
        if (Message->size >= 1)
        {
            HKHubModuleWirelessTransceiverBroadcast(Device, (HKHubModuleWirelessTransceiverPacket){
                .sig = { .channel = Port, .timestamp = Timestamp - ((Message->size * HKHubArchProcessorSpeedMemoryRead) + (Message->size * HKHubArchProcessorSpeedPortTransmission)) },
                .data = Message->memory[Message->offset]
            });
        }
    }
    
    return HKHubArchPortResponseSuccess;
}

static HKHubArchPortResponse HKHubModuleWirelessTransceiverReceive(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchProcessor ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    const size_t GlobalTimestamp = HKHubArchSchedulerGetTimestamp(HKHubModuleWirelessTransceiverGetScheduler(Device));
    if (ConnectedDevice->message.timestamp > GlobalTimestamp) return HKHubArchPortResponseDefer; //TODO: How to handle transmits on the same timestamp
    
    CCDictionary Packets = Device->internal;
    uint8_t *Data = CCDictionaryGetValue(Packets, &(HKHubModuleWirelessTransceiverPacketSignature){ .timestamp = Timestamp, .channel = Port });
    
    if (Data)
    {
        *Message = (HKHubArchPortMessage){
            .memory = Data,
            .offset = 0,
            .size = 1
        };
        
        if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
        
        return HKHubArchPortResponseSuccess;
    }
    
    return HKHubArchPortResponseTimeout;
}

static uintmax_t HKHubModuleWirelessTransceiverPacketSignatureHasher(const HKHubModuleWirelessTransceiverPacketSignature *Sig)
{
    return Sig->timestamp ^ ((uintmax_t)Sig->channel << ((sizeof(uintmax_t) * 8) - 8));
}

static CCComparisonResult HKHubModuleWirelessTransceiverPacketSignatureComparator(const HKHubModuleWirelessTransceiverPacketSignature *left, const HKHubModuleWirelessTransceiverPacketSignature *right)
{
    return (left->channel == right->channel) && (left->timestamp == right->timestamp) ? CCComparisonResultEqual : CCComparisonResultInvalid;
}

HKHubModule HKHubModuleWirelessTransceiverCreate(CCAllocatorType Allocator)
{
    return HKHubModuleCreate(Allocator, (HKHubArchPortTransmit)HKHubModuleWirelessTransceiverReceive, (HKHubArchPortTransmit)HKHubModuleWirelessTransceiverTransmit, CCDictionaryCreate(Allocator, CCDictionaryHintHeavyFinding | CCDictionaryHintHeavyInserting | CCDictionaryHintHeavyDeleting, sizeof(HKHubModuleWirelessTransceiverPacketSignature), sizeof(uint8_t), &(CCDictionaryCallbacks){
        .getHash = (CCDictionaryKeyHasher)HKHubModuleWirelessTransceiverPacketSignatureHasher,
        .compareKeys = (CCComparator)HKHubModuleWirelessTransceiverPacketSignatureComparator
    }), (HKHubModuleDataDestructor)CCDictionaryDestroy);
}

void HKHubModuleWirelessTransceiverReceivePacket(HKHubModule Module, HKHubModuleWirelessTransceiverPacket Packet)
{
    CCAssertLog(Module, "Module must not be null");
    
    CCDictionary Packets = Module->internal;
    CCDictionaryEntry Entry = CCDictionaryEntryForKey(Packets, &Packet.sig);
    
    if (CCDictionaryEntryIsInitialized(Packets, Entry))
    {
        Packet.data ^= *(uint8_t*)CCDictionaryGetEntry(Packets, Entry);
    }
    
    CCDictionarySetEntry(Packets, Entry, &Packet.data);
}

_Bool HKHubModuleWirelessTransceiverInspectPacket(HKHubModule Module, HKHubModuleWirelessTransceiverPacketSignature Sig, uint8_t *Data)
{
    CCAssertLog(Module, "Module must not be null");
    
    CCDictionary Packets = Module->internal;
    CCDictionaryEntry Entry = CCDictionaryFindKey(Packets, &Sig);
    
    if ((Entry) && (Data)) *Data = *(uint8_t*)CCDictionaryGetEntry(Packets, Entry);
    
    return Entry;
}

void HKHubModuleWirelessTransceiverPacketPurge(HKHubModule Module, size_t Timestamp)
{
    CCAssertLog(Module, "Module must not be null");
    
    CCDictionary Packets = Module->internal;
    CCOrderedCollection Keys = CCDictionaryGetKeys(Packets);
    
    CC_COLLECTION_FOREACH_PTR(HKHubModuleWirelessTransceiverPacketSignature, Sig, Keys)
    {
        if (Sig->timestamp >= Timestamp) CCDictionaryRemoveValue(Packets, Sig);
    }
}
