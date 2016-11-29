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

#include "HubArchInstruction.h"


#pragma mark Instructions

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationMOV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationADD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSUB(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationMUL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSDIV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationUDIV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSMOD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationUMOD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationCMP(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSHL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSHR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationXOR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationOR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationAND(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationNOT(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationHLT(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSEND(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationRECV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJMP(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJZ(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNZ(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJS(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNS(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJO(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNO(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSGE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSLE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSG(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUGE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJULE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);
static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUG(HKHubArchProcessor Processor, const HKHubArchInstructionState *State);


static const struct {
    CCString mnemonic;
    HKHubArchInstructionOperation operation;
    HKHubArchInstructionOperand operands[3];
} Instructions[64] = {
    { CC_STRING("add")     , HKHubArchInstructionOperationADD,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("add")     , HKHubArchInstructionOperationADD,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("mov")     , HKHubArchInstructionOperationMOV,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jz")      , HKHubArchInstructionOperationJZ,   { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")     , HKHubArchInstructionOperationSUB,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")     , HKHubArchInstructionOperationSUB,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("mov")     , HKHubArchInstructionOperationMOV,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("jnz")     , HKHubArchInstructionOperationJNZ,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")     , HKHubArchInstructionOperationMUL,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")     , HKHubArchInstructionOperationMUL,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("js")      , HKHubArchInstructionOperationJS,   { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")    , HKHubArchInstructionOperationSDIV, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")    , HKHubArchInstructionOperationSDIV, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jns")     , HKHubArchInstructionOperationJNS,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")    , HKHubArchInstructionOperationUDIV, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")    , HKHubArchInstructionOperationUDIV, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jo")      , HKHubArchInstructionOperationJO,   { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")    , HKHubArchInstructionOperationSMOD, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")    , HKHubArchInstructionOperationSMOD, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jno")     , HKHubArchInstructionOperationJNO,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")    , HKHubArchInstructionOperationUMOD, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")    , HKHubArchInstructionOperationUMOD, { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandR,   HKHubArchInstructionOperandM  } },
    { CC_STRING("cmp")     , HKHubArchInstructionOperationCMP,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("cmp")     , HKHubArchInstructionOperationCMP,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")     , HKHubArchInstructionOperationSHL,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")     , HKHubArchInstructionOperationSHL,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandR,   HKHubArchInstructionOperandM  } },
    { CC_STRING("shr")     , HKHubArchInstructionOperationSHR,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shr")     , HKHubArchInstructionOperationSHR,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("recv")    , HKHubArchInstructionOperationRECV, { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,   HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")     , HKHubArchInstructionOperationXOR,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")     , HKHubArchInstructionOperationXOR,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM  } },
    { CC_STRING("or")      , HKHubArchInstructionOperationOR,   { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("or")      , HKHubArchInstructionOperationOR,   { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                    , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("and")     , HKHubArchInstructionOperationAND,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("and")     , HKHubArchInstructionOperationAND,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("not")     , HKHubArchInstructionOperationNOT,  { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("hlt")     , HKHubArchInstructionOperationHLT,  { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsl")     , HKHubArchInstructionOperationJSL,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsge")    , HKHubArchInstructionOperationJSGE, { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsle")    , HKHubArchInstructionOperationJSLE, { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsg")     , HKHubArchInstructionOperationJSG,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jul")     , HKHubArchInstructionOperationJUL,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("juge")    , HKHubArchInstructionOperationJUGE, { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jule")    , HKHubArchInstructionOperationJULE, { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jug")     , HKHubArchInstructionOperationJUG,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")    , HKHubArchInstructionOperationSEND, { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM  } },
    { CC_STRING("recv")    , HKHubArchInstructionOperationRECV, { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,   HKHubArchInstructionOperandNA } },
    { CC_STRING("nop")     , NULL,                              { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jmp")     , HKHubArchInstructionOperationJMP,  { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } }
};

static const struct {
    CCString mnemonic;
    uint8_t encoding;
} Registers[6] = {
    { CC_STRING("r0"),      HKHubArchInstructionRegisterR0 },
    { CC_STRING("r1"),      HKHubArchInstructionRegisterR1 },
    { CC_STRING("r2"),      HKHubArchInstructionRegisterR2 },
    { CC_STRING("r3"),      HKHubArchInstructionRegisterR3 },
    { CC_STRING("flags"),   HKHubArchInstructionRegisterFlags },
    { CC_STRING("pc"),      HKHubArchInstructionRegisterPC },
};

#pragma mark - Error Messages

static const CCString HKHubArchInstructionErrorMessageUnknownMnemonic = CC_STRING("no instruction with name available");
static const CCString HKHubArchInstructionErrorMessageUnknownOperands = CC_STRING("incorrect operands");
static const CCString HKHubArchInstructionErrorMessageMin0Max3Operands = CC_STRING("expects 0 to 3 operands");
static const CCString HKHubArchInstructionErrorMessageResolveOperand = CC_STRING("unknown operand");
static const CCString HKHubArchInstructionErrorMessageMemoryRegister = CC_STRING("only general purpose registers r0, r1, r2, r3 may be used as memory references");
static const CCString HKHubArchInstructionErrorMessageMin0Max2MemoryRegister = CC_STRING("expects 0 to 2 registers");
static const CCString HKHubArchInstructionErrorMessageMemoryAdditionOnly = CC_STRING("addition is the only arithmetic operation available for 2 register memory references");

#pragma mark -

static HKHubArchInstructionOperand HKHubArchInstructionResolveOperand(HKHubArchAssemblyASTNode *Operand, CCOrderedCollection Errors, CCDictionary Labels, CCDictionary Defines)
{
    if (Operand->type == HKHubArchAssemblyASTTypeMemory) return HKHubArchInstructionOperandM;
    
    if (Operand->childNodes)
    {
        const size_t Count = CCCollectionGetCount(Operand->childNodes);
        if (Count == 1)
        {
            HKHubArchAssemblyASTNode *Value = CCOrderedCollectionGetElementAtIndex(Operand->childNodes, 0);
            if (Value->type == HKHubArchAssemblyASTTypeInteger) return HKHubArchInstructionOperandI;
            else if (Value->type == HKHubArchAssemblyASTTypeSymbol)
            {
                HKHubArchAssemblyASTNode **Symbol = CCDictionaryGetValue(Defines, &Value->string);
                if (Symbol) Value = *Symbol;
                
                for (size_t Loop = 0; Loop < sizeof(Registers) / sizeof(typeof(*Registers)); Loop++) //TODO: make dictionary
                {
                    if (CCStringEqual(Registers[Loop].mnemonic, Value->string)) return HKHubArchInstructionOperandR;
                }
                
                if ((Value->type == HKHubArchAssemblyASTTypeInteger) || (Value->type == HKHubArchAssemblyASTTypeSymbol)) return HKHubArchInstructionOperandI; //assume is label or literal value
            }
        }
        
        else if (Count > 1) return HKHubArchInstructionOperandI;
    }
    
    return HKHubArchInstructionOperandNA;
}

size_t HKHubArchInstructionEncode(size_t Offset, uint8_t Data[256], HKHubArchAssemblyASTNode *Command, CCOrderedCollection Errors, CCDictionary Labels, CCDictionary Defines)
{
    CCAssertLog(Command, "Command must not be null");
    
    HKHubArchInstructionOperand Operands[3] = { HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA };
    if (Command->childNodes)
    {
        if (CCCollectionGetCount(Command->childNodes) <= 3)
        {
            size_t Index = 0;
            CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Operand, Command->childNodes)
            {
                Operands[Index] = HKHubArchInstructionResolveOperand(Operand, Errors, Labels, Defines);
                Index++;
            }
        }
        
        else
        {
            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageMin0Max3Operands, Command, NULL, NULL);
            
            return Offset;
        }
    }
    
    CCString FoundErr = HKHubArchInstructionErrorMessageUnknownMnemonic;
    for (size_t Loop = 0; Loop < sizeof(Instructions) / sizeof(typeof(*Instructions)); Loop++) //TODO: make dictionary
    {
        if ((Instructions[Loop].mnemonic) && (CCStringEqual(Instructions[Loop].mnemonic, Command->string)))
        {
            FoundErr = HKHubArchInstructionErrorMessageUnknownOperands;
            
            if ((Instructions[Loop].operands[0] & Operands[0]) && (Instructions[Loop].operands[1] & Operands[1]) && (Instructions[Loop].operands[2] & Operands[2]))
            {
                size_t Count = 0, BitCount = 6;
                uint8_t Bytes[5] = { Loop << 2, 0, 0, 0, 0 };
                
                for (size_t Index = 0; Index < 3; Index++)
                {
                    size_t FreeBits = 8 - (BitCount % 8);
                    if (Operands[Index] & HKHubArchInstructionOperandI)
                    {
                        HKHubArchAssemblyASTNode *Op = CCOrderedCollectionGetElementAtIndex(Command->childNodes, Index);
                        if (Op->childNodes)
                        {
                            uint8_t Result;
                            if (HKHubArchAssemblyResolveInteger(Offset, &Result, Command, Op, Errors, Labels, Defines))
                            {
                                if (Instructions[Loop].operands[Index] == HKHubArchInstructionOperandRel) Result -= Offset;
                                
                                Bytes[Count++] |= Result >> (8 - FreeBits);
                                Bytes[Count] = (Result & CCBitSet(8 - FreeBits)) << FreeBits;
                            }
                            
                            else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Op, NULL);
                        }
                        
                        else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Op, NULL);
                        
                        BitCount += 8;
                    }
                    
                    else if (Operands[Index] & HKHubArchInstructionOperandR)
                    {
                        HKHubArchAssemblyASTNode *Op = CCOrderedCollectionGetElementAtIndex(Command->childNodes, Index);
                        if ((Op->childNodes) && (CCCollectionGetCount(Op->childNodes) == 1))
                        {
                            HKHubArchAssemblyASTNode *Value = CCOrderedCollectionGetElementAtIndex(Op->childNodes, 0);
                            for (size_t Loop = 0; Loop < sizeof(Registers) / sizeof(typeof(*Registers)); Loop++) //TODO: make dictionary
                            {
                                if (CCStringEqual(Registers[Loop].mnemonic, Value->string))
                                {
                                    if (FreeBits <= 3)
                                    {
                                        Bytes[Count++] |= Registers[Loop].encoding >> (3 - FreeBits);
                                        Bytes[Count] = (Registers[Loop].encoding & CCBitSet(3 - FreeBits)) << (8 - (3 - FreeBits));
                                    }
                                    
                                    else Bytes[Count] |= (Registers[Loop].encoding & CCBitSet(FreeBits)) << (FreeBits - 3);
                                    break;
                                }
                            }
                        }
                        
                        else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Op, NULL);
                        
                        BitCount += 3;
                    }
                    
                    else if (Operands[Index] & HKHubArchInstructionOperandM)
                    {
                        HKHubArchAssemblyASTNode *Memory = CCOrderedCollectionGetElementAtIndex(Command->childNodes, Index);
                        if ((Memory->childNodes) && (CCCollectionGetCount(Memory->childNodes) == 1))
                        {
                            HKHubArchAssemblyASTNode *Op = CCOrderedCollectionGetElementAtIndex(Memory->childNodes, 0);
                            
                            if (Op->childNodes)
                            {
                                size_t RegIndex = 0;
                                uint8_t Regs[2] = { HKHubArchInstructionRegisterGeneralPurpose, HKHubArchInstructionRegisterGeneralPurpose };
                                
                                CC_COLLECTION_FOREACH_PTR(HKHubArchAssemblyASTNode, Value, Op->childNodes)
                                {
                                    for (size_t Loop = 0; Loop < sizeof(Registers) / sizeof(typeof(*Registers)); Loop++) //TODO: make dictionary
                                    {
                                        if (CCStringEqual(Registers[Loop].mnemonic, Value->string))
                                        {
                                            if (RegIndex < 2)
                                            {
                                                Regs[RegIndex] = Registers[Loop].encoding;
                                            }
                                            
                                            RegIndex++;
                                            break;
                                        }
                                    }
                                }
                                
                                if ((Regs[0] & HKHubArchInstructionRegisterGeneralPurpose) && (Regs[1] & HKHubArchInstructionRegisterGeneralPurpose))
                                {
                                    /*
                                     0000 iiiiiiii - Immediate address
                                     0001 rr - Register address (r0 - r3)
                                     0010 iiiiiiii rr - Immediate + Register address (r0 - r3)
                                     0011 rr rr - Register + Register address (r0 - r3)
                                     */
                                    switch (RegIndex)
                                    {
                                        case 0: //integer
                                        {
                                            uint8_t MemoryType = HKHubArchInstructionMemoryOffset;
                                            if (FreeBits <= 4)
                                            {
                                                Bytes[Count++] |= MemoryType >> (4 - FreeBits);
                                                Bytes[Count] = (MemoryType & CCBitSet(4 - FreeBits)) << (8 - (4 - FreeBits));
                                            }
                                            
                                            else Bytes[Count] |= (MemoryType & CCBitSet(FreeBits)) << (FreeBits - 4);
                                            
                                            BitCount += 4;
                                            FreeBits = 8 - (BitCount % 8);
                                            
                                            uint8_t Result;
                                            if (HKHubArchAssemblyResolveInteger(Offset, &Result, Command, Op, Errors, Labels, Defines))
                                            {
                                                Bytes[Count++] |= Result >> (8 - FreeBits);
                                                Bytes[Count] = (Result & CCBitSet(8 - FreeBits)) << FreeBits;
                                            }
                                            
                                            else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Op, NULL);
                                            
                                            BitCount += 8;
                                            break;
                                        }
                                            
                                        case 1: //reg or reg+integer/reg-integer
                                        {
                                            const size_t OpCount = CCCollectionGetCount(Op->childNodes);
                                            if (OpCount == 1) //reg
                                            {
                                                uint8_t Memory = (HKHubArchInstructionMemoryRegister << 2) | (Regs[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask);
                                                if (FreeBits <= 6)
                                                {
                                                    Bytes[Count++] |= Memory >> (6 - FreeBits);
                                                    Bytes[Count] = (Memory & CCBitSet(6 - FreeBits)) << (8 - (6 - FreeBits));
                                                }
                                                
                                                else Bytes[Count] |= (Memory & CCBitSet(FreeBits)) << (FreeBits - 6);
                                                
                                                BitCount += 6;
                                            }
                                            
                                            else if (OpCount >= 3) //reg+integer/reg-integer
                                            {
                                                uint8_t MemoryType = HKHubArchInstructionMemoryRelativeOffset;
                                                if (FreeBits <= 4)
                                                {
                                                    Bytes[Count++] |= MemoryType >> (4 - FreeBits);
                                                    Bytes[Count] = (MemoryType & CCBitSet(4 - FreeBits)) << (8 - (4 - FreeBits));
                                                }
                                                
                                                else Bytes[Count] |= (MemoryType & CCBitSet(FreeBits)) << (FreeBits - 4);
                                                
                                                BitCount += 4;
                                                FreeBits = 8 - (BitCount % 8);
                                                
                                                CCDictionarySetValue(Labels, (void*)&Registers[0].mnemonic, &(uint8_t){ 0 });
                                                CCDictionarySetValue(Labels, (void*)&Registers[1].mnemonic, &(uint8_t){ 0 });
                                                CCDictionarySetValue(Labels, (void*)&Registers[2].mnemonic, &(uint8_t){ 0 });
                                                CCDictionarySetValue(Labels, (void*)&Registers[3].mnemonic, &(uint8_t){ 0 });
                                                
                                                uint8_t Result;
                                                if (HKHubArchAssemblyResolveInteger(Offset, &Result, Command, Op, Errors, Labels, Defines))
                                                {
                                                    Bytes[Count++] |= Result >> (8 - FreeBits);
                                                    Bytes[Count] = (Result & CCBitSet(8 - FreeBits)) << FreeBits;
                                                }
                                                
                                                else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Op, NULL);
                                                
                                                CCDictionaryRemoveValue(Labels, (void*)&Registers[0].mnemonic);
                                                CCDictionaryRemoveValue(Labels, (void*)&Registers[1].mnemonic);
                                                CCDictionaryRemoveValue(Labels, (void*)&Registers[2].mnemonic);
                                                CCDictionaryRemoveValue(Labels, (void*)&Registers[3].mnemonic);
                                                
                                                BitCount += 8;
                                                
                                                uint8_t Memory = Regs[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask;
                                                if (FreeBits <= 2)
                                                {
                                                    Bytes[Count++] |= Memory >> (2 - FreeBits);
                                                    Bytes[Count] = (Memory & CCBitSet(2 - FreeBits)) << (8 - (2 - FreeBits));
                                                }
                                                
                                                else Bytes[Count] |= (Memory & CCBitSet(FreeBits)) << (FreeBits - 2);
                                                
                                                BitCount += 2;
                                            }
                                            
                                            else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Memory, NULL);
                                            
                                            break;
                                        }
                                            
                                        case 2: //reg+reg
                                        {
                                            if (CCCollectionGetCount(Op->childNodes) == 3)
                                            {
                                                HKHubArchAssemblyASTNode *Operation = CCOrderedCollectionGetElementAtIndex(Op->childNodes, 1);
                                                if (Operation->type == HKHubArchAssemblyASTTypePlus)
                                                {
                                                    uint8_t Memory = (HKHubArchInstructionMemoryRelativeRegister << 4) | ((Regs[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask) << 2) | (Regs[1] & HKHubArchInstructionRegisterGeneralPurposeIndexMask); //type|reg1|reg2
                                                    Bytes[Count++] |= Memory >> (8 - FreeBits);
                                                    Bytes[Count] = (Memory & CCBitSet(8 - FreeBits)) << FreeBits;
                                                    
                                                    BitCount += 8;
                                                }
                                                
                                                else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageMemoryAdditionOnly, Command, Op, Operation);
                                            }
                                            
                                            else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Memory, NULL);
                                            
                                            break;
                                        }
                                            
                                        default:
                                            HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageMin0Max2MemoryRegister, Command, Memory, NULL);
                                            break;
                                    }
                                }
                                
                                else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageMemoryRegister, Command, Memory, NULL);
                            }
                            
                            else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Memory, NULL);
                        }
                        
                        else HKHubArchAssemblyErrorAddMessage(Errors, HKHubArchInstructionErrorMessageResolveOperand, Command, Memory, NULL);
                    }
                }
                
                const size_t ByteCount = (BitCount / 8) + 1;
                if (Data) memcpy(&Data[Offset], Bytes, ByteCount);
                
                return Offset + ByteCount;
            }
        }
    }
    
    HKHubArchAssemblyErrorAddMessage(Errors, FoundErr, Command, NULL, NULL);
    
    return Offset;
}

