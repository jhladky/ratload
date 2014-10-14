#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/types.h>

#include "ratload.h"

static void check_args(const int argc, const char * argv[]);
static void loop_to_array(FILE * prog_rom);
static inline char int_to_char(const uint8_t in);
static inline uint8_t char_to_int(const char in);
static inline void force_quit(const char * phrase);

int main(const int argc, const char * argv[]) {
   struct termios options;
   uint8_t progRomArr[PROG_ROM_LINES][PROG_ROM_SEGS], c, topC;
   char progRomProper[PROG_ROM_LINES][PROG_ROM_SEGS];
   char confirm, start = 0X7E; //0X78 == '~'
   FILE * prog_rom; //fix this variable name later
   int fd, i, j, pNdx, sNdx;

   check_args(argc, argv);

   if (!strcmp(argv[1], "-f")) {
      pNdx = 2;
      sNdx = 4;
   } else {
      pNdx = 4;
      sNdx = 2;
   }

   if ((prog_rom = fopen(argv[pNdx], "r")) == NULL) {
      force_quit("Opening prog_rom failed");
   }

   if ((fd = open(argv[sNdx], O_RDWR)) == -1) {
      force_quit("Opening serial device failed");
   }

  //loop through the INIT prog_rom array
   loop_to_array(prog_rom);
   for (i = 0; i < INIT_HEIGHT; i++) {
      for (j = 0; j < INIT_WIDTH; j++) {
         c = fgetc(prog_rom);
         if (c >= '0' && c <= '9') {
            c -= '0';
         } else if (c >= 'A' && c <= 'F') {
            c = c - 'A' + 10;
         } else {
            printf("Invalid prog_rom.vhd file, exiting.\n");
            fclose(prog_rom);
            close(fd);
            exit(EXIT_FAILURE);
         }
         progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] = c;
      }
      //the " at the end of the string:
      fgetc(prog_rom);
      loop_to_array(prog_rom);
   }

   //loop through the INITP prog_rom array
   for (i = 0; i < INITP_HEIGHT; i++) {
      for (j = 0; j < INITP_WIDTH; j++) {
         c = fgetc(prog_rom);
         if (c >= '0' && c <= '9') {
            c -= '0';
         } else if (c >= 'A' && c <= 'F') {
            c = c - 'A' + 10;
         } else {
            printf("Invalid prog_rom.vhd file, exiting.\n");
            fclose(prog_rom);
            close(fd);
            exit(EXIT_FAILURE);
         }
         topC = c;
         topC &= 0x0c;
         topC = topC >> 2;
         progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = topC;

         c &= 0x03;
         progRomArr[(i * 128) + ((63 - j) * 2)][0] = c;
      }

      fgetc(prog_rom);
      loop_to_array(prog_rom);
   }

   fclose(prog_rom);

   //convert the instructions BACK to ASCII
   for (i = 0; i < PROG_ROM_LINES; i++) {
      for (j = 0; j < PROG_ROM_SEGS; j++) {
         progRomProper[i][j] = int_to_char(progRomArr[i][j]);
      }
   }

   //configuration of the serial port
   if (tcgetattr(fd, &options) == -1) {
      force_quit("Serial Configuration failed.");
   }

   cfsetispeed(&options, B9600);
   cfsetospeed(&options, B9600);
   options.c_cflag |= (CLOCAL | CREAD);
   options.c_cflag |= PARENB;
   options.c_cflag |= PARODD;
   options.c_cflag &= ~CSTOPB;
   options.c_cflag &= ~CSIZE;
   options.c_cflag |= CS8;
   options.c_cflag &= ~CRTSCTS; //disable hardware flow control

   if (tcsetattr(fd, TCSANOW, &options) == -1) {
      force_quit("Serial Configuration failed");
   }

   //confirm = 0x7F;

   //for debugging
#ifdef DEBUG
   for (i = 0; i < 32; i++) {
      for (j = 4; j > -1; j--) {
         printf("%c", progRomProper[i][j]);
      }
      printf("\n");
   }
#endif

   //send the start byte, wait until we get it back
   //then we can start sending the actual data
   if (write(fd, &start, 1) < 1 ||
       read(fd, &confirm, 1) < 1) {
      force_quit("Error communicating with Nexys2 board.\n");
   }

   fprintf(stderr, "Connection opened: sending data...");

   //send the instructions to the UART
   for (i = 0; i < 1024; i++) {
      for (j = 4; j > -1; j--) {
         if (write(fd, &progRomProper[i][j], 1) < 1 ||
             read(fd, &confirm, 1) < 1) {
            force_quit("Error communicating with Nexys2 board.\n");
         }
      }
   }

   printf("Finished!\n");
   close(fd);

   return EXIT_SUCCESS;
}

//make sure we are specifying -f \path\to\file
static void check_args(const int argc, const char * argv[]) {
   if (argc != NUM_ARGS) {
      printf("Too %s arguments.\n", argc > NUM_ARGS ? "many" : "few");
      printf("Please specify a file (-f) and serial TTY (-d)\n");
      exit(EXIT_FAILURE);
   } else if ((strcmp(argv[1], "-f") && strcmp(argv[3], "-f")) ||
              (strcmp(argv[1], "-d") && strcmp(argv[3], "-d"))) {
      printf("Option not supported. Only -f and -d supported\n");
      exit(EXIT_FAILURE);
   }
}

//loop to get to the beginning of the data
static void loop_to_array(FILE * prog_rom) {
   char a = ' ';

   while (a != '"') {
      a = fgetc(prog_rom);
   }
}

static inline char int_to_char(const uint8_t in) {
   return in + (in <= 9 ? '0' : ('A' - 10));
}

static inline uint8_t char_to_int(const char in) {
   //fill me out
   return in;
}

static inline void force_quit(const char* phrase) {
   perror(phrase);
   exit(EXIT_FAILURE);
}
