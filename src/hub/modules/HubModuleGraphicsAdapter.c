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

#define T size_t
#include <CommonC/Extrema.h>

typedef struct {
    uint8_t x, y, width, height;
} HKHubModuleGraphicsAdapterViewport;

typedef struct {
    CCChar character;
    struct {
        uint8_t x;
        uint8_t y;
    } offset;
} HKHubModuleGraphicsAdapterCursorControl;

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_CURSOR_CONTROL_COUNT 16

typedef struct {
    uint8_t x, y;
    uint8_t visibility;
    HKHubModuleGraphicsAdapterViewport bounds;
    HKHubModuleGraphicsAdapterCursorControl control[HK_HUB_MODULE_GRAPHICS_ADAPTER_CURSOR_CONTROL_COUNT];
} HKHubModuleGraphicsAdapterCursor;

typedef CC_FLAG_ENUM(HKHubModuleGraphicsAdapterCell, uint64_t) {
    HKHubModuleGraphicsAdapterCellModeMask = 0x80000000,
    HKHubModuleGraphicsAdapterCellModeBitmap = 0,
    HKHubModuleGraphicsAdapterCellModeReference = 0x80000000,
    
    //ttttssss 0pppbaaa iffggggg gggggggg gggggggg
    //cccccccc 1pppbaaa iffmmrrr yyyyyyyy xxxxxxxx
    
    //c = palette index offset
    HKHubModuleGraphicsAdapterCellPaletteOffsetIndex = 32,
    HKHubModuleGraphicsAdapterCellPaletteOffsetMask = (0xffULL << HKHubModuleGraphicsAdapterCellPaletteOffsetIndex),
    
    //t = y-relative position of glyph
    HKHubModuleGraphicsAdapterCellPositionTIndex = 36,
    HKHubModuleGraphicsAdapterCellPositionTMask = (0xfULL << HKHubModuleGraphicsAdapterCellPositionTIndex),
    
    //s = x-relative position of glyph
    HKHubModuleGraphicsAdapterCellPositionSIndex = 32,
    HKHubModuleGraphicsAdapterCellPositionSMask = (0xfULL << HKHubModuleGraphicsAdapterCellPositionSIndex),
    
    //p = palette page
    HKHubModuleGraphicsAdapterCellPalettePageIndex = 28,
    HKHubModuleGraphicsAdapterCellPalettePageMask = (7 << HKHubModuleGraphicsAdapterCellPalettePageIndex),
    
    //b = bold
    HKHubModuleGraphicsAdapterCellBoldIndex = 27,
    HKHubModuleGraphicsAdapterCellBoldFlag = (1 << HKHubModuleGraphicsAdapterCellBoldIndex),
    
    //i = italic
    HKHubModuleGraphicsAdapterCellItalicIndex = 23,
    HKHubModuleGraphicsAdapterCellItalicFlag = (1 << HKHubModuleGraphicsAdapterCellItalicIndex),
    
    //f = animation filter (0 = rrrr rrrr, 1 = rxrx rxrx, 2 = rrxx rrxx, 3 = rrrr xxxx)
    HKHubModuleGraphicsAdapterCellAnimationFilterIndex = 21,
    HKHubModuleGraphicsAdapterCellAnimationFilterMask = (3 << HKHubModuleGraphicsAdapterCellAnimationFilterIndex),
    
    //a = animation offset (current frame + anim offset = anim index)
    HKHubModuleGraphicsAdapterCellAnimationOffsetIndex = 24,
    HKHubModuleGraphicsAdapterCellAnimationOffsetMask = (7 << HKHubModuleGraphicsAdapterCellAnimationOffsetIndex),
    
    //g = glyph index
    HKHubModuleGraphicsAdapterCellGlyphIndexMask = 0x1fffff,
    
    //m = attribute modifier (0 = ref.cpbaif + v; 1 = ref.baif + v, cp = v; 2 = ref.cpbi + v, af = v; 3 = cpbaif = v)
    HKHubModuleGraphicsAdapterCellAttributeModifierIndex = 19,
    HKHubModuleGraphicsAdapterCellAttributeModifierMask = (3 << HKHubModuleGraphicsAdapterCellAttributeModifierIndex),
    
    //r = reference layer
    HKHubModuleGraphicsAdapterCellReferenceLayerIndex = 16,
    HKHubModuleGraphicsAdapterCellReferenceLayerMask = (7 << HKHubModuleGraphicsAdapterCellReferenceLayerIndex),
    
    //x = x position
    HKHubModuleGraphicsAdapterCellPositionXIndex = 0,
    HKHubModuleGraphicsAdapterCellPositionXMask = (0xff << HKHubModuleGraphicsAdapterCellPositionXIndex),
    
    //y = y position
    HKHubModuleGraphicsAdapterCellPositionYIndex = 8,
    HKHubModuleGraphicsAdapterCellPositionYMask = (0xff << HKHubModuleGraphicsAdapterCellPositionYIndex),
    
    HKHubModuleGraphicsAdapterCellAttributeMask = ~(HKHubModuleGraphicsAdapterCellGlyphIndexMask | HKHubModuleGraphicsAdapterCellPositionSMask | HKHubModuleGraphicsAdapterCellPositionTMask),
    HKHubModuleGraphicsAdapterCellReferenceAttributeMask = HKHubModuleGraphicsAdapterCellAttributeMask | HKHubModuleGraphicsAdapterCellPaletteOffsetMask,
    
    CC_RESERVED_BITS(HKHubModuleGraphicsAdapterCell, 0, 40)
};

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_CELL_SIZE 5

