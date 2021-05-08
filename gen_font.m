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
            [DefaultFonts addObject: @[CTFontCreateWithGraphicsFont(Font, FontSize, NULL, NULL), @0.0f]];
            CGFontRelease(Font);
        }
    }
}

static NSArray *ParseFonts(FILE *Input, _Bool Verbose)
{
    NSMutableArray *Fonts = [NSMutableArray array];
    
    char FontName[256] = {0};
    for (float FontSize = 12.0f, BaselineOffset = 0.0f; fscanf(Input, "%*1[ ]\"%255[^\"\n]\":%f,%f", FontName, &FontSize, &BaselineOffset); FontSize = 12.0f, BaselineOffset = 0.0f)
    {
        CGFontRef Font = CGFontCreateWithFontName([NSString stringWithUTF8String: FontName]);
        if (Font)
        {
            [Fonts addObject: @[CTFontCreateWithGraphicsFont(Font, FontSize, NULL, NULL), @(BaselineOffset)]];
            CGFontRelease(Font);
        }
        
        else if (Verbose) fprintf(stderr, "No font for name: %s\n", FontName);
    }
    
    return Fonts;
}

typedef struct {
    FILE *file;
    size_t count;
} Resource;

static void ParseMap(CGContextRef Ctx, CGRect Rect, FILE *Input, Resource *Indexes, Resource *Bitmaps, _Bool Verbose, _Bool SaveImage)
{
    uint32_t Start = 0, Stop = 0;
    switch (fscanf(Input, "U+%x-%x", &Start, &Stop))
    {
        case 0:
            fscanf(Input, "%lc", &Start);
        case 1:
            Stop = Start;
            break;
            
        default:
            if (Start > Stop)
            {
                if (Verbose) fprintf(stderr, "Invalid character range (must be ascending): U+%.4x-%.4x\n", Start, Stop);
                
                return;
            }
            break;
    }
    
    NSArray *Fonts = ParseFonts(Input, Verbose);
    if (!Fonts.count) Fonts = DefaultFonts;
    
    for ( ; Start; Start++)
    {
        NSString *String = [[NSString alloc] initWithBytes: &(uint32_t){ NSSwapHostIntToLittle(Start) } length: sizeof(Start) encoding: NSUTF32LittleEndianStringEncoding];
        
        if (String.length)
        {
            CGContextSetRGBFillColor(Ctx, 0.0, 0.0, 0.0, 1.0);
            CGContextFillRect(Ctx, Rect);
            
            CFMutableAttributedStringRef AttributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
            
            CFAttributedStringReplaceString(AttributedString, (CFRange){ 0, 0 }, (CFStringRef)String);
            NSUInteger Location = 0;
            CFRange CurrentRange = { Location, 1 };
            Location += CurrentRange.length;
            
            CGColorRef Colour = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);
            CFAttributedStringSetAttribute(AttributedString, CurrentRange, kCTForegroundColorAttributeName, Colour);
            CGColorRelease(Colour);
            
            Colour = CGColorCreateGenericRGB(0.0f, 0.0f, 1.0f, 1.0f);
            CFAttributedStringSetAttribute(AttributedString, CurrentRange, kCTBackgroundColorAttributeName, Colour);
            CGColorRelease(Colour);
            
            for (id Font in Fonts)
            {
                CFAttributedStringSetAttribute(AttributedString, CurrentRange, kCTFontAttributeName, Font[0]);
                CFAttributedStringSetAttribute(AttributedString, CurrentRange, kCTBaselineOffsetAttributeName, Font[1]);
                
                CGMutablePathRef Path = CGPathCreateMutable();
                CGPathAddRect(Path, NULL, Rect);
                
                CTFramesetterRef Framesetter = CTFramesetterCreateWithAttributedString(AttributedString);
                CTFrameRef Frame = CTFramesetterCreateFrame(Framesetter, CurrentRange, Path, NULL);
                CTFrameDraw(Frame, Ctx);
                
                CFRelease(Path);
                CFRelease(Framesetter);
                CFRelease(Frame);
                
                for (size_t Loop = 0; Loop < sizeof(Data) / 4; Loop += 4)
                {
                    if (Data[Loop + 2] != 0)
                    {
                        if (SaveImage)
                        {
                            CGImageRef Image = CGBitmapContextCreateImage(Ctx);
                            [((NSImage*)[[NSImage alloc] initWithCGImage: Image size: NSZeroSize]).TIFFRepresentation writeToFile: [NSString stringWithFormat: @"U+%.4x.tiff", Start] atomically: NO];
                            CGImageRelease(Image);
                        }
                        
                        size_t Y = (Loop / 4) / Width;
                        size_t X = (Loop / 4) - (Y * Width);
                        size_t MaxX = X, MaxY = Y;
                        
                        for ( ; Loop < sizeof(Data) / 4; Loop += 4)
                        {
                            if (Data[Loop] != 0)
                            {
                                Y = (Loop / 4) / Width;
                                X = (Loop / 4) - (Y * Width);
                                
                                if (X > MaxX) MaxX = X;
                                if (Y > MaxY) MaxY = Y;
                            }
                        }
                        
                        const size_t MaxWidth = (MaxX / Cell) + 1, MaxHeight = (MaxY / Cell) + 1;
                        
                        
                        goto Rendered;
                    }
                }
            }
            
            if (Verbose) fprintf(stderr, "No font with glyph for character: U+%.4x\n", Start);
            
        Rendered:
            
            CFRelease(AttributedString);
        }
        
        if (Start == Stop) break;
    }
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        InitDefaults();
        
        _Bool Verbose = TRUE, SaveImage = TRUE;
        
        CGColorSpaceRef ColourSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef Ctx = CGBitmapContextCreate(Data, Width, Height, 8, Width * 4, ColourSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(ColourSpace);
        
        CGContextSetAllowsFontSmoothing(Ctx, FALSE);
        CGContextSetShouldAntialias(Ctx, FALSE);
        CGContextSetAllowsAntialiasing(Ctx, FALSE);
        
        CGContextSetRGBFillColor(Ctx, 0.0, 0.0, 0.0, 1.0);
        
        const CGRect Rect = CGRectMake(0.0f, 0.0f, Width, Height);
        
        Resource Indexes[2] = {
            { .file = fopen("glyphset.little.index", "wb"), .count = 0 },
            { .file = fopen("glyphset.big.index", "wb"), .count = 0 }
        };
        Resource Bitmaps[2] = {
            { .file = fopen("unicode.1.2.1.glyphset", "wb"), .count = 0 },
            { .file = fopen("unicode.2.2.1.glyphset", "wb"), .count = 0 }
        };
        
        ParseMap(Ctx, Rect, stdin, Indexes, Bitmaps, Verbose, SaveImage);
        
        fclose(Indexes[0].file);
        fclose(Indexes[1].file);
        fclose(Bitmaps[0].file);
        fclose(Bitmaps[1].file);
    }
    
    return 0;
}
