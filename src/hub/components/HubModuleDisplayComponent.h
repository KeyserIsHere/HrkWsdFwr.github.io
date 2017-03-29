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

#ifndef HackingGame_HubModuleDisplayComponent_h
#define HackingGame_HubModuleDisplayComponent_h

#include <Blob2D/Blob2D.h>

#include "HubModuleComponent.h"
#include "HubModuleDisplay.h"

#define HK_HUB_MODULE_DISPLAY_COMPONENT_ID (HK_HUB_MODULE_COMPONENT_ID | HKHubTypeModuleDisplay)

typedef struct {
    CC_COMPONENT_INHERIT(HKHubModuleComponentClass);
} HKHubModuleDisplayComponentClass, *HKHubModuleDisplayComponentPrivate;

extern const CCComponentExpressionDescriptor HKHubModuleDisplayComponentDescriptor;

void HKHubModuleDisplayComponentRegister(void);
void HKHubModuleDisplayComponentDeregister(void);

/*!
 * @brief Initialize the display module component.
 * @param Component The component to be initialized.
 * @param id The component ID.
 */
static inline void HKHubModuleDisplayComponentInitialize(CCComponent Component, CCComponentID id);

/*!
 * @brief Deallocate the display module component.
 * @param Component The component to be deallocated.
 */
static inline void HKHubModuleDisplayComponentDeallocate(CCComponent Component);


#pragma mark -

static inline void HKHubModuleDisplayComponentInitialize(CCComponent Component, CCComponentID id)
{
    HKHubModuleComponentInitialize(Component, id);
    
    HKHubModuleComponentSetName(Component, CCStringCopy(CC_STRING("display")));
    HKHubModuleComponentSetModule(Component, HKHubModuleDisplayCreate(CC_STD_ALLOCATOR));
}

static inline void HKHubModuleDisplayComponentDeallocate(CCComponent Component)
{
    HKHubModuleComponentDeallocate(Component);
}

#endif
