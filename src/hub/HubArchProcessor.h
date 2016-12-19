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
#include "HubArchPort.h"

typedef struct {
    CCDictionary ports;
    struct {
        HKHubArchPortID port;
        HKHubArchPortMessage data;
        uint8_t offset;
        enum {
            HKHubArchProcessorMessageClear,
            HKHubArchProcessorMessageComplete,
            HKHubArchProcessorMessageSend,
            HKHubArchProcessorMessageReceive
        } type;
        size_t timestamp;
        size_t wait;
    } message;
    struct {
        uint8_t r[4];
        uint8_t pc;
        uint8_t flags;
    } state;
    size_t cycles;
    _Bool complete;
    uint8_t memory[256];
} HKHubArchProcessorInfo;

typedef enum {
    HKHubArchProcessorFlagsZero = (1 << 0),
    HKHubArchProcessorFlagsCarry = (1 << 1),
    HKHubArchProcessorFlagsSign = (1 << 2),
    HKHubArchProcessorFlagsOverflow = (1 << 3),
    
    HKHubArchProcessorFlagsMask = HKHubArchProcessorFlagsZero | HKHubArchProcessorFlagsCarry | HKHubArchProcessorFlagsSign | HKHubArchProcessorFlagsOverflow
} HKHubArchProcessorFlags;

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
 * @brief Set the cycles the processor should run.
 * @param Processor The processor to allocate the time to.
 * @param Cycles The number of cycles to run.
 */
void HKHubArchProcessorSetCycles(HKHubArchProcessor Processor, size_t Cycles);

/*!
 * @brief Add the amount of time the processor should run for.
 * @param Processor The processor to allocate the time to.
 * @param Seconds The time in seconds the processor should run for.
 */
void HKHubArchProcessorAddProcessingTime(HKHubArchProcessor Processor, double Seconds);

/*!
 * @brief Add a connection to the processor.
 * @param Processor The processor to add the connection to.
 * @param Port The port of the processor the connection belongs to.
 * @param Connection The connection to add to the process. A reference to the connection is
 *        retained.
 */
void HKHubArchProcessorConnect(HKHubArchProcessor Processor, HKHubArchPortID Port, HKHubArchPortConnection CC_RETAIN(Connection));

/*!
 * @brief Disconnect a connection from the processor.
 * @description Causes the connection to be disconnected completely from either interface.
 * @param Processor The processor to remove the connection from.
 * @param Port The port of the processor the connection belongs to.
 */
void HKHubArchProcessorDisconnect(HKHubArchProcessor Processor, HKHubArchPortID Port);

/*!
 * @brief Get an interfaceable port reference from the processor.
 * @param Processor The processor get the port of.
 * @param Port The port of the processor.
 */
HKHubArchPort HKHubArchProcessorGetPort(HKHubArchProcessor Processor, HKHubArchPortID Port);

/*!
 * @brief Run the processor.
 * @param Processor The processor to be run.
 */
void HKHubArchProcessorRun(HKHubArchProcessor Processor);

#endif
