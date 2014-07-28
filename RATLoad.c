#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>

#include "RATLoad.h"

static void check_args(const int argc, const char * argv[]);
static void loop_to_array(FILE * prog_rom);
static inline char int_to_char(const uint8_t in);
static inline void force_quit(const char* phrase);

int main(const int argc, const char * argv[]) {
   uint8_t progRomArr[1024][5], c, topC;
   char progRomProper[1024][5];
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
   for (i = 0; i < 64; i++) {
      for (j = 0; j < 64; j++) {
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
   for (i = 0; i < 8; i++) {
      for (j = 0; j < 64; j++) {
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
   for (i = 0; i < 1024; i++) {
      for (j = 0; j < 5; j++) {
         progRomProper[i][j] = int_to_char(progRomArr[i][j]);
      }
   }
  
  //configuration of the serial port
  /*fd.SetBaudRate(SerialStreamBuf::BAUD_9600);
  fd.SetCharSize(SerialStreamBuf::CHAR_SIZE_8);
  fd.SetNumOfStopBits(1);
  fd.SetParity(SerialStreamBuf::PARITY_ODD);
  fd.SetFlowControl(SerialStreamBuf::FLOW_CONTROL_NONE); */
  
  //make sure it can run at the proper baud rate
  /*if(fd.BaudRate() != SerialStreamBuf::BAUD_9600) {
    printf("TTY cannot operate at necessary baud rate.\n");
    exit(EXIT_FAILURE);
    }*/

  //double check configuration
  /*if(!fd.good()) {
    force_quit("Serial Configuration failed");
    }*/
  
  //const char start = 0x7e; //a ~
  //char confirm = 0x7f;

  //send the start byte, wait until we get it back
  //then we can start sending the actual data
 
  /*for(int i=0; i<32; i++) {  
    for(int j=4; j>-1; j--) {   
      cout << progRomProper[i][j]; 
    }
    cout << endl;
    }*/

  /*fd.write(&start, 1);
  while(confirm != start) {
    fd.read(&confirm, 1);
    }*/

   printf("Connection opened: sending data...");

  //send the instructions to the UART
  /*for(i = 0; i < 1024; i++) {
    for(j = 4; j > -1; j--) {
      fd.write(&progRomProper[i][j], 1);
      while(confirm != progRomProper[i][j]) {
        fd.read(&confirm, 1);
      }
      confirm = 0x7f;
    }
    }*/

   printf("Finished!\n");
   close(fd);

   return EXIT_SUCCESS;
}

//make sure we are specifying -f \path\to\file
static void check_args(const int argc, const char* argv[]) {
   if (argc != NUM_ARGS) {
      printf("Too %s arguments.\n", argc > NUM_ARGS ? "many" : "few");
      printf("Please specify a file (-f) and serial TTY (-d)\n");
      exit(EXIT_FAILURE);
   } else if((strcmp(argv[1], "-f") && strcmp(argv[3], "-f")) ||
             (strcmp(argv[1], "-d") && strcmp(argv[3], "-d"))) {
      printf("Option not supported. Only -f and -d supported\n");
      exit(EXIT_FAILURE);
   }
}

//loop to get to the beginning of the data
static void loop_to_array(FILE* prog_rom) {
   char a = ' ';
  
   while (a != '"') {
      a = fgetc(prog_rom);
   }
}

static inline char int_to_char(const uint8_t in) {
   return in + (in <= 9 ? '0' : ('A' - 10));
}


static inline void force_quit(const char* phrase) {
   perror(phrase);
   exit(EXIT_FAILURE);
}
