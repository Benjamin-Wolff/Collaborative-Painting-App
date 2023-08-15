///Main Client class: deal with drawing and communication with server
//module Client;

// import D standard libraries
import std.stdio;
import std.string;
import std.concurrency;
import std.socket;
import std.stdio;
import std.algorithm;
import core.thread;
import std.json;
import std.utf;
import std.format;
import std.random;
import core.stdc.stdlib;
import bindbc.sdl;

// import local modules/files that we need
import Clickable: Clickable;
import Slider: Slider;
import SDLUtils;
import SurfacePointOperation: SurfacePointOperation;
import Stroke: Stroke;
import Singleton : Singleton;
import Packet : Packet;
import ButtonChoices: ButtonChoices;
import SdlLoader;  //Initializes SDL library 


//Generate Documentation: 
//Note: it must be run with module, instead of import..
//dub run adrdox -- -i /Users/floating/Desktop/finalproject-team-byyz/demo_server_client/demo_Client



///A Thread-safe deque shared by multi-threads in the client instance
synchronized class SafeDeque(T) {
    private T[] deque;

	/**
	* push back data into queue
	* Params:
	* 		T x: commands to be pushed back
	*/
    void push_back(T x) {
        deque ~= cast(shared) x;
    }

	/**
	* pop front data into queue
	* Params:
	* 		T x: commands to be pop front
	* Returns: the commands to be pop front
	*/
    T pop_front() {
        assert(size() > 0, "Can't pop front from empty Deque!");
        T res = cast() deque[0];
        deque = deque[1 .. $];
        return res;
    }

	/**
	* Get size of the queue
	* Params:
	* Returns: the length of the queue
	*/
	size_t size() {
        return deque.length;
    }
}

///Client class: responsible for drawing and interaction with server
class Client {
	bool isConnected;
	TcpSocket socket;
	SDL_Surface* imgSurface;
	bool runApplication = true; 
	SDL_Window* window;
	ButtonChoices colorChoices;
	Slider brushSlider;
	bool drawing = false;
	bool purple = false;
	bool yellow = false;
	int brushSize = 2;
	auto commands = new shared(SafeDeque!Packet);   // Make it thread safe
	char[] user;

    /// Initialize client app
    this(string host="3.19.60.89", ushort port=50_002) {
		// Create socket and connect to server, listen message from localhost server
		// AWS hostname: 3.19.60.89
		// TODO:Prompte User IP Address: type in host and port
		socket = create_socket(host, port);
		user = getUserId();
		if (socket is null) {
			isConnected = false;
		} else {
			isConnected = true;
		}

		// Create an SDL window and Surface
		Singleton.GetInstance.windowWidth=1024;
		Singleton.GetInstance.windowHeight=576;
		Singleton.GetInstance.windowDepth=32;
		Singleton.GetInstance.boundaryLeft=170;
		Singleton.GetInstance.boundaryRight=1014;
		Singleton.GetInstance.boundaryUp=10;
		Singleton.GetInstance.boundaryDown=566;
		window = SDL_CreateWindow("D SDL Painting",
			SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED,
			Singleton.GetInstance.windowWidth,
			Singleton.GetInstance.windowHeight,
			SDL_WINDOW_SHOWN);

		imgSurface = SDL_CreateRGBSurface(0, Singleton.GetInstance.windowWidth, Singleton.GetInstance.windowHeight, 
		Singleton.GetInstance.windowDepth, 0, 0, 0, 0);

		// Create new slider bar and buttons
		uint[] colors = [SDL_MapRGB(imgSurface.format, 255, 0, 0), 
						SDL_MapRGB(imgSurface.format, 0, 255, 0), 
						SDL_MapRGB(imgSurface.format, 0, 0, 255),
						SDL_MapRGB(imgSurface.format, 160, 32, 240),
						SDL_MapRGB(imgSurface.format, 255, 255, 0)];

		colorChoices = new ButtonChoices(colors);
		brushSlider = new Slider(20, 350);

		colorChoices.initRender(imgSurface);
		brushSlider.initRender(imgSurface);

		Singleton.GetInstance.drawColor = SDL_MapRGB(imgSurface.format, 255, 0, 0);
		Singleton.GetInstance.red = getRed(Singleton.GetInstance.drawColor);
		Singleton.GetInstance.green = getGreen(Singleton.GetInstance.drawColor);
		Singleton.GetInstance.blue = getBlue(Singleton.GetInstance.drawColor);

    }

