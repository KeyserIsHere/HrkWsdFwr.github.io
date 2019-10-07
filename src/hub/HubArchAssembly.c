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

#include "HubArchAssembly.h"
#include "HubArchInstruction.h"

static size_t HKHubArchAssemblyCompile(size_t Offset, HKHubArchBinary Binary, CCOrderedCollection(HKHubArchAssemblyASTNode) AST, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines, int Pass);

static void HKHubArchAssemblyASTNodeDestructor(void *Container, HKHubArchAssemblyASTNode *Node)
{
    if (Node->string) CCStringDestroy(Node->string);
    if (Node->childNodes) CCCollectionDestroy(Node->childNodes);
}

#define CC_CONTAINER_TYPE_DISABLE
static size_t HKHubArchAssemblyResolveLiteralValue(CCArray(HKHubArchAssemblyASTNode *) Parents, const char *String, size_t Length, _Bool Hex, _Bool Sym, _Bool Dec, char Operator)
{
#undef CC_CONTAINER_TYPE_DISABLE
    const size_t Index = CCArrayGetCount(Parents) - 1;
    if ((Operator == ')') && (Index))
    {
        CCArrayRemoveElementAtIndex(Parents, Index);
        return 0;
    }
    
    HKHubArchAssemblyASTNode *Parent = *(HKHubArchAssemblyASTNode**)CCArrayGetElementAtIndex(Parents, Index);
    
    HKHubArchAssemblyASTNode Node = {
        .type = HKHubArchAssemblyASTTypeUnknown,
        .line = Parent->line,
        .childNodes = NULL
    };
    
    size_t Skip = 0;
    
    if ((Hex) || (Dec))
    {
        Node.type = HKHubArchAssemblyASTTypeInteger;
        Node.integer.value = (uint8_t)strtol(String, NULL, Dec ? 10 : 16);
    }
    
    else if (Sym)
    {
        Node.type = HKHubArchAssemblyASTTypeSymbol;
    }
    
    else
    {
        switch (Operator)
        {
            case '.':
                Node.type = HKHubArchAssemblyASTTypeOffset;
                break;
                
            case '+':
                Node.type = HKHubArchAssemblyASTTypePlus;
                break;
                
            case '-':
                Node.type = HKHubArchAssemblyASTTypeMinus;
                break;
                
            case '*':
                Node.type = HKHubArchAssemblyASTTypeMultiply;
                break;
                
            case '/':
                Node.type = HKHubArchAssemblyASTTypeDivide;
                break;
                
            case '%':
                Node.type = HKHubArchAssemblyASTTypeModulo;
                break;
                
            case '!':
            {
                switch (String[1])
                {
                    case '=':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeNotEqual;
                        break;
                        
                    default:
                        Node.type = HKHubArchAssemblyASTTypeNot;
                        break;
                }
                break;
            }
                
            case '~':
                Node.type = HKHubArchAssemblyASTTypeOnesComplement;
                break;
                
            case '=':
                if (String[1])
                {
                    Skip = 1;
                    Node.type = HKHubArchAssemblyASTTypeEqual;
                }
                break;
                
            case '<':
            {
                switch (String[1])
                {
                    case '<':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeShiftLeft;
                        break;
                        
                    case '=':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeLessThanOrEqual;
                        break;
                        
                    default:
                        Node.type = HKHubArchAssemblyASTTypeLessThan;
                        break;
                }
                break;
            }
                
            case '>':
            {
                switch (String[1])
                {
                    case '>':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeShiftRight;
                        break;
                        
                    case '=':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeGreaterThanOrEqual;
                        break;
                        
                    default:
                        Node.type = HKHubArchAssemblyASTTypeGreaterThan;
                        break;
                }
                break;
            }
                
            case '&':
            {
                switch (String[1])
                {
                    case '&':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeLogicalAnd;
                        break;
                        
                    default:
                        Node.type = HKHubArchAssemblyASTTypeBitwiseAnd;
                        break;
                }
                break;
            }
                
            case '|':
            {
                switch (String[1])
                {
                    case '|':
                        Skip = 1;
                        Node.type = HKHubArchAssemblyASTTypeLogicalOr;
                        break;
                        
                    default:
                        Node.type = HKHubArchAssemblyASTTypeBitwiseOr;
                        break;
                }
                break;
            }
                
            case '^':
                Node.type = HKHubArchAssemblyASTTypeBitwiseXor;
                break;
                
            case '(':
                Node.type = HKHubArchAssemblyASTTypeExpression;
                Node.childNodes = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTNode), (CCCollectionElementDestructor)HKHubArchAssemblyASTNodeDestructor);
                break;
        }
    }
    
    if (!Parent->childNodes) Parent->childNodes = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTNode), (CCCollectionElementDestructor)HKHubArchAssemblyASTNodeDestructor);
    
    if (Node.type != HKHubArchAssemblyASTTypeExpression) Node.string = CCStringCreateWithSize(CC_STD_ALLOCATOR, CCStringHintCopy | CCStringEncodingASCII, String, Length + Skip);
    
    CCCollectionEntry Entry = CCOrderedCollectionAppendElement(Parent->childNodes, &Node);
    
    if (Node.type == HKHubArchAssemblyASTTypeExpression)
    {
        HKHubArchAssemblyASTNode *ExpressionNode = CCCollectionGetElement(Parent->childNodes, Entry);
        CCArrayAppendElement(Parents, &ExpressionNode);
    }
    
    return Skip;
}

