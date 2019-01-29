/*
 *  Copyright (c) 2019, Stefan Johnson
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

#include "RapServer.h"
#include <sys/socket.h>
#include <netinet/in.h>

#define HK_RAP_SERVER_PORT 9999

typedef enum {
    HKRapServerOperationOpen = 1,
    HKRapServerOperationRead,
    HKRapServerOperationWrite,
    HKRapServerOperationSeek,
    HKRapServerOperationClose,
    HKRapServerOperationSystem,
    HKRapServerOperationCmd,
    
    HKRapServerOperationReply = 0x80
} HKRapServerOperation;

typedef struct {
    uint8_t op; // HKRapServerOperation
    union {
        struct {
            uint8_t rw;
            uint32_t length;
            uint8_t filename[];
        } open;
        struct {
            uint32_t length;
        } read;
        struct {
            uint32_t length;
            uint8_t data[];
        } write;
        struct {
            uint8_t flag;
            uint64_t offset;
        } seek;
        struct {
            uint32_t fd;
        } close;
        struct {
            uint32_t length;
            uint8_t command[];
        } system;
        struct {
            uint32_t length;
            uint8_t command[];
        } cmd;
    };
} HKRapServerDataRequest;

typedef struct {
    uint8_t op; // HKRapServerOperation
    union {
        struct {
            uint32_t fd;
        } open;
        struct {
            uint32_t length;
            uint8_t data[];
        } read;
        struct {
            uint32_t length;
        } write;
        struct {
            uint64_t offset;
        } seek;
        struct {
            uint32_t ret;
        } close;
        struct {
            uint32_t length;
            uint8_t result[];
        } system;
        struct {
            uint32_t length;
            uint8_t result[];
        } cmd;
    };
} CC_PACKED HKRapServerDataResponse;

#define HK_RAP_SERVER_DATA_OP_SIZE sizeof(uint8_t)

#define HK_RAP_SERVER_DATA_RESPONSE_OPEN_SIZE           (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->open)))
#define HK_RAP_SERVER_DATA_RESPONSE_READ_SIZE(length)   (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->read)) + length)
#define HK_RAP_SERVER_DATA_RESPONSE_WRITE_SIZE          (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->write)))
#define HK_RAP_SERVER_DATA_RESPONSE_SEEK_SIZE           (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->seek)))
#define HK_RAP_SERVER_DATA_RESPONSE_CLOSE_SIZE          (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->close)))
#define HK_RAP_SERVER_DATA_RESPONSE_SYSTEM_SIZE(length) (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->system)) + length)
#define HK_RAP_SERVER_DATA_RESPONSE_CMD_SIZE(length)    (HK_RAP_SERVER_DATA_OP_SIZE + sizeof(typeof(((HKRapServerDataResponse*)NULL)->cmd)) + length)

static int RapServerLoop(void *Arg)
{
    int SockFd = socket(AF_INET, SOCK_STREAM, 0);
    if (SockFd == -1)
    {
        CC_LOG_ERROR("Failed to create RAP server due to socket creation failure");
        return EXIT_FAILURE;
    }
    
    if (setsockopt(SockFd, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int)) == -1)
    {
        
        CC_LOG_ERROR("Failed to create RAP server due to setting socket option failure");
        close(SockFd);
        return EXIT_FAILURE;
    }
    
    if (setsockopt(SockFd, SOL_SOCKET, SO_REUSEPORT, &(int){ 1 }, sizeof(int)) == -1)
    {
        
        CC_LOG_ERROR("Failed to create RAP server due to setting socket option failure");
        close(SockFd);
        return EXIT_FAILURE;
    }
    
    struct sockaddr_in Address = {
        .sin_family = AF_INET,
        .sin_addr = {
            .s_addr = INADDR_ANY
        },
        .sin_port = htons(HK_RAP_SERVER_PORT)
    };
    
    if (bind(SockFd, (struct sockaddr*)&Address, sizeof(Address)) == -1)
    {
        CC_LOG_ERROR("Failed to create RAP server due to address binding failure");
        close(SockFd);
        return EXIT_FAILURE;
    }
    
    if (listen(SockFd, 32) == -1)
    {
        CC_LOG_ERROR("Failed to listen for connections to RAP server");
        close(SockFd);
        return EXIT_FAILURE;
    }
    
    uint8_t Buffer[256];
    for ( ; ; )
    {
        int Connection = accept(SockFd, (struct sockaddr*)&Address, &(socklen_t){ sizeof(Address) });
        if (Connection == -1) CC_LOG_ERROR("Failed to accept incoming connection to RAP server");
        
        for ( ; Connection != -1; )
        {
            ssize_t Size = recv(Connection, Buffer, sizeof(Buffer) / sizeof(typeof(*Buffer)), 0);
            if (Size > 0)
            {
                switch (((HKRapServerDataRequest*)Buffer)->op)
                {
                    case HKRapServerOperationOpen:
                    {
                        uint32_t Fd = 1;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->open.fd = htonl(Fd);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_OPEN_SIZE, 0);
                        if (Size == -1) perror("reply open");
                        break;
                    }
                        
                    case HKRapServerOperationRead:
                    {
                        uint32_t Length = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->read.length = htonl(Length);
                        memcpy(((HKRapServerDataResponse*)Buffer)->read.data, (uint8_t[]){ 0 }, Length);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_READ_SIZE(Length), 0);
                        if (Size == -1) perror("reply read");
                        break;
                    }
                        
                    case HKRapServerOperationWrite:
                    {
                        uint32_t Length = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->write.length = htonl(Length);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_WRITE_SIZE, 0);
                        if (Size == -1) perror("reply write");
                        break;
                    }
                        
                    case HKRapServerOperationSeek:
                    {
                        uint64_t Offset = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->seek.offset = htonll(Offset);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_SEEK_SIZE, 0);
                        if (Size == -1) perror("reply seek");
                        break;
                    }
                        
                    case HKRapServerOperationClose:
                    {
                        uint32_t Ret = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->close.ret = htonl(Ret);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_CLOSE_SIZE, 0);
                        if (Size == -1) perror("reply close");
                        
                        close(Connection); Connection = -1;
                        break;
                    }
                        
                    case HKRapServerOperationSystem:
                    {
                        uint32_t Length = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->system.length = htonl(Length);
                        memcpy(((HKRapServerDataResponse*)Buffer)->system.result, (uint8_t[]){ 0 }, Length);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_SYSTEM_SIZE(Length), 0);
                        if (Size == -1) perror("reply system");
                        break;
                    }
                        
                    case HKRapServerOperationCmd:
                    {
                        uint32_t Length = 0;
                        ((HKRapServerDataResponse*)Buffer)->op |= HKRapServerOperationReply;
                        ((HKRapServerDataResponse*)Buffer)->cmd.length = htonl(Length);
                        memcpy(((HKRapServerDataResponse*)Buffer)->cmd.result, (uint8_t[]){ 0 }, Length);
                        Size = send(Connection, Buffer, HK_RAP_SERVER_DATA_RESPONSE_CMD_SIZE(Length), 0);
                        if (Size == -1) perror("reply cmd");
                        break;
                    }
                }
            }
            
            else if (Size == -1) perror("read");
            
            if (Size <= 0) break;
        }
        
        if (Connection != -1) close(Connection);
    }
    
    return EXIT_SUCCESS;
}

static thrd_t RapServerThread;
void HKRapServerStart(void)
{
    int err;
    if ((err = thrd_create(&RapServerThread, (thrd_start_t)RapServerLoop, NULL)) != thrd_success)
    {
        CC_LOG_ERROR("Failed to create rap server thread (%d)", err);
        return;
    }
}
