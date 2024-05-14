#include "platform.h"
#include <stdio.h>
#include <string.h>
#include "xuartps.h"
#include "xparameters.h" // Includes the parameters (Addresses, IDs, etc.) from the VIVADO build. 
#include "xil_printf.h"  // Allows us to print and requires less space than standard output "stdio".
#include "xgpio.h"       // Gives access to the AXI GPIO drivers
#include "xil_types.h"   // C data types (u32, etc.)

// Get device IDs from xparameters.h
#define BTN_ID XPAR_AXI_GPIO_BTNS_BASEADDR 
#define LED_ID XPAR_AXI_GPIO_LEDS_BASEADDR
#define SWS_ID XPAR_AXI_GPIO_SWS_BASEADDR
#define UART_ID XPAR_XUARTPS_0_BASEADDR

#define TEST_BUFFER_SIZE 32

// Defines GPIO channel (in this case all GPIO used are in block 1)
#define BTN_CHANNEL 1
#define LED_CHANNEL 1
#define SWS_CHANNEL 1

#define BTN_MASK 0b1111 // 4-bit wide
#define LED_MASK 0b1111
#define SWS_MASK 0b11   // 2-bit wide

// static u8 SendBuffer[TEST_BUFFER_SIZE];	/* Buffer for Transmitting Data */
// static u8 RecvBuffer[TEST_BUFFER_SIZE];	/* Buffer for Receiving Data */

