///ButtonChoices class to represent a number of buttons which a selected option
//module ButtonChoices;

import Clickable: Clickable;
import bindbc.sdl;
import SDLUtils;
import std.algorithm;
import std.conv;

/// ButtonChoices class to represent a number of buttons which a selected option
class ButtonChoices : Clickable!uint
{
	SDL_Rect[] choices;
	uint[] colors;
	uint pointColor;
	SDL_Rect selectedPoint;
	int selected;
	bool clicked;
	int numButtons;

	// ButtonChoices bc = new ButtonChoices(colors, 10, 10, 140, 35, 10, 10, SDL_MapRGB(imgSurface.format, 255, 255, 255), 15);
	this(uint[] c, int startX = 10, int startY = 10, int buttonW = 140, int buttonH = 35, int pointW = 10, int pointH = 10,
		uint pointC = 4_294_967_295u, int distanceBetween = 15, int defaultVal = 0)
	{
		colors = c;
		pointColor = pointC;
		numButtons = to!int(colors.length);

		for (int i = 0; i < numButtons; i++)
		{
			SDL_Rect r;
			with (r)
			{
				w = buttonW;
				h = buttonH;
				x = startX;
				y = startY + (i * (buttonH + distanceBetween));
			}

			choices = choices ~ r;
		}

		selected = defaultVal;
		with (selectedPoint)
		{
			h = pointH;
			w = pointW;
			x = startX - (pointW / 2) + (buttonW / 2);
			y = choices[defaultVal].y + (buttonH / 2) - (pointH / 2);
		}

		clicked = false;

	}

	/**
	* Renders the rectangles for the buttons and the selected button point.
	* Params:
	* 		surface = the SDL Surface that is being rendered
	*/
	void initRender(SDL_Surface* surface) 
	{
		for (int i = 0; i < numButtons; i++)
		{
			SDL_FillRect(surface, &choices[i], colors[i]);

		}
		SDL_FillRect(surface, &selectedPoint, pointColor);
	}

	/**
	* Renders the rectangle for the point in its new location after being changed
	* Params:
	* 		surface = 		   	the SDL Surface that is being rendered
	* 		previousSeledted = 	the index of the previously selected button option
	* 		newSelected = 		the index of the newly selected button option
	*/
	void renderPoint(SDL_Surface* surface, int previousSelected, int newSelected)
	{
		SDL_FillRect(surface, &selectedPoint, 0);
		SDL_FillRect(surface, &choices[previousSelected], colors[previousSelected]);
		selectedPoint.y = getCurrentY(newSelected);
		SDL_FillRect(surface, &selectedPoint, pointColor);
	}

	/**
	* Calculates the y-position of the point in its new location, represented by selected
	* Params:
	* 		selectedNum = 	the index of the button that is now being selected
	* Returns: An integer representing the y-value on the surface for the point's new location
	*/
	int getCurrentY(int selectedNum)
	{
		assert(choices.length > 0);
		return choices[selectedNum].y + (choices[0].h / 2) - (selectedPoint.h / 2);
	}

	override bool handleClick(SDL_Event e)
	{
		clicked = any!(choice => checkIfClicked(e, choice))(choices);

		return clicked;
	}

	override void handleRelease(SDL_Event e, SDL_Surface* surface)
	{
		assert(clicked == true);
		int oldSelected = selected;
		for (int i = 0; i < numButtons; i++)
		{
			if (checkIfClicked(e, choices[i]))
			{
				selected = i;
			}
		}

		if (selected != oldSelected)
		{
			renderPoint(surface, oldSelected, selected);
		}
		clicked = false;
	}

	override uint resultValue()
	{
		return colors[selected];
	}
}

@("Buttons click")
unittest {
	uint[] colors = [225u, 225u, 225u ,225u ,225u ];
	auto b = new ButtonChoices(colors);
	// 10, 10, 140, 35,
	SDL_Event event;
    event.type = SDL_MOUSEBUTTONDOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.state = SDL_PRESSED;
    event.button.x = 500; // X-coordinate of mouse click
    event.button.y = 600; // Y-coordinate of mouse click

	assert(!b.handleClick(event));
	
    event.button.x = 20; // X-coordinate of mouse click
    event.button.y = 10; // Y-coordinate of mouse click
	assert(b.handleClick(event));
	assert(b.clicked);
}

@("Button y-location")
unittest {
	uint[] colors = [225u, 225u, 225u, 225u, 225u];
	auto b = new ButtonChoices(colors, 10, 10, 140, 36, 10, 10);
	// choices[selectedNum].y + (choices[0].h / 2) - (selectedPoint.h / 2);
	// 10 + (36 / 2) - 5
// int startX = 10, int startY = 10, int buttonW = 140, int buttonH = 35, int pointW = 10, int pointH = 10,
// 		uint pointC = 4_294_967_295u, int distanceBetween = 15, int defaultVal = 0)
	import std.stdio;
	assert(b.getCurrentY(0) == 23);
}
