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

static const struct {
    CCString mnemonic;
    HKHubArchInstructionOperand operands[3];
} Instructions[64] = {
    { CC_STRING("add")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("add")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("mov")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jz")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("mov")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("jnz")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("js")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jns")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jo")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jno")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandR,   HKHubArchInstructionOperandM  } },
    { CC_STRING("cmp")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("cmp")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandR,   HKHubArchInstructionOperandM  } },
    { CC_STRING("shr")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shr")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("recv")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,   HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM  } },
    { CC_STRING("or")       , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("or")       , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { 0                     , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("and")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("and")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA } },
    { CC_STRING("not")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("hlt")      , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsl")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsge")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsle")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jsg")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jul")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("juge")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jule")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jug")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM  } },
    { CC_STRING("recv")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,   HKHubArchInstructionOperandNA } },
    { CC_STRING("nop")      , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jmp")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA } }
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

size_t HKHubArchInstructionEncode(size_t Offset, HKHubArchBinary Binary, HKHubArchAssemblyASTNode *Command, CCOrderedCollection Errors, CCDictionary Labels, CCDictionary Defines)
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
                if (Binary) memcpy(&Binary->data[Offset], Bytes, ByteCount);
                
                return Offset + ByteCount;
            }
        }
    }
    
    HKHubArchAssemblyErrorAddMessage(Errors, FoundErr, Command, NULL, NULL);
    
    return Offset;
}

uint8_t HKHubArchInstructionDecode(uint8_t Offset, HKHubArchBinary Binary, HKHubArchInstructionState *Decoded)
{
    CCAssertLog(Binary, "Binary must not be null");
    
    HKHubArchInstructionState State = { .opcode = -1, .operand = { { .type = HKHubArchInstructionOperandNA }, { .type = HKHubArchInstructionOperandNA }, { .type = HKHubArchInstructionOperandNA } } };
    uint8_t Byte = Binary->data[Offset++];
    
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
                Byte = Binary->data[Offset++];
            }
            
            if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandI)
            {
                uint8_t Value = (Byte & CCBitSet(FreeBits)) << (8 - FreeBits);
                if (FreeBits != 8)
                {
                    Byte = Binary->data[Offset++];
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
                    Byte = Binary->data[Offset++];
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
                }
                
                else if (Instructions[Opcode].operands[Loop] & HKHubArchInstructionOperandM)
                {
                    uint8_t Memory = Byte & CCBitSet(FreeBits);
                    if (FreeBits < 1)
                    {
                        Byte = Binary->data[Offset++];
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
                                Byte = Binary->data[Offset++];
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
                                Byte = Binary->data[Offset++];
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
                                Byte = Binary->data[Offset++];
                                Value |= Byte >> FreeBits;
                            }
                            
                            else FreeBits = 0;
                            
                            Reg = Byte & CCBitSet(FreeBits);
                            if (FreeBits < 2)
                            {
                                Byte = Binary->data[Offset++];
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
                                Byte = Binary->data[Offset++];
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
                    snprintf(Hex, sizeof(Hex), "%#.2x", State->operand[Loop].value);
                    
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
                            snprintf(Hex, sizeof(Hex), "%#.2x", State->operand[Loop].memory.offset);
                            
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
                            snprintf(Hex, sizeof(Hex), "%#.2x", State->operand[Loop].memory.relativeOffset.offset);
                            
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