static void HKHubArchAssemblyParseOperand(HKHubArchAssemblyASTNode *Node)
{
#define CC_CONTAINER_TYPE_DISABLE
    CCArray(HKHubArchAssemblyASTNode *) Parents = CCArrayCreate(CC_STD_ALLOCATOR, sizeof(HKHubArchAssemblyASTNode*), 16);
#undef CC_CONTAINER_TYPE_DISABLE
    CCArrayAppendElement(Parents, &Node);
    
    CCOrderedCollection(CCString) Strings = CCStringCreateBySeparatingOccurrencesOfGroupedStrings(Node->string, (CCString[2]){ CC_STRING(" "), CC_STRING("\t") }, 2);
    
    CC_COLLECTION_FOREACH(CCString, String, Strings)
    {
        if (CCStringGetLength(String))
        {
            CC_STRING_TEMP_BUFFER(Buffer, String)
            {
                const char *Start = Buffer;
                _Bool Hex = FALSE, Sym = FALSE, Dec = FALSE, CreateNode = FALSE;
                size_t Index = 0;
                for (char c; (c = *(Buffer++)); Index++)
                {
                    if ((isalnum(c)) || (c == '_'))
                    {
                        if (!CreateNode)
                        {
                            Hex = TRUE;
                            Sym = TRUE;
                            Dec = TRUE;
                        }
                        
                        CreateNode = TRUE;
                        
                        if ((Index == 0) && (c != '0')) Hex = FALSE;
                        else if ((Index == 1) && ((c != 'x') && (c != 'X'))) Hex = FALSE;
                        
                        if ((!isxdigit(c)) && ((Index != 1) || ((c != 'x') && (c != 'X'))))
                        {
                            Hex = FALSE;
                            Dec = FALSE;
                        }
                        
                        else if (!isdigit(c))
                        {
                            Dec = FALSE;
                        }
                    }
                    
                    else
                    {
                        if (CreateNode) Buffer += HKHubArchAssemblyResolveLiteralValue(Parents, Start, (Buffer - Start) - 1, Hex, Sym, Dec, 0);
                        
                        Hex = FALSE;
                        Sym = FALSE;
                        Dec = FALSE;
                        CreateNode = FALSE;
                        Index = 0;
                        
                        Buffer += HKHubArchAssemblyResolveLiteralValue(Parents, Buffer - 1, 1, Hex, Sym, Dec, c);
                        Start = Buffer;
                    }
                }
                
                if (CreateNode) HKHubArchAssemblyResolveLiteralValue(Parents, Start, (Buffer - Start) - 1, Hex, Sym, Dec, 0);
            }
        }
    }
    
    CCCollectionDestroy(Strings);
    CCArrayDestroy(Parents);
}

static void HKHubArchAssemblyParseCommand(const char **Source, size_t *Line, HKHubArchAssemblyASTType ParentType, CCOrderedCollection(HKHubArchAssemblyASTNode) AST)
{
    HKHubArchAssemblyASTType Type = HKHubArchAssemblyASTTypeInstruction;
    const char *Symbol = NULL, *String = NULL;
    _Bool IsStr = FALSE, IsComment = FALSE, IsEscape = FALSE, IsCommand = ParentType == HKHubArchAssemblyASTTypeSource;
    for (char c = 0; (c = **Source); (*Source)++)
    {
        if (!Symbol) Symbol = *Source;
        
        if ((!IsComment) && (!IsStr) && (IsCommand) && (c == '.'))
        {
            Type = HKHubArchAssemblyASTTypeDirective;
        }
        
        else if ((!IsComment) && (!IsStr) && (IsCommand) && (c == ':'))
        {
            Type = HKHubArchAssemblyASTTypeLabel;
        }
        
        else if ((!IsComment) && (!IsStr) && (!IsCommand) && (c == '['))
        {
            HKHubArchAssemblyASTNode Node = {
                .type = HKHubArchAssemblyASTTypeMemory,
                .string = 0,
                .line = *Line,
                .childNodes = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTNode), (CCCollectionElementDestructor)HKHubArchAssemblyASTNodeDestructor)
            };
            
            (*Source)++;
            HKHubArchAssemblyParseCommand(Source, Line, Type, Node.childNodes);
            CCOrderedCollectionAppendElement(AST, &Node);
            
            Symbol = NULL;
            Type = HKHubArchAssemblyASTTypeInstruction;
            
            if (**Source == '\n') return;
        }
        
        else if ((!IsComment) && (!IsEscape) && (!IsCommand) && (c == '"'))
        {
            if (!(IsStr = !IsStr))
            {
                const size_t Length = *Source - String - 1;
                
                HKHubArchAssemblyASTNode Node = {
                    .type = HKHubArchAssemblyASTTypeString,
                    .string = CCStringCreateWithSize(CC_STD_ALLOCATOR, CCStringHintCopy | CCStringEncodingUTF8, String + 1, Length),
                    .line = *Line,
                    .childNodes = NULL
                };
                
                CCOrderedCollectionAppendElement(AST, &Node);
                
                String = NULL;
                Symbol = NULL;
            }
            
            else String = *Source;
        }
        
        else if ((!IsComment) && (!IsStr) && (((IsCommand) && (isspace(c))) || (c == '\n') || (c == ',') || ((c == '#') && (IsComment = TRUE)) || (c == ']')))
        {
            if (*Source != Symbol)
            {
                const size_t Length = (*Source - Symbol) - (Type != HKHubArchAssemblyASTTypeLabel ? 0 : 1);
                if (ParentType != HKHubArchAssemblyASTTypeSource) Type = HKHubArchAssemblyASTTypeOperand;
                
                HKHubArchAssemblyASTNode Node = {
                    .type = Type,
                    .string = CCStringCreateWithSize(CC_STD_ALLOCATOR, CCStringHintCopy | CCStringEncodingASCII, Symbol, Length),
                    .line = *Line,
                    .childNodes = NULL
                };
                
                if ((!IsComment) && (c != '\n') && ((Type == HKHubArchAssemblyASTTypeInstruction) || (Type == HKHubArchAssemblyASTTypeDirective)))
                {
                    Node.childNodes = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTNode), (CCCollectionElementDestructor)HKHubArchAssemblyASTNodeDestructor);
                    HKHubArchAssemblyParseCommand(Source, Line, Type, Node.childNodes);
                }
                
                else if (Type == HKHubArchAssemblyASTTypeOperand)
                {
                    HKHubArchAssemblyParseOperand(&Node);
                }
                
                CCOrderedCollectionAppendElement(AST, &Node);
                
                if (c == ']') return;
            }
            
            Symbol = NULL;
            Type = HKHubArchAssemblyASTTypeInstruction;
        }
        
        else if ((!IsStr) && (c == '#'))
        {
            IsComment = TRUE;
        }
        
        else if (IsEscape)
        {
            IsEscape = FALSE;
        }
        
        else if (c == '\\')
        {
            IsEscape = TRUE;
        }
        
        if (c == '\n')
        {
            Symbol = NULL;
            IsComment = FALSE;
            (*Line)++;
            
            if (ParentType != HKHubArchAssemblyASTTypeSource) return;
        }
    }
    
    if ((Symbol) && (*Symbol) && (!**Source))
    {
        const size_t Length = *Source - Symbol;
        if (ParentType != HKHubArchAssemblyASTTypeSource) Type = HKHubArchAssemblyASTTypeOperand;
        
        HKHubArchAssemblyASTNode Node = {
            .type = Type,
            .string = CCStringCreateWithSize(CC_STD_ALLOCATOR, CCStringHintCopy | CCStringEncodingASCII, Symbol, Length),
            .line = *Line,
            .childNodes = NULL
        };
        
        if (Type == HKHubArchAssemblyASTTypeOperand)
        {
            HKHubArchAssemblyParseOperand(&Node);
        }
        
        CCOrderedCollectionAppendElement(AST, &Node);
    }
}