int main() 
{

    XGpio_Config *cfg_ptr;
    XGpio led_device, btn_device, sws_device;

    // UART
    int Status;
    XUartPs_Config *uart_ptr;
    XUartPs uart_device;
    // unsigned int SentCount;
	// unsigned int ReceivedCount;
	// u16 Index;
	// u32 LoopCount = 0;
    //

    int done = 0;
    int byte_count = 0;
    int execute_cmd;

    char command[6];
    char led_cmd[3];
    char led_num[2];

    u8 tmp_rx_buf;
    u8 rx_buf[40];

    u32 button_data = 0;
    u32 switch_data = 0;
    u32 led_data = 0;
    u32 data;

   	// Initialize LED Device

    // Lookup the device configuration based on the unique device ID (Base Address).
    // A pointer of data type XGpio_Config which points to the device configuration if DeviceID is found.
	cfg_ptr = XGpio_LookupConfig(LED_ID);

    // Initialize the XGpio instance provided by the caller based on the given configuration data.
    // Parameters: 
    // InstancePtr   - is a pointer to be assigned an XGpio instance
    // Config        - is a reference to a structure containing information about a specific GPIO device (see above call)
    // EffectiveAddr - is the device base address in the virtual memory address space 
	XGpio_CfgInitialize(&led_device, cfg_ptr, cfg_ptr->BaseAddress); // BaseAddress is extrapolated from the cfg_ptr struct
 
	// Initialize Button Device
	cfg_ptr = XGpio_LookupConfig(BTN_ID);
    XGpio_CfgInitialize(&btn_device, cfg_ptr, cfg_ptr->BaseAddress);

	// Initialize Switch Device
	cfg_ptr = XGpio_LookupConfig(SWS_ID);
    XGpio_CfgInitialize(&sws_device, cfg_ptr, cfg_ptr->BaseAddress);

    // Initialize UART PS Device
    uart_ptr = XUartPs_LookupConfig(UART_ID);
    Status = XUartPs_CfgInitialize(&uart_device, uart_ptr, uart_ptr->BaseAddress);

    // Set UART Normal Operation
    XUartPs_SetOperMode(&uart_device, XUARTPS_OPER_MODE_NORMAL);

    // Initialize Buffers
    // for (Index = 0; Index < TEST_BUFFER_SIZE; Index++) {
	// 	SendBuffer[Index] = '0' + Index;
	// 	RecvBuffer[Index] = 0;
	// }


    // Set Switch Tristate
    // Set the input/output direction of all discrete signals for the specified GPIO channel.
    // Parameters:
    // InstancePtr   - is a pointer to an XGpio instance to be worked on.
    // Channel	     - contains the channel of the GPIO (1 or 2) to operate on.
    // DirectionMask - is a bitmask specifying which discretes are input and which are output. Bits set to 0 are output and bits set to 1 are input.
	XGpio_SetDataDirection(&sws_device, SWS_CHANNEL, SWS_MASK); // Input

    // Set Button Tristate
	XGpio_SetDataDirection(&btn_device, BTN_CHANNEL, BTN_MASK); // Input
 
	// Set Led Tristate
	XGpio_SetDataDirection(&led_device, LED_CHANNEL, 0);        // Output

    init_platform(); // Init caches and cofig PSUART

    xil_printf("CFInitialize returned (0 = success) %d\n\r", Status);
    print("---Enter a command---\n\r");

   // While loop until user enters "finish" command
   while(done == 0)
   {
	   execute_cmd = 0;
	   memset(rx_buf, 0, sizeof(rx_buf));
	   byte_count = 0;

	   // Build up message from UART Terminal
	   while (execute_cmd == 0)
	   {
		   // Read UART data
		   while ((data = XUartPs_Recv(&uart_device, &tmp_rx_buf, 1)) == 0);

		   rx_buf[byte_count] = tmp_rx_buf;

		   if (rx_buf[byte_count] == '\r')
			   execute_cmd = 1;

		   byte_count++;
	   }

        // ReceivedCount = 0;
        // while (ReceivedCount < TEST_BUFFER_SIZE) {
        //     ReceivedCount += XUartPs_Recv(&uart_device, &RecvBuffer[ReceivedCount],(TEST_BUFFER_SIZE - ReceivedCount));
        // }



	   // Build the command arrays
	   memcpy(command, &rx_buf[0], 6);
	   memcpy(led_cmd, &rx_buf[0], 3);
	   memcpy(led_num, &rx_buf[4], 2);

	   // Read the button & switch status
       // Read state of discretes for the specified GPIO channel.
       // Parameters:
       // InstancePtr - is a pointer to an XGpio instance to be worked on.
       // Channel	  - contains the channel of the GPIO (1 or 2) to operate on.

	   button_data = XGpio_DiscreteRead(&btn_device, BTN_CHANNEL);
	   switch_data = XGpio_DiscreteRead(&sws_device, SWS_CHANNEL);

	   // Execute the received command
	   if (strcmp(led_cmd, "led") == 0)
	   {
           // Example: led 01 -> 0x1
           //          led 02 -> 0x2
           //          ...
           //          led 15 -> 0xF
		   led_data = led_num[1] - 48;

		   if ((led_num[0] - 48) == 1)
			   led_data += 10;

           // Write to discretes register for the specified GPIO channel.
           // Parameters:
           // InstancePtr - is a pointer to an XGpio instance to be worked on.
           // Channel	   - contains the channel of the GPIO (1 or 2) to operate on.
           // Mask	       - is the value to be written to the discretes register.
		   XGpio_DiscreteWrite(&led_device, LED_CHANNEL, led_data);
	   }
	   else if (strcmp(command, "button") == 0)
		   xil_printf("Button Status: %d\n\r", button_data);
	   else if (strcmp(command, "switch") == 0)
		   xil_printf("Switch Status: %d\n\r", switch_data);
	   else if (strcmp(command, "finish") == 0)
		   done = 1;
	   else
		   print("Command is invalid, re-enter below:\n\r");

// Debugging print outs below
//	   print("Command: ");
//	   print(command);
//	   print("\n\r");
//
//	   print("LED_cmd: ");
//	   print(led_cmd);
//	   print("\n\r");
//
//	   print("LED_num: ");
//	   print(led_num);
//	   print("\n\r");

   }

   print("---Exiting main---\n\r");
   cleanup_platform();
   return 0;
}
