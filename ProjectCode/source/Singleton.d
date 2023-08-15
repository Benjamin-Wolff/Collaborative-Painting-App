///Singleton class that wrap up constance
//module Singleton;

///A class that wrap up constant values
class Singleton {
	private static Singleton instance;
	int windowWidth;
	int windowHeight;
	int windowDepth;
	int boundaryLeft;
	int boundaryRight;
	int boundaryUp;
	int boundaryDown;
	uint drawColor;
	ubyte red;
	ubyte green;
	ubyte blue;

	private this(){
	}

	static Singleton GetInstance(){
		if (instance is null){
			instance = new Singleton;
		}
		return instance;
	}
}
