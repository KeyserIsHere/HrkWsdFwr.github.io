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

#define HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_DATA_CHUNK_DEFAULT_SIZE 8

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
    CCBigIntFast id;
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
        struct {
            uint8_t encoding[5];
            uint8_t size;
        } instruction;
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
    CCBigIntFast index;
    uint8_t *message;
    uint8_t chunks;
    uint8_t chunkBatchSize;
    struct {
        uint16_t commands;
        CCArray(uint16_t) devices;
    } filter;
} HKHubModuleDebugControllerEventState;

typedef struct {
    CCArray(HKHubModuleDebugControllerDevice) devices;
    HKHubModuleDebugControllerEventState eventPortState[128];
    CCBigIntFast sharedID;
} HKHubModuleDebugControllerState;

static void HKHubModuleDebugControllerDeviceEventDestructor(HKHubModuleDebugControllerDeviceEvent *Event)
{
    if (Event->type == HKHubModuleDebugControllerDeviceEventTypeChangedDataChunk)
    {
        if (Event->data) CCArrayDestroy(Event->data);
    }
    
    CCBigIntFastDestroy(Event->id);
}

static void HKHubModuleDebugControllerPushEvent(HKHubModuleDebugControllerState *State, HKHubModuleDebugControllerDeviceEventBuffer *Events, HKHubModuleDebugControllerDeviceEvent *Event)
{
    Event->id = CCBigIntFastCreate(CC_STD_ALLOCATOR);
    CCBigIntFastSet(&Event->id, State->sharedID);
    CCBigIntFastAdd(&State->sharedID, 1);
    
    if (CCArrayGetCount(Events->buffer) == HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX)
    {
        CCArrayAppendElement(Events->buffer, Event);
        Events->count++;
    }
    
    else
    {
        HKHubModuleDebugControllerDeviceEventDestructor(CCArrayGetElementAtIndex(Events->buffer, Events->count % HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX));
        
        CCArrayReplaceElementAtIndex(Events->buffer, Events->count % HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX, Event);
    }
}

static HKHubModuleDebugControllerDeviceEvent *HKHubModuleDebugControllerPopEvent(HKHubModuleDebugControllerDeviceEventBuffer *Events, size_t *Index)
{
    if ((*Index + HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX) <= Events->count) *Index = Events->count - HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX;
    
    return CCArrayGetElementAtIndex(Events->buffer, (*Index)++ % HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_BUFFER_MAX);
}

static inline size_t HKHubModuleDebugControllerEventPortMessageSize(size_t MinSize, size_t DefaultChunkSize)
{
    const size_t DefaultLargestMessageSize = 2 + DefaultChunkSize;
    
    return MinSize > DefaultLargestMessageSize ? MinSize : DefaultLargestMessageSize;
}

static _Bool HKHubModuleDebugControllerFindDevice(CCArray(uint16_t) DeviceRanges, const uint16_t MatchDevice, size_t *RangeIndex, uint16_t *UpdatedRange, _Bool *Insert)
{
    //TODO: change to a binary search
    
    _Bool EarlyExit = FALSE;
    for (size_t Loop = 0, Count = CCArrayGetCount(DeviceRanges); Loop < Count; Loop++)
    {
        uint16_t *DeviceRange = CCArrayGetElementAtIndex(DeviceRanges, Loop);
        const uint16_t Start = *DeviceRange >> 12;
        const uint16_t Stop = (*DeviceRange & 0xf) + Start;
        const _Bool Unused = (*DeviceRange & 0xf) != 0xf;
        
        if (((Start - 1) == MatchDevice) && Unused)
        {
            if (RangeIndex) *RangeIndex = Loop;
            if (UpdatedRange) *UpdatedRange = ((Stop - Start) + 1) | ((Start - 1) << 12);
            if (Insert) *Insert = FALSE;
            
            return FALSE;
        }
        
        else if (((Stop + 1) == MatchDevice) && Unused)
        {
            if (RangeIndex) *RangeIndex = Loop;
            if (UpdatedRange) *UpdatedRange = ((Stop - Start) + 1) | (Start << 12);
            if (Insert) *Insert = FALSE;
            
            EarlyExit = TRUE;
        }
        
        else if ((Start <= MatchDevice) && (Stop >= MatchDevice))
        {
            if (RangeIndex) *RangeIndex = Loop;
            if (UpdatedRange) *UpdatedRange = *DeviceRange;
            if (Insert) *Insert = FALSE;
            
            return TRUE;
        }
        
        else if (MatchDevice < Start)
        {
            if (RangeIndex) *RangeIndex = Loop;
            if (UpdatedRange) *UpdatedRange = MatchDevice << 12;
            if (Insert) *Insert = TRUE;
            
            return FALSE;
        }
        
        else if (EarlyExit) return FALSE;
    }
    
    if (!EarlyExit)
    {
        if (RangeIndex) *RangeIndex = SIZE_MAX;
        if (UpdatedRange) *UpdatedRange = MatchDevice << 12;
        if (Insert) *Insert = TRUE;
    }
    
    return FALSE;
}

