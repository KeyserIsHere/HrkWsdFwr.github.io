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

#include "Base.h"
#include "HubArchExpressions.h"
#include "HubArchAssembly.h"
#include "RapServer.h"
#include "HubSystem.h"
#include "HubProcessorComponent.h"
#include "HubPortConnectionComponent.h"
#include "HubDebuggerComponent.h"
#include "HubModuleComponent.h"
#include "HubModuleKeyboardComponent.h"
#include "HubModuleDisplayComponent.h"
#include "HubModuleWirelessTransceiverComponent.h"
#include "ItemManualComponent.h"

#if CC_PLATFORM_OS_X || CC_PLATFORM_IOS
#include <CoreFoundation/CoreFoundation.h>
#endif

static void PreSetup(void)
{
    char Path[] = __FILE__;
    if ((sizeof(__FILE__) > sizeof("Hacking-Game/src/main.c")) && (!strcmp(Path + (sizeof(__FILE__) - sizeof("Hacking-Game/src/main.c")), "Hacking-Game/src/main.c")))
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warray-bounds"
        Path[sizeof(__FILE__) - sizeof("Hacking-Game/src/main.c")] = 0;
#pragma clang diagnostic pop

        CCFileFilterInputAddPath(Path);
    }
    
    CCExpressionEvaluatorRegister(CC_STRING("disassemble"), HKHubArchExpressionDisassemble);
    
    HKHubSystemRegister();
    HKHubProcessorComponentRegister();
    HKHubPortConnectionComponentRegister();
    HKHubDebuggerComponentRegister();
    HKHubModuleComponentRegister();
    HKHubModuleKeyboardComponentRegister();
    HKHubModuleDisplayComponentRegister();
    HKHubModuleWirelessTransceiverComponentRegister();
    
    HKItemManualComponentRegister();
    
    HKRapServerStart();
}

static void Setup(void)
{
    HKHubArchAssemblyIncludeSearchPaths = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(FSPath), FSPathComponentDestructorForCollection);
    
    FSPath IncludeSearchPath = FSPathCopy(B2EngineConfiguration.project);
    
    FSPathRemoveComponentLast(IncludeSearchPath);
    FSPathRemoveComponentLast(IncludeSearchPath);
    
    FSPathAppendComponent(IncludeSearchPath, FSPathComponentCreate(FSPathComponentTypeDirectory, "logic"));
    FSPathAppendComponent(IncludeSearchPath, FSPathComponentCreate(FSPathComponentTypeDirectory, "programs"));
    
    CCOrderedCollectionAppendElement(HKHubArchAssemblyIncludeSearchPaths, &IncludeSearchPath);
}

int main(int argc, const char *argv[])
{
    B2EngineSetupBegin = PreSetup;
    B2EngineSetupComplete = Setup;
    
    B2EngineConfiguration.launch = B2LaunchOptionGame;
    
#if CC_PLATFORM_OS_X || CC_PLATFORM_IOS
    CFBundleRef Bundle = CFBundleGetBundleWithIdentifier(CFSTR("io.scrimpycat.HackingGame"));
    CFURLRef ResourceURL = CFBundleCopyResourcesDirectoryURL(Bundle);
    char ResourcePath[PATH_MAX];
    
    if ((!ResourceURL) || (!CFURLGetFileSystemRepresentation(ResourceURL, TRUE, (UInt8*)ResourcePath, sizeof(ResourcePath))))
    {
        CC_LOG_ERROR("Could not find asset path");
        return EXIT_FAILURE;
    }
    
    CFRelease(ResourceURL);
    
    B2EngineConfiguration.project = FSPathCreateFromSystemPath(ResourcePath);
#else
    char Path[] = __FILE__;
    Path[sizeof(__FILE__) - sizeof("src/main.c")] = 0;
    B2EngineConfiguration.project = FSPathCreateFromSystemPath(Path);
#endif
    
    FSPathAppendComponent(B2EngineConfiguration.project, FSPathComponentCreate(FSPathComponentTypeDirectory, "assets"));
    FSPathAppendComponent(B2EngineConfiguration.project, FSPathComponentCreate(FSPathComponentTypeFile, "game"));
    FSPathAppendComponent(B2EngineConfiguration.project, FSPathComponentCreate(FSPathComponentTypeExtension, "gamepkg"));
    
    return B2EngineRun(argc, argv);
}
