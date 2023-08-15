///Main driver function for the app
//module App;

import Client: Client;
import std.stdio;
import std.conv;
import std.string;
import server: Server;

/// Main function to run a Client
void main(){
	string userType = "";
	string host = "";
	ushort portNum;
	writeln("\n\nWelcome! Enter the letter 'c' if you are a client and 's' if you are a server.");
	writeln("\tNote that we do have an AWS server (AWS hostname: 3.19.60.89, port 50002)");

	userType = readln().strip();

	while(userType != "c" && userType != "s") {
		writeln("\nPlease try again. Enter the letter 'c' if you are a client and 's' if you are a server.");
		userType = readln().strip();
	}
	
	writeln("\nThank you! Now, please input the host name for the server you intend to use (3.19.60.89)");
		host = readln().strip();

		writeln("\nNow, please input the port number (50002)");
		while(portNum == 0) {
			try {
				portNum = to!ushort(readln().strip());
			}
			catch(ConvException e) {
				writeln("\nInvalid port number, please input the port number (50002)");
			}
		}

	if (userType == "c") {

		Client client = new Client(host, portNum);
		client.run();
	}
	else {
		//Create a new server
    	auto listener = new Server(host, portNum, 3);
		writeln("Awaiting client connections");

		//Server begins to run
		listener.runServer();
		destroy(listener);
	}

	return;
}



