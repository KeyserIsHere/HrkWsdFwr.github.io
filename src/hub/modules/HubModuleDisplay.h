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

#ifndef HackingGame_HubModuleDisplay_h
#define HackingGame_HubModuleDisplay_h

#include "HubModule.h"

/*!
 * @brief Convert the display buffer to a given format.
 * @param Allocator The allocator to be used for the data.
 * @param Buffer The display buffer to be converted (256 bytes).
 * @return The converted data.
 */
typedef CC_NEW CCData (*HKHubModuleDisplayBufferConverter)(CCAllocatorType Allocator, const uint8_t Buffer[256]);

/*!
 * @brief Retreive the display buffer as is, applying no conversions.
 */
extern const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer;

/*!
 * @brief Retrieve the display buffer as a uniformly distributed colour buffer.
 * @description Colour is in the format RGB888. 
 *
 *              Display buffer is assumed to be of the format ffrrggbb, where lowest
 *              2 bits are the blue channel, next 2 bits are the green channel, next
 *              2 bits are the red channel, and highest two bits are the scale factor.
 *
 *              Channel values are in multiples of 68. e.g. r = 1 (red = 68)
 *              Scale factor is a multiple of 17. e.g. r = 1 (red = 68), sf = 2
 *              (scale factor = 34) = red = 68+34 = 102
 *
 *              The scale factor is applied to each channel.
 *
 *              Pros:
 *              Good colour distribution (equal reds, greens, blues), mixed channels,
 *              good selection of greys.
 *
 *              Cons:
 *              No absolute red, green, or blue.
 */
extern const HKHubModuleDisplayBufferConverter HKHubModuleDisplayBuffer_UniformColourRGB888;


/*!
 * @brief Create a display module.
 * @description This is a generic addressable memory store and data conversion device.
 * @param Allocator The allocator to be used.
 * @return The display module. Must be destroyed to free memory.
 */
CC_NEW HKHubModule HKHubModuleDisplayCreate(CCAllocatorType Allocator);

/*!
 * @brief Convert the display buffer to a given output format.
 * @param Allocator The allocator to be used for the data.
 * @param Module The display.
 * @return The data with the applied conversion. Must be destroyed to free memory.
 */
CC_NEW CCData HKHubModuleDisplayConvertBuffer(CCAllocatorType Allocator, HKHubModule Module, HKHubModuleDisplayBufferConverter Converter);

#endif