typedef struct {
    uint8_t glyphs[HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER];
    uint8_t palettes[HK_HUB_MODULE_GRAPHICS_ADAPTER_PALETTE_PAGE_COUNT][256];
    uint8_t layers[HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT][HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_HEIGHT][HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_WIDTH][HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_CELL_SIZE];
} HKHubModuleGraphicsAdapterMemory;

typedef struct {
    uint8_t frame;
    struct {
        HKHubModuleGraphicsAdapterCursor cursor;
        struct {
            uint8_t page;
            uint8_t offset;
        } palette;
        struct {
            _Bool bold : 1;
            _Bool italic : 1;
            uint8_t slope : 3;
        } style;
        struct {
            uint8_t offset;
            uint8_t filter;
        } animation;
    } attributes[HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT];
    HKHubModuleGraphicsAdapterViewport viewports[256];
    HKHubModuleGraphicsAdapterMemory memory;
} HKHubModuleGraphicsAdapterState;

static CC_FORCE_INLINE HKHubModuleGraphicsAdapterCell HKHubModuleGraphicsAdapterCellMode(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellModeMask;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetPaletteOffset(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPaletteOffsetMask) >> HKHubModuleGraphicsAdapterCellPaletteOffsetIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetS(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPositionSMask) >> HKHubModuleGraphicsAdapterCellPositionSIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetT(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPositionTMask) >> HKHubModuleGraphicsAdapterCellPositionTIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetPalettePage(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPalettePageMask) >> HKHubModuleGraphicsAdapterCellPalettePageIndex;
}

static CC_FORCE_INLINE _Bool HKHubModuleGraphicsAdapterCellIsBold(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellBoldFlag;
}

