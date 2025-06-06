//-----------------------------------------------------------------------------
// Rock, Paper, Scissors game by Syn9
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
    int p_score;
    int c_score;
    int tries = 3;
    int max = tries;
    
    const int ROCK = 0;
    const int PAPER = 1;
    const int SCISSORS = 2;
    const int INVALID = 3;
    
    const int TIE = 0;
    const int PLAYER_WIN = 1;
    const int COMPUTER_WIN = 2;
	
    io::printfn("Let's play Rock-Paper-Scissors!");
    while (tries > 0) {
        io::printf("Best out of %d, %d tries remaining. ", max, tries);
        io::printfn("What is your guess? [r]ock, [p]aper, or [s]cissors?");
	
        int guess = INVALID;
        while (true) {
            String? s = io::treadline();
            if (catch s) { continue; }
            
            if ("r" == s) {
                guess = ROCK;
            }
            else if ("p" == s) {
                guess = PAPER;
            }
            else if ("s" == s) {
                guess = SCISSORS;
            }
            else {
                io::printfn("input invalid.");
            }
            if (INVALID != guess) {
                break;
            }
        }
    
        String choice;
        if (ROCK == guess) {
            choice = "Rock";
        }
        else if (PAPER == guess) {
            choice = "Paper";
        }
        else if (SCISSORS == guess) {
            choice = "Scissors";
        }
        io::printfn("Player: %s", choice);
    
        int comp = util_rand_range(0, 3);
        if (ROCK == comp) {
            choice = "Rock";
        }
        else if (PAPER == comp) {
            choice = "Paper";
        }
        else if (SCISSORS == comp) {
            choice = "Scissors";
        }
        io::printfn("Computer: %s", choice);
    
        int result = TIE;
        if (( ROCK == comp && SCISSORS == guess ) || ( SCISSORS == comp && PAPER == guess ) || ( PAPER == comp && ROCK == guess )) {
            result = COMPUTER_WIN;
        }
        else if (( ROCK == guess && SCISSORS == comp ) || ( SCISSORS == guess && PAPER == comp ) || ( PAPER == guess && ROCK == comp )) {
            result = PLAYER_WIN;
        }
        
        tries = tries - 1;
        if (TIE == result) {
            io::printfn("Tie!");
            tries = tries + 1;
        }
        else if (COMPUTER_WIN == result) {
            io::printfn("Computer Score!");
            c_score = c_score + 1;
        }
        else if (PLAYER_WIN == result) {
            io::printfn("Player Score!");
            p_score = p_score + 1;
        }
        io::printfn("Score: Player: %d, Computer: %d", p_score, c_score);
    }
    
    if (p_score == c_score) {
        io::printfn("GAME TIED!");
    }
    else if (p_score > c_score) {
        io::printfn("PLAYER WINS GAME!");
    }
    else {
        io::printfn("COMPUTER WINS GAME!");
    }
}

