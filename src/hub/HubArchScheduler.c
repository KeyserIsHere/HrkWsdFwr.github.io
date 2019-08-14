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

#include "HubArchScheduler.h"

typedef struct HKHubArchSchedulerInfo {
    CCCollection hubs;
    size_t timestamp;
} HKHubArchSchedulerInfo;


static void HKHubArchSchedulerProcessorElementDestructor(CCCollection Collection, HKHubArchProcessor *Element)
{
    HKHubArchProcessorDestroy(*Element);
}

static void HKHubArchSchedulerDestructor(HKHubArchScheduler Scheduler)
{
    CCCollectionDestroy(Scheduler->hubs);
}

HKHubArchScheduler HKHubArchSchedulerCreate(CCAllocatorType Allocator)
{
    HKHubArchScheduler Scheduler = CCMalloc(Allocator, sizeof(HKHubArchSchedulerInfo), NULL, CC_DEFAULT_ERROR_CALLBACK);
    
    if (Scheduler)
    {
        *Scheduler = (HKHubArchSchedulerInfo){ .hubs = CCCollectionCreate(Allocator, CCCollectionHintHeavyEnumerating, sizeof(HKHubArchProcessor), (CCCollectionElementDestructor)HKHubArchSchedulerProcessorElementDestructor) };
        
        CCMemorySetDestructor(Scheduler, (CCMemoryDestructorCallback)HKHubArchSchedulerDestructor);
    }
    
    else CC_LOG_ERROR("Failed to create port connection, due to allocation failure (%zu)", sizeof(HKHubArchSchedulerInfo));
    
    return Scheduler;
}

void HKHubArchSchedulerDestroy(HKHubArchScheduler Scheduler)
{
    CCAssertLog(Scheduler, "Scheduler must not be null");
    
    CCFree(Scheduler);
}

void HKHubArchSchedulerAddProcessor(HKHubArchScheduler Scheduler, HKHubArchProcessor Processor)
{
    CCAssertLog(Scheduler, "Scheduler must not be null");
    CCAssertLog(Processor, "Processor must not be null");
    
    CCCollectionInsertElement(Scheduler->hubs, &(HKHubArchProcessor){ CCRetain(Processor) });
}

void HKHubArchSchedulerRemoveProcessor(HKHubArchScheduler Scheduler, HKHubArchProcessor Processor)
{
    CCAssertLog(Scheduler, "Scheduler must not be null");
    CCAssertLog(Processor, "Processor must not be null");
    
    CCCollectionEntry Entry = CCCollectionFindElement(Scheduler->hubs, &Processor, NULL);
    if (Entry)
    {
        CC_DICTIONARY_FOREACH_VALUE(HKHubArchPortConnection, Connection, Processor->ports)
        {
            for (int Loop = 0; Loop < 2; Loop++)
            {
                if (Connection->port[Loop].device == Processor) Connection->port[Loop].disconnect = NULL;
            }
            
            HKHubArchPortConnectionDisconnect(Connection);
        }
        
        CCCollectionRemoveElement(Scheduler->hubs, Entry);
    }
}

void HKHubArchSchedulerRun(HKHubArchScheduler Scheduler, double Seconds)
{
    CCAssertLog(Scheduler, "Scheduler must not be null");
    
    size_t PrevTimestamp = 0;
    
    CC_COLLECTION_FOREACH(HKHubArchProcessor, Processor, Scheduler->hubs)
    {
        if ((Processor->state.debug.mode != HKHubArchProcessorDebugModePause) || (Processor->state.debug.step)) HKHubArchProcessorAddProcessingTime(Processor, Seconds);
        else HKHubArchProcessorSetCycles(Processor, 0);
        
        if ((PrevTimestamp < Processor->cycles) && (Processor->status == HKHubArchProcessorStatusRunning)) PrevTimestamp = Processor->cycles;
    }
    
    Scheduler->timestamp = PrevTimestamp;
    
    /*
     TODO: Test a ping pong approach. Where there's two arrays, one is the active list that will be iterated (all
     processors in the active list are yet to be complete). While running the processors, if they have not completed
     add them to the other array. After the active list has finished being iterated, set the other array to be the
     new active list. Keep repeating until the list is empty.
     
     Avoids iterating over processors that have already completed. This will most likely perform better on very large
     lists, but worse on small lists.
     */
    for (_Bool Complete = FALSE; !Complete; )
    {
        PrevTimestamp = 0;
        
        Complete = TRUE;
        CC_COLLECTION_FOREACH(HKHubArchProcessor, Processor, Scheduler->hubs)
        {
            HKHubArchProcessorRun(Processor);
            Complete &= !HKHubArchProcessorIsRunning(Processor);
            
            if (Processor->state.debug.mode == HKHubArchProcessorDebugModePause) HKHubArchProcessorSetCycles(Processor, 0);
            if ((PrevTimestamp < Processor->cycles) && (Processor->status & HKHubArchProcessorStatusResumable)) PrevTimestamp = Processor->cycles;
        }
        
        Scheduler->timestamp = PrevTimestamp;
    }
}

size_t HKHubArchSchedulerGetTimestamp(HKHubArchScheduler Scheduler)
{
    CCAssertLog(Scheduler, "Scheduler must not be null");
    
    return Scheduler->timestamp;
}