static CC_FORCE_INLINE _Bool HKHubModuleGraphicsAdapterCellIsItalic(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellItalicFlag;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetAnimationFilter(HKHubModuleGraphicsAdapterCell Cell)
{
    switch ((Cell & HKHubModuleGraphicsAdapterCellAnimationFilterMask) >> HKHubModuleGraphicsAdapterCellAnimationFilterIndex)
    {
        case 0:
            return 0xff;
            
        case 1:
            return 0xaa;
            
        case 2:
            return 0xcc;
            
        case 3:
            return 0xf0;
    }
    
    CCAssertLog(0, "Unsupported animation filter");
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetAttributeModifier(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellAttributeModifierMask) >> HKHubModuleGraphicsAdapterCellAttributeModifierIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetAnimationOffset(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellAnimationOffsetMask) >> HKHubModuleGraphicsAdapterCellAnimationOffsetIndex;
}

static CC_FORCE_INLINE uint32_t HKHubModuleGraphicsAdapterCellGetGlyphIndex(HKHubModuleGraphicsAdapterCell Cell)
{
    return Cell & HKHubModuleGraphicsAdapterCellGlyphIndexMask;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetReferenceLayer(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellReferenceLayerMask) >> HKHubModuleGraphicsAdapterCellReferenceLayerIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetX(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPositionXMask) >> HKHubModuleGraphicsAdapterCellPositionXIndex;
}

static CC_FORCE_INLINE uint8_t HKHubModuleGraphicsAdapterCellGetY(HKHubModuleGraphicsAdapterCell Cell)
{
    return (Cell & HKHubModuleGraphicsAdapterCellPositionYMask) >> HKHubModuleGraphicsAdapterCellPositionYIndex;
}

static CC_FORCE_INLINE HKHubModuleGraphicsAdapterCell HKHubModuleGraphicsAdapterCellCombineAttributes(HKHubModuleGraphicsAdapterCell Attr, HKHubModuleGraphicsAdapterCell RefAttr)
{
#define ATTR_ADD(attribute) ((Attr & ~attribute) | (((Attr & attribute) + (RefAttr & attribute)) & attribute))
    
    switch (HKHubModuleGraphicsAdapterCellGetAttributeModifier(Attr))
    {
        case 0:
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellBoldFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellItalicFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellAnimationOffsetMask);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellAnimationFilterMask);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellPalettePageMask);
            
            if (HKHubModuleGraphicsAdapterCellMode(RefAttr) == HKHubModuleGraphicsAdapterCellModeReference) Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellPaletteOffsetMask);
            break;
            
        case 1:
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellBoldFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellItalicFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellAnimationOffsetMask);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellAnimationFilterMask);
            break;
            
        case 2:
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellBoldFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellItalicFlag);
            Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellPalettePageMask);
            
            if (HKHubModuleGraphicsAdapterCellMode(RefAttr) == HKHubModuleGraphicsAdapterCellModeReference) Attr = ATTR_ADD(HKHubModuleGraphicsAdapterCellPaletteOffsetMask);
            break;
            
        default:
            break;
    }
    
    return Attr;
}

static int32_t HKHubModuleGraphicsAdapterCellIndex(HKHubModuleGraphicsAdapterMemory *Memory, size_t Layer, size_t X, size_t Y, HKHubModuleGraphicsAdapterCell *Attributes, uint8_t *S, uint8_t *T)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    CCAssertLog(X < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_WIDTH, "X must not exceed layer width");
    CCAssertLog(Y < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_HEIGHT, "Y must not exceed layer height");
    
    HKHubModuleGraphicsAdapterCell Glyph = ((HKHubModuleGraphicsAdapterCell)Memory->layers[Layer][Y][X][0] << 32)
                                         | ((HKHubModuleGraphicsAdapterCell)Memory->layers[Layer][Y][X][1] << 24)
                                         | ((HKHubModuleGraphicsAdapterCell)Memory->layers[Layer][Y][X][2] << 16)
                                         | ((HKHubModuleGraphicsAdapterCell)Memory->layers[Layer][Y][X][3] << 8)
                                         | Memory->layers[Layer][Y][X][4];
    
    if (Attributes) *Attributes = Glyph;
    
    switch (HKHubModuleGraphicsAdapterCellMode(Glyph))
    {
        case HKHubModuleGraphicsAdapterCellModeBitmap:
            if (S) *S = HKHubModuleGraphicsAdapterCellGetS(Glyph);
            if (T) *T = HKHubModuleGraphicsAdapterCellGetT(Glyph);
            if (Attributes) *Attributes = *Attributes & ~HKHubModuleGraphicsAdapterCellPaletteOffsetMask;
            return HKHubModuleGraphicsAdapterCellGetGlyphIndex(Glyph);
            
        case HKHubModuleGraphicsAdapterCellModeReference:
        {
            const size_t RefLayer = HKHubModuleGraphicsAdapterCellGetReferenceLayer(Glyph);
            if (RefLayer > Layer)
            {
                HKHubModuleGraphicsAdapterCell RefAttrs = 0;
                const int32_t Index = HKHubModuleGraphicsAdapterCellIndex(Memory, RefLayer, HKHubModuleGraphicsAdapterCellGetX(Glyph), HKHubModuleGraphicsAdapterCellGetY(Glyph), &RefAttrs, S, T);
                
                if (Attributes) *Attributes = HKHubModuleGraphicsAdapterCellCombineAttributes(Glyph, RefAttrs);
                
                return Index;
            }
        }
            
        default:
            break;
    }
    
    return -1;
}

