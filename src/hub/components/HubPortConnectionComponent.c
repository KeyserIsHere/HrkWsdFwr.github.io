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

#include "HubPortConnectionComponent.h"

const CCString HKHubPortConnectionComponentName = CC_STRING("port_connection");

static const CCComponentExpressionDescriptor HKHubPortConnectionComponentDescriptor = {
    .id = HK_HUB_PORT_CONNECTION_COMPONENT_ID,
    .initialize = NULL,
    .deserialize = HKHubPortConnectionComponentDeserializer,
    .serialize = NULL
};

void HKHubPortConnectionComponentRegister(void)
{
    CCComponentRegister(HK_HUB_PORT_CONNECTION_COMPONENT_ID, HKHubPortConnectionComponentName, CC_STD_ALLOCATOR, sizeof(HKHubPortConnectionComponentClass), HKHubPortConnectionComponentInitialize, NULL, HKHubPortConnectionComponentDeallocate);
    
    CCComponentExpressionRegister(CC_STRING("port-connection"), &HKHubPortConnectionComponentDescriptor, TRUE);
}

void HKHubPortConnectionComponentDeregister(void)
{
    CCComponentDeregister(HK_HUB_PORT_CONNECTION_COMPONENT_ID);
}

static CCComponentExpressionArgumentDeserializer Arguments[] = {
    { .name = CC_STRING("disconnectable:"), .serializedType = CCExpressionValueTypeUnspecified, .setterType = CCComponentExpressionArgumentTypeBool, .setter = (CCComponentExpressionSetter)HKHubPortConnectionComponentSetDisconnectable }
};

void HKHubPortConnectionComponentDeserializer(CCComponent Component, CCExpression Arg, _Bool Deferred)
{
    if (CCExpressionGetType(Arg) == CCExpressionValueTypeList)
    {
        const size_t ArgCount = CCCollectionGetCount(CCExpressionGetList(Arg));
        if (CCCollectionGetCount(CCExpressionGetList(Arg)) >= 2)
        {
            CCExpression NameExpr = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Arg), 0);
            if (CCExpressionGetType(NameExpr) == CCExpressionValueTypeAtom)
            {
                CCString Name = CCExpressionGetAtom(NameExpr);
                if (CCStringEqual(Name, CC_STRING("ports:")))
                {
                    if (ArgCount == 3)
                    {
                        CCExpression Device1 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Arg), 1);
                        CCExpression Device2 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Arg), 2);
                        if ((CCExpressionGetType(Device1) == CCExpressionValueTypeList) && (CCExpressionGetType(Device2) == CCExpressionValueTypeList) && (CCCollectionGetCount(CCExpressionGetList(Device1)) == 2) && (CCCollectionGetCount(CCExpressionGetList(Device2)) == 2))
                        {
                            CCExpression Entity1 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Device1), 0);
                            CCExpression Port1 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Device1), 1);
                            CCExpression Entity2 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Device2), 0);
                            CCExpression Port2 = *(CCExpression*)CCOrderedCollectionGetElementAtIndex(CCExpressionGetList(Device2), 1);
                            
                            if ((CCExpressionGetType(Entity1) == CCEntityExpressionValueTypeEntity) && (CCExpressionGetType(Entity2) == CCEntityExpressionValueTypeEntity) && (CCExpressionGetType(Port1) == CCExpressionValueTypeInteger) && (CCExpressionGetType(Port2) == CCExpressionValueTypeInteger))
                            {
                                HKHubPortConnectionComponentSetEntityMapping(Component, (HKHubPortConnectionEntityMapping){
                                    .entity = CCRetain(CCExpressionGetData(Entity1)),
                                    .port = CCExpressionGetInteger(Port1)
                                }, (HKHubPortConnectionEntityMapping){
                                    .entity = CCRetain(CCExpressionGetData(Entity2)),
                                    .port = CCExpressionGetInteger(Port2)
                                });
                            }
                            
                             else CC_LOG_ERROR("Expect value for argument (ports:) to be two lists of type (entity:custom port:integer)");
                        }
                        
                        else CC_LOG_ERROR("Expect value for argument (ports:) to be two lists of type (entity:custom port:integer)");
                    }
                    
                    else CC_LOG_ERROR("Expect value for argument (ports:) to be two lists of type (entity:custom port:integer)");
                    
                    return;
                }
            }
        }
    }
    
    CCComponentExpressionDeserializeArgument(Component, Arg, Arguments, sizeof(Arguments) / sizeof(typeof(*Arguments)), Deferred);
}
