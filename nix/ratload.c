#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/types.h>

#include "ratload.h"

static void parse_args(char** parsed, const int argc, char* argv[]);
static int config_and_handshake(int* fd, const char* port);
static int program_board(const char* fileName, const char* portName);
static int run_serial_test(const char* portName);
static void loop_to_array(FILE * prog_rom);
static inline char int_to_char(const uint8_t in);
static int char_to_int(uint8_t* out, char in);

static const char* err2Str[NUM_ERRORS + 1] = {
   "",                                    // 0
   "File not found.",                     // 1
   "Invalid prog_rom file.",              // 2
   "Bad file read.",                      // 3
   "Bad serial device.",                  // 4
   "Configuring serial device failed.",   // 5
   "Handshake with Nexys board failed.",  // 6
   "Received bad data from Nexys board.", // 7
   "Timeout."                             // 8
};

int main(const int argc, char* argv[]) {
   int res;
   char* parsed[2] = {"", ""};

   parse_args(parsed, argc, argv);

   if (parsed[0] == NULL) {
      res = run_serial_test(parsed[1]);
   } else {
      res = program_board(parsed[0], parsed[1]);
   }

   if (res) {
      fprintf(stderr, "%s\n", err2Str[res]);
   }

   return 0;
}

static int run_serial_test(const char* portName) {
   uint8_t confirm, i;
   int sp, res;

   if ((res = config_and_handshake(&sp, portName))) {
      return res;
   }

   for (i = 0; i < TEST_LENGTH; i++) {
      confirm = int_to_char(i);
      if (write(sp, &confirm, 1) < 1) {
         close(sp);
         perror("write");
         return E_BAD_DEV;
      }

      if (read(sp, &confirm, 1) < 1) {
         close(sp);
         perror("read");
         return E_BAD_DEV;
      }

      if (confirm != int_to_char(i)) {
         return E_BAD_DATA;
      }
   }

   return 0;
}

static int program_board(const char* fileName, const char* portName) {
   uint8_t progRomArr[PROG_ROM_LINES][PROG_ROM_SEGS], b;
   char progRomProper[PROG_ROM_LINES][PROG_ROM_SEGS];
   FILE * progRom;
   char confirm;
   int i, j, fd, res;

   if ((progRom = fopen(fileName, "r")) == NULL) {
      return E_NO_FILE;
   }

   // Loop through the INIT prog_rom array.
   loop_to_array(progRom);
   for (i = 0; i < INIT_HEIGHT; i++) {
      for (j = 0; j < INIT_WIDTH; j++) {
         if ((res = char_to_int(&b, fgetc(progRom)))) {
            fclose(progRom);
            return res;
         }
         progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] = b;
      }
      // The " at the end of the string.
      fgetc(progRom);
      loop_to_array(progRom);
   }

   // Loop through the INITP prog_rom array.
   for (i = 0; i < INITP_HEIGHT; i++) {
      for (j = 0; j < INITP_WIDTH; j++) {
         if ((res = char_to_int(&b, fgetc(progRom)))) {
            fclose(progRom);
            return res;
         }
         progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = (b & 0X0C) >> 2;
         progRomArr[(i * 128) + ((63 - j) * 2)][0] = b & 0x03;
      }
      fgetc(progRom);
      loop_to_array(progRom);
   }

   fclose(progRom);

   //convert the instructions BACK to ASCII
   for (i = 0; i < PROG_ROM_LINES; i++) {
      for (j = 0; j < PROG_ROM_SEGS; j++) {
         progRomProper[i][j] = int_to_char(progRomArr[i][j]);
      }
   }

   if ((res = config_and_handshake(&fd, portName))) {
      return res;
   }

   printf("Connection opened: sending data\n");

   //send the instructions to the UART
   for (i = 0; i < 1024; i++) {
      for (j = 4; j > -1; j--) {
         if (write(fd, &progRomProper[i][j], 1) < 1 ||
             read(fd, &confirm, 1) < 1) {
            perror("write");
            return E_BAD_DEV;
         }
      }
      if (!(i % 103)) {
         printf("%d%% ", (int) (i / 1024.0 * 100));
         fflush(stdout);
      }
   }

   close(fd);
   printf("\nFinished.\n");

   return 0;
}