uint8_t HKHubArchInstructionDecode(uint8_t Offset, uint8_t Data[256], HKHubArchInstructionState *Decoded)
{
    CCAssertLog(Data, "Data must not be null");
    
    HKHubArchInstructionState State = { .opcode = -1, .operand = { { .type = HKHubArchInstructionOperandNA }, { .type = HKHubArchInstructionOperandNA }, { .type = HKHubArchInstructionOperandNA } } };
    uint8_t Byte = Data[Offset++];
    
    uint8_t FreeBits = 2;
    const uint8_t Opcode = Byte >> 2;
    if (Instructions[Opcode].mnemonic)
    {
        State.opcode = Opcode;
        
        for (int Loop = 0; (Loop < 3) && (Instructions[Opcode].operands[Loop] != HKHubArchInstructionOperandNA); Loop++)
        {
            if (FreeBits == 0)
            {
                FreeBits = 8;
                Byte = Data[Offset++];
            }
            
            if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandI)
            {
                uint8_t Value = (Byte & CCBitSet(FreeBits)) << (8 - FreeBits);
                if (FreeBits != 8)
                {
                    Byte = Data[Offset++];
                    Value |= Byte >> FreeBits;
                }
                
                else FreeBits = 0;
                
                State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandI, .value = Value };
            }
            
            else if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandRM)
            {
                uint8_t Reg = Byte & CCBitSet(FreeBits);
                if (FreeBits < 3)
                {
                    Byte = Data[Offset++];
                    Reg = (Reg << (3 - FreeBits)) | (Byte >> (8 - (3 - FreeBits)));
                    FreeBits = 8 - (3 - FreeBits);
                }
                
                else
                {
                    if (FreeBits > 3) Reg >>= (FreeBits - 3);
                    FreeBits -= 3;
                }
                
                if (Reg & (HKHubArchInstructionRegisterGeneralPurpose | HKHubArchInstructionRegisterSpecialPurpose))
                {
                    if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandR) State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandR, .reg = Reg };
                    else State.opcode = -1;
                }
                
                else if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandM)
                {
                    uint8_t Memory = Byte & CCBitSet(FreeBits);
                    if (FreeBits < 1)
                    {
                        Byte = Data[Offset++];
                        Memory = (Memory << (1 - FreeBits)) | (Byte >> (8 - (1 - FreeBits)));
                        FreeBits = 8 - (1 - FreeBits);
                    }
                    
                    else
                    {
                        if (FreeBits > 1) Memory >>= (FreeBits - 1);
                        FreeBits -= 1;
                    }
                    
                    Memory |= Reg << 1;
                    
                    switch (Memory)
                    {
                        case HKHubArchInstructionMemoryOffset:
                        {
                            uint8_t Value = (Byte & CCBitSet(FreeBits)) << (8 - FreeBits);
                            if (FreeBits != 8)
                            {
                                Byte = Data[Offset++];
                                Value |= Byte >> FreeBits;
                            }
                            
                            else FreeBits = 0;
                            
                            State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandM, .memory = { .type = Memory, .offset = Value } };
                            break;
                        }
                            
                        case HKHubArchInstructionMemoryRegister:
                            Reg = Byte & CCBitSet(FreeBits);
                            if (FreeBits < 2)
                            {
                                Byte = Data[Offset++];
                                Reg = (Reg << (2 - FreeBits)) | (Byte >> (8 - (2 - FreeBits)));
                                FreeBits = 8 - (2 - FreeBits);
                            }
                            
                            else
                            {
                                if (FreeBits > 2) Reg >>= (FreeBits - 2);
                                FreeBits -= 2;
                            }
                            
                            State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandM, .memory = { .type = Memory, .reg = Reg | HKHubArchInstructionRegisterGeneralPurpose } };
                            break;
                            
                        case HKHubArchInstructionMemoryRelativeOffset:
                        {
                            uint8_t Value = (Byte & CCBitSet(FreeBits)) << (8 - FreeBits);
                            if (FreeBits != 8)
                            {
                                Byte = Data[Offset++];
                                Value |= Byte >> FreeBits;
                            }
                            
                            else FreeBits = 0;
                            
                            Reg = Byte & CCBitSet(FreeBits);
                            if (FreeBits < 2)
                            {
                                Byte = Data[Offset++];
                                Reg = (Reg << (2 - FreeBits)) | (Byte >> (8 - (2 - FreeBits)));
                                FreeBits = 8 - (2 - FreeBits);
                            }
                            
                            else
                            {
                                if (FreeBits > 2) Reg >>= (FreeBits - 2);
                                FreeBits -= 2;
                            }
                            
                            State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandM, .memory = { .type = Memory, .relativeOffset = { .offset = Value, .reg = Reg | HKHubArchInstructionRegisterGeneralPurpose } } };
                            break;
                        }
                            
                        case HKHubArchInstructionMemoryRelativeRegister:
                            Reg = Byte & CCBitSet(FreeBits);
                            if (FreeBits < 4)
                            {
                                Byte = Data[Offset++];
                                Reg = (Reg << (4 - FreeBits)) | (Byte >> (8 - (4 - FreeBits)));
                                FreeBits = 8 - (4 - FreeBits);
                            }
                            
                            else
                            {
                                if (FreeBits > 4) Reg >>= (FreeBits - 4);
                                FreeBits -= 4;
                            }
                            
                            State.operand[Loop] = (HKHubArchInstructionOperandValue){ .type = HKHubArchInstructionOperandM, .memory = { .type = Memory, .relativeReg = { (Reg >> 2) | HKHubArchInstructionRegisterGeneralPurpose, (Reg & 3) | HKHubArchInstructionRegisterGeneralPurpose } } };
                            break;
                    }
                }
                
                else State.opcode = -1;
            }
        }
    }
    
    if (Decoded) *Decoded = State;
    
    return Offset;
}

