import jssc.SerialPort;
import jssc.SerialPortList;
import jssc.SerialPortException;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.FileReader;

public class Main {

   private static final int PROG_ROM_LINES = 1024;
   private static final int PROG_ROM_SEGS = 5;
   private static final int INIT_HEIGHT = 64;
   private static final int INIT_WIDTH = 64;
   private static final int INITP_HEIGHT = 8;
   private static final int INITP_WIDTH = 64;
   private static final byte MAGIC_BYTE = 0X7E;

   ///error codes///
   private static final int E_NO_FILE      = 1;
   private static final int E_BAD_FILE     = 2;
   private static final int E_BAD_READ     = 3;
   private static final int E_BAD_DEV      = 4;
   private static final int E_CONF_FAIL    = 5;
   private static final int E_HANDSHAKE    = 6;
   private static final int E_COMM_FAIL    = 7;
   private static final int E_TIMEOUT      = 8;

   private static String[] err2Str = new String[] {
      "",                                       // 0
      "File not found.",                        // 1
      "Invalid prog_rom file.",                 // 2
      "Bad file read.",                         // 3
      "Bad serial device.",                     // 4
      "Configuration of serial device failed.", // 5
      "Handshake with Nexys board failed.",     // 6  
      "Error communicating with Nexys board.",  // 7
      "Communication Timeout."                  // 8
   };

   public static void main(String[] args) {
      String [] parsed = parse_args(args);
      int res;

      res = programBoard(parsed[0], parsed[1]);
      if (res != 0) {
         System.err.println("Error " + res + ": " + err2Str[res]);
      }
   }

   private static int programBoard(String file, String serialDevice) {
      byte[][] progRomArr = new byte[PROG_ROM_LINES][PROG_ROM_SEGS];
      byte c, topC, confirm;
      char[][] progRomProper = new char[PROG_ROM_LINES][PROG_ROM_SEGS];
      int i, j;
      FileReader prog_rom = null; //fix this variable name later
      SerialPort sp = new SerialPort(serialDevice);

      try {
         prog_rom = new FileReader(new File(file));
      } catch (FileNotFoundException e) {
         return E_NO_FILE;
      }
      
      //loop through the INIT prog_rom array
      try {
         loop_to_array(prog_rom);
         for (i = 0; i < INIT_HEIGHT; i++) {
            for (j = 0; j < INIT_WIDTH; j++) {
               c = (byte) prog_rom.read();
               if (c >= '0' && c <= '9') {
                  c -= '0';
               } else if (c >= 'A' && c <= 'F') {
                  c = (byte) (c - 'A' + 10);
               } else {
                  prog_rom.close();
                  sp.closePort();
                  return E_BAD_FILE;
               }
               progRomArr[(i * 16) + ((63 - j) / 4)][j % 4 + 1] = c;
            }
            //the " at the end of the string:
            prog_rom.read();
            loop_to_array(prog_rom);
         }
      } catch (IOException e) {
         return E_BAD_READ;
      } catch (SerialPortException e) {
         return E_BAD_DEV;
      }

      //loop through the INITP prog_rom array
      try {
         for (i = 0; i < INITP_HEIGHT; i++) {
            for (j = 0; j < INITP_WIDTH; j++) {
               c = (byte) prog_rom.read();
               if (c >= '0' && c <= '9') {
                  c -= '0';
               } else if (c >= 'A' && c <= 'F') {
                  c = (byte) (c - 'A' + 10);
               } else {
                  prog_rom.close();
                  sp.closePort();
                  return E_BAD_FILE;
               }
               topC = c;
               topC &= 0x0c;
               topC = (byte) (topC >> 2);
               progRomArr[(i * 128) + ((63 - j) * 2) + 1][0] = topC;

               c &= 0x03;
               progRomArr[(i * 128) + ((63 - j) * 2)][0] = c;
            }

            prog_rom.read();
            loop_to_array(prog_rom);
         }

         prog_rom.close();
      } catch (IOException e) {
         return E_BAD_READ;
      } catch (SerialPortException e) {
         return E_BAD_DEV;
      }

      //convert the instructions BACK to ASCII
      for (i = 0; i < PROG_ROM_LINES; i++) {
         for (j = 0; j < PROG_ROM_SEGS; j++) {
            progRomProper[i][j] = int_to_char(progRomArr[i][j]);
         }
      }

      //configuration of the serial port
      try {
         sp.openPort();
         sp.setParams(9600, 8, 1, 1, false, false);
      } catch (SerialPortException e) {
         return E_CONF_FAIL;
      }


      // The "handshaking procedure". Send a special byte to the
      // UART and wait for it to send it back. This will tell the
      // UART we are ready and confirm the UART is ready as well.
      // try {
         // sp.writeByte(MAGIC_BYTE);
         // confirm = sp.readBytes(1)[0];
         // if (confirm != MAGIC_BYTE) {
         //    System.out.println("error >>>" + confirm + "<<<");
         //    return E_HANDSHAKE;
         // }
         
      // } catch (SerialPortException e) {
      //    return E_COMM_FAIL;
      // }
      
      System.out.printf("Connection opened: sending data");

      // Send the instructions to the UART.
      try {
         for (i = 0; i < 1024; i++) {
            for (j = 4; j > -1; j--) {
               sp.writeByte((byte) progRomProper[i][j]);
               confirm = sp.readBytes(1)[0];
            }
            if (i % 100 == 0) {
               System.err.printf(".");
            }
         }
         sp.closePort();
      } catch (SerialPortException e) {
         return E_COMM_FAIL;
      }

      return 0;
   }

   private static char int_to_char(final byte in) {
      return (char) (in + (in <= 9 ? '0' : ('A' - 10)));
   }

   //loop to get to the beginning of the data
   private static void loop_to_array(FileReader prog_rom) throws IOException {
      char a = ' ';

      while (a != '"') {
         a = (char) prog_rom.read();
      }
   }

   private static String[] parse_args(String[] args) {
      String[] parsed = new String[2], portNames;
      boolean fFound = false, dFound = false, lFound = false, hFound = false;
      int i;

      for (i = 0; i < args.length; i++) {
         if (i < args.length - 1 &&
             (args[i].equals("-f") || args[i].equals("--file"))) {
            fFound = true;
            parsed[0] = args[i + 1];
            i++;
         } else if (i < args.length - 1 &&
                    (args[i].equals("-d") || args[i].equals("--device"))) {
            dFound = true;
            parsed[1] = args[i + 1];
            i++;
         } else if (args[i].equals("-h") || args[i].equals("--help")) {
            hFound = true;
         } else if (args[i].equals("-l") || args[i].equals("--list")) {
            lFound = true;
         }
      }

      if (!hFound && lFound) {
         portNames = SerialPortList.getPortNames();
         for (i = 0; i < portNames.length; i++) {
            System.out.println(portNames[i]);
         }
         System.exit(0);
      } else if (hFound || !fFound || !dFound) {
         System.out.println("Usage: winRATLoad -d|--device <serial device> " +
                            "-f|--file <prog_rom file>");
         System.out.println("       (program Nexys2 board)");
         System.out.println("   or  winRATLoad -l|--list");
         System.out.println("       (list available serial devices)");
         System.out.println("   or  winRATLoad -h|--help");
         System.out.println("       (print this message)");
         System.exit(1);
      }

      return parsed;
   }
}
