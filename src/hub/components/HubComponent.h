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

#ifndef HackingGame_HubComponent_h
#define HackingGame_HubComponent_h

#include <Blob2D/Blob2D.h>
#include "HubArchProcessor.h"
#include "HubSystem.h"

#define HK_HUB_COMPONENT_ID HK_HUB_COMPONENT_FLAG

typedef struct {
    CC_COMPONENT_INHERIT(CCComponentClass);
    CCString name;
    HKHubArchProcessor processor;
} HKHubComponentClass, *HKHubComponentPrivate;


void HKHubComponentRegister(void);
void HKHubComponentDeregister(void);

/*!
 * @brief Initialize the hub component.
 * @param Component The component to be initialized.
 * @param id The component ID.
 */
static inline void HKHubComponentInitialize(CCComponent Component, CCComponentID id);

/*!
 * @brief Deallocate the hub component.
 * @param Component The component to be deallocated.
 */
static inline void HKHubComponentDeallocate(CCComponent Component);

/*!
 * @brief Get the name of the hub.
 * @param Component The hub component.
 * @return The hub name.
 */
static inline CCString HKHubComponentGetName(CCComponent Component);

/*!
 * @brief Set the name of the hub.
 * @param Component The hub component.
 * @param Name The hub name. Ownership is transferred to the component.
 */
static inline void HKHubComponentSetName(CCComponent Component, CCString CC_OWN(Name));

/*!
 * @brief Get the processor of the hub.
 * @param Component The hub component.
 * @return The hub processor.
 */
static inline HKHubArchProcessor HKHubComponentGetProcessor(CCComponent Component);

/*!
 * @brief Set the processor of the hub.
 * @param Component The hub component.
 * @param Processor The hub processor. Ownership is transferred to the component.
 */
static inline void HKHubComponentSetProcessor(CCComponent Component, HKHubArchProcessor CC_OWN(Processor));


#pragma mark -

static inline void HKHubComponentInitialize(CCComponent Component, CCComponentID id)
{
    CCComponentInitialize(Component, id);
    ((HKHubComponentPrivate)Component)->name = 0;
    ((HKHubComponentPrivate)Component)->processor = NULL;
}

static inline void HKHubComponentDeallocate(CCComponent Component)
{
    if (((HKHubComponentPrivate)Component)->name) CCStringDestroy(((HKHubComponentPrivate)Component)->name);
    if (((HKHubComponentPrivate)Component)->processor) HKHubArchProcessorDestroy(((HKHubComponentPrivate)Component)->processor);
    CCComponentDeallocate(Component);
}

static inline CCString HKHubComponentGetName(CCComponent Component)
{
    return ((HKHubComponentPrivate)Component)->name;
}

static inline void HKHubComponentSetName(CCComponent Component, CCString Name)
{
    if (((HKHubComponentPrivate)Component)->name) CCStringDestroy(((HKHubComponentPrivate)Component)->name);
    
    ((HKHubComponentPrivate)Component)->name = Name;
}

static inline HKHubArchProcessor HKHubComponentGetProcessor(CCComponent Component)
{
    return ((HKHubComponentPrivate)Component)->processor;
}

static inline void HKHubComponentSetProcessor(CCComponent Component, HKHubArchProcessor Processor)
{
    if (((HKHubComponentPrivate)Component)->processor) HKHubArchProcessorDestroy(((HKHubComponentPrivate)Component)->processor);
    
    ((HKHubComponentPrivate)Component)->processor = Processor;
}

#endif