	~this() {
		if (imgSurface != null) {
			SDL_FreeSurface(imgSurface);
		}
	}

	/// Receiving thread: keep receiving packets, and push into command queue
	void receiving_thread(){
		while (isConnected && runApplication) {
			ubyte[Packet.sizeof] buffer;
			auto received = socket.receive(buffer);
			
			//Socket offline, thread ends...
			if (received <= 0){
				writeln("Server disconnected");
				if (runApplication) {
					writeln("Continue drawing locally...");					
				}
				socket.shutdown(SocketShutdown.BOTH);
				socket.close();
				isConnected = false;
				return;
			} else if (received == Packet.sizeof) {
				auto fromServer = buffer[0 .. received];
				Packet formattedPacket = Packet.decodePacket(fromServer);
				commands.push_back(formattedPacket);
			}
		}
	}

	/// Working thread: processing packets from shared command_queue, and executing commands
	void working_thread() {
		Stroke[string] strokeMap;   // current strokes hashmap for all clients
		Stroke[] strokeHistory;		// history stroke
		Stroke[] undoHistory;		// the strokes that are "undo", used for "redo"

		// Keep fetching and consuming the commands
		while (runApplication) {
			if (commands.size() > 0) {
				auto command = commands.pop_front;

				switch (command.message) {
					case cast(ubyte)1:
						// execute the command, add to strokeMap
						auto operation = new SurfacePointOperation(imgSurface,command.x,command.y, command.r, command.g, command.b);
						operation.execute();
						import std.conv;
						string user = to!string(command.user);
						if (user in strokeMap) {
							strokeMap[user].append(operation);
						} else {
							strokeMap[user] = new Stroke;
						}
						break;

					case cast(ubyte)2:
						// end the stroke, fetch it into strokeHistory
						import std.conv;
						string user = to!string(command.user);
						if (user in strokeMap) {
							strokeHistory ~= strokeMap[user];
							strokeMap.remove(user);
						}
						break;

					case cast(ubyte)3:
						// pop the most recent stroke, undo it, push it to undoHistory
						if (strokeHistory.length > 0) {
							auto lastStroke = strokeHistory[$-1];
							strokeHistory = strokeHistory[0 .. $-1];
							lastStroke.undo();
							undoHistory ~= lastStroke;						
						} else {
							writeln("No stroke history, cannot undo!");
						}
						break;

					case cast(ubyte)4:
						// pop the most recent "undo" stroke, execute it, push it to strokeHistory
						if (undoHistory.length > 0) {
							auto lastStroke = undoHistory[$-1];
							undoHistory = undoHistory[0 .. $-1];
							lastStroke.execute();
							strokeHistory ~= lastStroke;						
						} else {
							writeln("No undo stroke history, cannot redo!");
						}
						break;

					default:
						break;
				}
			}
		}
	}