void HKHubModuleGraphicsAdapterSetCursor(HKHubModule Adapter, uint8_t Layer, uint8_t X, uint8_t Y)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].cursor.x = X;
    State->attributes[Layer].cursor.y = Y;
}

void HKHubModuleGraphicsAdapterSetCursorVisibility(HKHubModule Adapter, uint8_t Layer, uint8_t Visibility)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].cursor.visibility = Visibility;
}

void HKHubModuleGraphicsAdapterSetCursorBounds(HKHubModule Adapter, uint8_t Layer, uint8_t X, uint8_t Y, uint8_t Width, uint8_t Height)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].cursor.bounds = (HKHubModuleGraphicsAdapterViewport){ .x = X, .y = Y, .width = Width, .height = Height };
}

void HKHubModuleGraphicsAdapterSetCursorControl(HKHubModule Adapter, uint8_t Layer, uint8_t Index, CCChar Character, uint8_t X, uint8_t Y)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    CCAssertLog(Index < HK_HUB_MODULE_GRAPHICS_ADAPTER_CURSOR_CONTROL_COUNT, "Index must not exceed cursor control count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].cursor.control[Index].character = Character;
    State->attributes[Layer].cursor.control[Index].offset.x = X;
    State->attributes[Layer].cursor.control[Index].offset.y = Y;
}

void HKHubModuleGraphicsAdapterSetPalettePage(HKHubModule Adapter, uint8_t Layer, uint8_t Page)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    CCAssertLog(Page < HK_HUB_MODULE_GRAPHICS_ADAPTER_PALETTE_PAGE_COUNT, "Page must not exceed palette page count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].palette.page = Page;
}

void HKHubModuleGraphicsAdapterSetPaletteOffset(HKHubModule Adapter, uint8_t Layer, uint8_t Offset)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].palette.offset = Offset;
}

void HKHubModuleGraphicsAdapterSetBold(HKHubModule Adapter, uint8_t Layer, _Bool Enable)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].style.bold = Enable;
}

void HKHubModuleGraphicsAdapterSetItalic(HKHubModule Adapter, uint8_t Layer, _Bool Enable)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].style.italic = Enable;
}

void HKHubModuleGraphicsAdapterSetAnimationOffset(HKHubModule Adapter, uint8_t Layer, uint8_t Offset)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].animation.offset = Offset;
}

void HKHubModuleGraphicsAdapterSetAnimationFilter(HKHubModule Adapter, uint8_t Layer, uint8_t Filter)
{
    CCAssertLog(Layer < HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, "Layer must not exceed layer count");
    
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    State->attributes[Layer].animation.filter = Filter;
}

void HKHubModuleGraphicsAdapterDrawCharacter(HKHubModule Adapter, uint8_t Layer, CCChar Character);
void HKHubModuleGraphicsAdapterDrawRef(HKHubModule Adapter, uint8_t Layer, uint8_t X, uint8_t Y, uint8_t Width, uint8_t Height, uint8_t RefLayer);

const uint8_t *HKHubModuleGraphicsAdapterGetGlyphBitmap(HKHubModule Adapter, CCChar Character, uint8_t AnimationOffset, uint8_t AnimationFilter, uint8_t *Width, uint8_t *Height, uint8_t *PaletteSize)
{
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    HKHubModuleGraphicsAdapterMemory *Memory = &State->memory;
    const uint8_t Frame = State->frame + AnimationOffset;
    
    if (!(Frame & AnimationFilter)) return NULL;
    
    //TODO: Maintain a lookup for dynamic glyph bitmaps
    for (size_t Offset = 0; (Offset + 3) < HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER; )
    {
        uint8_t BitmapWidth = (Memory->glyphs[Offset] >> 4);
        uint8_t BitmapHeight = (Memory->glyphs[Offset] & 0xf);
        uint8_t BitmapPalette = (Memory->glyphs[Offset + 1] >> 5);
        uint32_t Index = ((Memory->glyphs[Offset + 1] << 16) | (Memory->glyphs[Offset + 2] << 8) | Memory->glyphs[Offset + 3]) & HKHubModuleGraphicsAdapterCellGlyphIndexMask;
        const size_t BitmapSize = HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(BitmapWidth + 1, BitmapHeight + 1, BitmapPalette + 1);
        
        Offset += 4;
        
        if (Index == Character)
        {
            *Width = BitmapWidth;
            *Height = BitmapHeight;
            *PaletteSize = BitmapPalette;
            
            for (uint8_t Frames = 0, Animation = 0; (Animation != 0xff) && ((Offset + BitmapSize) < HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER); Animation |= Frames)
            {
                Frames = Memory->glyphs[Offset++];
                
                if (Frames & Frame) return &Memory->glyphs[Offset];
                
                Offset += BitmapSize;
            }
            
            return NULL;
        }
        
        for (uint8_t Animation = 0; (Animation != 0xff) && ((Offset + BitmapSize) < HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER); )
        {
            Animation |= Memory->glyphs[Offset++];
            Offset += BitmapSize;
        }
    }
    
    return HKHubModuleGraphicsAdapterStaticGlyphGet(Character, Width, Height, PaletteSize);
}

