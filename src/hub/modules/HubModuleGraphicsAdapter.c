/*
 *  Copyright (c) 2021, Stefan Johnson
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

#include "HubModuleGraphicsAdapter.h"

#define CC_TYPE_HKHubModuleGraphicsAdapterCell(...) HKHubModuleGraphicsAdapterCell
#define CC_TYPE_0_HKHubModuleGraphicsAdapterCell CC_TYPE_HKHubModuleGraphicsAdapterCell,

#define CC_PRESERVE_CC_TYPE_HKHubModuleGraphicsAdapterCell CC_TYPE_HKHubModuleGraphicsAdapterCell

#define CC_TYPE_DECL_HKHubModuleGraphicsAdapterCell(...) HKHubModuleGraphicsAdapterCell, __VA_ARGS__
#define CC_TYPE_DECL_0_HKHubModuleGraphicsAdapterCell CC_TYPE_DECL_HKHubModuleGraphicsAdapterCell,

#define CC_MANGLE_TYPE_0_HKHubModuleGraphicsAdapterCell HKHubModuleGraphicsAdapterCell

#define Tbuffer PTYPE(HKHubModuleGraphicsAdapterCell *)
#include <CommonC/Memory.h>

typedef struct {
    uint8_t x, y, width, height;
} HKHubModuleGraphicsAdapterViewport;

typedef CC_FLAG_ENUM(HKHubModuleGraphicsAdapterCell, uint32_t) {
    HKHubModuleGraphicsAdapterCellModeMask = 0x80000000,
    HKHubModuleGraphicsAdapterCellModeBitmap = 0,
    HKHubModuleGraphicsAdapterCellModeReference = 0x80000000,
    
    //p = palette page
    HKHubModuleGraphicsAdapterCellPalettePageIndex = 28,
    HKHubModuleGraphicsAdapterCellPalettePageMask = (7 << HKHubModuleGraphicsAdapterCellPalettePageIndex),
    
    //b = bold
    HKHubModuleGraphicsAdapterCellBoldFlag = (1 << 27),
    
    //a = animation offset (current frame + anim offset = anim index)
    HKHubModuleGraphicsAdapterCellAnimationOffsetIndex = 24,
    HKHubModuleGraphicsAdapterCellAnimationOffsetMask = (7 << HKHubModuleGraphicsAdapterCellAnimationOffsetIndex),
    
    //i = bitmap index
    HKHubModuleGraphicsAdapterCellGlyphIndexMask = 0x1fffff,
    
    //r = reference layer
    HKHubModuleGraphicsAdapterCellReferenceLayerIndex = 16,
    HKHubModuleGraphicsAdapterCellReferenceLayerMask = (7 << HKHubModuleGraphicsAdapterCellReferenceLayerIndex),
    
    //x = x position
    HKHubModuleGraphicsAdapterCellPositionXIndex = 0,
    HKHubModuleGraphicsAdapterCellPositionXMask = (0xff << HKHubModuleGraphicsAdapterCellPositionXIndex),
    
    //y = y position
    HKHubModuleGraphicsAdapterCellPositionYIndex = 8,
    HKHubModuleGraphicsAdapterCellPositionYMask = (0xff << HKHubModuleGraphicsAdapterCellPositionYIndex)
};

typedef struct {
    HKHubModuleGraphicsAdapterViewport viewports[256];
    uint8_t glyphs[HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER];
    uint8_t palettes[HK_HUB_MODULE_GRAPHICS_ADAPTER_PALETTE_PAGE_COUNT][256];
    uint8_t layers[HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT][HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_WIDTH * HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_HEIGHT * sizeof(HKHubModuleGraphicsAdapterCell)];
} HKHubModuleGraphicsAdapterMemory;

static CC_FORCE_INLINE HKHubModuleGraphicsAdapterCell HKHubModuleGraphicsAdapterCellMode(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellModeMask;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetPalettePage(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPalettePageMask) >> HKHubModuleGraphicsAdapterCellPalettePageIndex;
}

static CC_FORCE_INLINE _Bool HKHubModuleGraphicsAdapterCellIsBold(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellBoldFlag;
}
