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

#ifndef HackingGame_HubArchProcessor_h
#define HackingGame_HubArchProcessor_h

#include <Blob2D/Blob2D.h>
#include "HubArchBinary.h"

typedef struct {
    CCDictionary ports;
    struct {
        uint8_t r[4];
        uint8_t pc;
        uint8_t flags;
    } state;
    size_t cycles;
    _Bool complete;
    uint8_t memory[256];
} HKHubArchProcessorInfo;

/*!
 * @brief The processor.
 * @description Allows @b CCRetain.
 */
typedef HKHubArchProcessorInfo *HKHubArchProcessor;

/*!
 * @brief The clock rate of the processor;
 */
extern const double HKHubArchProcessorHertz;

/*!
 * @brief The memory read speed of the processor;
 */
extern const size_t HKHubArchProcessorSpeedMemoryRead;

/*!
 * @brief The memory write speed of the processor;
 */
extern const size_t HKHubArchProcessorSpeedMemoryWrite;

/*!
 * @brief The port transmission speed of the processor;
 */
extern const size_t HKHubArchProcessorSpeedPortTransmission;


/*!
 * @brief Create a hub.
 * @param Allocator The allocator to be used.
 * @param Binary The binary to initialise the processor with.
 * @return The processor. Must be destroyed to free memory.
 */
CC_NEW HKHubArchProcessor HKHubArchProcessorCreate(CCAllocatorType Allocator, HKHubArchBinary Binary);

/*!
 * @brief Destroy a processor.
 * @param Processor The processor to be destroyed.
 */
void HKHubArchProcessorDestroy(HKHubArchProcessor CC_DESTROY(Processor));

/*!
 * @brief Reset the processor's state.
 * @param Processor The processor to reset.
 * @param Binary The binary to initialise the processor with.
 */
void HKHubArchProcessorReset(HKHubArchProcessor Processor, HKHubArchBinary Binary);

/*!
 * @brief Add the amount of time the processor should run for.
 * @param Processor The processor to allocate the time to.
 * @param Seconds The time in seconds the processor should run for.
 */
void HKHubArchProcessorSetProcessingTime(HKHubArchProcessor Processor, double Seconds);

/*!
 * @brief Run the processor.
 * @param Processor The processor to be run.
 */
void HKHubArchProcessorRun(HKHubArchProcessor Processor);

#endif
