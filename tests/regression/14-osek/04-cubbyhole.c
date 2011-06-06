// PARAM: --oil 04-cubbyhole.oil --tramp 04-defaultAppWorkstation/tpl_os_generated_configuration.h -I 04-defaultAppWorkstation/ -I 04-defaultAppWorkstation/os-minimalheaders/os_machine/posix-libpcl/ -I 04-defaultAppWorkstation/os-minimalheaders/

#include <stdio.h>
#include <string.h>
#include "tpl_os.h"
// #include "tpl_os_generated_configuration.h"

#define _XOPEN_SOURCE 500
#include <unistd.h>

char* cubbyHole = "pong";

int main(void)
{
    StartOS(OSDEFAULTAPPMODE);
    return 0;
}

/*Autostarted once at system start. Blocks in WaitEvent(...)*/
TASK(ping)
{
    printf("Ping started.\n");
    while(1){
/*    	WaitEvent(pong_deployed);
        ClearEvent(pong_deployed);*/
        GetResource(cubbyHoleMutex);
	cubbyHole = "ping";
        printf("Current state is: %s\n", cubbyHole);
        ReleaseResource(cubbyHoleMutex);
//         SetEvent(pong, ping_deployed);
    }
    TerminateTask();    
}

/*Autostarted once at system start. Blocks in WaitEvent(...)*/
TASK(pong)
{
    printf("Pong started.\n");
    while(1){
/*    	WaitEvent(ping_deployed);
        ClearEvent(ping_deployed);*/
        GetResource(cubbyHoleMutex);
        cubbyHole = "pong";
	printf("Current state is: %s\n", cubbyHole);
        ReleaseResource(cubbyHoleMutex);
//         SetEvent(ping, pong_deployed);
    }
}

/*Started once after 10 seconds with hight priority.*/
TASK(shutdown)
{
    printf("Shutting down...");
    ShutdownOS(E_OK);
}