static int config_and_handshake(int* sp, const char* portName) {
   struct termios options;
   char confirm = MAGIC_BYTE;

   if ((*sp = open(portName, O_RDWR)) == -1) {
      perror("open");
      return E_BAD_DEV;
   }

   // Configuration of the serial port.
   if (tcgetattr(*sp, &options) == -1) {
      perror("tcgetattr");
      return E_CONF_FAIL;
   }

   cfsetispeed(&options, B57600);
   cfsetospeed(&options, B57600);
   //options.c_cflag = CLOCAL | CREAD | PARENB | PARODD | CS8;
   options.c_cflag = CLOCAL | CREAD | PARENB | PARODD | CS8;
   options.c_iflag = 0;
   options.c_oflag = 0;
   options.c_lflag = ICANON;

   if (tcsetattr(*sp, TCSANOW, &options) == -1) {
      close(*sp);
      perror("tcsetattr");
      return E_CONF_FAIL;
   }

   fprintf(stderr, "HERE1 sp is %d\n", *sp);

   if (write(*sp, &confirm, 1) < 1) {
      close(*sp);
      perror("write");
      return E_BAD_DEV;
   }
   fprintf(stderr, "HERE2 sp is %d\n", *sp);

   confirm = 0;

   if (read(*sp, &confirm, 1) < 1) {
      close(*sp);
      perror("read");
      return E_BAD_DEV;
   }

   fprintf(stderr, "HERE3\n");

   if (confirm != MAGIC_BYTE) {
      close(*sp);
      return E_HANDSHAKE;
   }

   return 0;
}

static void parse_args(char** parsed, const int argc, char* argv[]) {
   bool fFound = false, dFound = false, lFound = false,
      hFound = false, tFound = false;
   int i;

   for (i = 0; i < argc; i++) {
      if (i < argc - 1 &&
          (!strcmp(argv[i], "-f") || !strcmp(argv[i], "--file"))) {
         fFound = true;
         parsed[0] = argv[i + 1];
         i++;
      } else if (i < argc - 1 &&
                 (!strcmp(argv[i], "-d") || !strcmp(argv[i], "--device"))) {
         dFound = true;
         parsed[1] = argv[i + 1];
         i++;
      } else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
         hFound = true;
      } else if (!strcmp(argv[i], "-l") || !strcmp(argv[i], "--list")) {
         lFound = true;
      } else if (!strcmp(argv[i], "-t") || !strcmp(argv[i], "--test")) {
         tFound = true;
      }
   }

   if (!hFound && lFound) {
      printf("Serial port listing not supported on this platform.\n");
      exit(EXIT_SUCCESS);
   } else if (hFound || (!tFound && (!fFound || !dFound)) ||
              (tFound && !dFound) || (tFound && fFound)) {
      printf("Usage: ratload -d|--device <serial device> "
             "-f|--file <prog_rom file>\n"
             "       (program Nexys2 board)\n"
             "   or  ratload -d|--device <serial device> -t|--test\n"
             "       (run serial connection test)\n"
             "   or  ratload -l|--list\n"
             "       (list available serial devices)\n"
             "   or  ratload -h|--help\n"
             "       (print this message)\n");
      exit(EXIT_FAILURE);
   }

   if (tFound) {
      parsed[0] = NULL;
   }
}

//loop to get to the beginning of the data
static void loop_to_array(FILE * progRom) {
   char a = ' ';

   while (a != '"') {
      a = fgetc(progRom);
   }
}

static inline char int_to_char(const uint8_t in) {
   return in + (in <= 9 ? '0' : ('A' - 10));
}

static int char_to_int(uint8_t* out, char in) {
   int err = 0;

   if (in >= '0' && in <= '9') {
      *out = in - '0';
   } else if (in >= 'A' && in <= 'F') {
      *out = in - 'A' + 10;
   } else {
      err = E_BAD_FILE;
   }

   return err;
}