CCOrderedCollection(HKHubArchAssemblyASTNode) HKHubArchAssemblyParse(const char *Source)
{
    CCAssertLog(Source, "Source must not be null");
    
    CCOrderedCollection(HKHubArchAssemblyASTNode) AST = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTNode), (CCCollectionElementDestructor)HKHubArchAssemblyASTNodeDestructor);
    
    HKHubArchAssemblyParseCommand(&Source, &(size_t){ 0 }, HKHubArchAssemblyASTTypeSource, AST);
    
    return AST;
}

_Bool HKHubArchAssemblyResolveSymbol(HKHubArchAssemblyASTNode *Value, uint8_t *Result, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    uint8_t *Data;
    if ((Data = CCDictionaryGetValue(Defines, &Value->string)) || (Data = CCDictionaryGetValue(Labels, &Value->string)))
    {
        *Result = *Data;
        return TRUE;
    }
    
    return FALSE;
}

#pragma mark - Error Messages

static const CCString HKHubArchAssemblyErrorMessageOperand1Symbol = CC_STRING("operand 1 should be a symbol");
static const CCString HKHubArchAssemblyErrorMessageOperand2Symbol = CC_STRING("operand 2 should be a symbol");
static const CCString HKHubArchAssemblyErrorMessageOperand1SymbolOrInteger = CC_STRING("operand 1 should be a symbol or integer");
static const CCString HKHubArchAssemblyErrorMessageOperand2SymbolOrInteger = CC_STRING("operand 2 should be a symbol or integer");
static const CCString HKHubArchAssemblyErrorMessageOperand3SymbolOrInteger = CC_STRING("operand 3 should be a symbol or integer");
static const CCString HKHubArchAssemblyErrorMessageOperandInteger = CC_STRING("operand should be an integer");
static const CCString HKHubArchAssemblyErrorMessageOperandString = CC_STRING("operand should be a string");
static const CCString HKHubArchAssemblyErrorMessageOperandResolveInteger = CC_STRING("could not resolve operand to integer");
static const CCString HKHubArchAssemblyErrorMessageOperandResolveIntegerMinusRegister = CC_STRING("cannot resolve the equation when register is to the right of the minus sign");
static const CCString HKHubArchAssemblyErrorMessageMin0Max0Operands = CC_STRING("expects no operands");
static const CCString HKHubArchAssemblyErrorMessageMin0Max2Operands = CC_STRING("expects 0 to 2 operands");
static const CCString HKHubArchAssemblyErrorMessageMin1MaxNOperands = CC_STRING("expects 1 or more operands");
static const CCString HKHubArchAssemblyErrorMessageMin1Max2Operands = CC_STRING("expects 1 to 2 operands");
static const CCString HKHubArchAssemblyErrorMessageMin2Max3Operands = CC_STRING("expects 2 to 3 operands");
static const CCString HKHubArchAssemblyErrorMessageMin1Max1Operands = CC_STRING("expects 1 operand");
static const CCString HKHubArchAssemblyErrorMessageMin2Max2Operands = CC_STRING("expects 2 operands");
static const CCString HKHubArchAssemblyErrorMessageSizeLimit = CC_STRING("exceeded size limit");
static const CCString HKHubArchAssemblyErrorMessageUnknownCommand = CC_STRING("unknown command");

