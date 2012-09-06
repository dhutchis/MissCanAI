// Dylan Hutchison

import std.stdio;
import std.bitmanip;
import std.conv;
import std.concurrency;
import std.array;
import std.algorithm;
import std.exception;

StateHolder[State] stateMap;



/**
	State: # of missionairies (M) and cannibals (LC) on left and right side and the current location of the boat.
		I only store the M and LC on the left (LM, LC) as the right is computable from the left.
*/
struct State
{
	/*mixin(bitfields!(
		ubyte,	"LC",	2,
		ubyte,	"LM",	2,
		bool,	"isL",	1,
		ubyte,	"",		3	// padding
	));*/
	ubyte LC, LM;
	bool isL;
	
	this(ubyte LC, ubyte LM, bool isL) { this.LC=LC; this.LM=LM; this.isL=isL; }
	
	string toString() const { return "{LC:"~to!string(LC)~",LM:"~to!string(LM)~","~(isL ? "L" : "R")~"}"; }
	@property bool isValid() const { return (LM == 0 || LM >= LC) && (3-LM == 0 || 3-LM >= 3-LC); }
	
	State[] expandState() const {
		assert(isValid);
		State[] sx;
		State news;
		if (isL) {
			switch (LC) {
				case 3:
				case 2:
					news = this; news.isL = false;
					news.LC -= 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = false;
					news.LC -= 1;
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
					news.LM -= 1;
					if (news.isValid) sx ~= news;
				case 0: break;
				default: assert(false);
			}
		} else { // boat is on the right
			switch (3-LC) {
				case 3:
				case 2:
					news = this; news.isL = true;
					news.LC += 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = true;
					news.LC += 1;
					if (news.isValid) sx ~= news;
					if (3-LM >= 1) {
						news = this; news.isL = true;
						news.LC += 1;
						news.LM += 1;
						if (news.isValid) sx ~= news; 
					}
				case 0: break;
				default: assert(false);
			}
			switch (3-LM) {
				case 3:
				case 2:
					news = this; news.isL = true;
					news.LM += 2;
					if (news.isValid) sx ~= news;
				case 1:
					news = this; news.isL = true;
					news.LM += 1;
					if (news.isValid) sx ~= news;
				case 0: break;
				default: assert(false);
			}
		}
		return sx;
	}
	
	private:
	
}

class StateHolder 
{
	State s;
	StateHolder prev;
	uint cost; // 1 more than the prev cost
	bool isForward; // is it on the path going forward or backward?
	
	this(State s, StateHolder prev, bool isForward) {
		uint cost = prev is null ? 0 : prev.cost+1;
		this(s, prev, cost, isForward);
	}
	
	private this(State s, StateHolder prev, uint cost, bool isForward) {
		this.s = s; this.prev = prev; this.cost = cost; this.isForward = isForward;
	} 
	
	invariant() {
		assert(prev is null || cost == prev.cost + 1); // path cost
	}
	
	/*hash_t toHash() {
		return s.toHash();
	}
	
	bool opEquals(Object rhs) {
		auto that = cast(StateHolder) rhs;
		return s == that.s;
	}*/
	
	string toString() {
		return "H"~s.toString();
	}
}

void main() {
//	spawn(&doBFS!true, State(3,3,true)); // start at initial state
//	spawn(&doBFS!false, State(0,0,false)); // start at goal state
	//writeln(State(2,2,true).expandState());
	
	State[] frontierStart, frontierEnd, SS; // lifo queue - add to back, take from front
	
	// initialize frontiers and statemap
	frontierStart ~= State(3,3,true);
	frontierEnd ~= State(0,0,false);
	stateMap[frontierStart[0]] = new StateHolder(frontierStart[0], null, true);
	stateMap[frontierEnd[0]] = new StateHolder(frontierEnd[0], null, false);
	writeln("first\n");
	while (true) {
		// expand start frontier
		writeln("frontierStart before:", frontierStart);
		if (!frontierStart.empty)
			SS = doBFS!true(frontierStart);
		if (SS) break;
		writeln("frontierEnd   before:\t\t\t\t\t\t\t", frontierEnd);
		if (!frontierEnd.empty)
			SS = doBFS!false(frontierEnd);
		if (SS) break;
		assert(!frontierStart.empty || !frontierEnd.empty, "Empty frontiers"); // the problem is solvable
	}
	assert(SS);
	writeln("SOLUTION: ",SS);
}

// returns solution sequence if we found one
State[] doBFS(bool isForward)(ref State[] frontier)
{
	
	//while (!frontier.empty) {
		State stateToExpand = frontier.front;
		frontier.popFront();
		StateHolder stateToExpandHolder = stateMap[stateToExpand];
		
		foreach (State childState; stateToExpand.expandState()) {
			if (childState in stateMap) {
				// if it's from the other process, we met!
				StateHolder childStateHolder = stateMap[childState];
				if (childStateHolder.isForward != isForward) {
					// we met!
					writeln("GOT IT!");
					State[] SS;
					static if (isForward) {
						SS = getSolutionSequence(stateToExpandHolder, childStateHolder);
					} else {
						SS = getSolutionSequence(childStateHolder, stateToExpandHolder);
					}
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
	return null;
}

// initial <- ... <- lastForwardState -- firstBackwardState -> ... -> goal state
State[] getSolutionSequence(StateHolder lastForwardState, StateHolder firstBackwardState)
{
	State[] SS = [lastForwardState.s]; // solution sequence
	while (lastForwardState.prev !is null)
		SS ~= (lastForwardState = lastForwardState.prev).s;
	reverse(SS);
	SS ~= firstBackwardState.s;
	while (firstBackwardState !is null)
		SS ~= (firstBackwardState = firstBackwardState.prev).s;
	return SS;
}


