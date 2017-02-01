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

#ifndef HackingGame_HubModule_h
#define HackingGame_HubModule_h

#include "HubArchPort.h"

/*!
 * @brief Callback to destroy the internal data.
 */
typedef void (*HKHubModuleDataDestructor)(void *Internal);

typedef struct {
    void *internal;
    CCDictionary ports;
    HKHubArchPortTransmit send;
    HKHubArchPortTransmit receive;
    HKHubModuleDataDestructor destructor;
} HKHubModuleInfo;


/*!
 * @brief The module.
 * @description Allows @b CCRetain.
 */
typedef HKHubModuleInfo *HKHubModule;


/*!
 * @brief Create a module.
 * @param Allocator The allocator to be used.
 * @param Send The sender.
 * @param Receive The receiver.
 * @param Internal The internal data.
 * @param Destructor The destructor for the internal data.
 * @return The module. Must be destroyed to free memory.
 */
CC_NEW HKHubModule HKHubModuleCreate(CCAllocatorType Allocator, HKHubArchPortTransmit Send, HKHubArchPortTransmit Receive, void *Internal, HKHubModuleDataDestructor Destructor);

/*!
 * @brief Destroy a module.
 * @param Module The module to be destroyed.
 */
void HKHubModuleDestroy(HKHubModule CC_DESTROY(Module));

/*!
 * @brief Add a connection to the module.
 * @param Module The module to add the connection to.
 * @param Port The port of the module the connection belongs to.
 * @param Connection The connection to add to the module. A reference to the connection is
 *        retained.
 */
void HKHubModuleConnect(HKHubModule Module, HKHubArchPortID Port, HKHubArchPortConnection CC_RETAIN(Connection));

/*!
 * @brief Disconnect a connection from the module.
 * @description Causes the connection to be disconnected completely from either interface.
 * @param Module The module to remove the connection from.
 * @param Port The port of the module the connection belongs to.
 */
void HKHubModuleDisconnect(HKHubModule Module, HKHubArchPortID Port);

/*!
 * @brief Get an interfaceable port reference from the module.
 * @param Internal The module get the port of.
 * @param Port The port of the module.
 */
HKHubArchPort HKHubModuleGetPort(HKHubModule Module, HKHubArchPortID Port);

#endif