#pragma mark - Directives
CCOrderedCollection(FSPath) HKHubArchAssemblyIncludeSearchPaths = NULL;
static const CCString HKHubArchAssemblyErrorMessageFile = CC_STRING("could not find file");
static const CCString HKHubArchAssemblyErrorMessageSearchPaths = CC_STRING("no include search paths specified");

static size_t HKHubArchAssemblyCompileDirectiveInclude(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    if ((Command->childNodes) && (CCCollectionGetCount(Command->childNodes) == 1))
    {
        HKHubArchAssemblyASTNode *ProcOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);

        if ((ProcOp->type == HKHubArchAssemblyASTTypeOperand) && (ProcOp->childNodes) && (CCCollectionGetCount(ProcOp->childNodes) == 1))
        {
            HKHubArchAssemblyASTNode *Proc = CCOrderedCollectionGetElementAtIndex(ProcOp->childNodes, 0);

            if (Proc->type == HKHubArchAssemblyASTTypeSymbol)
            {
                if ((HKHubArchAssemblyIncludeSearchPaths) && (CCCollectionGetCount(HKHubArchAssemblyIncludeSearchPaths)))
                {
                    _Bool Found = FALSE;
                    CC_COLLECTION_FOREACH(FSPath, SearchPath, HKHubArchAssemblyIncludeSearchPaths)
                    {
                        FSPath Path = FSPathCopy(SearchPath);
                        
                        CC_STRING_TEMP_BUFFER(Name, Proc->string) FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeFile, Name));
                        FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeExtension, "chasm"));
                        
                        if (FSManagerExists(Path))
                        {
                            Found = TRUE;
                            
                            FSHandle Handle;
                            if (FSHandleOpen(Path, FSHandleTypeRead, &Handle) == FSOperationSuccess)
                            {
                                size_t Size = FSManagerGetSize(Path);
                                char *Source;
                                CC_SAFE_Malloc(Source, sizeof(char) * (Size + 2));
                                
                                FSHandleRead(Handle, &Size, Source, FSBehaviourDefault);
                                Source[Size] = '\n';
                                Source[Size + 1] = 0;
                                
                                FSHandleClose(Handle);
                                
                                CCOrderedCollection(HKHubArchAssemblyASTNode) AST = HKHubArchAssemblyParse(Source);
                                CC_SAFE_Free(Source);
                                
                                Offset = HKHubArchAssemblyCompile(Offset, Binary, AST, Errors, Labels, Defines, !Binary);
                                
                                if (Command->string) CCStringDestroy(Command->string);
                                if (Command->childNodes) CCCollectionDestroy(Command->childNodes);
                                
                                Command->type = HKHubArchAssemblyASTTypeAST;
                                Command->string = 0;
                                Command->childNodes = AST;
                            }
                            
                            else
                            {
                                CC_LOG_ERROR("Could not open file (%s)", FSPathGetPathString(Path));
                                
                                CCString File = CCStringCreate(CC_STD_ALLOCATOR, 0, FSPathGetPathString(Path));
                                CCString ErrMsg = CCStringCreateByJoiningStrings((CCString[]){
                                    CC_STRING("unable to open file ("),
                                    File,
                                    CC_STRING(")")
                                }, 3, 0);
                                
                                CCStringDestroy(File);
                                
                                HKHubArchAssemblyErrorAddMessage(Errors, ErrMsg, Command, ProcOp, Proc);
                            }
                            
                            FSPathDestroy(Path);
                            
                            break;
                        }
                        
                        FSPathDestroy(Path);
                    }
                    
                    if (!Found)
                    {
                        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageFile, Command, ProcOp, Proc);
                    }
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageSearchPaths, Command, ProcOp, Proc);
                }
            }

            else
            {
                HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, ProcOp, Proc);
            }
        }

        else
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, ProcOp, NULL);
        }
    }

    else
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin1Max1Operands, Command, NULL, NULL);
    }
    
    return Offset;
}

static const CCString HKHubArchAssemblyErrorAssertion = CC_STRING("assertion failed");

static size_t HKHubArchAssemblyCompileDirectiveAssert(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    const size_t Count = CCCollectionGetCount(Command->childNodes);
    if ((Command->childNodes) && (Count >= 1) && (Count <= 2))
    {
        HKHubArchAssemblyASTNode *ExpressionOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
        
        if ((ExpressionOp->type == HKHubArchAssemblyASTTypeOperand) && (ExpressionOp->childNodes))
        {
            HKHubArchAssemblyASTNode *ExpressionOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
            
            uint8_t Result;
            if (HKHubArchAssemblyResolveInteger(Offset, &Result, Command, ExpressionOp, Errors, Labels, Defines, NULL))
            {
                if (!Result)
                {
                    CCString Message = HKHubArchAssemblyErrorAssertion;
                    if (Count == 2)
                    {
                        HKHubArchAssemblyASTNode *MessageOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
                        
                        if (MessageOp->type == HKHubArchAssemblyASTTypeString)
                        {
                            Message = CCStringCreateByJoiningStrings((CCString[2]){ HKHubArchAssemblyErrorAssertion, MessageOp->string }, 2, CC_STRING(": "));
                        }
                        
                        else
                        {
                            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandString, Command, MessageOp, NULL);
                        }
                    }
                    
                    HKHubArchAssemblyErrorAddMessage(Errors, Message, Command, ExpressionOp, NULL);
                }
            }
        }
        
        else
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandInteger, Command, ExpressionOp, NULL);
        }
    }
    
    else
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin1Max2Operands, Command, NULL, NULL);
    }
    
    return Offset;
}

