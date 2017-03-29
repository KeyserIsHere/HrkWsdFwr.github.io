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

#include "HubModuleDisplayComponent.h"
#include "HubModuleComponent.h"
#include "HubModuleDisplay.h"


const char * const HKHubModuleDisplayComponentName = "display-module";

const CCComponentExpressionDescriptor HKHubModuleDisplayComponentDescriptor = {
    .id = HK_HUB_MODULE_DISPLAY_COMPONENT_ID,
    .initialize = NULL,
    .deserialize = NULL,
    .serialize = NULL
};

void HKHubModuleDisplayComponentRegister(void)
{
    CCComponentRegister(HK_HUB_MODULE_DISPLAY_COMPONENT_ID, HKHubModuleDisplayComponentName, CC_STD_ALLOCATOR, sizeof(HKHubModuleDisplayComponentClass), HKHubModuleDisplayComponentInitialize, NULL, HKHubModuleDisplayComponentDeallocate);
    
    CCComponentExpressionRegister(CC_STRING("display-module"), &HKHubModuleDisplayComponentDescriptor, TRUE);
}

void HKHubModuleDisplayComponentDeregister(void)
{
    CCComponentDeregister(HK_HUB_MODULE_DISPLAY_COMPONENT_ID);
}