void HKHubModuleGraphicsAdapterBlit(HKHubModule Adapter, HKHubArchPortID Port, uint8_t *Framebuffer, size_t Size)
{
    HKHubModuleGraphicsAdapterState *State = Adapter->internal;
    HKHubModuleGraphicsAdapterMemory *Memory = &State->memory;
    
    for (size_t Y = State->viewports[Port].y, ViewportHeight = (size_t)State->viewports[Port].height + 1; Y < ViewportHeight; Y++)
    {
        for (size_t X = State->viewports[Port].x, ViewportWidth = (size_t)State->viewports[Port].width + 1; X < ViewportWidth; X++)
        {
            HKHubModuleGraphicsAdapterCell Glyph;
            uint8_t S, T;
            const int32_t Index = HKHubModuleGraphicsAdapterCellIndex(Memory, Port % HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT, X % HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_WIDTH, Y % HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_HEIGHT, &Glyph, &S, &T);
            
            if (Index != -1)
            {
                uint8_t Width, Height, PaletteSize;
                const uint8_t *Bitmap = HKHubModuleGraphicsAdapterGetGlyphBitmap(Adapter, Index, HKHubModuleGraphicsAdapterCellGetAnimationOffset(Glyph), HKHubModuleGraphicsAdapterCellGetAnimationFilter(Glyph), &Width, &Height, &PaletteSize);
                
                if (Bitmap)
                {
                    Width++;
                    Height++;
                    PaletteSize++;
                    
                    uint8_t PaletteMask = CCBitSet(PaletteSize);
                    size_t SampleBase = (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * T * PaletteSize * Width) + (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * S * PaletteSize);
                    
                    for (size_t FramebufferY = Y - State->viewports[Port].y, MaxY = CCMin(ViewportHeight, FramebufferY + HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL), SampleIndex = 0; FramebufferY < MaxY; FramebufferY++)
                    {
                        for (size_t FramebufferX = X - State->viewports[Port].x, MaxX = CCMin(ViewportWidth, FramebufferX + HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL); FramebufferX < MaxX; FramebufferX++, SampleIndex++)
                        {
                            const size_t Pixel = (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * FramebufferY * ViewportWidth) + (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * FramebufferX);
                            
                            if (Pixel < Size)
                            {
                                const uint8_t Sample = Bitmap[(SampleBase + SampleIndex) / 8];
                                const uint8_t PaletteIndex = (Sample >> (((SampleIndex % 8) / PaletteSize) * PaletteSize)) & PaletteMask;
                                Framebuffer[Pixel] = Memory->palettes[HKHubModuleGraphicsAdapterCellGetPalettePage(Glyph)][PaletteIndex + HKHubModuleGraphicsAdapterCellGetPaletteOffset(Glyph)];
                            }
                        }
                    }
                    
                    continue;
                }
            }
            
            for (size_t FramebufferY = Y - State->viewports[Port].y, MaxY = CCMin(ViewportHeight, FramebufferY + HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL); FramebufferY < MaxY; FramebufferY++)
            {
                for (size_t FramebufferX = X - State->viewports[Port].x, MaxX = CCMin(ViewportWidth, FramebufferX + HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL); FramebufferX < MaxX; FramebufferX++)
                {
                    const size_t Pixel = (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * FramebufferY * ViewportWidth) + (HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL * FramebufferX);
                    
                    if (Pixel < Size) Framebuffer[Pixel] = 0;
                }
            }
        }
    }
}