static size_t HKHubArchAssemblyCompileDirectivePort(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    const size_t Count = CCCollectionGetCount(Command->childNodes);
    if ((Command->childNodes) && (Count >= 2) && (Count <= 3))
    {
        HKHubArchAssemblyASTNode *NameOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
        
        if ((NameOp->type == HKHubArchAssemblyASTTypeOperand) && (NameOp->childNodes) && (CCCollectionGetCount(NameOp->childNodes) == 1))
        {
            HKHubArchAssemblyASTNode *PortOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
            
            if ((PortOp->type == HKHubArchAssemblyASTTypeOperand) && (PortOp->childNodes) && (CCCollectionGetCount(PortOp->childNodes) >= 1))
            {
                HKHubArchAssemblyASTNode *Name = CCOrderedCollectionGetElementAtIndex(NameOp->childNodes, 0);
                
                if (Name->type == HKHubArchAssemblyASTTypeSymbol)
                {
                    uint8_t Port;
                    if (HKHubArchAssemblyResolveInteger(Offset, &Port, Command, PortOp, Errors, Labels, Defines, NULL))
                    {
                        CCDictionarySetValue(Defines, &Name->string, &Port);
                        
                        uint8_t PortCount = 1;
                        
                        if (Count == 3)
                        {
                            HKHubArchAssemblyASTNode *PortCountOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 2);
                            
                            if ((PortCountOp->type == HKHubArchAssemblyASTTypeOperand) && (PortCountOp->childNodes) && (CCCollectionGetCount(PortCountOp->childNodes) >= 1))
                            {
                                if (!HKHubArchAssemblyResolveInteger(Offset, &PortCount, Command, PortCountOp, Errors, Labels, Defines, NULL))
                                {
                                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, PortCountOp, NULL);
                                    PortCount = 0;
                                }
                            }
                            
                            else
                            {
                                HKHubArchAssemblyErrorAddMessage(Errors,HKHubArchAssemblyErrorMessageOperand3SymbolOrInteger, Command, PortCountOp, NULL);
                            }
                        }
                        
                        if ((PortCount) && (Binary))
                        {
                            _Bool RegisterPort = TRUE;
                            const uint8_t LastPort = Port + PortCount - 1;
                            CC_COLLECTION_FOREACH_PTR(HKHubArchBinaryNamedPort, NamedPort, Binary->namedPorts)
                            {
                                const uint8_t LastNamedPort = NamedPort->start + NamedPort->count - 1;
                                if (((Port >= NamedPort->start) || (LastPort >= NamedPort->start)) && ((Port <= LastNamedPort) || (LastPort <= LastNamedPort)))
                                {
                                    RegisterPort = FALSE;
                                    
                                    if (CCStringEqual(Name->string, NamedPort->name))
                                    {
                                        NamedPort->start = Port;
                                        NamedPort->count = PortCount;
                                    }
                                    
                                    else
                                    {
                                        CCString Message = CCStringCreateByJoiningStrings((CCString[5]){
                                            CC_STRING("mapping for port '"),
                                            Name->string,
                                            CC_STRING("' overlaps pre-existing mapping on port '"),
                                            NamedPort->name,
                                            CC_STRING("'")
                                        }, 5, 0);
                                        
                                        HKHubArchAssemblyErrorAddMessage(Errors, Message, Command, NULL, NULL);
                                    }
                                }
                            }
                            
                            if (RegisterPort)
                            {
                                CCCollectionInsertElement(Binary->namedPorts, &(HKHubArchBinaryNamedPort){
                                    .name = CCStringCopy(Name->string),
                                    .start = Port,
                                    .count = PortCount
                                });
                            }
                        }
                    }
                    
                    else
                    {
                        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, PortOp, NULL);
                    }
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, NameOp, Name);
                }
            }
            
            else
            {
                HKHubArchAssemblyErrorAddMessage(Errors,HKHubArchAssemblyErrorMessageOperand2SymbolOrInteger, Command, PortOp, NULL);
            }
        }
        
        else
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, NameOp, NULL);
        }
    }
    
    else
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin2Max3Operands, Command, NULL, NULL);
    }
    
    return Offset;
}

static size_t HKHubArchAssemblyCompileDirectiveDefine(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    if ((Command->childNodes) && (CCCollectionGetCount(Command->childNodes) == 2))
    {
        HKHubArchAssemblyASTNode *NameOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 0);
        
        if ((NameOp->type == HKHubArchAssemblyASTTypeOperand) && (NameOp->childNodes) && (CCCollectionGetCount(NameOp->childNodes) == 1))
        {
            HKHubArchAssemblyASTNode *AliasOp = CCOrderedCollectionGetElementAtIndex(Command->childNodes, 1);
            
            if ((AliasOp->type == HKHubArchAssemblyASTTypeOperand) && (AliasOp->childNodes) && (CCCollectionGetCount(AliasOp->childNodes) >= 1))
            {
                HKHubArchAssemblyASTNode *Name = CCOrderedCollectionGetElementAtIndex(NameOp->childNodes, 0);
                
                if (Name->type == HKHubArchAssemblyASTTypeSymbol)
                {
                    uint8_t Result;
                    if (HKHubArchAssemblyResolveInteger(Offset, &Result, Command, AliasOp, Errors, Labels, Defines, NULL))
                    {
                        CCDictionarySetValue(Defines, &Name->string, &Result);
                    }
                    
                    else
                    {
                        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, AliasOp, NULL);
                    }
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, NameOp, Name);
                }
            }
            
            else
            {
                HKHubArchAssemblyErrorAddMessage(Errors,HKHubArchAssemblyErrorMessageOperand2SymbolOrInteger, Command, AliasOp, NULL);
            }
        }
        
        else
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperand1Symbol, Command, NameOp, NULL);
        }
    }
    
    else
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin2Max2Operands, Command, NULL, NULL);
    }
    
    return Offset;
}

