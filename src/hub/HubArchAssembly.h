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

#ifndef HackingGame_HubArchAssembly_h
#define HackingGame_HubArchAssembly_h

#include <Blob2D/Blob2D.h>

typedef enum {
    HKHubArchAssemblyASTTypeSource,
    HKHubArchAssemblyASTTypeUnknown,
    HKHubArchAssemblyASTTypeInstruction,
    HKHubArchAssemblyASTTypeDirective,
    HKHubArchAssemblyASTTypeLabel,
    HKHubArchAssemblyASTTypeInteger,
    HKHubArchAssemblyASTTypeRegister,
    HKHubArchAssemblyASTTypeMemory,
    HKHubArchAssemblyASTTypeOperand,
    HKHubArchAssemblyASTTypeSymbol,
    HKHubArchAssemblyASTTypePlus,
    HKHubArchAssemblyASTTypeMinus,
    HKHubArchAssemblyASTTypeOffset
} HKHubArchAssemblyASTType;

typedef struct {
    HKHubArchAssemblyASTType type;
    CCString string;
    union {
        struct {
            uint8_t value;
        } integer;
    };
    CCOrderedCollection childNodes;
    size_t line;
} HKHubArchAssemblyASTNode;


/*!
 * @brief Parse the source and produce the AST for the given assembly.
 * @param Source The assembly source code.
 * @return The AST, must be destroyed to free up memory.
 */
CC_NEW CCOrderedCollection HKHubArchAssemblyParse(const char *Source);

/*!
 * @brief Print the AST for debugging purposes.
 * @param AST The AST to be printed.
 */
void HKHubArchPrintAST(CCOrderedCollection AST);

#endif