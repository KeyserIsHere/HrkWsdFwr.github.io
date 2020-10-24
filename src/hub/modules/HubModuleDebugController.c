/*
 *  Copyright (c) 2020, Stefan Johnson
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

#include "HubModuleDebugController.h"

#define HK_HUB_MODULE_DEBUG_CONTROLLER_QUERY_PORT_MASK 0x80

#define HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX 100

#if DEBUG
size_t HKHubModuleDebugControllerEventBufferMax = HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX;
#undef HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX
#define HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX HKHubModuleDebugControllerEventBufferMax
#endif

typedef enum {
    HKHubModuleDebugControllerDeviceEventTypePause,
    HKHubModuleDebugControllerDeviceEventTypeRun,
    HKHubModuleDebugControllerDeviceEventTypeChangeBreakpoint,
    HKHubModuleDebugControllerDeviceEventTypeChangePortConnection,
    HKHubModuleDebugControllerDeviceEventTypeExecutedOperation,
    HKHubModuleDebugControllerDeviceEventTypeModifyRegister,
    HKHubModuleDebugControllerDeviceEventTypeModifyMemory,
    HKHubModuleDebugControllerDeviceEventTypeChangedDataChunk,
    HKHubModuleDebugControllerDeviceEventTypeDeviceConnected,
    HKHubModuleDebugControllerDeviceEventTypeDeviceDisconnected
} HKHubModuleDebugControllerDeviceEventType;

typedef struct {
    CCBigInt id;
    HKHubModuleDebugControllerDeviceEventType type;
    size_t device;
    union {
        struct {
            uint8_t offset;
            HKHubArchProcessorDebugBreakpoint access;
        } breakpoint;
        struct {
            struct {
                size_t device;
                uint8_t port;
            } target;
            uint8_t port;
        } connection;
        uint8_t instruction[5];
        HKHubArchInstructionRegister reg;
        struct {
            uint8_t offset;
            uint8_t size;
        } memory;
        CCArray(uint8_t) data; //TODO: union of 8/ptr size uint8_t's, or the array of uint8_t's to avoid allocations on small data
    };
} HKHubModuleDebugControllerDeviceEvent;

CC_ARRAY_DECLARE(HKHubModuleDebugControllerDeviceEvent);

typedef struct {
    CCArray(HKHubModuleDebugControllerDeviceEvent) buffer;
    size_t count;
} HKHubModuleDebugControllerDeviceEventBuffer;

typedef enum {
    HKHubModuleDebugControllerDeviceTypeNone,
    HKHubModuleDebugControllerDeviceTypeProcessor,
    HKHubModuleDebugControllerDeviceTypeModule
} HKHubModuleDebugControllerDeviceType;

typedef struct {
    HKHubModuleDebugControllerDeviceType type;
    union {
        HKHubArchProcessor processor;
        HKHubModule module;
    };
    HKHubModuleDebugControllerDeviceEventBuffer events;
    HKHubModule controller;
    size_t index;
} HKHubModuleDebugControllerDevice;

CC_ARRAY_DECLARE(HKHubModuleDebugControllerDevice);

typedef struct {
    size_t index;
} HKHubModuleDebugControllerEventState;

typedef struct {
    CCArray(HKHubModuleDebugControllerDevice) devices;
    HKHubModuleDebugControllerEventState eventPortState[128];
    CCBigInt sharedID;
} HKHubModuleDebugControllerState;

static void HKHubModuleDebugControllerPushEvent(HKHubModuleDebugControllerState *State, HKHubModuleDebugControllerDeviceEventBuffer *Events, HKHubModuleDebugControllerDeviceEvent *Event)
{
    Event->id = CCBigIntCreate(CC_STD_ALLOCATOR);
    CCBigIntSet(Event->id, State->sharedID);
    CCBigIntAdd(State->sharedID, 1);
    
    if (CCArrayGetCount(Events->buffer) == HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX)
    {
        CCArrayAppendElement(Events->buffer, Event);
        Events->count++;
    }
    
    else
    {
        CCArrayReplaceElementAtIndex(Events->buffer, Events->count % HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX, Event);
    }
}

static HKHubModuleDebugControllerDeviceEvent *HKHubModuleDebugControllerPopEvent(HKHubModuleDebugControllerDeviceEventBuffer *Events, size_t *Index)
{
    if ((*Index + HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX) <= Events->count) *Index = Events->count - HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX;
    
    return CCArrayGetElementAtIndex(Events->buffer, (*Index)++ % HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX);
}

static void HKHubModuleDebugControllerStateDestructor(HKHubModuleDebugControllerState *State)
{
    for (size_t Loop = 0, Count = CCArrayGetCount(State->devices); Loop < Count; Loop++)
    {
        HKHubModuleDebugControllerDevice *Device = CCArrayGetElementAtIndex(State->devices, Loop);
        
        if (Device->events.buffer)
        {
            for (size_t Loop2 = 0, Count2 = CCArrayGetCount(Device->events.buffer); Loop2 < Count2; Loop2++)
            {
                HKHubModuleDebugControllerDeviceEvent *Event = CCArrayGetElementAtIndex(Device->events.buffer, Loop2);
                if (Event->type == HKHubModuleDebugControllerDeviceEventTypeChangedDataChunk)
                {
                    if (Event->data) CCArrayDestroy(Event->data);
                }
                
                CCBigIntDestroy(Event->id);
            }
        }
        
        switch (Device->type)
        {
            case HKHubModuleDebugControllerDeviceTypeProcessor:
                Device->processor->state.debug.operation = NULL;
                Device->processor->state.debug.portConnectionChange = NULL;
                Device->processor->state.debug.breakpointChange = NULL;
                Device->processor->state.debug.debugModeChange = NULL;
                
                Device->processor->state.debug.context = NULL;
                
                HKHubArchProcessorSetDebugMode(Device->processor, HKHubArchProcessorDebugModeContinue);
                break;
                
            case HKHubModuleDebugControllerDeviceTypeModule:
                Device->module->debug.context = NULL;
                break;
                
            default:
                break;
        }
        
        CCArrayDestroy(Device->events.buffer);
    }
    
    CCArrayDestroy(State->devices);
    CCBigIntDestroy(State->sharedID);
    CCFree(State);
}

HKHubModule HKHubModuleDebugControllerCreate(CCAllocatorType Allocator)
{
    HKHubModuleDebugControllerState *State = CCMalloc(Allocator, sizeof(HKHubModuleDebugControllerState), NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (State)
    {
        memset(State, 0, sizeof(*State));
        
        State->devices = CCArrayCreate(Allocator, sizeof(HKHubModuleDebugControllerDevice), 4);
        State->sharedID = CCBigIntCreate(CC_STD_ALLOCATOR);
        
        return HKHubModuleCreate(Allocator, NULL, NULL, State, (HKHubModuleDataDestructor)HKHubModuleDebugControllerStateDestructor, NULL);
    }
    
    else CC_LOG_ERROR("Failed to create debug controller module due to allocation failure: allocation of size (%zu)", sizeof(HKHubModuleDebugControllerState));
    
    return NULL;
}

void HKHubModuleDebugControllerConnectProcessor(HKHubModule Controller, HKHubArchProcessor Processor)
{
    CCAssertLog(Controller, "Controller must not be null");
    CCAssertLog(Processor, "Processor must not be null");
    CCAssertLog(!Processor->state.debug.context, "Processor must not already be debugged");
    
    HKHubModuleDebugControllerState *State = Controller->internal;
    const size_t Index = CCArrayAppendElement(State->devices, &(HKHubModuleDebugControllerDevice){
        .type = HKHubModuleDebugControllerDeviceTypeProcessor,
        .processor = Processor,
        .events = {
            .buffer = CCArrayCreate(CC_STD_ALLOCATOR, sizeof(HKHubModuleDebugControllerDeviceEvent), 16),
            .count = 0
        },
        .controller = Controller
    });
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModePause);
    
    HKHubModuleDebugControllerDevice * const Device = CCArrayGetElementAtIndex(State->devices, Index);
    
    Processor->state.debug.context = Device;
    
//    Processor->state.debug.operation = HKHubModuleDebugControllerInstructionHook;
//    Processor->state.debug.portConnectionChange = HKHubModuleDebugControllerPortConnectionChangeHook;
//    Processor->state.debug.breakpointChange = HKHubModuleDebugControllerBreakpointChangeHook;
//    Processor->state.debug.debugModeChange = HKHubModuleDebugControllerDebugModeChangeHook;
    
    HKHubModuleDebugControllerPushEvent(State, &Device->events, &(HKHubModuleDebugControllerDeviceEvent){
        .type = HKHubModuleDebugControllerDeviceEventTypeDeviceConnected,
        .device = (Device->index = Index)
    });
}

void HKHubModuleDebugControllerDisconnectProcessor(HKHubModule Controller, HKHubArchProcessor Processor)
{
    CCAssertLog(Controller, "Controller must not be null");
    CCAssertLog(Processor, "Processor must not be null");
    CCAssertLog(Processor->state.debug.context && ((HKHubModuleDebugControllerDevice*)Processor->state.debug.context)->controller == Controller, "Processor must be connected to the controller");
    
    HKHubModuleDebugControllerDevice *Device = Processor->state.debug.context;
    Device->type = HKHubModuleDebugControllerDeviceTypeNone;
    Device->processor = NULL;
    
    HKHubModuleDebugControllerPushEvent(Controller->internal, &Device->events, &(HKHubModuleDebugControllerDeviceEvent){
        .type = HKHubModuleDebugControllerDeviceEventTypeDeviceDisconnected,
        .device = Device->index
    });
    
    Processor->state.debug.operation = NULL;
    Processor->state.debug.portConnectionChange = NULL;
    Processor->state.debug.breakpointChange = NULL;
    Processor->state.debug.debugModeChange = NULL;
    
    Processor->state.debug.context = NULL;
    
    HKHubArchProcessorSetDebugMode(Processor, HKHubArchProcessorDebugModeContinue);
}

void HKHubModuleDebugControllerConnectModule(HKHubModule Controller, HKHubModule Module)
{
    CCAssertLog(Controller, "Controller must not be null");
    CCAssertLog(Module, "Module must not be null");
    CCAssertLog(!Module->debug.context, "Module must not already be debugged");
    
    HKHubModuleDebugControllerState *State = Controller->internal;
    const size_t Index = CCArrayAppendElement(State->devices, &(HKHubModuleDebugControllerDevice){
        .type = HKHubModuleDebugControllerDeviceTypeModule,
        .module = Module,
        .events = {
            .buffer = NULL,
            .count = 0
        },
        .controller = Controller
    });
    
    HKHubModuleDebugControllerDevice * const Device = CCArrayGetElementAtIndex(State->devices, Index);
    
    Module->debug.context = Device;
    
    HKHubModuleDebugControllerPushEvent(State, &Device->events, &(HKHubModuleDebugControllerDeviceEvent){
        .type = HKHubModuleDebugControllerDeviceEventTypeDeviceConnected,
        .device = (Device->index = Index)
    });
}

void HKHubModuleDebugControllerDisconnectModule(HKHubModule Controller, HKHubModule Module)
{
    CCAssertLog(Controller, "Controller must not be null");
    CCAssertLog(Module, "Module must not be null");
    CCAssertLog(Module->debug.context && ((HKHubModuleDebugControllerDevice*)Module->debug.context)->controller == Controller, "Module must be connected to the controller");
    
    HKHubModuleDebugControllerDevice *Device = Module->debug.context;
    Device->type = HKHubModuleDebugControllerDeviceTypeNone;
    Device->module = NULL;
    
    HKHubModuleDebugControllerPushEvent(Controller->internal, &Device->events, &(HKHubModuleDebugControllerDeviceEvent){
        .type = HKHubModuleDebugControllerDeviceEventTypeDeviceDisconnected,
        .device = Device->index
    });
}
