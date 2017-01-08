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

#include "HubSystem.h"
#include <threads.h>
#include "HubProcessorComponent.h"
#include "HubArchScheduler.h"

static _Bool HKHubSystemTryLock(void);
static void HKHubSystemLock(void);
static void HKHubSystemUnlock(void);
static _Bool HKHubSystemHandlesComponent(CCComponentID id);
static void HKHubSystemUpdate(double DeltaTime, CCCollection Components);

static HKHubArchScheduler Scheduler;
static mtx_t Lock;
void HKHubSystemRegister(void)
{
    int err;
    if ((err = mtx_init(&Lock, mtx_plain | mtx_recursive)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to create hub system lock (%d)", err);
        exit(EXIT_FAILURE); //TODO: How should we handle this?
    }
    
    Scheduler = HKHubArchSchedulerCreate(CC_STD_ALLOCATOR);
    
    CCComponentSystemRegister(HK_HUB_SYSTEM_ID, CCComponentSystemExecutionTypeUpdate, (CCComponentSystemUpdateCallback)HKHubSystemUpdate, HKHubSystemHandlesComponent, NULL, NULL, HKHubSystemTryLock, HKHubSystemLock, HKHubSystemUnlock);
}

void HKHubSystemDeregister(void)
{
    mtx_destroy(&Lock);
    
    CCComponentSystemDeregister(HK_HUB_SYSTEM_ID, CCComponentSystemExecutionTypeUpdate);
}

static _Bool HKHubSystemTryLock(void)
{
    int err = mtx_trylock(&Lock);
    if ((err != thrd_success) && (err != thrd_busy))
    {
        CC_LOG_ERROR("Failed to lock hub system (%d)", err);
    }
    
    return err == thrd_success;
}

static void HKHubSystemLock(void)
{
    int err;
    if ((err = mtx_lock(&Lock)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to lock hub system (%d)", err);
    }
}

static void HKHubSystemUnlock(void)
{
    int err;
    if ((err = mtx_unlock(&Lock)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to unlock hub system (%d)", err);
    }
}

static _Bool HKHubSystemHandlesComponent(CCComponentID id)
{
    return (id & 0x7f000000) == HK_HUB_COMPONENT_FLAG;
}

static void HKHubSystemUpdateScheduler(CCCollection Components, void (*Update)(HKHubArchScheduler,HKHubArchProcessor))
{
    CC_COLLECTION_FOREACH(CCComponent, Hub, Components)
    {
        if ((CCComponentGetID(Hub) & HKHubTypeMask) == HKHubTypeProcessor)
        {
            Update(Scheduler, HKHubProcessorComponentGetProcessor(Hub));
        }
    }
    
    CCCollectionDestroy(Components);
}

static void HKHubSystemUpdate(double DeltaTime, CCCollection Components)
{
    HKHubSystemUpdateScheduler(CCComponentSystemGetAddedComponentsForSystem(HK_HUB_SYSTEM_ID), HKHubArchSchedulerAddProcessor);
    HKHubSystemUpdateScheduler(CCComponentSystemGetRemovedComponentsForSystem(HK_HUB_SYSTEM_ID), HKHubArchSchedulerRemoveProcessor);
    
    HKHubArchSchedulerRun(Scheduler, DeltaTime);
}
