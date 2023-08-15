///Surface command that undo and redo
//module SurfacePointOperation;

import Command: Command;
import bindbc.sdl;

/// Change the color of a position on the SDL_Surface
class SurfacePointOperation : Command {
	SDL_Surface* mSurface;
	int mXPosition, mYPosition;  // position of the point
	ubyte mR, mG, mB;		// target color to change to
	
	this(SDL_Surface* surface, int xPos, int yPos, ubyte r, ubyte g, ubyte b){
		mSurface = surface;
		mXPosition = xPos;
		mYPosition = yPos;
		mR = r;
		mG = g;
		mB = b;
	}

	/// Function for updating the pixels to the target color.
	int execute(){
        changeColor(mR, mG, mB);
        return 0;
	}

	/// change back to Color(0, 0, 0)
	int undo(){
        changeColor(0, 0, 0);
		return 0;
	}

    /// Reusable helper function to change the color of the position to the target color
    private int changeColor(ubyte r, ubyte g, ubyte b) {
		// When we modify pixels, we need to lock the surface first
		SDL_LockSurface(mSurface);
		// Make sure to unlock the mSurface when we are done.
		scope(exit) SDL_UnlockSurface(mSurface);

		// Retrieve the pixel array that we want to modify
		ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
        // get the first pixel index of position(x, y) from the pixel array of the surface
        int index = mYPosition * mSurface.pitch + mXPosition * mSurface.format.BytesPerPixel;
        // Change the "r, g, b" components of the pixels
        pixelArray[index] = r;
        pixelArray[index+1] = g;
        pixelArray[index+2] = b;
		return 0;
    }

	/// Check a pixel colors at given position
    ubyte[] pixelAt(int x, int y) {
        SDL_LockSurface(mSurface);
        scope(exit) SDL_UnlockSurface(mSurface);

        ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
        int index = mYPosition * mSurface.pitch + mXPosition * mSurface.format.BytesPerPixel;
        return [pixelArray[index], pixelArray[index+1], pixelArray[index+2]];      
    }
}

@("SurfacePointOperation: execute")
unittest {
	SDL_Surface* s = SDL_CreateRGBSurface(0, 600, 480, 32, 0, 0, 0, 0);
    SurfacePointOperation so = new SurfacePointOperation(s, 100, 100, 100, 150, 200);
	so.execute();

    assert(	so.pixelAt(100, 100)[0] == 100 && 
        so.pixelAt(100, 100)[1] == 150 &&
        so.pixelAt(100, 100)[2] == 200, 
        "Execute SurfacePointOperation error!");
}

@("SurfacePointOperation: execute")
unittest {
	SDL_Surface* s = SDL_CreateRGBSurface(0, 600, 480, 32, 0, 0, 0, 0);
    SurfacePointOperation so = new SurfacePointOperation(s, 100, 100, 100, 150, 200);
	so.undo();

    assert(	so.pixelAt(100, 100)[0] == 0 && 
        so.pixelAt(100, 100)[1] == 0 &&
        so.pixelAt(100, 100)[2] == 0, 
        "Undo SurfacePointOperation  error!");
	SDL_FreeSurface(s);
}