static size_t HKHubArchAssemblyCompileDirectiveByte(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    if (Command->childNodes)
    {
        if (!Binary) return Offset + CCCollectionGetCount(Command->childNodes);
        
        CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Operand, Command->childNodes)
        {
            if ((Operand->type == HKHubArchAssemblyASTTypeOperand) && (Operand->childNodes))
            {
                HKHubArchAssemblyResolveInteger(Offset, &Binary->data[Offset], Command, Operand, Errors, Labels, Defines, NULL);
            }
            
            else
            {
                HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandInteger, Command, Operand, NULL);
            }
            
            Offset++;
        }
    }
    
    else
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin1MaxNOperands, Command, NULL, NULL);
    }
    
    return Offset;
}

static size_t HKHubArchAssemblyCompileDirectiveEntrypoint(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    if ((Command->childNodes) && (CCCollectionGetCount(Command->childNodes)))
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin0Max0Operands, Command, NULL, NULL);
    }
    
    else if (Binary) Binary->entrypoint = Offset;
    
    return Offset;
}

static size_t HKHubArchAssemblyCompileDirectiveBreakRW(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines)
{
    size_t Count = 0;
    if ((Command->childNodes) && ((Count = CCCollectionGetCount(Command->childNodes)) > 2))
    {
        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageMin0Max2Operands, Command, NULL, NULL);
    }
    
    else if (Binary)
    {
        uint8_t Args[2] = { Offset, 1 };
        
        if (Count)
        {
            size_t Index = 0;
            CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Operand, Command->childNodes)
            {
                if ((Operand->type == HKHubArchAssemblyASTTypeOperand) && (Operand->childNodes))
                {
                    HKHubArchAssemblyResolveInteger(Offset, &Args[Index++], Command, Operand, Errors, Labels, Defines, NULL);
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandInteger, Command, Operand, NULL);
                }
            }
        }
        
        for (size_t Loop = 0; Loop < Args[1]; Loop++)
        {
            CCArrayAppendElement(Binary->presetBreakpoints, &(uint8_t){ Args[0] + Loop });
        }
    }
    
    return Offset;
}

#pragma mark -

static const struct {
    CCString mnemonic;
    size_t (*compile)(size_t, HKHubArchBinary, HKHubArchAssemblyASTNode *, CCOrderedCollection, CCDictionary, CCDictionary);
} Directives[] = {
    { CC_STRING(".define"), HKHubArchAssemblyCompileDirectiveDefine },
    { CC_STRING(".byte"), HKHubArchAssemblyCompileDirectiveByte },
    { CC_STRING(".entrypoint"), HKHubArchAssemblyCompileDirectiveEntrypoint },
    { CC_STRING(".include"), HKHubArchAssemblyCompileDirectiveInclude },
    { CC_STRING(".assert"), HKHubArchAssemblyCompileDirectiveAssert },
    { CC_STRING(".port"), HKHubArchAssemblyCompileDirectivePort },
    { CC_STRING(".break"), HKHubArchAssemblyCompileDirectiveBreakRW }
};

static uint8_t HKHubArchAssemblyResolveEquation(uint8_t Left, uint8_t Right, CCArray(HKHubArchAssemblyASTType) Modifiers, HKHubArchAssemblyASTType Operation)
{
    for (size_t Loop = 0, Count = CCArrayGetCount(Modifiers); Loop < Count; Loop++)
    {
        switch (*(HKHubArchAssemblyASTType*)CCArrayGetElementAtIndex(Modifiers, Loop))
        {
            case HKHubArchAssemblyASTTypeMinus:
                Right = -Right;
                break;
                
            case HKHubArchAssemblyASTTypeNot:
                Right = !Right;
                break;
                
            case HKHubArchAssemblyASTTypeOnesComplement:
                Right = ~Right;
                break;
                
            default:
                break;
        }
    }
    
    switch (Operation)
    {
        case HKHubArchAssemblyASTTypeMultiply:
            return Left * Right;
            
        case HKHubArchAssemblyASTTypeDivide:
            return Left / Right;
            
        case HKHubArchAssemblyASTTypeModulo:
            return Left % Right;
            
        case HKHubArchAssemblyASTTypeShiftLeft:
            return Left << Right;
            
        case HKHubArchAssemblyASTTypeShiftRight:
            return Left >> Right;
            
        case HKHubArchAssemblyASTTypeBitwiseAnd:
            return Left & Right;
            
        case HKHubArchAssemblyASTTypeBitwiseOr:
            return Left | Right;
            
        case HKHubArchAssemblyASTTypeBitwiseXor:
            return Left ^ Right;
            
        case HKHubArchAssemblyASTTypeLogicalAnd:
            return Left && Right;
            
        case HKHubArchAssemblyASTTypeLogicalOr:
            return Left || Right;
            
        case HKHubArchAssemblyASTTypeEqual:
            return Left == Right;
            
        case HKHubArchAssemblyASTTypeNotEqual:
            return Left != Right;
            
        case HKHubArchAssemblyASTTypeLessThan:
            return Left < Right;
            
        case HKHubArchAssemblyASTTypeLessThanOrEqual:
            return Left <= Right;
            
        case HKHubArchAssemblyASTTypeGreaterThan:
            return Left > Right;
            
        case HKHubArchAssemblyASTTypeGreaterThanOrEqual:
            return Left >= Right;
            
        default:
            return Left + Right;
    }
}