static void HKHubModuleDebugControllerAddDevice(CCArray(uint16_t) DeviceRanges, const uint16_t MatchDevice)
{
    size_t RangeIndex;
    uint16_t UpdatedRange;
    _Bool Insert;
    
    if (!HKHubModuleDebugControllerFindDevice(DeviceRanges, MatchDevice, &RangeIndex, &UpdatedRange, &Insert))
    {
        if (Insert)
        {
            if (RangeIndex == SIZE_MAX) CCArrayAppendElement(DeviceRanges, &UpdatedRange);
            else CCArrayInsertElementAtIndex(DeviceRanges, RangeIndex, &UpdatedRange);
        }
        
        else CCArrayReplaceElementAtIndex(DeviceRanges, RangeIndex, &UpdatedRange);
    }
}

static void HKHubModuleDebugControllerRemoveDevice(CCArray(uint16_t) DeviceRanges, const uint16_t MatchDevice)
{
    size_t RangeIndex;
    uint16_t UpdatedRange;
    
    if (HKHubModuleDebugControllerFindDevice(DeviceRanges, MatchDevice, &RangeIndex, &UpdatedRange, NULL))
    {
        const uint16_t Start = UpdatedRange >> 12;
        const uint16_t Stop = (UpdatedRange & 0xf) + Start;
        
        if (Start == Stop)
        {
            CCArrayRemoveElementAtIndex(DeviceRanges, RangeIndex);
        }
        
        else if ((Start - 1) == MatchDevice)
        {
            CCArrayReplaceElementAtIndex(DeviceRanges, RangeIndex, &(uint16_t){ ((Stop - Start) - 1) | ((Start + 1) << 12) });
        }
        
        else if ((Stop + 1) == MatchDevice)
        {
            CCArrayReplaceElementAtIndex(DeviceRanges, RangeIndex, &(uint16_t){ ((Stop - Start) - 1) | (Start << 12) });
        }
        
        else
        {
            CCArrayReplaceElementAtIndex(DeviceRanges, RangeIndex, &(uint16_t){ ((Stop - MatchDevice) - 1) | ((MatchDevice + 1) << 12) });
            CCArrayInsertElementAtIndex(DeviceRanges, RangeIndex, &(uint16_t){ ((MatchDevice - Start) - 1) | (Start << 12) });
        }
    }
}

