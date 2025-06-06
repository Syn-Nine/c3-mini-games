//-----------------------------------------------------------------------------
// Catfish Bouncer - Raylib minigame by Syn9
// Tested with c3c 0.7.1
//-----------------------------------------------------------------------------

module game;

import std::io;
import std::math::random;
import std::math;
import raylib5::rl;
import libc;

//-----------------------------------------------------------------------------
// Structure Definitions
//-----------------------------------------------------------------------------

struct Game_data_s {
    // clock
    double t_prev;
    double t_base;
    double t_delta;
    
    // ball
    float ball_x;
    float ball_y;
    float ball_dx;
    float ball_dy;
    float ball_speed;
    
    // mouse
    int mx;
    int my;
    int prev_mx;
    int prev_my;
    float dmx;
    float dmy;
    
    // state
    float yumY;
    int fish;
    bool newBall;
}


//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

fn void draw_game_board() {
    rl::beginDrawing();
    rl::clearBackground(BG_COLOR);
    
    // testing text output
    rl::drawText("Catfish Bouncer!", 20, 20, 20, TXT_COLOR);
    rl::drawText(string::tformat_zstr("fps: %d", (int)( 1 / game_data.t_delta )), 20, 40, 20, TXT_COLOR);
    rl::drawText(string::tformat_zstr("clock: %f", libc::clock() / 1000.0 - game_data.t_base ), 20, 60, 20, TXT_COLOR);
    rl::drawCircle(XRES_HALF, YRES_HALF, 30, CAT_COLOR);
    
    // draw cat
    float w = 15;
    float h = 50;
    rl::drawTriangle({XRES_HALF, YRES_HALF}, {XRES_HALF - w, YRES_HALF - h}, {XRES_HALF - w - w, YRES_HALF}, CAT_COLOR);
    rl::drawTriangle({XRES_HALF, YRES_HALF}, {XRES_HALF + w + w, YRES_HALF}, {XRES_HALF + w, YRES_HALF - h}, CAT_COLOR);
    
    // draw fish
    for (int i = 0; i < game_data.fish; i++) {
        rl::drawCircle((int)(XRES_HALF + ( i - ( game_data.fish - 1.00 ) / 2 ) * 12), YRES_HALF + 50, 5, YUM_COLOR);
    }
    
    // draw ball
    if (!game_data.newBall) {
        rl::drawCircle((int)(game_data.ball_x), (int)(game_data.ball_y), BALL_RADIUS, BALL_COLOR);
    }
    
    // draw yum text
    game_data.yumY = (float)(game_data.yumY - game_data.t_delta);
    if (game_data.yumY > 0) {
        rl::drawText("YUM!", XRES_HALF - 50, (int)(YRES_HALF - 50 - YUM_MAX * ( 1 - game_data.yumY )), 40, YUM_COLOR);
    }
    
    // draw paddles
    rl::drawRectangle(game_data.mx - PADDLE_W, 0, PADDLE_W * 2, PADDLE_H, PADDLE_COLOR);
    rl::drawRectangle(game_data.mx - PADDLE_W, YRES - PADDLE_H, PADDLE_W * 2, PADDLE_H, PADDLE_COLOR);
    rl::drawRectangle(0, game_data.my - PADDLE_W, PADDLE_H, PADDLE_W * 2, PADDLE_COLOR);
    rl::drawRectangle(XRES - PADDLE_H, game_data.my - PADDLE_W, PADDLE_H, PADDLE_W * 2, PADDLE_COLOR);
    rl::endDrawing();
}


