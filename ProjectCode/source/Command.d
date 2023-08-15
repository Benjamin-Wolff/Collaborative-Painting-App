/// the general interface of a pixel change on the canvas
//module Command;

/// the general interface of a pixel change on the canvas
interface Command {
	int execute();
	int undo();
} 