static HKHubArchPortResponse HKHubModuleDebugControllerReceive(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
    
    if (HKHubArchPortIsReady(OppositePort))
    {
        if (Message->size >= 1)
        {
            HKHubModuleDebugControllerState *State = Device->internal;
            
            if (Port & HK_HUB_MODULE_DEBUG_CONTROLLER_QUERY_PORT_MASK)
            {
                // query api
            }
            
            else
            {
                // event api
                HKHubArchPortResponse Response = HKHubArchPortResponseTimeout;
                
                switch (Message->memory[Message->offset] >> 4)
                {
                    case 0:
                        //[0:4] add filter [command:4]
                        State->eventPortState[Port].filter.commands |= 1 << (Message->memory[Message->offset] & 0xf);
                        Response = HKHubArchPortResponseSuccess;
                        break;
                        
                    case 1:
                        //[1:4] remove filter [command:4]
                        State->eventPortState[Port].filter.commands &= ~(1 << (Message->memory[Message->offset] & 0xf));
                        Response = HKHubArchPortResponseSuccess;
                        break;
                        
                    case 2:
                        //[2:4] add filter [device:12]
                        if (Message->size >= 2)
                        {
                            const uint16_t FilterDevice = ((uint16_t)(Message->memory[Message->offset] & 0xf) << 8) | Message->memory[Message->offset + 1];
                            
                            if (!State->eventPortState[Port].filter.devices)
                            {
                                State->eventPortState[Port].filter.devices = CCArrayCreate(CC_STD_ALLOCATOR, sizeof(uint16_t), 4);
                            }
                            
                            HKHubModuleDebugControllerAddDevice(State->eventPortState[Port].filter.devices, FilterDevice);
                            Response = HKHubArchPortResponseSuccess;
                        }
                        break;
                        
                    case 3:
                        //[3:4] remove filter [device:12]
                        if (Message->size >= 2)
                        {
                            if (State->eventPortState[Port].filter.devices)
                            {
                                const uint16_t FilterDevice = ((uint16_t)(Message->memory[Message->offset] & 0xf) << 8) | Message->memory[Message->offset + 1];
                                
                                HKHubModuleDebugControllerRemoveDevice(State->eventPortState[Port].filter.devices, FilterDevice);
                                
                                if (CCArrayGetCount(State->eventPortState[Port].filter.devices) == 0)
                                {
                                    CCArrayDestroy(State->eventPortState[Port].filter.devices);
                                    State->eventPortState[Port].filter.devices = NULL;
                                }
                            }
                            
                            Response = HKHubArchPortResponseSuccess;
                        }
                        break;
                        
                    case 4:
                        //[4:4] [_:4] set modified data chunk [size:8]
                        if (Message->size >= 2)
                        {
                            State->eventPortState[Port].chunkBatchSize = Message->memory[Message->offset + 1];
                            Response = HKHubArchPortResponseSuccess;
                        }
                        
                        break;
                }
                
                return Response;
            }
        }
    }
    
    return HKHubArchPortResponseSuccess;
}

