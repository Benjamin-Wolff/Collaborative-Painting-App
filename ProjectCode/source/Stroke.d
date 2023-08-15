///Stroke that represents a consecutive drawing line/shape
//module Stroke;
import SurfacePointOperation: SurfacePointOperation;

/// A stroke represents a consecutive drawing line/shape. It is composed by a list of point operations on the surface
class Stroke {
	SurfacePointOperation[] operations;

	/// Construct a new Stroke
	this() {
		operations = [];
	}

	/// append a new point operation
	void append(SurfacePointOperation operation) {
		operations ~= operation;
	}

	/// Execute/Redo all the point operations of the stroke
	void execute() {
		foreach (o; operations) {
			o.execute();
		}
	}

	/// Undo all the point operations of the stroke
	void undo() {
		foreach (o; operations) {
			o.undo();
		}
	}
}
