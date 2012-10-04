/** 
	Dylan Hutchison
	CS 541 Artificial Intelligence HW #1
	Russel & Norvig Book Problem 3.9
	Due 19 September 2012

	Finds an optimal solution to the Missionaries and Cannibals problem with 3 missionaries and cannibals on one side of the river.
	Approach: Graph-based Uninformed Bidirectional search.  Alternates expanding state nodes from both the initial state and the goal state
		until the two searches meet at a common state in the middle.  The solution sequence of actions is constructed from the two search sequences.
		Remembers which states have been explored in the past to prevent loops by storing them in an associative array.
	Search Strategy: Breadth First Search - guaranteed to find an optimal solution as the first solution found will have minimum cost.

	To see debug output, compile with '-debug=MissCanAI'.  Include unittests with '-unittest'.
*/


import std.stdio;
//import std.bitmanip;
import std.conv;
//import std.concurrency;
import std.array;
import std.algorithm;

/**
	The explored state space!  Maps every explored State to a StateHolder class which holds information about that state.
*/
StateHolder[State] stateMap;

/**
	State: # of missionairies (M) and cannibals (LC) on left and right side and the current location of the boat.
		I only store the M and C on the left (LM, LC) as the right is computable from the left.
*/
struct State
{
	/* Attempt to use bitfields to reduce memory of each State struct.
	mixin(bitfields!(
		ubyte,	"LC",	2,
		ubyte,	"LM",	2,
		bool,	"isL",	1,
		ubyte,	"",		3	// padding
	));
	*/
	ubyte LC, LM;
	bool isL;
	
	/// String representation of this struct
	string toString() const { return "{LC:"~to!string(LC)~",LM:"~to!string(LM)~","~(isL ? "L" : "R")~"}"; }
	
	/// Is this state valid?  Yes if a missionaries are not outnumbered by cannibals on either side of the river.
	@property bool isValid() const pure nothrow @safe { 
		assert(0 <= LC && LC <= 3, "Too many or too few cannibals");
		assert(0 <= LM && LM <= 3, "Too many or too few missionaries");
		return (LM == 0 || LM >= LC) && (3-LM == 0 || 3-LM >= 3-LC); 
	}
	
	/// Generate all valid children of this state by taking every possible action.
	State[] expandState() const pure nothrow @safe {
		assert(isValid);
		State[] sx; // the valid child states
		State news;
		if (isL) {
			switch (LC) {
				case 2, 3:
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
				case 2, 3:
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
	
}

/**
	Holds information about a State.
*/
class StateHolder 
{
	immutable State s;
	StateHolder prev;
	//uint cost; // 1 more than the prev cost --- Don't need to keep track of cost. We're using BFS - guranteed optimal.
	immutable bool isForward; // is it on the path going forward or backward?
	
	this(State s, StateHolder prev, bool isForward) {
		//uint cost = prev is null ? 0 : prev.cost+1;
		//this(s, prev, cost, isForward);
		this.s = s; this.prev = prev; this.isForward = isForward;
	}
	
	/*private this(State s, StateHolder prev, uint cost, bool isForward) {
		this.s = s; this.prev = prev; this.cost = cost; this.isForward = isForward;
	} */
	
	/*invariant() {
		assert(prev is null || cost == prev.cost + 1); // path cost
	}*/
	
	/*hash_t toHash() {
		return s.toHash();
	}
	
	bool opEquals(Object rhs) {
		auto that = cast(StateHolder) rhs;
		return s == that.s;
	}*/
	
	/// Deep string representation of this State and all the States leading up to it.
	string toString() const {
		return "H"~s.toString()~(prev is null ? "" : prev.toString());
	}
}

void main() {
	// Do this for parallel bidirectional search.
//	spawn(&doBFS!true, State(3,3,true)); // start at initial state
//	spawn(&doBFS!false, State(0,0,false)); // start at goal state
	
	State[] frontierStart, frontierEnd, SS; // lifo queue - add to back, take from front
	
	// initialize frontiers and statemap
	frontierStart ~= State(3,3,true);
	frontierEnd ~= State(0,0,false);
	stateMap[frontierStart[0]] = new StateHolder(frontierStart[0], null, true);
	stateMap[frontierEnd[0]] = new StateHolder(frontierEnd[0], null, false);
	
	// While either frontier is non-empty (and we haven't found the solution yet)
	while (!frontierStart.empty || !frontierEnd.empty) {
		// expand start frontier
		debug(MissCanAI) writeln("frontierStart before:", frontierStart);
		if (!frontierStart.empty)
			SS = doBFS!true(frontierStart);
		if (SS) break;
		
		// expand end frontier
		debug(MissCanAI) writeln("frontierEnd   before:\t\t\t\t\t\t\t", frontierEnd);
		if (!frontierEnd.empty)
			SS = doBFS!false(frontierEnd);
		if (SS) break;
	}
	if (!SS)
		writeln("Empty frontiers - Cannot find a solution."); // Should never happen as the problem is solvable
	else
		writeln("SOLUTION: ",SS);
}

/// Expands the next state in the frontier and adds its children to the frontier
/// returns solution sequence if found or null
State[] doBFS(bool isForward)(ref const(State)[] frontier)
{
	
	//while (!frontier.empty) {
	immutable State stateToExpand = frontier.front;
	frontier.popFront();
	StateHolder stateToExpandHolder = stateMap[stateToExpand];
	
	foreach (const State childState; stateToExpand.expandState()) {
		if (childState in stateMap) {
			// if it's from the other process, we met!
			StateHolder childStateHolder = stateMap[childState];
			if (childStateHolder.isForward != isForward) {
				// we met!
				State[] SS;
				static if (isForward) {
					SS = getSolutionSequence(stateToExpandHolder, childStateHolder);
				} else {
					SS = getSolutionSequence(childStateHolder, stateToExpandHolder);
				}
				return SS;
			} else {
				// repeated state, throw it away
				continue;
			}
		} else {
			// new state - RACE HERE for parallel
			stateMap[childState] = new StateHolder(childState, stateToExpandHolder, isForward);
			frontier ~= childState;
		}
	}
	return null;
}

/// Builds the solution sequence from the stateMap
State[] getSolutionSequence(StateHolder lastForwardState, StateHolder firstBackwardState)
{
	// initial <- ... <- lastForwardState --- firstBackwardState -> ... -> goal state
	State[] SS = [lastForwardState.s]; // solution sequence
	while (lastForwardState.prev !is null)
		SS ~= (lastForwardState = lastForwardState.prev).s;
	reverse(SS);
	SS ~= firstBackwardState.s;
	while (firstBackwardState.prev !is null)
		SS ~= (firstBackwardState = firstBackwardState.prev).s;
	return SS;
}