static HKHubArchPortResponse HKHubModuleDebugControllerSend(HKHubArchPortConnection Connection, HKHubModule Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchProcessor ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    HKHubModuleDebugControllerState *State = Device->internal;
    
    if (Port & HK_HUB_MODULE_DEBUG_CONTROLLER_QUERY_PORT_MASK)
    {
        // query api
    }
    
    else
    {
        // event api
        for (size_t Loop = 0, Count = CCArrayGetCount(State->devices); Loop < Count; Loop++)
        {
            const HKHubModuleDebugControllerDevice *DebuggedDevice = CCArrayGetElementAtIndex(State->devices, Loop);
            
            if (DebuggedDevice->events.buffer)
            {
                const HKHubModuleDebugControllerDeviceEvent *Event = NULL;
                CCComparisonResult Result = CCComparisonResultInvalid;
                
                for (size_t Loop2 = DebuggedDevice->index, Count2 = CCArrayGetCount(DebuggedDevice->events.buffer); (Loop2 < Count2) && (Result != CCComparisonResultEqual) && (Result != CCComparisonResultDescending); Loop2++)
                {
                    Event = CCArrayGetElementAtIndex(DebuggedDevice->events.buffer, Loop2);
                    Result = CCBigIntFastCompare(State->eventPortState[Port].index, Event->id);
                }
                
                if (Result == CCComparisonResultEqual)
                {
                    size_t Size = 0;
                    State->eventPortState[Port].message[Size++] = (Event->type << 4) | ((Event->device & 0xf00) >> 8);
                    State->eventPortState[Port].message[Size++] = Event->device & 0xff;
                    
                    switch (Event->type)
                    {
                        case HKHubModuleDebugControllerDeviceEventTypePause:
                            //[0:4] [device:12] paused
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeRun:
                            //[1:4] [device:12] running
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeChangeBreakpoint:
                            //[2:4] [device:12] change breakpoint [offset:8] [w:1] [r:1]
                            State->eventPortState[Port].message[Size++] = Event->breakpoint.offset;
                            State->eventPortState[Port].message[Size++] = Event->breakpoint.access & 3;
                            _Static_assert(HKHubArchProcessorDebugBreakpointRead == (1 << 0), "Read breakpoint flag changed");
                            _Static_assert(HKHubArchProcessorDebugBreakpointWrite == (1 << 1), "Write breakpoint flag changed");
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeChangePortConnection:
                            //[3:4] [device:12] change [port:8] [receiving port: 8, device:12]
                            State->eventPortState[Port].message[Size++] = Event->connection.port;
                            State->eventPortState[Port].message[Size++] = Event->connection.target.port;
                            State->eventPortState[Port].message[Size++] = (Event->connection.target.device & 0xf00) >> 8;
                            State->eventPortState[Port].message[Size++] = Event->connection.target.device & 0xff;
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeExecutedOperation:
                            //[4:4] [device:12] change op [encoded instruction:8 ...]
                            for (size_t Index = 0; Index < Event->instruction.size; Index++)
                            {
                                State->eventPortState[Port].message[Size++] = Event->instruction.encoding[Index];
                            }
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeModifyRegister:
                            //[5:4] [device:12] modified [reg:3]
                            State->eventPortState[Port].message[Size++] = Event->reg;
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeModifyMemory:
                            //[6:4] [device:12] modified memory [offset:8] [size:8]
                            State->eventPortState[Port].message[Size++] = Event->memory.offset;
                            State->eventPortState[Port].message[Size++] = Event->memory.size;
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeChangedDataChunk:
                        {
                            //[7:4] [device:12] modified [data:8 ...] (comes in as 8 byte sequences, this can be changed)
                            size_t ChunkSize = CCArrayGetCount(Event->data) - State->eventPortState[Port].chunks;
                            
                            if (ChunkSize > State->eventPortState[Port].chunkBatchSize) ChunkSize = State->eventPortState[Port].chunkBatchSize;
                            
                            memcpy(&State->eventPortState[Port].message[Size], CCArrayGetData(Event->data) + State->eventPortState[Port].chunks, ChunkSize);
                            State->eventPortState[Port].chunks += ChunkSize;
                            Size += ChunkSize;
                            break;
                        }
                            
                        case HKHubModuleDebugControllerDeviceEventTypeDeviceConnected:
                            //[8:4] [device:12] connected
                            break;
                            
                        case HKHubModuleDebugControllerDeviceEventTypeDeviceDisconnected:
                            //[9:4] [device:12] disconnected
                            break;
                            
                    }
                    
                    *Message = (HKHubArchPortMessage){
                        .memory = State->eventPortState[Port].message,
                        .offset = 0,
                        .size = Size
                    };
                    
                    if (!HKHubArchPortIsReady(HKHubArchPortConnectionGetOppositePort(Connection, Device, Port))) return HKHubArchPortResponseDefer;
                    
                    return HKHubArchPortResponseSuccess;
                }
            }
        }
    }
    
    return HKHubArchPortResponseTimeout;
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
                HKHubModuleDebugControllerDeviceEventDestructor(CCArrayGetElementAtIndex(Device->events.buffer, Loop2));
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
    
    for (size_t Loop = 0; Loop < sizeof(State->eventPortState) / sizeof(typeof(*State->eventPortState)); Loop++)
    {
        CCBigIntFastDestroy(State->eventPortState[Loop].index);
        CC_SAFE_Free(State->eventPortState[Loop].message);
        if (State->eventPortState[Loop].filter.devices) CCArrayDestroy(State->eventPortState[Loop].filter.devices);
    }
    
    CCArrayDestroy(State->devices);
    CCBigIntFastDestroy(State->sharedID);
    CCFree(State);
}

HKHubModule HKHubModuleDebugControllerCreate(CCAllocatorType Allocator)
{
    HKHubModuleDebugControllerState *State = CCMalloc(Allocator, sizeof(HKHubModuleDebugControllerState), NULL, CC_DEFAULT_ERROR_CALLBACK);
    if (State)
    {
        for (size_t Loop = 0; Loop < sizeof(State->eventPortState) / sizeof(typeof(*State->eventPortState)); Loop++)
        {
            State->eventPortState[Loop].index = CC_BIG_INT_FAST_0;
            CC_SAFE_Malloc(State->eventPortState[Loop].message, HKHubModuleDebugControllerEventPortMessageSize(16, HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_DATA_CHUNK_DEFAULT_SIZE));
            State->eventPortState[Loop].chunks = 0;
            State->eventPortState[Loop].chunkBatchSize = HK_HUB_MODULE_DEBUG_CONTROLLER_EVENT_DATA_CHUNK_DEFAULT_SIZE;
            State->eventPortState[Loop].filter.commands = 0;
            State->eventPortState[Loop].filter.devices = NULL;
        }
        
        State->devices = CCArrayCreate(Allocator, sizeof(HKHubModuleDebugControllerDevice), 4);
        State->sharedID = CCBigIntFastCreate(CC_STD_ALLOCATOR);
        
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
