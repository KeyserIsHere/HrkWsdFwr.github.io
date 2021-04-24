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

@import Foundation;
@import CoreText;
@import CoreGraphics;
@import AppKit;

static const size_t Cell = 7 * 2;
static const size_t Width = Cell * 2, Height = Cell * 2;
static uint8_t Data[Width * 4 * Height];

static __strong NSMutableArray *DefaultFonts = nil;

static void InitDefaults(void)
{
    DefaultFonts = [NSMutableArray array];
    
    const float FontSize = 12.0f;
    const CFStringRef FontNames[] = {
        CFSTR("Andale Mono"),
        CFSTR("Arial Unicode MS"),
        CFSTR("GB18030 Bitmap"),
        CFSTR("Monaco"),
        CFSTR("LucidaGrande"),
        CFSTR("CourierNewPSMT"),
        CFSTR("GeezaPro"),
        CFSTR("NotoNastaliqUrdu"),
        CFSTR("Ayuthaya"),
        CFSTR("Kailasa"),
        CFSTR("PingFangSC-Regular"),
        CFSTR("PingFangTC-Regular"),
        CFSTR("PingFangTC-Regular"),
        CFSTR("PingFangSC-Regular"),
        CFSTR("PingFangHK-Regular"),
        CFSTR("PingFangSC-Regular"),
        CFSTR("HiraginoSans-W3"),
        CFSTR("HiraginoSansGB-W3"),
        CFSTR("AppleSDGothicNeo-Regular"),
        CFSTR("KohinoorBangla-Regular"),
        CFSTR("KohinoorDevanagari-Regular"),
        CFSTR("GujaratiSangamMN"),
        CFSTR("GurmukhiMN"),
        CFSTR("KannadaSangamMN"),
        CFSTR("KhmerSangamMN"),
        CFSTR("LaoSangamMN"),
        CFSTR("MalayalamSangamMN"),
        CFSTR("MyanmarSangamMN"),
        CFSTR("OriyaSangamMN"),
        CFSTR("SinhalaSangamMN"),
        CFSTR("TamilSangamMN"),
        CFSTR("KohinoorTelugu-Regular"),
        CFSTR("Mshtakan"),
        CFSTR("EuphemiaUCAS"),
        CFSTR("PlantagenetCherokee"),
        CFSTR("Kefa-Regular")
    };
    
    for (size_t Loop = 0; Loop < sizeof(FontNames) / sizeof(typeof(*FontNames)); Loop++)
    {
        CGFontRef Font = CGFontCreateWithFontName(FontNames[Loop]);
        if (Font)
        {
            [DefaultFonts addObject: CTFontCreateWithGraphicsFont(Font, FontSize, NULL, NULL)];
            CGFontRelease(Font);
        }
    }
}