CC_ARRAY_DECLARE(uint32_t);

static CCArray(uint32_t) HKHubModuleGraphicsAdapterGlyphIndexes = CC_STATIC_ARRAY(sizeof(uint32_t), HKHubModuleGraphicsAdapterCellGlyphIndexMask + 1, 0, CC_STATIC_ALLOC_BSS(uint32_t[HKHubModuleGraphicsAdapterCellGlyphIndexMask + 1]));

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_HALF_WIDTH_GLYPH_BITMAPS ((0 << 7) | (1 << 3) | 0)
#define HK_HUB_MODULE_GRAPHICS_ADAPTER_FULL_WIDTH_GLYPH_BITMAPS ((1 << 7) | (1 << 3) | 0)

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_HALF_WIDTH_GLYPH_BITMAP_SIZE HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(1, 2, 1)
#define HK_HUB_MODULE_GRAPHICS_ADAPTER_FULL_WIDTH_GLYPH_BITMAP_SIZE HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(2, 2, 1)

static CCArray HKHubModuleGraphicsAdapterGlyphBitmaps[16 * 16 * 8][2] = {
    [0] = { CC_STATIC_ARRAY(HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(1, 1, 1), 1, 1, CC_STATIC_ALLOC_BSS(uint8_t[HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(1, 1, 1)])), NULL },
    [HK_HUB_MODULE_GRAPHICS_ADAPTER_HALF_WIDTH_GLYPH_BITMAPS] = { CC_STATIC_ARRAY(HK_HUB_MODULE_GRAPHICS_ADAPTER_HALF_WIDTH_GLYPH_BITMAP_SIZE, 2040, 0, CC_STATIC_ALLOC_BSS(uint8_t[HK_HUB_MODULE_GRAPHICS_ADAPTER_HALF_WIDTH_GLYPH_BITMAP_SIZE])), NULL },
    [HK_HUB_MODULE_GRAPHICS_ADAPTER_FULL_WIDTH_GLYPH_BITMAPS] = { CC_STATIC_ARRAY(HK_HUB_MODULE_GRAPHICS_ADAPTER_FULL_WIDTH_GLYPH_BITMAP_SIZE, 151660, 0, CC_STATIC_ALLOC_BSS(uint8_t[HK_HUB_MODULE_GRAPHICS_ADAPTER_FULL_WIDTH_GLYPH_BITMAP_SIZE])), NULL }
};