    /// Main thread: run the client application, keeps listening to user interactions
	void run() {
		// Spawn a new working thread: for processing all commands
		new Thread({
					working_thread();
				}).start();

		// If connected to server: spawn a receiving thread to receive packets
		if (isConnected) {
			new Thread({
						receiving_thread();
					}).start();		
		}
		
		///The drawing loop
		while (runApplication){
			SDL_Event e;

			while (SDL_PollEvent(&e) != 0){
				if (e.type == SDL_QUIT){
					if (isConnected) {
                        // message number "5" means client would be offline
						Packet endPacket = create_new_packet(user, 1, 2, 3, 4, 5, 5);
						socket.send(endPacket.GetPacketAsBytes());
						socket.close();
						isConnected = false;						
					}
					runApplication = false;
				} else if (e.type == SDL_MOUSEBUTTONDOWN){
					if (colorChoices.handleClick(e) || brushSlider.handleClick(e)) {
						drawing = false;
					}
					else { 
						drawing = true;
					}
				} else if (e.type == SDL_MOUSEBUTTONUP) { 
					drawing = false;

					if (colorChoices.clicked) {
						colorChoices.handleRelease(e, imgSurface);
						Singleton.GetInstance.drawColor = colorChoices.resultValue;
						Singleton.GetInstance.red = getRed(Singleton.GetInstance.drawColor);
						Singleton.GetInstance.green = getGreen(Singleton.GetInstance.drawColor);
						Singleton.GetInstance.blue = getBlue(Singleton.GetInstance.drawColor);

						//Flag mark for special brushes
						if (colorChoices.selected == 3) {
							purple = true;
							yellow = false;
						} else if (colorChoices.selected == 4) {
							yellow = true;
							purple = false;
						} else {
							purple = false;
							yellow = false;
						}
					} 
					else if (brushSlider.clicked) {
						//get brush size based on user sliding bar
						brushSlider.handleRelease(e, imgSurface);
						brushSize = cast(int)brushSlider.sliderLocation + 2;
					} else {
						//Send empty packet to server: mark the end of a line
						Packet endPacket = create_new_packet(user, 0, 0, 0, 0, 0, 2);
						if (isConnected) {
							socket.send(endPacket.GetPacketAsBytes());							
						} else {
							commands.push_back(endPacket);
						}
					}
				//User mouse moving, send pixels to server
				} else if (e.type == SDL_MOUSEMOTION && drawing){
					int xPos = e.button.x;
					int yPos = e.button.y;
					
					//Special brushes color:
					auto random_color = new int[3];

					//Special brushes configuration:
					if (purple || yellow) {
						//Random position
						if (rand_bool()) xPos += 3;
						else xPos -= 3;
						if (rand_bool()) yPos += 3;
						else yPos -= 3;
						
						string choice = "";
						if (purple) choice = "Purple";
						else if (yellow) choice = "Yellow";
						random_color = get_random_color(choice);
					}

					for (int w = -brushSize; w < brushSize; w++){
						for (int h = -brushSize; h < brushSize; h++){
							//Special purple brushes's position/color change
							if (purple) {
								xPos = xPos + w;
								yPos = yPos + h;
							}

							//Edge case: out of boundary
							if (xPos + w < Singleton.GetInstance.boundaryLeft
							|| xPos + w > Singleton.GetInstance.boundaryRight
							|| yPos + h < Singleton.GetInstance.boundaryUp 
							||yPos + h > Singleton.GetInstance.boundaryDown) continue;

							if (purple || yellow) {
								Singleton.GetInstance.red = cast(ubyte)random_color[0];
								Singleton.GetInstance.green= cast(ubyte)random_color[1];
								Singleton.GetInstance.blue = cast(ubyte)random_color[2];
							}
			
							//Update packet's r, g, b value
							ubyte r = Singleton.GetInstance.red;
							ubyte g = Singleton.GetInstance.green;
							ubyte b = Singleton.GetInstance.blue;

							Packet data = create_new_packet(user, xPos + w , yPos + h , r, g, b, 1);
							// writeln(format("Sending Packet: x: %s, y: %s ",xPos + w , yPos + h));
							if (isConnected) {
								socket.send(data.GetPacketAsBytes());							
							} else {
								commands.push_back(data);
							}
						}
					}
				} else if (e.type == SDL_KEYDOWN){
					switch (e.key.keysym.sym){
							case SDLK_UP:
								// handle up arrow key press -> undo
								Packet undoPacket = create_new_packet(user, 0, 0, 0, 0, 0, 3);
								writeln("Undo by user: ", undoPacket.user);
								if (isConnected) {
									socket.send(undoPacket.GetPacketAsBytes());							
								} else {
									commands.push_back(undoPacket);
								}
								break;

							case SDLK_DOWN:
								// handle down arrow key press -> redo
								Packet redoPacket = create_new_packet(user, 0, 0, 0, 0, 0, 4);
								writeln("Redo by user: ", redoPacket.user);
								if (isConnected) {
									socket.send(redoPacket.GetPacketAsBytes());							
								} else {
									commands.push_back(redoPacket);
								}
								break;

							default:
								writeln("other key pressed");						
								break;
						}
				}
			}

			// Blit the surace and Update the window surface
			SDL_BlitSurface(imgSurface, null, SDL_GetWindowSurface(window), null);
			SDL_UpdateWindowSurface(window);
			SDL_Delay(16);
		}

		// Destroy our window
		SDL_DestroyWindow(window);
	}
}

