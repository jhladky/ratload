#ifndef __RATLOAD_H__
#define __RATLOAD_H__

#define NUM_ARGS 5
#define PROG_ROM_LINES 1024
#define PROG_ROM_SEGS 5

#define INIT_HEIGHT 64
#define INIT_WIDTH 64
#define INITP_HEIGHT 8
#define INITP_WIDTH 64
#define MAGIC_BYTE 0X7E
#define TEST_LENGTH 16

///errors///
#define E_NO_FILE      1
#define E_BAD_FILE     2
#define E_BAD_READ     3
#define E_BAD_DEV      4
#define E_CONF_FAIL    5
#define E_HANDSHAKE    6
#define E_BAD_DATA     7
#define E_TIMEOUT      8

#define NUM_ERRORS     8

#endif
