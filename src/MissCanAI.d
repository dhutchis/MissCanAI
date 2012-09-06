// Dylan Hutchison

import std.stdio;
import std.bitmanip;
import std.conv;
import std.concurrency;

shared StateHolder[State] stateMap;

void main() {
	// use associative array shared StateNodeInfo[State]
	//spawn(&doBFS!true, State(3,3,true)); // start at initial state
	//spawn(&doBFS!false, State(0,0,false)); // start at goal state
	writeln(State(3,3,true).expandState());
}
//template BoatSide(S) { 
//		static if(S.isL) {
//			alias LC LC;
//			alias LM M;
//		} else {
//			alias RC LC;
//			alias RM M;
//		}
//	}

/**
	State: # of missionairies (M) and cannibals (LC) on left and right side and the current location of the boat.
		I only store the M and LC on the left (LM, LC) as the right is computable from the left.
*/
struct State
{
	public: 
	
	this(ubyte LC, ubyte LM, bool isL) { _LC=LC; _LM=LM; isL=isL; }
	
	// void functions?
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
	
	//bool isGoalState() const pure nothrow @safe { return _LC == 0 && _LM == 0; }
	
	const hash_t toHash() const pure nothrow @safe {
		return _LC && _LM << 2 && _isL << 4;
	}
	
	string toString() const { return "{LC:"~to!string(_LC)~",LM:"~to!string(_LM)~","~(_isL ? "L" : "R")~"}"; }
	
	@property bool isValid() const { return (_LM == 0 || _LM >= _LC) && (3-_LM == 0 || 3-_LM >= 3-_LC); }
	
	
	
	State[] expandState() const {
		State[] sx;
		State news;
		// actions: send M, LC, MM, MC, CC
		//ubyte LC, M;
		/*if (_isL) {
			//LC = _LC; M = _LM;
			alias LC LC;
			alias LM M;
		} else {
			//LC = 3-_LC; M = 3-_LM;
			alias RC LC;
			alias RM M;
		}*/
		/*if (LC >= 2 && (3-M == 0 || 3-M == 1 && 3-LC == 0))
			news = this; news.isL = !_isL;
			news.LC = _LC - 2;*/
		//alias BoatSide!(this).LC LC;
		//function bool() LC = _isL ? this.LC : this.RC;
		//auto LC = _isL ? _LC : 3-_LC;
		
		if (_isL) {
			switch (this.LC) {
				case 3:
				case 2:
					news = this; news.isL = false;
					news.LC -= 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = false;
					news.LC = LC-1;
					if (news.isValid) sx ~= news;
					if (LM >= 1) {
						news = this; news.isL = false;
						news.LC -= 1;
						news.LM -= 1;
						if (news.isValid) sx ~= news; 
					}
				case 0: break;
				default: assert(false);
			}
			switch (LM) {
				case 3:
				case 2:
					news = this; news.isL = false;
					news.LM -= 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = false;
					news.LM = LM-1;
					if (news.isValid) sx ~= news;
				case 0: break;
				default: assert(false);
			}
		} else {
			switch (RC) {
				case 3:
				case 2:
					news = this; news.isL = true;
					news.RC -= 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = true;
					news.RC = RC-1;
					if (news.isValid) sx ~= news;
					if (RM >= 1) {
						news = this; news.isL = true;
						news.RC -= 1;
						news.RM -= 1;
						if (news.isValid) sx ~= news; 
					}
				case 0: break;
				default: assert(false);
			}
			switch (RM) {
				case 3:
				case 2:
					news = this; news.isL = true;
					news.RM -= 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = true;
					news.RM = RM-1;
					if (news.isValid) sx ~= news;
				case 0: break;
				default: assert(false);
			}
		}
		return sx;
	}
	
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
		//assert((_LM == 0 || _LM >= _LC) && (3-_LM == 0 || 3-_LM >= 3-_LC));
	}
	
}

class StateHolder 
{
	State sn;
	StateHolder prev;
	uint cost; // 1 more than the prev cost
	bool isForward; // is it on the path going forward or backward?
	
	this(State sn, StateHolder prev, bool isForward) {
		uint cost = prev is null ? 0 : prev.cost+1;
		this(sn, prev, cost, isForward);
	}
	
	private this(State sn, StateHolder prev, uint cost, bool isForward) {
		this.sn = sn; this.prev = prev; this.cost = cost; this.isForward = isForward;
	} 
	
	invariant() {
		assert(prev is null || cost == prev.cost + 1); // path cost
	}
	
	hash_t toHash() {
		return sn.toHash();
	}
	
	bool opEquals(Object rhs) {
		auto that = cast(StateHolder) rhs;
		return sn == that.sn;
	}
	
	string toString() {
		return "H"~sn.toString();
	}
}

void doBFS(bool isForward)(State startState)
{
	State[] frontier; // lifo queue - add to back, take from front
	
	frontier ~= startState;
	stateMap[startState] = new StateHolder(startState, null, isForward);
	
	while (!frontier.empty) {
		State stateToExpand = frontier.front;
		frontier = frontier.popFront();
		StateHolder stateToExpandHolder = stateMap[stateToExpand];
		
		foreach (State childState; expandState(stateToExpand)) {
			if (childState in stateMap) {
				// if it's from the other process, we met!
				if (stateMap[childState].isForward != isForward) {
					// we met!
					// ...
				} else {
					// repeated state, throw it away
					continue;
				}
			} else {
				// new state - RACE HERE'
				stateMap[childState] = new StateHolder(childState, stateToExpandHolder, isForward);
				frontier ~= childState;
			}
		}
	}
}


