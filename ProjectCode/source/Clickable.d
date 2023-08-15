///Abstract clase for a Clickable object
//module Clickable;

import bindbc.sdl;

/// Abstract clase for a Clickable object
abstract class BaseClickable {
    bool clicked;
    
    /**
	 * Handles a click event, and returns if the item is currently clicked
	 * Params:
	 * 		e = 	the SDL_Event that is assumed to be a click
	 * Returns: true if the clickable is currently being clicked, false otherwise
	 */
    abstract bool handleClick(SDL_Event e);

        /**
	 * Handles a release option based on the functionality of the clickable
	 * Params:
	 * 		e = 	the SDL_Event that is assumed to be a release
	 */
    abstract void handleRelease(SDL_Event e, SDL_Surface* surface);
}

/// Clickable class containing a template for the result type
class Clickable(T) : BaseClickable {
    /// Returns the expected result value
    abstract T resultValue();
}