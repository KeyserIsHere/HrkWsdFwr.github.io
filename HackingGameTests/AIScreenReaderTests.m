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

#import <XCTest/XCTest.h>
#import "AIScreenReader.h"

@interface AIScreenReaderTests : XCTestCase

@end

@implementation AIScreenReaderTests

-(void) testNormalize
{
#define S(x) ((x) << HKHubModuleGraphicsAdapterCharacterPositionSIndex)
#define T(x) ((x) << HKHubModuleGraphicsAdapterCharacterPositionTIndex)

    
    HKHubModuleGraphicsAdapterCharacter Characters[5][4] = {
        { S(0) | T(0) | 1, S(0) | T(0) | 2, S(1) | T(0) | 2, S(0) | T(0) | 3 },
        { S(0) | T(1) | 1, S(0) | T(1) | 2, S(1) | T(1) | 2, 0 },
        { S(0) | T(0) | 1, S(0) | T(2) | 2, S(0) | T(0) | 2, 0 },
        { S(0) | T(0) | 1, S(0) | T(0) | 2, S(1) | T(1) | 2, S(0) | T(0) | 3 },
        { 0, 0, 0, S(0) | T(1) | 4 }
    };
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 2);
    
    XCTAssertEqual(Characters[0][0], S(0) | T(1) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], S(1) | T(1) | 2, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][3], S(0) | T(0) | 3, @"Should merge");
    
    XCTAssertEqual(Characters[1][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[1][1], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[1][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[1][3], 0, @"Should not merge");
    
    XCTAssertEqual(Characters[2][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[2][1], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[2][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[2][3], S(0) | T(0) | 3, @"Should merge");
    
    XCTAssertEqual(Characters[3][0], S(0) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[3][1], S(0) | T(0) | 2, @"Should merge");
    XCTAssertEqual(Characters[3][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[3][3], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    XCTAssertEqual(Characters[4][0], 0, @"Should not be normalized");
    XCTAssertEqual(Characters[4][1], 0, @"Should not be normalized");
    XCTAssertEqual(Characters[4][2], 0, @"Should not be normalized");
    XCTAssertEqual(Characters[4][3], S(0) | T(1) | 4, @"Should not be normalized");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = S(1) | T(0) | 1;
    Characters[0][2] = S(2) | T(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(2) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = S(1) | T(0) | 1;
    Characters[0][2] = S(2) | T(1) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(1) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = S(1) | T(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(0) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], 0, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = S(2) | T(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(0) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], 0, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(1) | 1;
    Characters[0][1] = S(1) | T(0) | 1;
    Characters[0][2] = S(2) | T(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][1], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = S(1) | T(0) | 1;
    Characters[0][2] = S(2) | T(0) | 2;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(1) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][2], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");
    
    Characters[0][0] = S(0) | T(0) | 1;
    Characters[0][1] = S(1) | T(0) | 1;
    Characters[0][2] = S(0) | T(0) | 1;
    Characters[0][3] = S(1) | T(0) | 1;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 4, 5, 9, 1);
    XCTAssertEqual(Characters[0][0], S(1) | T(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    XCTAssertEqual(Characters[0][2], S(1) | T(0) | 1, @"Should not merge");
    XCTAssertEqual(Characters[0][3], HK_AI_SCREEN_READER_SKIP_CHAR, @"Should merge");
    
    Characters[0][0] = T(0) | S(0) | 1;
    Characters[0][1] = T(1) | S(0) | 1;
    Characters[0][2] = T(2) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], T(2) | S(0) | 1, @"Should merge");
    XCTAssertEqual(Characters[0][1], T(1) | S(0) | 1, @"Should not merge");
    XCTAssertEqual(Characters[0][2], T(2) | S(0) | 1, @"Should not merge");
    XCTAssertEqual(Characters[0][3], 0, @"Should merge");

    Characters[0][0] = T(0) | S(0) | 1;
    Characters[0][1] = T(1) | S(0) | 1;
    Characters[0][2] = T(2) | S(1) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");

    Characters[0][0] = T(0) | S(0) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = T(1) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");

    Characters[0][0] = T(0) | S(0) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = T(0) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = T(0) | S(0) | 1;
    Characters[0][2] = T(0) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = T(0) | S(0) | 1;
    Characters[0][2] = T(1) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], T(1) | S(0) | 1, @"Should merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = T(0) | S(0) | 1;
    Characters[0][2] = 0;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], T(0) | S(0) | 1, @"Should merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = T(0) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], T(0) | S(0) | 1, @"Should merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = 0;
    Characters[0][3] = T(0) | S(0) | 1;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], T(0) | S(0) | 1, @"Should merge");

    Characters[0][0] = T(0) | S(1) | 1;
    Characters[0][1] = T(1) | S(0) | 1;
    Characters[0][2] = T(2) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = T(0) | S(0) | 1;
    Characters[0][1] = T(1) | S(0) | 1;
    Characters[0][2] = T(2) | S(1) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = T(1) | S(0) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = 0;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = T(1) | S(0) | 1;
    Characters[0][2] = 0;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = T(1) | S(0) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = 0;
    Characters[0][3] = T(1) | S(0) | 1;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = T(0) | S(1) | 1;
    Characters[0][1] = 0;
    Characters[0][2] = 0;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = T(0) | S(1) | 1;
    Characters[0][2] = 0;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = T(0) | S(1) | 1;
    Characters[0][3] = 0;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
    
    Characters[0][0] = 0;
    Characters[0][1] = 0;
    Characters[0][2] = 0;
    Characters[0][3] = T(0) | S(1) | 1;
    HKAIScreenReaderNormalize((HKHubModuleGraphicsAdapterCharacter*)Characters, 1, 4, 9, 4);
    XCTAssertEqual(Characters[0][0], HK_AI_SCREEN_READER_INCOMPLETE_CHAR_FLAG | 9, @"Should not merge");
}

@end
