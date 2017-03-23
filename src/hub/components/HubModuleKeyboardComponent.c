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

#include "HubModuleKeyboardComponent.h"
#include "HubModuleComponent.h"
#include "HubModuleKeyboard.h"

static void HKHubModuleKeyboardComponentInitializer(CCComponent Component);

const CCComponentExpressionDescriptor HKHubModuleKeyboardComponentDescriptor = {
    .id = HK_HUB_MODULE_COMPONENT_ID,
    .initialize = HKHubModuleKeyboardComponentInitializer,
    .deserialize = NULL,
    .serialize = NULL
};

void HKHubModuleKeyboardComponentKeyboardCallback(CCComponent Component, CCKeyboardMap State)
{
    if (State.state.down) CCMessagePost(CC_STD_ALLOCATOR, HK_HUB_MODULE_KEYBOARD_COMPONENT_KEY_IN_MESSAGE_ID, CCMessageDeliverToComponentBelongingToEntity(HK_HUB_MODULE_COMPONENT_ID, CCComponentGetEntity(Component)), sizeof(uint8_t), &(uint8_t){ State.character });
}

static void HKHubModuleKeyboardComponentMessageHandler(CCComponent Component, CCMessage *Message)
{
    switch (Message->id)
    {
        case HK_HUB_MODULE_KEYBOARD_COMPONENT_KEY_IN_MESSAGE_ID:
            HKHubModuleKeyboardEnterKey(HKHubModuleComponentGetModule(Component), *(uint8_t*)CCMessageGetData(Message));
            break;
    }
}

static void HKHubModuleKeyboardComponentInitializer(CCComponent Component)
{
    HKHubModuleComponentSetName(Component, CCStringCopy(CC_STRING("keyboard")));
    HKHubModuleComponentSetModule(Component, HKHubModuleKeyboardCreate(CC_STD_ALLOCATOR));
    HKHubModuleComponentSetMessageHandler(Component, HKHubModuleKeyboardComponentMessageHandler);
}
