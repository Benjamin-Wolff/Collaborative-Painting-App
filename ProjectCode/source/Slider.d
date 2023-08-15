///Slider object class
//module Slider;

import Clickable: Clickable;
import bindbc.sdl;
import SDLUtils;
import std.conv;

/// class to represent a Slider to select multiple options, mostly just for the brush size
class Slider : Clickable!double {
	int sliderLocation;
	int numOptions;
	SDL_Rect sliderBar;
	SDL_Rect sliderPoint;
	uint barColor;
	uint pointColor;
	bool clicked;

	// Slider(30, 400, 200, 5, 20, 20, 70000u, 15_790_320u, 4);
	this(int x, int y, int numO=3, int defaultVal=0, int barW=140, int barH=6, int pointW=10, int pointH=10, 
		uint barC=10_494_192u, uint pointC=4_294_967_295u) {
		sliderBar.x = x;
		sliderBar.y = y;
		sliderBar.w = barW;
		sliderBar.h = barH;
		sliderPoint.x = x - (pointW / 2) + defaultVal * (barW / 2);
		sliderPoint.y = y - (pointH / 2) + (barH / 2);
		sliderPoint.w = pointW;
		sliderPoint.h = pointH;

		barColor = barC;
		pointColor = pointC;

		clicked = false;
		numOptions = numO;
	}

	/**
	* Renders the rectangles for the slider bar and the slider individual point.
	* Params:
	* 		surface = the SDL Surface that is being rendered
	*/
	void initRender(SDL_Surface* surface) {
		SDL_FillRect(surface, &sliderBar, barColor);
		SDL_FillRect(surface, &sliderPoint, pointColor);
	}

	/**
	* Renders the rectangle for the point in its new location after being changed
	* Params:
	* 		surface = 	the SDL Surface that is being rendered
	* 		newOption = the option that will be selected after the rendering
	*/
	void renderPoint(SDL_Surface* surface, int newOption) {
		SDL_FillRect(surface, &sliderPoint, 0);
		sliderLocation = newOption;
		sliderPoint.x = getCurrentX(newOption);
		initRender(surface);
	}

	/**
	* Calculates the x-position of the point in its new location, represented by optionNum
	* Params:
	* 		optionNum = 	the index of the option that is now being selected
	* Returns: An integer representing the x-value on the surface for the point's new location
	*/
	int getCurrentX(int optionNum) {
		// return sliderBar.x - (sliderPoint.w / 2) + optionNum*(sliderBar.w / numOptions);
		return sliderBar.x + optionNum*(sliderBar.w / numOptions);
	}

	override bool handleClick(SDL_Event e) {
		assert (e.type == SDL_MOUSEBUTTONDOWN);
		if (checkIfClicked(e, sliderPoint)) {
			clicked = true;
		}

		return clicked;

	}

	override void handleRelease(SDL_Event e, SDL_Surface* surface) {
		if (!clicked) {
			return;
		}
		for (int i = 0; i < numOptions; i++) {
			if (checkLocation(e, getCurrentX(i), sliderBar.y, sliderBar.w, sliderBar.h, 5)) {
				renderPoint(surface, i);
			}
		}
		clicked = false;
		return;
	}

    override double resultValue() {
        return to!double(sliderLocation + 1) / numOptions;
    }
}


@("Slider click")
unittest {
	auto s = new Slider(20, 350);
	SDL_Event event;
    event.type = SDL_MOUSEBUTTONDOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.state = SDL_PRESSED;
    event.button.x = 500; // X-coordinate of mouse click
    event.button.y = 600; // Y-coordinate of mouse click

	assert(!s.handleClick(event));
	
    event.button.x = 20; // X-coordinate of mouse click
    event.button.y = 355; // Y-coordinate of mouse click
	assert(s.handleClick(event));
	assert(s.clicked);
}

@("Slider x-location")
unittest {
	auto s = new Slider(20, 350, 2);
	// 20 + 1*(140 / 2) = 90
	assert(s.getCurrentX(1) == 90);
	assert(s.getCurrentX(0) == 20);
}
