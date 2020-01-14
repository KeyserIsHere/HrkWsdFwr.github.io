/*
 *  Copyright (c) 2019, Stefan Johnson
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

#ifndef HackingGame_HubSchematicComponent_h
#define HackingGame_HubSchematicComponent_h

#include "Base.h"
#include "HubArchPort.h"
#include "HubSystem.h"

#define HK_HUB_SCHEMATIC_COMPONENT_ID (HKHubTypeSchematic | HK_HUB_COMPONENT_FLAG)

typedef struct {
    CC_COMPONENT_INHERIT(CCComponentClass);
    _Bool editable;
    _Bool debuggable;
} HKHubSchematicComponentClass, *HKHubSchematicComponentPrivate;


void HKHubSchematicComponentRegister(void);
void HKHubSchematicComponentDeregister(void);
void HKHubSchematicComponentDeserializer(CCComponent Component, CCExpression Arg, _Bool Deferred);

/*!
 * @brief Initialize the schematic component.
 * @param Component The component to be initialized.
 * @param id The component ID.
 */
static inline void HKHubSchematicComponentInitialize(CCComponent Component, CCComponentID id);

/*!
 * @brief Deallocate the schematic component.
 * @param Component The component to be deallocated.
 */
static inline void HKHubSchematicComponentDeallocate(CCComponent Component);

/*!
 * @brief Get whether the schematic is editable.
 * @param Component The schematic component.
 * @return Whether the schematic can be edited.
 */
static inline _Bool HKHubSchematicComponentGetIsEditable(CCComponent Component);

/*!
 * @brief Set whether the schematic is editable or not.
 * @param Component The schematic component.
 * @param Editable Whether the schematic is editable or not.
 */
static inline void HKHubSchematicComponentSetIsEditable(CCComponent Component, _Bool Editable);

/*!
 * @brief Get whether the schematic is debuggable.
 * @param Component The schematic component.
 * @return Whether the schematic can be debugged.
 */
static inline _Bool HKHubSchematicComponentGetIsDebuggable(CCComponent Component);

/*!
 * @brief Set whether the schematic is debuggable or not.
 * @param Component The schematic component.
 * @param Debuggable Whether the schematic can be debugged or not.
 */
static inline void HKHubSchematicComponentSetIsDebuggable(CCComponent Component, _Bool Debuggable);


#pragma mark -

static inline void HKHubSchematicComponentInitialize(CCComponent Component, CCComponentID id)
{
    CCComponentInitialize(Component, id);
    ((HKHubSchematicComponentPrivate)Component)->editable = FALSE;
    ((HKHubSchematicComponentPrivate)Component)->debuggable = FALSE;
}

static inline void HKHubSchematicComponentDeallocate(CCComponent Component)
{
    CCComponentDeallocate(Component);
}

static inline _Bool HKHubSchematicComponentGetIsEditable(CCComponent Component)
{
    return ((HKHubSchematicComponentPrivate)Component)->editable;
}

static inline void HKHubSchematicComponentSetIsEditable(CCComponent Component, _Bool Editable)
{
    ((HKHubSchematicComponentPrivate)Component)->editable = Editable;
}

static inline _Bool HKHubSchematicComponentGetIsDebuggable(CCComponent Component)
{
    return ((HKHubSchematicComponentPrivate)Component)->debuggable;
}

static inline void HKHubSchematicComponentSetIsDebuggable(CCComponent Component, _Bool Debuggable)
{
    ((HKHubSchematicComponentPrivate)Component)->debuggable = Debuggable;
}

#endif
