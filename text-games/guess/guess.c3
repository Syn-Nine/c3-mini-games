//-----------------------------------------------------------------------------
// Guess the number game by Syn9
// Tested with c3c v0.7.1
//-----------------------------------------------------------------------------

import std::io;
import std::math::random;

fn int util_rand_range(int lhs, int rhs) {
	return lhs + rand(rhs - lhs); // [lhs, rhs)
}

//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

fn void main() {
	// state
    int tries = 6;
    int secret = util_rand_range(1, 19 + 1);
	
	// game loop
    while (tries > 0) {
        io::printfn("Enter a guess between 0 and 20, %d tries remaining", tries);
        
		int? guess = io::treadline().to_int();
		if (catch guess) { continue; }
        if (guess < secret) {
            io::printfn("Too Small");
        }
        else if (guess > secret) {
            io::printfn("Too Large");
        }
        else {
            io::printfn("You Win!");
            tries = 0;
        }
		
        tries = tries - 1;
        if (0 == tries) {
            io::printfn("Game Over");
        }
    }
}