_Bool HKHubArchAssemblyResolveInteger(size_t Offset, uint8_t *Result, HKHubArchAssemblyASTNode *Command, HKHubArchAssemblyASTNode *Operand, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines, CCDictionary(CCString, uint8_t) Variables)
{
    uint8_t Byte = 0;
    _Bool ConstantOnly = FALSE, Success = TRUE;
    HKHubArchAssemblyASTType Operation = HKHubArchAssemblyASTTypeUnknown;
    CCArray(HKHubArchAssemblyASTType) Modifiers = CCArrayCreate(CC_STD_ALLOCATOR, sizeof(HKHubArchAssemblyASTType), 16);
    
    CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Value, Operand->childNodes)
    {
        switch (Value->type)
        {
            case HKHubArchAssemblyASTTypeInteger:
                Byte = HKHubArchAssemblyResolveEquation(Byte, Value->integer.value, Modifiers, Operation);
                CCArrayRemoveAllElements(Modifiers);
                ConstantOnly = FALSE;
                Operation = HKHubArchAssemblyASTTypeUnknown;
                break;
                
            case HKHubArchAssemblyASTTypeOffset:
                Byte = HKHubArchAssemblyResolveEquation(Byte, Offset, Modifiers, Operation);
                CCArrayRemoveAllElements(Modifiers);
                ConstantOnly = FALSE;
                Operation = HKHubArchAssemblyASTTypeUnknown;
                break;
                
            case HKHubArchAssemblyASTTypeMinus:
            case HKHubArchAssemblyASTTypeNot:
            case HKHubArchAssemblyASTTypeOnesComplement:
                ConstantOnly = TRUE;
            case HKHubArchAssemblyASTTypePlus:
                CCArrayAppendElement(Modifiers, &Value->type);
                break;
                
            case HKHubArchAssemblyASTTypeMultiply:
            case HKHubArchAssemblyASTTypeDivide:
            case HKHubArchAssemblyASTTypeModulo:
            case HKHubArchAssemblyASTTypeShiftLeft:
            case HKHubArchAssemblyASTTypeShiftRight:
            case HKHubArchAssemblyASTTypeBitwiseAnd:
            case HKHubArchAssemblyASTTypeBitwiseOr:
            case HKHubArchAssemblyASTTypeBitwiseXor:
            case HKHubArchAssemblyASTTypeLogicalAnd:
            case HKHubArchAssemblyASTTypeLogicalOr:
            case HKHubArchAssemblyASTTypeEqual:
            case HKHubArchAssemblyASTTypeNotEqual:
            case HKHubArchAssemblyASTTypeLessThan:
            case HKHubArchAssemblyASTTypeLessThanOrEqual:
            case HKHubArchAssemblyASTTypeGreaterThan:
            case HKHubArchAssemblyASTTypeGreaterThanOrEqual:
            {
                ConstantOnly = TRUE;
                
                if (Operation == HKHubArchAssemblyASTTypeUnknown)
                {
                    Operation = Value->type;
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, Operand, Value);
                    Success = FALSE;
                }
                break;
            }
                
            case HKHubArchAssemblyASTTypeSymbol:
            {
                uint8_t ResolvedValue;
                if ((Variables) && (CCDictionaryFindKey(Variables, &Value->string)))
                {
                    if (ConstantOnly)
                    {
                        HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveIntegerMinusRegister, Command, Operand, Value);
                        Success = FALSE;
                    }
                }
                
                else if (HKHubArchAssemblyResolveSymbol(Value, &ResolvedValue, Labels, Defines))
                {
                    Byte = HKHubArchAssemblyResolveEquation(Byte, ResolvedValue, Modifiers, Operation);
                    CCArrayRemoveAllElements(Modifiers);
                    ConstantOnly = FALSE;
                    Operation = HKHubArchAssemblyASTTypeUnknown;
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, Operand, Value);
                    Success = FALSE;
                }
                break;
            }
                
            case HKHubArchAssemblyASTTypeExpression:
            {
                uint8_t ResolvedValue;
                if (HKHubArchAssemblyResolveInteger(Offset, &ResolvedValue, Command, Value, Errors, Labels, Defines, Variables))
                {
                    Byte = HKHubArchAssemblyResolveEquation(Byte, ResolvedValue, Modifiers, Operation);
                    CCArrayRemoveAllElements(Modifiers);
                    ConstantOnly = FALSE;
                    Operation = HKHubArchAssemblyASTTypeUnknown;
                }
                
                else
                {
                    HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, Operand, Value);
                    Success = FALSE;
                }
                break;
            }
                
            default:
                HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageOperandResolveInteger, Command, Operand, Value);
                Success = FALSE;
                break;
        }
    }
    
    CCArrayDestroy(Modifiers);
    
    if (Result) *Result = Byte;
    
    return Success;
}

