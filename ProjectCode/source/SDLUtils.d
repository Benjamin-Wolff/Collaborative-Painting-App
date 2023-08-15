///Utility functions
//module SDLUtils;

import bindbc.sdl;
import std.random;
import std.socket;
import std.json;
import std.stdio;
import std.utf;
import core.stdc.stdlib;
import Packet : Packet;

/**
*Checks if an SDL Rectangle was clicked in an SDL Event
* Params:
* 		e = 	SDL event that is assumed to be a click or release
*  		r = 	SDL Rectangle that we are using the location of
* Returns: true if a rectangle (represent a button) is clicked, false otherwise
*/
bool checkIfClicked(SDL_Event e, SDL_Rect r) {
	return checkLocation(e, r.x, r.y, r.w, r.h);
}

/**
*Checks if an SDL Rectangle was clicked based on the location, size, and slack involved
* Params:
* 		e = 		SDL event that is assumed to be a click or release
*  		x = 		x-value of the rectangles location
*  		y = 		y-value of the rectangles location
*  		w = 		width of the rectangle
*  		h = 		height of the rectangle
*  		slack = 	some additional padding we are accepting for the click/release
* Returns: true if a rectangle (represent a button) is clicked, false otherwise
*/
bool checkLocation(SDL_Event e, int x, int y, int w, int h, int slack = 0) {
	return e.button.x >= (x - slack) && e.button.x <= (x + w + slack)
			&& e.button.y >= (y - slack) && e.button.y <= (y + h + slack);
}

/// Function to extract the blue component from a Uint
ubyte getBlue(uint color) {
    return (color >> 16) & 0xFF;
}

/// Function to extract the green component from a Uint
ubyte getGreen(uint color) {
    return (color >> 8) & 0xFF;
}

/// Function to extract the red component from a Uint
ubyte getRed(uint color) {
    return color & 0xFF;
}

/// Return true or false with ~equal probability
bool rand_bool() {
	if (rand() > RAND_MAX / 2) return true;
	return false;
}

/// Generate random color for special brushes
auto get_random_color(string color) {
	int r;
	int g;
	int b;
	if (color == "Purple") {
		r = uniform (200, 250);
		g = uniform(0, 190);
		b = uniform(190, 230);

	} else if (color == "Yellow") {
		r = uniform(0, 100);
		g = uniform(0, 150);
		b = uniform(0, 255);
	}
	return [r, g, b];
}

///Function that get client ip based a third-party server
auto getUserId() {
    auto r = getAddress("8.8.8.8",53); // NOTE: This is effetively getAddressInfo

    auto sockfd = new Socket(AddressFamily.INET,  SocketType.STREAM);
    // Connect to the google server
    import std.conv;
    const char[] address = r[0].toAddrString().dup;
    ushort port = to!ushort(r[0].toPortString());
    sockfd.connect(new InternetAddress(address,port));
    // Obtain local sockets address
    //writeln("Our ip address    : ",sockfd.localAddress.toAddrString());
	auto userIp = sockfd.localAddress.toAddrString().toUTF8.dup;
	for(int i = cast(int) userIp.length; i < 16; i++) {
		userIp ~= "\0";
	}
	return userIp;
}


///Create a new packet
Packet create_new_packet(char[] _user, int posX, int posY, ubyte _r, ubyte _g, ubyte _b, ubyte _message) {
	Packet packet;
	with (packet){
			user = _user;
			x = posX;
			y = posY;
			r = _r;
			g = _g;
			b = _b;
			message = _message;
	}

	return packet;
}

///Create a new socket
auto create_socket(string HOST, ushort PORT) {
	TcpSocket socket = new TcpSocket(AddressFamily.INET);

	try{
		socket.connect(new InternetAddress(HOST, PORT));
		writeln("Connected");
		return socket;
	}
	catch (SocketOSException e){
		writeln("Connection Error: ", e.message);
		writeln("Running application locally...");
	}

	return null;
}

// Test the checkIfClicked method
@("Check if clicked methods")
unittest {
	SDL_Event event;
    event.type = SDL_MOUSEBUTTONDOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.state = SDL_PRESSED;
    event.button.x = 100; // X-coordinate of mouse click
    event.button.y = 200; // Y-coordinate of mouse click

    // Create two SDL rectangles for testing
    SDL_Rect rect1 = { 80, 170, 100, 50 }; // x, y, width, height
    SDL_Rect rect2 = { 200, 300, 50, 100 }; // x, y, width, height

	assert(checkIfClicked(event, rect1));
	assert(!checkIfClicked(event, rect2));

	assert(checkLocation(event, 80, 170, 100, 50));
	assert(checkLocation(event, 80, 170, 20, 20, 20));
	assert(!checkLocation(event, 80, 170, 20, 20, 0));

}

// Test the get color methods
@("Get color methods")
unittest {
	uint color = 0xFF3402;
	assert(getBlue(color) == 0xFF);
	assert(getGreen(color) == 0x34);
	assert(getRed(color) == 0x02);
}

//Test special brushes color is within a range
//Suppose client choose purple brushes, it will get color within purple range
@("Special Brush Colors")
unittest{
	auto my_tuple = get_random_color("Purple");

	assert (my_tuple[0] >= 200 && my_tuple[0] <= 250);
	assert (my_tuple[1] >= 0 && my_tuple[1] <= 190);
	assert (my_tuple[2] >= 190 && my_tuple[2] <= 230);
}

//Test for creating new packet's x, y position, r/g/b value is correct
@("New Packet Creation")
unittest{
	Packet data = create_new_packet(getUserId(), 100, 200, 255, 255, 0, 1);
	assert(data.r == 255);
	assert(data.g == 255);
	assert(data.b == 0);
	assert(data.x == 100);
	assert(data.y == 200);
}
	

