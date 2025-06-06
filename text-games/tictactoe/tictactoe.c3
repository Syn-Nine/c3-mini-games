//-----------------------------------------------------------------------------
// Tic-Tac-Toe game by Syn9
// Tested with c3c 0.7.1
//-----------------------------------------------------------------------------

import std::io;
import std::math::random;

fn int util_rand_range(int lhs, int rhs) {
	return lhs + rand(rhs - lhs); // [lhs, rhs)
}


//-----------------------------------------------------------------------------
// Global Enumeration
//-----------------------------------------------------------------------------

enum Enums {
    ENUM_COMPUTER,
    ENUM_EMPTY,
    ENUM_PLAYER,
}


//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

fn bool check_win(Enums who) {
    bool ret = false;
    int idx;
    
    // check rows
    for (int row = 0; row < 3; row++) {
        idx = row * 3;
        if (who == board[idx] && who == board[idx + 1] && who == board[idx + 2]) {
            ret = true;
        }
    }
    
    // check columns
    for (int col = 0; col < 3; col++) {
        idx = col;
        if (who == board[idx] && who == board[idx + 3] && who == board[idx + 6]) {
            ret = true;
        }
    }
    
    // check diagonals
    if (who == board[4]) {
        if (who == board[0] && who == board[8]) {
            ret = true;
        }
        else if (who == board[2] && who == board[6]) {
            ret = true;
        }
    }
    
    if (ret) {
        if (ENUM_PLAYER == who) {
            io::printfn("Player Wins!");
        }
        else {
            io::printfn("Computer Wins!");
        }
    }
    else {
        for (int i = 0; i < SZ; i++) {
            if (ENUM_EMPTY == board[i]) {
                break;
            }
            if (8 == i) {
                ret = true;
                io::printfn("DRAW!");
            }
        }
    }
    	
    return ret;
}

fn void draw_board() {
    io::printfn("/-----------\\");
    io::printf("| ");
    draw_cell(0);
    io::printf(" | ");
    draw_cell(1);
    io::printf(" | ");
    draw_cell(2);
    io::printfn(" | ");
    io::printfn("|---|---|---|");
    io::printf("| ");
    draw_cell(3);
    io::printf(" | ");
    draw_cell(4);
    io::printf(" | ");
    draw_cell(5);
    io::printfn(" | ");
    io::printfn("|---|---|---|");
    io::printf("| ");
    draw_cell(6);
    io::printf(" | ");
    draw_cell(7);
    io::printf(" | ");
    draw_cell(8);
    io::printfn(" | ");
    io::printfn("\\-----------/");
}

fn void draw_cell(int idx) {
    switch {
        case ENUM_PLAYER == board[idx]:
            io::printf("X");
        case ENUM_COMPUTER == board[idx]:
            io::printf("O");
        default:
            io::printf("%d", ( idx + 1 ));
    }
}

fn void get_player_input() {
    while (true) {
        io::printfn("Enter the # for your choice (X)");
        int? temp = io::treadline().to_int();
        if (catch temp) { continue; }
		
        if (temp > 0 && temp < 10 && ENUM_EMPTY == board[temp - 1]) {
            board[temp - 1] = ENUM_PLAYER;
            break;
        }
        io::printfn("Invalid choice.");
    }
}

fn void get_computer_input() {
    while (true) {
        int choice = util_rand_range(0, SZ);
        if (ENUM_EMPTY == board[choice]) {
            board[choice] = ENUM_COMPUTER;
            break;
        }
    }
}


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

const int SZ = 9;
Enums[9] board;

fn void main() {
    for (int i = 0; i < 9; i++) {
        board[i] = ENUM_EMPTY;
    }
    
    io::printfn("Let's play Tic-Tac-Toe!");
    io::printfn("-----------------------------------------------------");
    while (true) {
        draw_board();
        get_player_input();
        if (check_win(ENUM_PLAYER)) {
            break;
        }
        get_computer_input();
        if (check_win(ENUM_COMPUTER)) {
            break;
        }
    }
    draw_board();
}

