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
    { CC_STRING("add")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("add")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("add")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jz")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("sub")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jnz")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("mul")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("js")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("sdiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jns")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("udiv")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jo")       , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("smod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("jno")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("umod")     , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandR,  HKHubArchInstructionOperandM  } },
    { CC_STRING("cmp")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("cmp")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("cmp")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("shl")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandR,  HKHubArchInstructionOperandM  } },
    { CC_STRING("shr")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("shr")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("shr")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("recv")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("xor")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandI,  HKHubArchInstructionOperandM  } },
    { CC_STRING("or")       , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("or")       , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("or")       , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("and")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandR,  HKHubArchInstructionOperandNA } },
    { CC_STRING("and")      , .operands = { HKHubArchInstructionOperandR,   HKHubArchInstructionOperandRM, HKHubArchInstructionOperandNA } },
    { CC_STRING("and")      , .operands = { HKHubArchInstructionOperandRM,  HKHubArchInstructionOperandI,  HKHubArchInstructionOperandNA } },
    { CC_STRING("hlt")      , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jsl")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jsge")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jsle")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jsg")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jul")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("juge")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jule")     , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jug")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("send")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandI,  HKHubArchInstructionOperandM  } },
    { CC_STRING("recv")     , .operands = { HKHubArchInstructionOperandI,   HKHubArchInstructionOperandM,  HKHubArchInstructionOperandNA } },
    { CC_STRING("nop")      , .operands = { HKHubArchInstructionOperandNA,  HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } },
    { CC_STRING("jmp")      , .operands = { HKHubArchInstructionOperandRel, HKHubArchInstructionOperandNA, HKHubArchInstructionOperandNA } }
};

static const struct {
    CCString mnemonic;
    uint8_t encoding;
} Registers[6] = {
    { CC_STRING("r0"),      4 },
    { CC_STRING("r1"),      5 },
    { CC_STRING("r2"),      6 },
    { CC_STRING("r3"),      7 },
    { CC_STRING("pc"),      3 },
    { CC_STRING("flags"),   2 }
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
                HKHubArchAssemblyASTNode *Symbol = CCDictionaryGetValue(Defines, &Value->string);
                if (Symbol) Value = Symbol;
                
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
        if (CCStringEqual(Instructions[Loop].mnemonic, Command->string))
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
                                uint8_t Regs[2] = { 4, 4 };
                                
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
                                
                                if ((Regs[0] & 4) && (Regs[1] & 4))
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
                                            uint8_t MemoryType = 0;
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
                                            break;
                                            
                                        case 2: //reg+reg
                                        {
                                            if (CCCollectionGetCount(Op->childNodes) == 3)
                                            {
                                                HKHubArchAssemblyASTNode *Operation = CCOrderedCollectionGetElementAtIndex(Op->childNodes, 1);
                                                if (Operation->type == HKHubArchAssemblyASTTypePlus)
                                                {
                                                    uint8_t Memory = (3 << 4) | ((Regs[0] & 3) << 2) | (Regs[1] & 3); //type|reg1|reg2
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
