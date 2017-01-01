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

#include "HubArchModuleDebug.h"
#include "HubArchProcessor.h"

static HKHubArchPortResponse HKHubModuleDebug(HKHubArchPortConnection Connection, HKHubArchPortDevice Device, HKHubArchPortID Port, HKHubArchPortMessage *Message, HKHubArchPortDevice ConnectedDevice, int64_t Timestamp, size_t *Wait)
{
    /*
     As caller will always be a processor, we can calculate the amount of cycles it has and whether it is enough.
     
     Possibly just pass in callers cycles
     */
    //    ((HKHubArchProcessor)ConnectedDevice)->
    
    if (4 + (Message->size * (HKHubArchProcessorSpeedPortTransmission + HKHubArchProcessorSpeedMemoryRead)) <= ((HKHubArchProcessor)ConnectedDevice)->cycles)
    {
        const HKHubArchPort *OppositePort = HKHubArchPortConnectionGetOppositePort(Connection, Device, Port);
        CC_LOG_DEBUG_CUSTOM("%p(%u): %[*]hhx", ConnectedDevice, OppositePort->id, (size_t)Message->size, Message->memory + Message->offset);
        //        return HKHubArchPortResponseSuccess;
    }
    
    //"%[count{separator}]format_specifier" : Count can either be a value or * (size_t value in arg), separator is optional can be the text or * (char * value in arg), and then the standard format specifier
    return HKHubArchPortResponseSuccess;
}