// game logic
fn void update_game_state() {
    // mouse delta for moving paddles and applying friction
    game_data.prev_mx = game_data.mx;
    game_data.prev_my = game_data.my;
    game_data.mx = rl::getMouseX();
    game_data.my = rl::getMouseY();
    game_data.dmx = game_data.dmx * 0.80 + (float)( game_data.mx - game_data.prev_mx ) * ( 1 - 0.80 );
    game_data.dmy = game_data.dmy * 0.80 + (float)( game_data.my - game_data.prev_my ) * ( 1 - 0.80 );
    
    // time delta for animation
    double t_clock = libc::clock() / 1000.0;
    game_data.t_delta = ( t_clock - game_data.t_prev );
	if (game_data.t_delta < 1e-5) { game_data.t_delta = 1e-5; }
    game_data.t_prev = t_clock;
    
    // is ball outside of game board?
    if (( game_data.yumY < 0 && game_data.newBall ) || PADDLE_H > game_data.ball_x || XRES - PADDLE_H < game_data.ball_x || PADDLE_H > game_data.ball_y || YRES - PADDLE_H < game_data.ball_y) {
        // initialize position
		game_data.ball_x = (float)100 + (float)(rnd() * ( XRES_HALF - 200 ));
		if (rnd() < 0.50) {
            game_data.ball_x = XRES_HALF + game_data.ball_x;
        }
		game_data.ball_y = (float)100 + (float)(rnd() * ( YRES - 200 ));
	
	// initialize velocity
		game_data.ball_speed = START_SPEED;
        float angle = (float)(rnd() * 3.141593 * 2.00);
        game_data.ball_dx = game_data.ball_speed * math::cos(angle);
        game_data.ball_dy = game_data.ball_speed * math::sin(angle);
        game_data.newBall = false;
    }
    
    // update ball state
    if (!game_data.newBall) {
        // integrate ball location
        game_data.ball_x = game_data.ball_x + (float)(game_data.ball_dx * game_data.t_delta);
        game_data.ball_y = game_data.ball_y + (float)(game_data.ball_dy * game_data.t_delta);
	
	// top/bottom bounce
        if (game_data.ball_x > (float)(game_data.mx - PADDLE_W) && game_data.ball_x < (float)(game_data.mx + PADDLE_W)) {
            if (game_data.ball_y - BALL_RADIUS < PADDLE_H || game_data.ball_y + BALL_RADIUS > YRES - PADDLE_H) {
                game_data.ball_dy = - game_data.ball_dy;
                game_data.ball_y = PADDLE_H + BALL_RADIUS;
                if (game_data.ball_dy < 0) {
                    game_data.ball_y = YRES - PADDLE_H - BALL_RADIUS;
                }
                game_data.ball_dx = game_data.ball_dx + game_data.dmx * game_data.ball_speed / 20;
                game_data.ball_speed = game_data.ball_speed + INC_SPEED;
            }
        }
	
	// left/right bounce
        if (game_data.ball_y > (float)(game_data.my - PADDLE_W) && game_data.ball_y < (float)(game_data.my + PADDLE_W)) {
            if (game_data.ball_x - BALL_RADIUS < PADDLE_H || game_data.ball_x + BALL_RADIUS > XRES - PADDLE_H) {
                game_data.ball_dx = - game_data.ball_dx;
                game_data.ball_x = PADDLE_H + BALL_RADIUS;
                if (game_data.ball_dx < 0) {
                    game_data.ball_x = XRES - PADDLE_H - BALL_RADIUS;
                }
                game_data.ball_dy = game_data.ball_dy + game_data.dmy * game_data.ball_speed / 20;
                game_data.ball_speed = game_data.ball_speed + INC_SPEED;
            }
        }
	
	// check for feed
        if (game_data.yumY < 0 && game_data.ball_x > XRES_HALF - FEED_RADIUS && game_data.ball_x < XRES_HALF + FEED_RADIUS && game_data.ball_y > YRES_HALF - FEED_RADIUS && game_data.ball_y < YRES_HALF + FEED_RADIUS) {
            game_data.yumY = 1.00;
            game_data.newBall = true;
            game_data.fish = game_data.fish + 1;
        }
    }
}


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

// window res
const int XRES = 800;
const int YRES = 600;
const int XRES_HALF = XRES / 2;
const int YRES_HALF = YRES / 2;

// entity colors
const BG_COLOR = rl::RAYWHITE;
const CAT_COLOR = rl::ORANGE;
const TXT_COLOR = rl::LIGHTGRAY;
const YUM_COLOR = rl::SKYBLUE;
const BALL_COLOR = rl::SKYBLUE;
const PADDLE_COLOR = rl::GRAY;

// game constants
const float START_SPEED = 300;
const float INC_SPEED = 20;
const int BALL_RADIUS = 20;
const float FEED_RADIUS = 50;
const int PADDLE_W = 50;
const int PADDLE_H = 10;
const float YUM_MAX = 100;

// global game structure
Game_data_s game_data;
    
fn void main() {
    rl::initWindow(XRES, YRES, "Catfish Bouncer");
    rl::setTargetFPS(60);
    
	game_data.t_prev = libc::clock() / 1000.0;
    game_data.t_base = libc::clock() / 1000.0;
	
    while (true) {
        update_game_state();
        draw_game_board();
        if (rl::windowShouldClose()) {
            break;
        }
    }
    
    rl::closeWindow();
}

