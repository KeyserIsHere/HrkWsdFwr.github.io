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

#ifndef HackingGame_HubArchScheduler_h
#define HackingGame_HubArchScheduler_h

#include "HubArchProcessor.h"

/*!
 * @brief The processor scheduler.
 * @description Allows @b CCRetain.
 */
typedef struct HKHubArchSchedulerInfo *HKHubArchScheduler;


/*!
 * @brief Create a scheduler.
 * @param Allocator The allocator to be used.
 * @return The scheduler. Must be destroyed to free memory.
 */
CC_NEW HKHubArchScheduler HKHubArchSchedulerCreate(CCAllocatorType Allocator);

/*!
 * @brief Destroy a scheduler.
 * @param Scheduler The scheduler to be destroyed.
 */
void HKHubArchSchedulerDestroy(HKHubArchScheduler CC_DESTROY(Scheduler));

/*!
 * @brief Add a processor hub to the scheduler.
 * @param Scheduler The scheduler to manage the processor.
 * @param Processor The processor to be managed by the scheduler.
 */
void HKHubArchSchedulerAddProcessor(HKHubArchScheduler Scheduler, HKHubArchProcessor CC_RETAIN(Processor));

/*!
 * @brief Remove a processor hub from the scheduler.
 * @description Disconnects all connections to that processor.
 * @param Scheduler The scheduler that manages the processor.
 * @param Processor The processor to be remove from the scheduler.
 */
void HKHubArchSchedulerRemoveProcessor(HKHubArchScheduler Scheduler, HKHubArchProcessor CC_DESTROY(Processor));

/*!
 * @brief Run the scheduler.
 * @param Scheduler The scheduler to be run.
 * @param Seconds The time in seconds the processors should be run for.
 */
void HKHubArchSchedulerRun(HKHubArchScheduler Scheduler, double Seconds);

#endif
