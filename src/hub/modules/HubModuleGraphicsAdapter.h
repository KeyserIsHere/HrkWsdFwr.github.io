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

#ifndef HackingGame_HubModuleGraphicsAdapter_h
#define HackingGame_HubModuleGraphicsAdapter_h

#include "HubModule.h"
#include "HubArchProcessor.h"

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL 7

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BITMAP_SIZE(width, height, palette) (((((width) * HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL) * ((height) * HK_HUB_MODULE_GRAPHICS_ADAPTER_CELL) * (palette)) + 7) / 8)

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_GLYPH_BUFFER 1024

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_PALETTE_PAGE_COUNT 8

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_WIDTH 256
#define HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_HEIGHT 256

#define HK_HUB_MODULE_GRAPHICS_ADAPTER_LAYER_COUNT 8

/*!
 * @brief Initialise the static glyphs.
 */
void HKHubModuleGraphicsAdapterStaticGlyphInit(void);

#endif