void HKHubModuleGraphicsAdapterStaticGlyphInit(void)
{
    FSPath Path = FSPathCopy(HKAssetPath);
    FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeDirectory, "graphics-adapter"));
    
    CCCollection Paths = CCCollectionCreate(CC_STD_ALLOCATOR, CCCollectionHintSizeSmall, sizeof(FSPath), FSPathDestructorForCollection);
    CCCollectionInsertElement(Paths, &(FSPath){ FSPathCreate(".glyphset") });
    CCOrderedCollection GlyphSets = FSManagerGetContentsAtPath(Path, Paths, FSMatchDefault);
    
    if (GlyphSets)
    {
        CC_COLLECTION_FOREACH(FSPath, GlyphSet, GlyphSets)
        {
            const size_t ComponentCount = FSPathGetComponentCount(GlyphSet);
            if (ComponentCount >= 4)
            {
                FSPathComponent PaletteComponent = FSPathGetComponentAtIndex(GlyphSet, ComponentCount - 2);
                FSPathComponent HeightComponent = FSPathGetComponentAtIndex(GlyphSet, ComponentCount - 3);
                FSPathComponent WidthComponent = FSPathGetComponentAtIndex(GlyphSet, ComponentCount - 4);
                
                if ((FSPathComponentGetType(WidthComponent) == FSPathComponentTypeExtension) &&
                    (FSPathComponentGetType(HeightComponent) == FSPathComponentTypeExtension) &&
                    (FSPathComponentGetType(PaletteComponent) == FSPathComponentTypeExtension))
                {
                    const char *WidthStr = FSPathComponentGetString(WidthComponent);
                    const char *HeightStr = FSPathComponentGetString(HeightComponent);
                    const char *PaletteStr = FSPathComponentGetString(PaletteComponent);
                    
                    size_t Width = WidthStr[0] - '0';
                    size_t Height = HeightStr[0] - '0';
                    size_t Palette = PaletteStr[0] - '0';
                    
                    if ((Width < 10) && (Height < 10) && (Palette < 10))
                    {
                        if (WidthStr[1]) Width = (Width * 10) + (WidthStr[1] - '0');
                        if (HeightStr[1]) Height = (Height * 10) + (HeightStr[1] - '0');
                        if (PaletteStr[1]) Palette = (Palette * 10) + (PaletteStr[1] - '0');
                        
                        const size_t BitmapSize = HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(Width, Height, Palette);
                        
                        if ((--Width < 16) && (--Height < 16) && (--Palette < 8))
                        {
                            const size_t Index = (Width << 7) | (Height << 3) | Palette;
                            
                            if (!HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0])
                            {
                                HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0] = CCArrayCreate(CC_STD_ALLOCATOR, BitmapSize, 16);
                            }
                            
                            FSHandle Handle;
                            if (FSHandleOpen(GlyphSet, FSHandleTypeRead, &Handle) == FSOperationSuccess)
                            {
#define MAX_BATCH_SIZE 16384
                                uint8_t Bitmaps[MAX_BATCH_SIZE];
                                size_t MaxCount = MAX_BATCH_SIZE / BitmapSize;
                                
                                for ( ; ; )
                                {
                                    size_t Size = BitmapSize * MaxCount;
                                    FSHandleRead(Handle, &Size, Bitmaps, FSBehaviourUpdateOffset);
                                    
                                    const size_t Count = Size / BitmapSize;
                                    if (!Count) break;
                                    
                                    if (CCArrayAppendElements(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0], Bitmaps, Count) == SIZE_MAX)
                                    {
                                        if (!HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1])
                                        {
                                            HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1] = CCArrayCreate(CC_STD_ALLOCATOR, BitmapSize, 16);
                                        }
                                        
                                        CCArrayAppendElements(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1], Bitmaps, Count);
                                    }
                                }
                                
                                FSHandleClose(Handle);
                            }
                            
                            else CC_LOG_ERROR("Failed to open glyphset file: %s", FSPathGetFullPathString(Path));
                        }
                    }
                }
            }
        }
        
        CCCollectionDestroy(GlyphSets);
    }
    
    FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeFile, "glyphset"));
    
#if CC_HARDWARE_ENDIAN_LITTLE
    FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeExtension, "little"));
#elif CC_HARDWARE_ENDIAN_BIG
    FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeExtension, "big"));
#else
#error Unknown endianness
#endif
    
    FSPathAppendComponent(Path, FSPathComponentCreate(FSPathComponentTypeExtension, "index"));
    
    if (FSManagerExists(Path))
    {
        FSHandle Handle;
        if (FSHandleOpen(Path, FSHandleTypeRead, &Handle) == FSOperationSuccess)
        {
            const size_t IndexSize = CCArrayGetElementSize(HKHubModuleGraphicsAdapterGlyphIndexes);
            size_t Size = IndexSize * CCArrayGetChunkSize(HKHubModuleGraphicsAdapterGlyphIndexes);
            
            FSHandleRead(Handle, &Size, CCArrayGetData(HKHubModuleGraphicsAdapterGlyphIndexes), FSBehaviourDefault);
            FSHandleClose(Handle);
            
            HKHubModuleGraphicsAdapterGlyphIndexes->count = Size / IndexSize;
        }
        
        else CC_LOG_ERROR("Failed to open glyphset index file: %s", FSPathGetFullPathString(Path));
    }
    
    CCCollectionDestroy(GlyphSets);
    FSPathDestroy(Path);
}

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_NULL_GLYPH_INDEX 0