static size_t HKHubArchAssemblyCompile(size_t Offset, HKHubArchBinary Binary, CCOrderedCollection(HKHubArchAssemblyASTNode) AST, CCOrderedCollection(HKHubArchAssemblyASTError) Errors, CCDictionary(CCString, uint8_t) Labels, CCDictionary(CCString, uint8_t) Defines, int Pass)
{
    CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Command, AST)
    {
        switch (Command->type)
        {
            case HKHubArchAssemblyASTTypeLabel:
                CCDictionarySetValue(Labels, &Command->string, &Offset);
                break;
                
            case HKHubArchAssemblyASTTypeInstruction:
                Offset = HKHubArchInstructionEncode(Offset, (Pass ? NULL : Binary->data), Command, (Pass ? NULL : Errors), Labels, Defines);
                break;
                
            case HKHubArchAssemblyASTTypeDirective:
                for (size_t Loop = 0; Loop < sizeof(Directives) / sizeof(typeof(*Directives)); Loop++) //TODO: make dictionary
                {
                    if (CCStringEqual(Directives[Loop].mnemonic, Command->string))
                    {
                        Offset = Directives[Loop].compile(Offset, (Pass ? NULL : Binary), Command, (Pass ? NULL : Errors), Labels, Defines);
                        break;
                    }
                }
                break;
                
            case HKHubArchAssemblyASTTypeAST:
                Offset = HKHubArchAssemblyCompile(Offset, Binary, Command->childNodes, Errors, Labels, Defines, Pass);
                break;
                
            default:
                HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageUnknownCommand, Command, NULL, NULL);
                break;
        }
        
        if (Offset > sizeof(Binary->data))
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchAssemblyErrorMessageSizeLimit, Command, NULL, NULL);
            Pass = 0;
            break;
        }
    }
    
    return Offset;
}

static void HKHubArchAssemblyASTErrorDestructor(void *Container, HKHubArchAssemblyASTError *Error)
{
    if (Error->message) CCStringDestroy(Error->message);
}

HKHubArchBinary HKHubArchAssemblyCreateBinary(CCAllocatorType Allocator, CCOrderedCollection(HKHubArchAssemblyASTNode) AST, CCOrderedCollection(HKHubArchAssemblyASTError) *Errors)
{
    CCAssertLog(AST, "AST must not be null");
    
    HKHubArchBinary Binary = HKHubArchBinaryCreate(Allocator);
    
    CCDictionary(CCString, uint8_t) Labels = CCDictionaryCreate(CC_STD_ALLOCATOR, CCDictionaryHintSizeSmall, sizeof(CCString), sizeof(uint8_t), &(CCDictionaryCallbacks){
        .getHash = CCStringHasherForDictionary,
        .compareKeys = CCStringComparatorForDictionary
    });
    
    CCOrderedCollection(HKHubArchAssemblyASTError) Err = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintOrdered, sizeof(HKHubArchAssemblyASTError), (CCCollectionElementDestructor)HKHubArchAssemblyASTErrorDestructor);
    
    for (int Pass = 1; Pass >= 0; Pass--)
    {
        CCDictionary(CCString, uint8_t) Defines = CCDictionaryCreate(CC_STD_ALLOCATOR, CCDictionaryHintSizeSmall, sizeof(CCString), sizeof(uint8_t), &(CCDictionaryCallbacks){
            .getHash = CCStringHasherForDictionary,
            .compareKeys = CCStringComparatorForDictionary
        });
        
        HKHubArchAssemblyCompile(0, Binary, AST, Err, Labels, Defines, Pass);
        
        CCDictionaryDestroy(Defines);
    }
    
    CCDictionaryDestroy(Labels);
    
    if (CCCollectionGetCount(Err))
    {
        HKHubArchBinaryDestroy(Binary);
        Binary = NULL;
        
        if (Errors) *Errors = Err;
        else CCCollectionDestroy(Err);
    }
    
    else CCCollectionDestroy(Err);
    
    return Binary;
}

static void HKHubArchAssemblyPrintASTNodes(CCOrderedCollection(HKHubArchAssemblyASTNode) AST)
{
    if (!AST) return;
    
    size_t Line = 0;
    _Bool First = TRUE;
    CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Node, AST)
    {
        if (Line != Node->line)
        {
            if (!First) printf("\n");
            
            Line = Node->line;
            First = TRUE;
        }
        
        static const char *Types[] = {
            "source",
            "ast",
            "unknown",
            "instruction",
            "directive",
            "label",
            "string",
            "integer",
            "register",
            "memory",
            "expression",
            "operand",
            "symbol",
            "plus",
            "minus",
            "multiply",
            "divide",
            "modulo",
            "not",
            "ones_complement",
            "shift_left",
            "shift_right",
            "bitwise_and",
            "bitwise_or",
            "bitwise_xor",
            "logical_and",
            "logical_or",
            "equal",
            "not_equal",
            "less_than",
            "less_than_or_equal",
            "greater_than",
            "greater_than_or_equal",
            "offset"
        };
        
        if (!First) printf(", ");
        
        printf("%s", Types[Node->type]);
        
        if (Node->string)
        {
            CC_STRING_TEMP_BUFFER(Buffer, Node->string)
            {
                printf("<%s>", Buffer);
            }
        }
        
        printf("(");
        
        HKHubArchAssemblyPrintASTNodes(Node->childNodes);
        
        printf(")");
        
        First = FALSE;
    }
}

void HKHubArchAssemblyPrintAST(CCOrderedCollection(HKHubArchAssemblyASTNode) AST)
{
    HKHubArchAssemblyPrintASTNodes(AST);
    printf("\n");
}

void HKHubArchAssemblyPrintError(CCOrderedCollection(HKHubArchAssemblyASTError) Errors)
{
    if (!Errors) return;
    
    CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTError, Error, Errors)
    {
        CCString Focus = (Error->value ? Error->value->string : (Error->operand ? Error->operand->string : Error->command->string));
        CC_LOG_DEBUG_CUSTOM("Line %zu:%S: %S", Error->command->line, Error->message, Focus);
    }
}
