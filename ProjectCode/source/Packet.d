///Packet that is sent between client and server: contains drawing pixel information
//module Packet;
import core.stdc.string;
import std.socket;

///Packet that is sent between client and server: contains drawing pixel information
struct Packet{

	char[16] user;  // Perhaps a unique identifier 
    int x;
    int y;
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte message; // 1: draw, 2: end, 3:undo, 4:redo, 5:disconnect

	/// Purpose of this function is to pack a bunch of
    /// bytes into an array for 'serialization' or otherwise
	/// ability to send back and forth across a server, or for
	/// otherwise saving to disk.	
    char[Packet.sizeof] GetPacketAsBytes(){
        char[Packet.sizeof] payload;
		import std.stdio;
		memmove(&payload,&user,user.sizeof);
		memmove(&payload[16],&x,x.sizeof);
		memmove(&payload[20],&y,y.sizeof);
		memmove(&payload[24],&r,r.sizeof);
		memmove(&payload[25],&g,g.sizeof);
		memmove(&payload[26],&b,b.sizeof);
		memmove(&payload[27],&message,message.sizeof);
        return payload;
    }
	/// Decoding bytes string into a packet
	static Packet decodePacket(ubyte[] buffer) {
		Packet p;
		ubyte[16] field = buffer[0 .. 16].dup;
		ubyte[4] field1 =  buffer[16 .. 20].dup;
		ubyte[4] field2 =  buffer[20 .. 24].dup;
		p.user = *cast(char[16]*)&field;
		p.x = *cast(int*)&field1;
		p.y = *cast(int*)&field2;
		p.r = buffer[24];
		p.g = buffer[25];
		p.b = buffer[26];
		p.message = buffer[27];
		return p;
	}
	/// Create a new packet based on input parameters
	static Packet create_new_packets(int posX, int posY, ubyte _r, ubyte _g, ubyte _b, ubyte _message) {
	Packet packet;
	auto results = getAddress("localhost");
	char[] userIp = [];
	foreach(addr ; results){
		if(addr.addressFamily() == AddressFamily.INET) {
			userIp = addr.toAddrString().dup;
			break;
		}
	}
	for(int i = 0; i < userIp.length; i++) {
		packet.user[i] = userIp[i];
	}
	packet.user[userIp.length] = '\0';					
	
	with (packet){
			x = posX;
			y = posY;
			r = _r;
			g = _g;
			b = _b;
			message = _message;
	}

	return packet;
}
}