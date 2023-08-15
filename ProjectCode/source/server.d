///Server is responsible for tansmit packets to other clients
//module Server;

import std.algorithm.comparison : equal;
import std.socket;
import std.stdio;
import std.range;
import core.memory;
import core.thread.osthread;
import core.time;

import Packet : Packet;

/// Server is responsible for tansmit packets to other clients
class Server {
    Socket s_sock;
    ushort s_portNumber;
    string s_host;
    ushort s_clientNumber;
    auto readSet = new SocketSet();
    Socket[] connectedClientsList;
    Packet[] history_stack;
    bool serverIsRunning = true;
    
    ubyte[Packet.sizeof] buffer;

    /// Constructor for server, inputting a valid host address and port number
    this(string hostname, ushort portNumber, ushort clientNumber) {
        /// 0 for tcp protocol
        s_sock = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        s_host = hostname;
        s_portNumber = portNumber;
        s_clientNumber = clientNumber;
        s_sock.bind(new InternetAddress(s_host,s_portNumber));
        writeln("Server Connected"); 
        s_sock.listen(s_clientNumber);
        writeln("Server listening..."); 
    }

    ~this() {
        s_sock.close();
        serverIsRunning = false;
    }
    /// Start running server.
    void runServer() {
        /// Main application loop for the server
        // serverIsRunning = true;
        while(serverIsRunning){
            /// Clear the readSet, add the server, add client
            readSet.reset();
            readSet.add(s_sock);

            /// Add new client
            foreach(client ; connectedClientsList){
                readSet.add(client);
            }

            /// Handle each client's message
            if(Socket.select(readSet, null, null)){
                /// New clients join request & send initial history command
                if(readSet.isSet(s_sock)){
                    auto newSocket = s_sock.accept();
                    /// Add a new client to the list
                    connectedClientsList ~= newSocket;
                    /// Initialize new client with history data
                    auto history = history_stack.dup;
                    foreach(i, history_p; history_stack) {
                        newSocket.send(history_p.GetPacketAsBytes());
                    }
                    writeln("> client",connectedClientsList.length," added to connectedClientsList");
                }
                clientLoop();
    	    }
	    }  
    }
    /// This is the client loop.
    void clientLoop() {
        /// Listen to each client's request
        for(int idx = 0; idx < connectedClientsList.length; idx++){
            /// Check to ensure that the client is in the readSet before receving
            auto client = connectedClientsList[idx];
            if(readSet.isSet(client)){
                /// Server effectively is blocked until a message is received here.
                /// When the message is received, then we send that message from the server to the client
                auto got = client.receive(buffer);
                Packet[] command_queue;// insert back, pop front
                Packet p = Packet.decodePacket(buffer);
                command_queue ~= p; // receive new packet from client, insert into command queue
                /// If there is command needs to be dealt with, do so
                while(!command_queue.empty) {
                    Packet packet = command_queue.front();
                    command_queue.popFront();
                    if(packet.message == cast(ubyte)5) {
                        // If client send message 5, it is quiting.
                        // Remove inactive client from client list
                        auto temp = connectedClientsList[0 .. idx];
                        temp ~= connectedClientsList[idx+1 .. connectedClientsList.length];
                        connectedClientsList = temp;
                        client.close();
                        writeln("Client diconnected");
                        /// Clear the history stack if no client is online.
                        if(connectedClientsList.length == 0) {
                            history_stack.length = 0;
                        }
                        continue;
                    }
                    broadcastToAllClients(packet);
                    /// Store the commands that are done in history stack.
                    history_stack ~= packet; // insert into history stack, insert back, pop back!!!
                }
            }
        }
    }
    /// This method takes the input packet and pass it to all active client.
    void broadcastToAllClients(Packet packet) {
        for(int i = 0; i < connectedClientsList.length; i++) {
            auto client2 = connectedClientsList[i];
            client2.send(packet.GetPacketAsBytes());
            // writeln("sent to client",i+1, "r: ", packet.r, " g: ", packet.g, " b: ", packet.b, " user: ", packet.user, " message: ", packet.message);
            writeln("sent to client", i+1, " : ", packet.GetPacketAsBytes());
        }
    }
}

// Test the constructor of the server class
unittest {
    auto server = new Server("localhost", 50001, 3);
    assert(server.s_host == "localhost");
    assert(server.s_portNumber == 50001);
    assert(server.s_clientNumber == 3);
    destroy(server);
}

// Test the broadcastToAllClients method of the server class
unittest {
    auto server = new Server("localhost", 50003, 3);
    auto packet = Packet.create_new_packets(1, 2, 3, 4, 5, 5);
    server.connectedClientsList = [        new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP),        new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP)    ];
    server.broadcastToAllClients(packet);
    destroy(server);
}

/// Entry point to Server
// void main(){
// 	writeln("Starting server...");
// 	writeln("Server must be started before clients may join");

//     /// Create a new server
//     auto listener = new Server("localhost", 50002, 3);
//     writeln("Awaiting client connections");

//     /// Server begins to run
//     // new Thread({listener.runServer()}).start();
//     listener.runServer();
//     Thread.sleep(5.seconds);
//     destroy(listener);
// }