CCString HKHubArchInstructionDisassemble(const HKHubArchInstructionState *State)
{
    CCAssertLog(State, "State must not be null");
    
    //TODO: Pass in formatting options?
    CCString Disassembly = 0;
    if ((State->opcode != -1) && (Instructions[State->opcode].mnemonic))
    {
        Disassembly = CCStringCopy(Instructions[State->opcode].mnemonic);
        
        for (int Loop = 0; (Loop < 3) && (State->operand[Loop].type != HKHubArchInstructionOperandNA); Loop++)
        {
            switch (State->operand[Loop].type)
            {
                case HKHubArchInstructionOperandI:
                {
                    char Hex[5];
                    snprintf(Hex, sizeof(Hex), State->operand[Loop].value ? "%#.2x" : "0x%#.2x", State->operand[Loop].value);
                    
                    CCString Value = CCStringCreate(CC_STD_ALLOCATOR, (CCStringHint)CCStringEncodingASCII, Hex);
                    CCString Temp = CCStringCreateByJoiningStrings((CCString[2]){ Disassembly, Value }, 2, Loop == 0 ? CC_STRING(" ") : CC_STRING(","));
                    CCStringDestroy(Disassembly);
                    Disassembly = Temp;
                    CCStringDestroy(Value);
                    
                    break;
                }
                    
                case HKHubArchInstructionOperandR:
                    if (State->operand[Loop].reg & HKHubArchInstructionRegisterGeneralPurpose)
                    {
                        CCString Temp = CCStringCreateByJoiningStrings((CCString[2]){ Disassembly, Registers[State->operand[Loop].reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask].mnemonic }, 2, Loop == 0 ? CC_STRING(" ") : CC_STRING(","));
                        CCStringDestroy(Disassembly);
                        Disassembly = Temp;
                    }
                    
                    else if (State->operand[Loop].reg & HKHubArchInstructionRegisterSpecialPurpose)
                    {
                        CCString Temp = CCStringCreateByJoiningStrings((CCString[2]){ Disassembly, Registers[(State->operand[Loop].reg & HKHubArchInstructionRegisterSpecialPurposeIndexMask) + 4].mnemonic }, 2, Loop == 0 ? CC_STRING(" ") : CC_STRING(","));
                        CCStringDestroy(Disassembly);
                        Disassembly = Temp;
                    }
                    break;
                    
                case HKHubArchInstructionOperandM:
                {
                    CCString Memory = 0;
                    switch (State->operand[Loop].memory.type)
                    {
                        case HKHubArchInstructionMemoryOffset:
                        {
                            char Hex[5];
                            snprintf(Hex, sizeof(Hex), State->operand[Loop].memory.offset ? "%#.2x" : "0x%#.2x", State->operand[Loop].memory.offset);
                            
                            CCString Value = CCStringCreate(CC_STD_ALLOCATOR, (CCStringHint)CCStringEncodingASCII, Hex);
                            Memory = CCStringCreateByJoiningStrings((CCString[3]){ CC_STRING("["), Value, CC_STRING("]") }, 3, 0);
                            CCStringDestroy(Value);
                            break;
                        }
                            
                        case HKHubArchInstructionMemoryRegister:
                            Memory = CCStringCreateByJoiningStrings((CCString[3]){ CC_STRING("["), Registers[State->operand[Loop].memory.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask].mnemonic, CC_STRING("]") }, 3, 0);
                            break;
                            
                        case HKHubArchInstructionMemoryRelativeOffset:
                        {
                            char Hex[5];
                            snprintf(Hex, sizeof(Hex), State->operand[Loop].memory.relativeOffset.offset ? "%#.2x" : "0x%#.2x", State->operand[Loop].memory.relativeOffset.offset);
                            
                            CCString Value = CCStringCreate(CC_STD_ALLOCATOR, (CCStringHint)CCStringEncodingASCII, Hex);
                            Memory = CCStringCreateByJoiningStrings((CCString[5]){
                                CC_STRING("["),
                                Value,
                                CC_STRING("+"),
                                Registers[State->operand[Loop].memory.relativeOffset.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask].mnemonic,
                                CC_STRING("]")
                            }, 5, 0);
                            CCStringDestroy(Value);
                            break;
                        }
                            
                        case HKHubArchInstructionMemoryRelativeRegister:
                            Memory = CCStringCreateByJoiningStrings((CCString[5]){
                                CC_STRING("["),
                                Registers[State->operand[Loop].memory.relativeReg[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask].mnemonic,
                                CC_STRING("+"),
                                Registers[State->operand[Loop].memory.relativeReg[1] & HKHubArchInstructionRegisterGeneralPurposeIndexMask].mnemonic,
                                CC_STRING("]")
                            }, 5, 0);
                            break;
                    }
                    
                    CCString Temp = CCStringCreateByJoiningStrings((CCString[2]){ Disassembly, Memory }, 2, Loop == 0 ? CC_STRING(" ") : CC_STRING(","));
                    CCStringDestroy(Disassembly);
                    Disassembly = Temp;
                    CCStringDestroy(Memory);
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
    
    return Disassembly;
}

HKHubArchInstructionOperationResult HKHubArchInstructionExecute(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    CCAssertLog(Processor, "Processor must not be null");
    CCAssertLog(State, "State must not be null");
    
    if (State->opcode == -1) return HKHubArchInstructionOperationResultFailure;
    
    if (!Instructions[State->opcode].operation) return HKHubArchInstructionOperationResultSuccess;
    
    return Instructions[State->opcode].operation(Processor, State);
}

#pragma mark - Instruction Operations

static inline uint8_t *HKHubArchInstructionOperandDestinationValue(HKHubArchProcessor Processor, const HKHubArchInstructionOperandValue *Operand)
{
    switch (Operand->type)
    {
        case HKHubArchInstructionOperandR:
            if (Operand->reg & HKHubArchInstructionRegisterGeneralPurpose) return Processor->state.r + (Operand->reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask);
            else if (Operand->reg == HKHubArchInstructionRegisterFlags) return &Processor->state.flags;
            else if (Operand->reg == HKHubArchInstructionRegisterPC) return &Processor->state.pc;
            break;
            
        case HKHubArchInstructionOperandM:
        {
            uint8_t Offset;
            switch (Operand->memory.type)
            {
                case HKHubArchInstructionMemoryOffset:
                    Offset = Operand->memory.offset;
                    break;
                    
                case HKHubArchInstructionMemoryRegister:
                    Offset = Processor->state.r[Operand->memory.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                    break;
                    
                case HKHubArchInstructionMemoryRelativeOffset:
                    Offset = Processor->state.r[Operand->memory.relativeOffset.reg & HKHubArchInstructionRegisterGeneralPurposeIndexMask] + Operand->memory.relativeOffset.offset;
                    break;
                    
                case HKHubArchInstructionMemoryRelativeRegister:
                    Offset = Processor->state.r[Operand->memory.relativeReg[0] & HKHubArchInstructionRegisterGeneralPurposeIndexMask] + Processor->state.r[Operand->memory.relativeReg[1] & HKHubArchInstructionRegisterGeneralPurposeIndexMask];
                    break;
            }
            
            return &Processor->memory[Offset];
        }
            
        default:
            break;
    }
    
    CCAssertLog(0, "Should be a correctly formatted operand");
    
    return NULL;
}

static inline const uint8_t *HKHubArchInstructionOperandSourceValue(HKHubArchProcessor Processor, const HKHubArchInstructionOperandValue *Operand)
{
    switch (Operand->type)
    {
        case HKHubArchInstructionOperandI:
            return &Operand->value;
            
        case HKHubArchInstructionOperandR:
        case HKHubArchInstructionOperandM:
            return HKHubArchInstructionOperandDestinationValue(Processor, Operand);
            
        default:
            break;
    }
    
    CCAssertLog(0, "Should be a correctly formatted operand");
    
    return NULL;
}

#pragma mark Arithmetic

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationMOV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 1 + ((State->operand[0].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryWrite) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    *Dest = *HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationADD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 2 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest + *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = (Result < *Dest ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest ^ *Src) & 0x80) ? 0 : (((*Dest ^ Result) & 0x80) ? HKHubArchProcessorFlagsOverflow : 0);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSUB(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 2 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest - *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = (Result > *Dest ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest ^ *Src) & 0x80) ? (((*Dest ^ Result) & 0x80) ? HKHubArchProcessorFlagsOverflow : 0) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationMUL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 2 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest * *Src;
    const int32_t Temp = (int32_t)*(int8_t*)Dest * (int32_t)*(int8_t*)Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = (((uint16_t)*Dest * (uint16_t)*Src) & 0xff00 ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = (*Dest ^ *Src) & 0x80 ? (((Result & 0x80) && (Temp == *(int8_t*)&Result)) ? 0 : HKHubArchProcessorFlagsOverflow) : ((!(Result & 0x80) && !(Temp & 0xffffff00)) ? 0 : HKHubArchProcessorFlagsOverflow);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSDIV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 3 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    int8_t *Dest = (int8_t*)HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const int8_t *Src = (const int8_t*)HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const int8_t Result = *Src == 0 ? 0 : *Dest / *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest & *Src) & 0x80) && (Result & 0x80) ? HKHubArchProcessorFlagsOverflow : 0;
    const HKHubArchProcessorFlags DivideByZero = *Src == 0 ? (HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Sign | Overflow | DivideByZero;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | ((uint8_t*)Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationUDIV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 3 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Src == 0 ? 0 : *Dest / *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags DivideByZero = *Src == 0 ? (HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | DivideByZero;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSMOD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 3 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    int8_t *Dest = (int8_t*)HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const int8_t *Src = (const int8_t*)HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const int8_t Result = *Src == 0 ? 0 : *Dest % *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest & *Src) & 0x80) && (Result & 0x80) ? HKHubArchProcessorFlagsOverflow : 0;
    const HKHubArchProcessorFlags DivideByZero = *Src == 0 ? (HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Sign | Overflow | DivideByZero;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | ((uint8_t*)Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationUMOD(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 3 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Src == 0 ? 0 : *Dest % *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags DivideByZero = *Src == 0 ? (HKHubArchProcessorFlagsOverflow | HKHubArchProcessorFlagsCarry) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | DivideByZero;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationCMP(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 2 + ((State->operand[0].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest - *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = (Result > *Dest ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest ^ *Src) & 0x80) ? (((*Dest ^ Result) & 0x80) ? HKHubArchProcessorFlagsOverflow : 0) : 0;
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
        
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSHL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 1 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest << *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = ((*Src <= 8) && (*Src > 0) && (*Dest & (0x80 >> (*Src - 1))) ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((*Dest >> (8 - *Src)) || ((*Src >= 8) && (*Dest)) ? HKHubArchProcessorFlagsOverflow : 0);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSHR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 1 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest >> *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Carry = ((*Src <= 8) && (*Src > 0) && (*Dest & (1 << (*Src - 1))) ? HKHubArchProcessorFlagsCarry : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    const HKHubArchProcessorFlags Overflow = ((uint8_t)(*Dest << (8 - *Src)) || ((*Src >= 8) && (*Dest)) ? HKHubArchProcessorFlagsOverflow : 0);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Carry | Sign | Overflow;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationXOR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 1 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest ^ *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Sign;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationOR(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    const size_t Cycles = 1 + ((State->operand[0].type == HKHubArchInstructionOperandM) * (HKHubArchProcessorSpeedMemoryRead + HKHubArchProcessorSpeedMemoryWrite)) + ((State->operand[1].type == HKHubArchInstructionOperandM) * HKHubArchProcessorSpeedMemoryRead);
    
    if (Processor->cycles < Cycles) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= Cycles;
    uint8_t *Dest = HKHubArchInstructionOperandDestinationValue(Processor, &State->operand[0]);
    const uint8_t *Src = HKHubArchInstructionOperandSourceValue(Processor, &State->operand[1]);
    
    const uint8_t Result = *Dest | *Src;
    const HKHubArchProcessorFlags Zero = (Result == 0 ? HKHubArchProcessorFlagsZero : 0);
    const HKHubArchProcessorFlags Sign = (Result & 0x80 ? HKHubArchProcessorFlagsSign : 0);
    
    Processor->state.flags = (Processor->state.flags & ~HKHubArchProcessorFlagsMask) | Zero | Sign;
    
    *Dest = Result;
    
    return HKHubArchInstructionOperationResultSuccess | (Dest == &Processor->state.pc ? HKHubArchInstructionOperationResultFlagSkipPC : 0);
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationAND(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    return HKHubArchInstructionOperationResultFailure;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationNOT(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    return HKHubArchInstructionOperationResultFailure;
}

#pragma mark Signals

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationHLT(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    return HKHubArchInstructionOperationResultFailure;
}

#pragma mark I/O

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationSEND(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    return HKHubArchInstructionOperationResultFailure;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationRECV(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    return HKHubArchInstructionOperationResultFailure;
}

#pragma mark Branching

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJMP(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    Processor->state.pc += State->operand[0].value;
    
    return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJZ(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (Processor->state.flags & HKHubArchProcessorFlagsZero)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNZ(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsZero) == 0)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJS(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (Processor->state.flags & HKHubArchProcessorFlagsSign)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNS(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsSign) == 0)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJO(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (Processor->state.flags & HKHubArchProcessorFlagsOverflow)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJNO(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsOverflow) == 0)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((_Bool)(Processor->state.flags & HKHubArchProcessorFlagsSign) != (_Bool)(Processor->state.flags & HKHubArchProcessorFlagsOverflow))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSGE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((_Bool)(Processor->state.flags & HKHubArchProcessorFlagsSign) == (_Bool)(Processor->state.flags & HKHubArchProcessorFlagsOverflow))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSLE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsZero) || ((_Bool)(Processor->state.flags & HKHubArchProcessorFlagsSign) != (_Bool)(Processor->state.flags & HKHubArchProcessorFlagsOverflow)))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJSG(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (((Processor->state.flags & HKHubArchProcessorFlagsZero) == 0) && ((_Bool)(Processor->state.flags & HKHubArchProcessorFlagsSign) == (_Bool)(Processor->state.flags & HKHubArchProcessorFlagsOverflow)))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUL(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (Processor->state.flags & HKHubArchProcessorFlagsCarry)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUGE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsCarry) == 0)
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJULE(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if ((Processor->state.flags & HKHubArchProcessorFlagsCarry) || (Processor->state.flags & HKHubArchProcessorFlagsZero))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}

static HKHubArchInstructionOperationResult HKHubArchInstructionOperationJUG(HKHubArchProcessor Processor, const HKHubArchInstructionState *State)
{
    if (Processor->cycles < 1) return HKHubArchInstructionOperationResultFailure;
    
    Processor->cycles -= 1;
    
    if (((Processor->state.flags & HKHubArchProcessorFlagsCarry) == 0) && ((Processor->state.flags & HKHubArchProcessorFlagsZero) == 0))
    {
        Processor->state.pc += State->operand[0].value;
        
        return HKHubArchInstructionOperationResultSuccess | HKHubArchInstructionOperationResultFlagSkipPC;
    }
    
    return HKHubArchInstructionOperationResultSuccess;
}