void HKHubModuleGraphicsAdapterStaticGlyphSet(CCChar Character, uint8_t Width, uint8_t Height, uint8_t PaletteSize, const uint8_t *Bitmap, size_t Count)
{
    CCAssertLog(Width <= 0xf, "Width must not exceed maximum width");
    CCAssertLog(Height <= 0xf, "Height must not exceed maximum height");
    CCAssertLog(PaletteSize <= 0x7, "PaletteSize must not exceed maximum palette size");
    CCAssertLog(Count <= HKHubModuleGraphicsAdapterCellGlyphIndexMask, "Count must not exceed maximum character count");
    
    if (Bitmap)
    {
        uint32_t Index = (Width << 7) | (Height << 3)| PaletteSize;
        
        if (!HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0])
        {
            HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0] = CCArrayCreate(CC_STD_ALLOCATOR, HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(Width + 1, Height + 1, PaletteSize + 1), 16);
        }
        
        size_t First = CCArrayAppendElements(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0], Bitmap, Count);
        
        if (First == SIZE_MAX)
        {
            if (!HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1])
            {
                HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1] = CCArrayCreate(CC_STD_ALLOCATOR, HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(Width + 1, Height + 1, PaletteSize + 1), 16);
            }
            
            First = CCArrayAppendElements(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1], Bitmap, Count);
            if (First == SIZE_MAX) return;
            
            First += CCArrayGetChunkSize(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0]);
        }
        
        if ((First & ~HKHubModuleGraphicsAdapterCellGlyphIndexMask) || ((First + Count) & ~HKHubModuleGraphicsAdapterCellGlyphIndexMask))
        {
            CC_LOG_ERROR("Exceeded static glyph count: (%d, %d, %d) %zu %zu", Width, Height, PaletteSize, CCArrayGetCount(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][0]), HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1] ? CCArrayGetCount(HKHubModuleGraphicsAdapterGlyphBitmaps[Index][1]) : 0);
            return;
        }
        
        Index = (Index << 21) | (uint32_t)First;
        
        for (size_t Loop = 0; Loop < Count; Loop++)
        {
            *(uint32_t*)CCArrayGetElementAtIndex(HKHubModuleGraphicsAdapterGlyphIndexes, Character + (uint32_t)Loop) = Index + (uint32_t)Loop;
        }
    }
    
    else
    {
        for (size_t Loop = 0; Loop < Count; Loop++)
        {
            *(uint32_t*)CCArrayGetElementAtIndex(HKHubModuleGraphicsAdapterGlyphIndexes, Character + (uint32_t)Loop) = HK_HUB_MODULE_GRAPHICS_ADAPTER_NULL_GLYPH_INDEX;
        }
    }
}

const uint8_t *HKHubModuleGraphicsAdapterStaticGlyphGet(CCChar Character, uint8_t *Width, uint8_t *Height, uint8_t *PaletteSize)
{
    const uint32_t Index = Character < CCArrayGetCount(HKHubModuleGraphicsAdapterGlyphIndexes) ? *(uint32_t*)CCArrayGetElementAtIndex(HKHubModuleGraphicsAdapterGlyphIndexes, Character) : HK_HUB_MODULE_GRAPHICS_ADAPTER_NULL_GLYPH_INDEX;
    
    *Width = Index >> 28;
    *Height = (Index >> 24) & 0xf;
    *PaletteSize = (Index >> 21) & 0x7;
    
    CCArray *Bitmaps = HKHubModuleGraphicsAdapterGlyphBitmaps[Index >> 21];
    uint32_t BitmapIndex = Index & HKHubModuleGraphicsAdapterCellGlyphIndexMask;
    
    if (!Bitmaps[0]) goto NotFound;
    
    if (BitmapIndex < CCArrayGetCount(Bitmaps[0]))
    {
        return CCArrayGetElementAtIndex(Bitmaps[0], BitmapIndex);
    }
    
    const size_t ChunkSize = CCArrayGetChunkSize(Bitmaps[0]);
    
    if (BitmapIndex >= ChunkSize) goto NotFound;
    
    BitmapIndex -= CCArrayGetChunkSize(Bitmaps[0]);
    
    if (!Bitmaps[1]) goto NotFound;
    
    if (BitmapIndex < CCArrayGetCount(Bitmaps[1]))
    {
        return CCArrayGetElementAtIndex(Bitmaps[1], BitmapIndex);
    }
    
NotFound:
    CC_LOG_ERROR("Bitmap does not exist: no bitmap at index (%u) in bitmaps (%p:%zu, %p:%zu)", Index, Bitmaps[0], CCArrayGetCount(Bitmaps[0]), Bitmaps[1], CCArrayGetCount(Bitmaps[1]));
    
    return HK_HUB_MODULE_GRAPHICS_ADAPTER_NULL_GLYPH_INDEX;
}
