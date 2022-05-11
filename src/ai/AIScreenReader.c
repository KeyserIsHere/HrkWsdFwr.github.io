/*
 *  Copyright (c) 2022, Stefan Johnson
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

#include "AIScreenReader.h"

void HKAIScreenReaderNormalize(HKHubModuleGraphicsAdapterCharacter *Characters, size_t Width, size_t Height, CCChar Replacement, size_t LineHeight)
{
    CCAssertLog(Characters, "Characters must not be null");
    CCAssertLog(LineHeight >= 1, "LineHeight must be at least 1");
    CCAssertLog(LineHeight <= Height, "LineHeight must be smaller or equal to Height");
    CCAssertLog(Replacement <= HKHubModuleGraphicsAdapterCharacterhGlyphIndexMask, "Replacement must not be outside of unicode range");
    
    const HKHubModuleGraphicsAdapterCharacter ReplacementCharacter = Replacement | HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG;
    
    for (size_t Y = 0, MergeableHeight = (Height - LineHeight) + 1; Y < MergeableHeight; Y++)
    {
        HKHubModuleGraphicsAdapterCharacter Prev = 0;
        
        for (size_t X = 0, PrevX = 0, S = 0; X < Width; X++, S++)
        {
            HKHubModuleGraphicsAdapterCharacter Current = 0;
            
            for (size_t Row = 0, T = 0; Row < LineHeight; Row++)
            {
                HKHubModuleGraphicsAdapterCharacter Next = Characters[((Y + Row) * Width) + X];
                
                if (Current)
                {
                    if (Next)
                    {
                        if (((Current & ~HKHubModuleGraphicsAdapterCharacterPositionTMask) != (Next & ~HKHubModuleGraphicsAdapterCharacterPositionTMask)) || (T != ((Next & HKHubModuleGraphicsAdapterCharacterPositionTMask) >> HKHubModuleGraphicsAdapterCharacterPositionTIndex)))
                        {
                            Current = ReplacementCharacter;
                            break;
                        }
                        
                        Current = (Current & ~HKHubModuleGraphicsAdapterCharacterPositionTMask) | (((uint32_t)T << HKHubModuleGraphicsAdapterCharacterPositionTIndex) & HKHubModuleGraphicsAdapterCharacterPositionTMask);
                        T++;
                    }
                    
                    else T = SIZE_MAX;
                }
                
                else if (Next)
                {
                    if (Next & HKHubModuleGraphicsAdapterCharacterPositionTMask)
                    {
                        Current = ReplacementCharacter;
                        break;
                    }
                    
                    Current = Next;
                    T = 1;
                }
            }
            
            Characters[(Y * Width) + X] = Current;
            
            if (Prev)
            {
                if (Current)
                {
                    if (((Prev & ~HKHubModuleGraphicsAdapterCharacterPositionSMask) != (Current & ~HKHubModuleGraphicsAdapterCharacterPositionSMask)) || (S != ((Current & HKHubModuleGraphicsAdapterCharacterPositionSMask) >> HKHubModuleGraphicsAdapterCharacterPositionSIndex)))
                    {
                        if (Current & HKHubModuleGraphicsAdapterCharacterPositionSMask)
                        {
                            Prev = 0;
                            Characters[(Y * Width) + X] = ReplacementCharacter;
                        }
                        
                        else
                        {
                            Prev = Current;
                            S = 0;
                            PrevX = X;
                        }
                    }
                    
                    else
                    {
                        Prev = (Prev & ~HKHubModuleGraphicsAdapterCharacterPositionSMask) | (((uint32_t)S << HKHubModuleGraphicsAdapterCharacterPositionSIndex) & HKHubModuleGraphicsAdapterCharacterPositionSMask);
                        Characters[(Y * Width) + PrevX] = Prev;
                        Characters[(Y * Width) + X] = HK_AI_SCREEN_READER_SKIP_CHAR;
                    }
                }
                
                else Prev = 0;
            }
            
            else if (Current)
            {
                if (Current & HKHubModuleGraphicsAdapterCharacterPositionSMask)
                {
                    Prev = 0;
                    Characters[(Y * Width) + X] = ReplacementCharacter;
                }
                
                else
                {
                    Prev = Current;
                    S = 0;
                    PrevX = X;
                }
            }
        }
    }
}
