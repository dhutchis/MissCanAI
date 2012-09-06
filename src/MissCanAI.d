// Dylan Hutchison

import std.stdio;
import std.bitmanip;
import std.conv;
import std.concurrency;

void main() {
	
	
	
}

/**
	State: # of missionairies (M) and cannibals (C) on left and right side and the current location of the boat.
		I only store the M and C on the left (LM, LC) as the right is computable from the left.
*/
struct StateNode
{
	public: // void functions?
	@property LC() { return _LC; }
	@property LC(const ubyte newLC) { return _LC = newLC; }
	@property LM() { return _LM; }
	@property LM(const ubyte newLM) { return _LM = newLM; }
	@property RC() { return 3-_LC; }
	@property ubyte RC(const ubyte newRC) { _LC = cast(ubyte)(3 - newRC); return newRC; }
	@property RM() { return 3-_LM; }
	@property RM(const ubyte newRM) { _LM = cast(ubyte)(3 - newRM); return newRM; }
	@property isL() { return _isL; }
	@property isL(bool newisL) { return _isL = newisL; }
	
	bool isGoalState() const pure nothrow @safe { return _LC == 0 && _LM == 0; }
	
	hash_t toHash() const pure nothrow @safe {
		return _LC && _LM << 2 && _isL << 4;
	}
	
	string toString() const { return "{LC:"~to!string(_LC)~",LM:"~to!string(_LM)~","~(_isL ? "L" : "R")~"}"; }
	
	private:
//	byte _LC=3, _LM=3;
//	enum BoatLoc { L, R };
//	BoatLoc boat = BoatLoc.L;
//	bool _isL = 0;
	mixin(bitfields!(
		ubyte,	"_LC",	2,
		ubyte,	"_LM",	2,
		bool,	"_isL",	1,
		ubyte,	"",		3	// padding
	));
	
	
	
	invariant() {
		assert(0 <= _LC && _LC <= 3);
		assert(0 <= _LM && _LM <= 3);
	}
	
}

class StateNodeHolder 
{
	StateNode sn;
	StateNodeHolder prev;
	uint cost; // 1 more than the prev cost
	bool isForward; // is it on the path going forward or backward?
	
	invariant() {
		assert(prev is null || cost == prev.cost + 1); // path cost
	}
	
	hash_t toHash() {
		return sn.toHash();
	}
	
	bool opEquals(Object rhs) {
		auto that = cast(StateNodeHolder) rhs;
		return sn == that.sn;
	}
	
	string toString() {
		return "H"~sn.toString();
	}
}