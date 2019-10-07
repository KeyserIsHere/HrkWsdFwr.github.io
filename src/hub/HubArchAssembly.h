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

#include "Base.h"
#include "HubArchBinary.h"

typedef enum {
    HKHubArchAssemblyASTTypeSource,
    HKHubArchAssemblyASTTypeAST,
    HKHubArchAssemblyASTTypeUnknown,
    HKHubArchAssemblyASTTypeInstruction,
    HKHubArchAssemblyASTTypeDirective,
    HKHubArchAssemblyASTTypeLabel,
    HKHubArchAssemblyASTTypeString,
    HKHubArchAssemblyASTTypeInteger,
    HKHubArchAssemblyASTTypeRegister,
    HKHubArchAssemblyASTTypeMemory,
    HKHubArchAssemblyASTTypeExpression,
    HKHubArchAssemblyASTTypeOperand,
    HKHubArchAssemblyASTTypeSymbol,
    HKHubArchAssemblyASTTypePlus,
    HKHubArchAssemblyASTTypeMinus,
    HKHubArchAssemblyASTTypeMultiply,
    HKHubArchAssemblyASTTypeDivide,
    HKHubArchAssemblyASTTypeModulo,
    HKHubArchAssemblyASTTypeNot,
    HKHubArchAssemblyASTTypeOnesComplement,
    HKHubArchAssemblyASTTypeShiftLeft,
    HKHubArchAssemblyASTTypeShiftRight,
    HKHubArchAssemblyASTTypeBitwiseAnd,
    HKHubArchAssemblyASTTypeBitwiseOr,
    HKHubArchAssemblyASTTypeBitwiseXor,
    HKHubArchAssemblyASTTypeLogicalAnd,
    HKHubArchAssemblyASTTypeLogicalOr,
    HKHubArchAssemblyASTTypeEqual,
    HKHubArchAssemblyASTTypeNotEqual,
    HKHubArchAssemblyASTTypeLessThan,
    HKHubArchAssemblyASTTypeLessThanOrEqual,
    HKHubArchAssemblyASTTypeGreaterThan,
    HKHubArchAssemblyASTTypeGreaterThanOrEqual,
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

typedef struct {
    CCString message;
    HKHubArchAssemblyASTNode *command;
    HKHubArchAssemblyASTNode *operand;
    HKHubArchAssemblyASTNode *value;
} HKHubArchAssemblyASTError;

/*!
 * @brief Stores the paths that will be searched when using the include directive.
 * @description This should be an ordered collection of @b FSPath paths for all
 *              directories that will be available to include searches.
 *
 *              When including a file that can be found in multiple paths, the first path
 *              in the list will take precedence.
 */
extern CCOrderedCollection HKHubArchAssemblyIncludeSearchPaths;

/*!
 * @brief Parse the source and produce the AST for the given assembly.
 * @param Source The assembly source code.
 * @return The AST (collection of @b HKHubArchAssemblyASTNode nodes), must be destroyed
 *         to free up memory.
 */
CC_NEW CCOrderedCollection HKHubArchAssemblyParse(const char *Source);

/*!
 * @brief Create a binary for the given AST.
 * @param Allocator The allocator to be used for the binary.
 * @param AST The AST to validate for any errors.
 * @param Errors Where to store the errors (collection of @b HKHubArchAssemblyASTError).
 *        May be null if no errors should be returned to caller. If errors are returned,
 *        they are owned by the caller and must be destroyed.
 *
 * @return The executable binary or null on failure. Must be destroyed to free memory.
 */
CC_NEW HKHubArchBinary HKHubArchAssemblyCreateBinary(CCAllocatorType Allocator, CCOrderedCollection AST, CC_NEW CCOrderedCollection *Errors);

/*!
 * @brief Print the AST for debugging purposes.
 * @param AST The AST to be printed.
 */
void HKHubArchAssemblyPrintAST(CCOrderedCollection AST);

/*!
 * @brief Print the errors for debugging purposes.
 * @param Errors The errors to be printed.
 */
void HKHubArchAssemblyPrintError(CCOrderedCollection Errors);

/*!
 * @brief Convenience function for resolving symbols to literal values.
 * @param Value The value to resolve.
 * @param Result The pointer to store the literal result.
 * @param Labels The labels.
 * @param Defines The defines.
 * @return TRUE if it was resolved to a literal value otherwise FALSE.
 */
_Bool HKHubArchAssemblyResolveSymbol(HKHubArchAssemblyASTNode *Value, uint8_t *Result, CCDictionary Labels, CCDictionary Defines);

/*!
 * @brief Convenience function for resolving integers from arithmetic operations.
 * @param Offset The current offsetto be used for offset references.
 * @param Result The pointer to store the literal result.
 * @param Command The command the operand belongs to.
 * @param Operand The operand to resolve as an integer.
 * @param Labels The labels.
 * @param Defines The defines.
 * @param Variables The optional unknown variable names.
 * @return TRUE if it was resolved to a literal value otherwise FALSE.
 */
_Bool HKHubArchAssemblyResolveInteger(size_t Offset, uint8_t *Result, HKHubArchAssemblyASTNode *Command, HKHubArchAssemblyASTNode *Operand, CCOrderedCollection Errors, CCDictionary Labels, CCDictionary Defines, CCDictionary Variables);

/*!
 * @brief Convenience function for adding error messages.
 * @param Errors The collection of errors.
 * @param Message The error message. Ownership is transferred to the error list.
 * @param Command The command the error is referencing.
 * @param Operand The operand the error is referencing.
 * @param Value The value the error is referencing.
 */
static inline void HKHubArchAssemblyErrorAddMessage(CCOrderedCollection Errors, CCString CC_OWN(Message), HKHubArchAssemblyASTNode *Command, HKHubArchAssemblyASTNode *Operand, HKHubArchAssemblyASTNode *Value);

#pragma mark -

static inline void HKHubArchAssemblyErrorAddMessage(CCOrderedCollection Errors, CCString Message, HKHubArchAssemblyASTNode *Command, HKHubArchAssemblyASTNode *Operand, HKHubArchAssemblyASTNode *Value)
{
    if (Errors)
    {
        CCOrderedCollectionAppendElement(Errors, &(HKHubArchAssemblyASTError){
            .message = Message,
            .command = Command,
            .operand = Operand,
            .value = Value
        });
    }
}

#endif
