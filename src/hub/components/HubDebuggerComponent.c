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

#include "HubDebuggerComponent.h"
#include "HubProcessorComponent.h"

const char * const HKHubDebuggerComponentName = "debugger";

static const CCComponentExpressionDescriptor HKHubDebuggerComponentDescriptor = {
    .id = HK_HUB_DEBUGGER_COMPONENT_ID,
    .initialize = NULL,
    .deserialize = NULL,
    .serialize = NULL
};

static void HKHubDebuggerComponentMessageHandler(CCComponent Debugger, CCMessage *Message)
{
    switch (Message->id)
    {
        case HK_HUB_DEBUGGER_COMPONENT_EXIT_MESSAGE_ID:
            CCComponentSystemRemoveComponent(Debugger);
            break;
            
        case HK_HUB_DEBUGGER_COMPONENT_PAUSE_MESSAGE_ID:
        {
            CC_COLLECTION_FOREACH(CCComponent, Component, CCEntityGetComponents(CCComponentGetEntity(Debugger)))
            {
                if ((CCComponentGetID(Component) & HKHubTypeMask) == HKHubTypeProcessor)
                {
                    HKHubArchProcessor Target = HKHubProcessorComponentGetProcessor(Component);
                    HKHubArchProcessorSetDebugMode(Target, HKHubArchProcessorDebugModePause);
                    break;
                }
            }
            break;
        }
            
        case HK_HUB_DEBUGGER_COMPONENT_CONTINUE_MESSAGE_ID:
        {
            CC_COLLECTION_FOREACH(CCComponent, Component, CCEntityGetComponents(CCComponentGetEntity(Debugger)))
            {
                if ((CCComponentGetID(Component) & HKHubTypeMask) == HKHubTypeProcessor)
                {
                    HKHubArchProcessor Target = HKHubProcessorComponentGetProcessor(Component);
                    HKHubArchProcessorSetDebugMode(Target, HKHubArchProcessorDebugModeContinue);
                    break;
                }
            }
            break;
        }
            
        case HK_HUB_DEBUGGER_COMPONENT_STEP_MESSAGE_ID:
        {
            CC_COLLECTION_FOREACH(CCComponent, Component, CCEntityGetComponents(CCComponentGetEntity(Debugger)))
            {
                if ((CCComponentGetID(Component) & HKHubTypeMask) == HKHubTypeProcessor)
                {
                    HKHubArchProcessor Target = HKHubProcessorComponentGetProcessor(Component);
                    HKHubArchProcessorStep(Target, 1);
                    break;
                }
            }
            break;
        }
    }
}

void HKHubDebuggerComponentRegister(void)
{
    CCComponentRegister(HK_HUB_DEBUGGER_COMPONENT_ID, HKHubDebuggerComponentName, CC_STD_ALLOCATOR, sizeof(HKHubDebuggerComponentClass), HKHubDebuggerComponentInitialize, HKHubDebuggerComponentMessageHandler, HKHubDebuggerComponentDeallocate);
    
    CCComponentExpressionRegister(CC_STRING("debugger"), &HKHubDebuggerComponentDescriptor, TRUE);
}

void HKHubDebuggerComponentDeregister(void)
{
    CCComponentDeregister(HK_HUB_DEBUGGER_COMPONENT_ID);
}
