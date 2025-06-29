//-----------------------------------------------------------------------------
// Dungeon of the Phoenix - by Syn9
// Tested with c3c 0.7.1
//-----------------------------------------------------------------------------

module game;

import std::io;
import std::math::random;
import std::math;
import raylib5::rl;
import libc;


fn int util_rand_range(int lhs, int rhs) {
	return lhs + rand(rhs - lhs); // [lhs, rhs)
}


fn void myDrawTextureProRGBA(rl::Texture texture, float tx, float ty, float tw, float th, float dx, float dy, float dw, float dh, float ox, float oy, float rot, int r, int g, int b, int a) {
	rl::drawTexturePro(texture, (rl::Rectangle){tx, ty, tw, th}, (rl::Rectangle){dx, dy, dw, dh}, (rl::Vector2){ox, oy}, rot, (rl::Color){(char)r, (char)g, (char)b, (char)a});
}


fn void myDrawTexturePro(rl::Texture texture, float tx, float ty, float tw, float th, float dx, float dy, float dw, float dh, float ox, float oy, float rot, rl::Color c) {
	rl::drawTexturePro(texture, (rl::Rectangle){tx, ty, tw, th}, (rl::Rectangle){dx, dy, dw, dh}, (rl::Vector2){ox, oy}, rot, c);
}



//-----------------------------------------------------------------------------
// Global Enumeration
//-----------------------------------------------------------------------------

enum Enums {
    ARM_HELMET,
    ARM_MAIL,
    ARM_SHIELD,
    CHASE,
    CONTROLS,
    GAME,
    HEART,
    INTRO,
    INVALID,
    KEY,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP,
    POTION_HEALTH,
    POTION_MANA,
    ROD,
    TURKEY_LEG,
    WANDER,
    WIN,
}


//-----------------------------------------------------------------------------
// Structure Definitions
//-----------------------------------------------------------------------------

struct Notification {
    String txt;
    rl::Color color;
    float timer;
}

struct Entity_s {
    float px;
    float py;
    int ix;
    int iy;
    int kx;
    int ky;
    int r;
    int g;
    int b;
    int sprite;
    int health;
    int max_health;
    int mana;
    int max_mana;
    int defense;
    int power;
    int level;
    int skip_update;
    float cooldown;
    Enums state;
    bool enemy;
    bool block_movement;
}

struct Vec2i {
    int x;
    int y;
}

struct Projectile_s {
    float px;
    float py;
    float vx;
    float vy;
    bool active;
}

struct Room_s {
    int x;
    int y;
    int w;
    int h;
    int cx;
    int cy;
}

struct Item_s {
    int ix;
    int iy;
    int sprite;
    String name;
    rl::Color color;
    Enums kind;
    int skip_update;
    bool block_movement;
    bool found;
}


//-----------------------------------------------------------------------------
// Function Definitions
//-----------------------------------------------------------------------------

fn void unload_sounds() {
    rl::unloadSound(snd_blip);
    rl::unloadSound(snd_hurt);
    rl::unloadSound(snd_attack);
    rl::unloadSound(snd_pickup);
    rl::unloadSound(snd_potion);
    rl::unloadSound(snd_ambient_1);
    rl::unloadSound(snd_ambient_2);
    rl::unloadSound(snd_ambient_3);
    rl::unloadSound(snd_cast);
    rl::unloadSound(snd_dead);
    rl::unloadSound(snd_door);
    rl::unloadSound(snd_levelup);
    rl::unloadSound(snd_shake);
    rl::unloadSound(snd_melody);
}

fn void ui_draw() {

    if (screen_shake) {
        double dt = 1.0 / 60.0;
        phoenix_frame = phoenix_frame + dt;
        if (phoenix_frame > 1) {
            phoenix_frame = phoenix_frame + dt * 0.50;
        }
        if (phoenix_frame > 8) {
            phoenix_frame = 8;
        }
        t_shake_timer = t_shake_timer - dt;
        if (t_shake_timer < 4.50 && !shake_sound_played) {
            rl::playSound(snd_shake);
            shake_sound_played = true;
            found_tears = true;
            rl::playSound(snd_levelup);
            note.txt = "Found Phoenix Tears!";
            note.color = CYAN;
            note.timer = 999.00;
        }
        if (shake_sound_played) {
            t_shake_move = t_shake_move - dt;
            if (0 > t_shake_move) {
                t_shake_move = 0.05;
                float an = (float)(rnd() * 2 * 3.14159326);
                shake_x = math::cos(an) * 4;
                shake_y = math::sin(an) * 4;
            }
            if (0 > t_shake_timer) {
                screen_shake = false;
                shake_x = 0;
                shake_y = 0;
                menu = WIN;
                rl::playSound(snd_melody);
                game_win = true;
                for (int eidx = 1; eidx < num_entities; eidx++) {
                    if (0 < eidx && game_win) {
                        entities[eidx].health = 0;
                        entities[eidx].sprite = 39;
                        entities[eidx].block_movement = false;
                    }
                }
            }
        }
    }
	
    double t_delta = 1.0 / 60.0;
    int lvl = entities[0].level;
    draw_text(0, ( YRES - 30 ) * SCALE, string::tformat("Level: %d", lvl), rl::DARKGRAY);
    draw_text(76 * SCALE, ( YRES - 30 ) * SCALE, string::tformat("Pwr: %d", entities[0].power), rl::DARKGRAY);
    draw_text(144 * SCALE, ( YRES - 30 ) * SCALE, string::tformat("Def: %d", entities[0].defense), rl::DARKGRAY);
	
    int tx = 0;
    int ty = 5;
    if (found_shield) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, 208 * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255);
    }
    tx = 1;
    if (found_helmet) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, 224 * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255);
    }
    tx = 2;
    if (found_mail) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, 240 * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255);
    }
    tx = 7;
    ty = 6;
    if (found_key) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, 256 * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 255, 255, 0, 255);
    }
    tx = 7;
    ty = 7;
    if (found_tears) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, 256 * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 32, 192, 255, 255);
    }
    if (!game_win && !screen_shake) {
        t_game = rl::getTime() - t_clock;
    }
	
    String time = "GameTime: ";
    int m = (int)(t_game / 60.0);
    int s = (int)(t_game - (double)m * 60.0);
    time = string::tformat("%s%d:", time, m);
    if (s < 10) {
        time = string::tformat("%s0", time);
    }
    time = string::tformat("%s%d", time, s);
    draw_text_sm(208 * SCALE, ( YRES - 10 ) * SCALE, time, rl::GRAY);
	
    if (0.00 < note.timer) {
        note.timer -= (float)t_delta;
        rl::Color color = note.color;
        if (2.00 > note.timer) {
            color = rl::DARKGRAY;
        }
        if (1.00 > note.timer) {
            color = DARKDARKGRAY;
        }
        draw_text(0, ( YRES - 16 ) * SCALE, string::tformat("> %s", note.txt), color);
    }
    else {
        draw_text(0, ( YRES - 16 ) * SCALE, ">", DARKDARKGRAY);
    }
	
    float r = (float)entities[0].health / (float)entities[0].max_health;
    float inc = 1.00 / (float)( lvl * 3 * 2 );
    float tot = 0;
    for (int i = 0; i < lvl * 2; i++) {
        tx = 0;
        ty = 6;
        myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::DARKGRAY);
        tot = tot + inc;
        if (r > tot) {
            myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, DARKRED);
        }
        tot = tot + inc;
        if (r > tot) {
            tx = 1;
            myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::RED);
        }
        tot = tot + inc;
    }
    draw_text(( XRES_HALF - 16 ) * SCALE, ( YRES - 30 ) * SCALE, string::tformat("HP: %d/%d", entities[0].health, entities[0].max_health), DARKRED);
	
    tx = 3;
    ty = 6;
    myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, ( XRES_HALF + 84 ) * SCALE, ( YRES - 32 ) * SCALE, (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::RED);
    draw_text(( XRES_HALF + 100 ) * SCALE, ( YRES - 30 ) * SCALE, string::tformat("x%d", inventory[0]), rl::RED);
    draw_text(( XRES_HALF + 68 ) * SCALE, ( YRES - 30 ) * SCALE, "H:", rl::RED);
	
    if (found_rod) {
        r = (float)entities[0].mana / (float)entities[0].max_mana;
        inc = 1.00 / (float)( lvl * 3 * 2 );
        tot = 0;
        for (int i = 0; i < lvl * 2; i++) {
            tx = 6;
            ty = 6;
            myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::DARKGRAY);
            tot = tot + inc;
            if (r > tot) {
                myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::DARKGREEN);
            }
            tot = tot + inc;
            if (r > tot) {
                myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2), (float)(( YRES - 16 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::GREEN);
            }
            tot = tot + inc;
        }
        draw_text(( XRES_HALF + 150 ) * SCALE, ( YRES - 30 ) * SCALE, string::tformat("MP: %d/%d", entities[0].mana, entities[0].max_mana), rl::DARKGREEN);
        tx = 2;
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF + 150 - 18 ) * SCALE), (float)(( YRES - 32 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 128, 255, 128, 255);
        tx = 3;
        myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(( XRES_HALF + 252 ) * SCALE), (float)(( YRES - 32 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, rl::GREEN);
        draw_text(( XRES_HALF + 268 ) * SCALE, ( YRES - 30 ) * SCALE, string::tformat("x%d", inventory[1]), rl::GREEN);
        draw_text(( XRES_HALF + 234 ) * SCALE, ( YRES - 30 ) * SCALE, "M:", rl::GREEN);
        draw_text(( XRES_HALF + 134 ) * SCALE, ( YRES - 15 ) * SCALE, "C:", rl::GREEN);
    }
	
    if (INTRO == menu) {
        draw_intro();
    }
    else if (CONTROLS == menu) {
        draw_controls();
    }
    else if (WIN == menu) {
        draw_win();
    }
}

fn void draw_house() {
    int x = XRES_HALF - 110;
    int y = YRES_HALF;
    myDrawTexturePro(gradient, 0, 0, 110, 26, (float)(x * SCALE), (float)(( y - 52 ) * SCALE), (float)(220 * SCALE), (float)(52 * SCALE), 0, 0, 0, rl::WHITE);
    myDrawTexturePro(icons, 5 * 8, 0, 8, 8, (float)(x * SCALE), (float)(y * SCALE), (float)(220 * SCALE), (float)(46 * SCALE), 0, 0, 0, SHARKGRAY);
    myDrawTexturePro(icons, 0, 80, 8, 8, (float)(( x - 8 ) * SCALE), (float)(( y - 60 ) * SCALE), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 40, 80, 8, 8, (float)(( x + 220 ) * SCALE), (float)(( y - 60 ) * SCALE), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 48, 80, 8, 8, (float)(( x - 8 ) * SCALE), (float)(( y + 46 ) * SCALE), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 56, 80, 8, 8, (float)(( x + 220 ) * SCALE), (float)(( y + 46 ) * SCALE), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 8, 80, 8, 8, (float)(x * SCALE), (float)(( y - 60 ) * SCALE), 220 * SCALE, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 32, 80, 8, 8, (float)(x * SCALE), (float)(( y + 46 ) * SCALE), 220 * SCALE, (float)SCALE_8, 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 24, 80, 8, 8, (float)(( x - 8 ) * SCALE), (float)(( y - 52 ) * SCALE), (float)SCALE_8, (float)(98 * SCALE), 0, 0, 0, rl::GOLD);
    myDrawTexturePro(icons, 16, 80, 8, 8, (float)(( x + 220 ) * SCALE), (float)(( y - 52 ) * SCALE), (float)SCALE_8, (float)(98 * SCALE), 0, 0, 0, rl::GOLD);
}

fn void draw_intro() {
    draw_house();
    int x = XRES_HALF - 110;
    int y = YRES_HALF;
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, (float)(( XRES_HALF - 40 ) * SCALE), (float)(( y - 30 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 0, 128, 255, 255);
    myDrawTexturePro(icons, 0, 8, 8, 8, (float)(( XRES_HALF - 8 ) * SCALE), (float)(( y - 30 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, BITTERSWEET);
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Dear", rl::WHITE);
    draw_text_sm(( x + 30 ) * SCALE, ( y + 4 ) * SCALE, "Adventurer", rl::BLUE);
    draw_text_sm(( x + 81 ) * SCALE, ( y + 4 ) * SCALE, ", your mother is gravely ill.", rl::WHITE);
    draw_text_sm(( x + 7 ) * SCALE, ( y + 14 ) * SCALE, "You must find the", rl::LIGHTGRAY);
    draw_text_sm(( x + 87 ) * SCALE, ( y + 14 ) * SCALE, "Tears of the Phoenix", CYAN);
    draw_text_sm(( x + 186 ) * SCALE, ( y + 14 ) * SCALE, "in the", rl::LIGHTGRAY);
    draw_text_sm(( x + 7 ) * SCALE, ( y + 24 ) * SCALE, "forbidden ruins to save her. Please hurry...", rl::GRAY);
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", rl::GRAY);
}

fn void draw_controls() {
    draw_house();
    int x = XRES_HALF - 110;
    int y = YRES_HALF;
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, (float)(( XRES_HALF - 40 ) * SCALE), (float)(( y - 30 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 0, 128, 255, 255);
    myDrawTexturePro(icons, 0, 8, 8, 8, (float)(( XRES_HALF - 8 ) * SCALE), (float)(( y - 30 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, BITTERSWEET);
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Controls:", rl::WHITE);
    draw_text_sm(( x + 19 ) * SCALE, ( y + 14 ) * SCALE, "Move: Arrow Keys", rl::WHITE);
    draw_text_sm(( x + 14 ) * SCALE, ( y + 24 ) * SCALE, "Attack: Bump", rl::WHITE);
    draw_text_sm(( x + 121 ) * SCALE, ( y + 4 ) * SCALE, "H: Heal Potion", rl::RED);
    draw_text_sm(( x + 120 ) * SCALE, ( y + 14 ) * SCALE, "M: Mana Potion", rl::GREEN);
    draw_text_sm(( x + 121 ) * SCALE, ( y + 24 ) * SCALE, "C: Cast Magic", rl::GREEN);
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", rl::GRAY);
}

fn void draw_win() {
    int x = XRES_HALF - 110;
    int y = YRES_HALF;
    t_win = t_win + 1.0 / 60.0;
    if (t_win < 0.50) {
        return ;
    }
    draw_house();
    float xx = (float)t_win * 10;
    float alpha = 255.0 * ( 1 - (float)t_win / 10.0 );
    if (alpha < 0) {
        alpha = 0;
    }
    myDrawTextureProRGBA(icons, 0, 0, 8, 8, (float)(( XRES_HALF - 40 + xx ) * SCALE), (float)(( y - 30 ) * SCALE), (float)SCALE_8 * 2, (float)SCALE_8 * 2, 0, 0, 0, 0, 128, 255, (int)alpha);
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 10 ) * SCALE, "I'm almost there, please hold on...", CYAN);
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to end.", rl::GRAY);
}

fn void add_note(String text, rl::Color color, float cooldown) {
    note.txt = text;
    note.color = color;
    note.timer = cooldown;
}

fn void draw_text(int x, int y, String txt, rl::Color color) {
    rl::drawTextEx(fnt, string::tformat_zstr("%s", txt), (rl::Vector2){x, y}, 15 * SCALE, 1, color);
}

fn void draw_text_center(int x, int y, String txt, rl::Color color) {
    int m = (int)rl::measureTextEx(fnt, string::tformat_zstr("%s", txt), 15 * SCALE, 1).x;
    draw_text(x - m / 2, y, txt, color);
}

fn void draw_text_right(int x, int y, String txt, rl::Color color) {
    int m = (int)rl::measureTextEx(fnt, string::tformat_zstr("%s", txt), 15 * SCALE, 1).x;
    draw_text(x - m, y, txt, color);
}

fn void draw_text_sm(int x, int y, String txt, rl::Color color) {
    rl::drawTextEx(fnt_sm, string::tformat_zstr("%s", txt), (rl::Vector2){x, y}, (float)SCALE_8, 0, color);
}

fn void draw_text_sm_center(int x, int y, String txt, rl::Color color) {
    int m = (int)rl::measureTextEx(fnt_sm, string::tformat_zstr("%s", txt), (float)SCALE_8, 0).x;
    draw_text_sm(x - m / 2, y, txt, color);
}

fn void draw_text_sm_right(int x, int y, String txt, rl::Color color) {
    int m = (int)rl::measureTextEx(fnt_sm, string::tformat_zstr("%s", txt), (float)SCALE_8, 0).x;
    draw_text_sm(x - m, y, txt, color);
}

fn void entity_new(int x, int y, int sprite, int health, int level, int power, int defense, bool enemy) {
    Entity_s e;
    e.px = x;
    e.py = y;
    e.ix = x;
    e.iy = y;
    e.sprite = sprite;
    e.block_movement = true;
    e.health = health;
    e.max_health = e.health;
    e.defense = defense;
    e.power = power;
    e.mana = 0;
    e.max_mana = 0;
    e.level = level;
    e.enemy = enemy;
    e.state = WANDER;
    e.skip_update = - 1;
	entities[num_entities] = e;
	num_entities += 1;
}

fn void entity_draw_all() {
    float px = entities[0].px;
    float py = entities[0].py;
    if (0 == entities[0].health) {
        entity_draw_player();
    }
    for (int i = 1; i < num_entities; i++) {
        if (0 > entities[i].skip_update) {
            if (!seen[entities[i].iy * MAP_WIDTH + entities[i].ix]) {
                continue;
            }
            float x = entities[i].px;
            float y = entities[i].py;
            if (0 < entities[i].health) {
                float dx = px - entities[i].px;
                float dy = py - entities[i].py;
                float dist = (float)math::sqrt((double)(dx * dx + dy * dy));
                if (dist < 7.00) {
                    int sprite = entities[i].sprite;
                    int tx = sprite % 8;
                    int ty = ( sprite - tx ) / 8;
                    float ratio = (float)((double)entities[0].level / ( (double)entities[i].level + 2 ) * 0.75);
                    if (ratio > 1) {
                        ratio = 1;
                    }
                    int r = 48;
                    int g = 48;
                    int b = 48;
                    if (dist < 5.00) {
                        r = (int)(255.0 * ( 1.0 - ratio ));
                        g = (int)(255.0 * ratio);
                        b = 0;
                    }
                    myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(x * SCALE_8) + (float)shake_x, (float)(y * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, r, g, b, 255);
                }
                else {
                    entities[i].skip_update = util_rand_range(5, 10);
                }
            }
            else {
                myDrawTexturePro(icons, 7 * 8, 4 * 8, 8, 8, (float)(x * SCALE_8) + (float)shake_x, (float)(y * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, DARKRED);
            }
        }
        else {
            entities[i].skip_update = entities[i].skip_update - 1;
        }
        int kx = entities[i].kx;
        int ky = entities[i].ky;
        if (kx < 0) {
            entities[i].kx = kx + 1;
        }
        if (kx > 0) {
            entities[i].kx = kx - 1;
        }
        if (ky < 0) {
            entities[i].ky = ky + 1;
        }
        if (ky > 0) {
            entities[i].ky = ky - 1;
        }
    }
    t_flames = t_flames + 1.0 / 60.0;
    for (int i = 0; i < num_torches; i++) {
        int ix = torches[i].x;
        int iy = torches[i].y;
        if (ix == entities[0].ix && iy == entities[0].iy && 0 < entities[0].health) {
            entities[0].health = 0;
            rl::playSound(snd_dead);
        }
        if (seen[iy * MAP_WIDTH + ix]) {
            int ofs = (int)(( t_flames * 12 + i )) % 6;
            int tx = (int)(( t_flames * 12 + i )) % 7;
            int ty = 7;
            myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(ix * SCALE_8 )+ (float)shake_x, (float)(iy * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, flame[ofs]);
        }
    }
    if (magic_ball.active) {
        myDrawTexturePro(icons, 6 * 8, 6 * 8, 8, 8, (float)magic_ball.px * (float)SCALE_8 + (float)shake_x, (float)magic_ball.py * (float)SCALE_8 + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, magic[util_rand_range(0, 5)]);
    }
    if (0 < entities[0].health) {
        entity_draw_player();
    }
}

fn void entity_draw_player() {
    int tx = 0;
    int ty = 0;
    float x = entities[0].px;
    float y = entities[0].py;
    if (0 < entities[0].health) {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(x * SCALE_8), (float)(y * SCALE_8), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, 0, 128, 255, 255);
    }
    else {
        myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(x * SCALE_8), (float)(y * SCALE_8), (float)SCALE_8, (float)SCALE_8, 0, 0, 0, 64, 64, 64, 255);
    }
}

fn void entity_move(int eidx, Enums move_dir) {
    int ix = entities[eidx].ix;
    int iy = entities[eidx].iy;
    int idx = iy * MAP_WIDTH + ix;
    if (MOVE_UP == move_dir && iy > 0 && 3 > board[idx - MAP_WIDTH]) {
        iy = iy - 1;
    }
    else if (MOVE_DOWN == move_dir && iy < MAP_HEIGHT - 1 && 3 > board[idx + MAP_WIDTH]) {
        iy = iy + 1;
    }
    else if (MOVE_LEFT == move_dir && ix > 0 && 3 > board[idx - 1]) {
        ix = ix - 1;
    }
    else if (MOVE_RIGHT == move_dir && ix < MAP_WIDTH - 1 && 3 > board[idx + 1]) {
        ix = ix + 1;
    }
    int new_idx = iy * MAP_WIDTH + ix;
    if (0 == eidx && idx != new_idx && 1 == board[new_idx]) {
        if (found_key) {
            found_key = false;
            add_note("Unlocked!", rl::YELLOW, 5.00);
            board[new_idx] = 2;
            rl::playSound(snd_door);
        }
        else {
            add_note("Locked!", rl::ORANGE, 5.00);
            new_idx = idx;
        }
    }
    if (idx != new_idx) {
        for (int i = 1; i < num_entities; i++) {
            if (0 > entities[i].skip_update && entities[i].block_movement && new_idx == entities[i].iy * MAP_WIDTH + entities[i].ix) {
                if (0 == eidx && 0 > entities[eidx].cooldown) {
                    entities[i].health = entities[i].health - 1;
                    note.txt = "Hit Beast for 1 dmg!";
                    note.color = rl::GRAY;
                    note.timer = 5.00;
                    entities[0].kx = ( ix - entities[eidx].ix ) * 8;
                    entities[0].ky = ( iy - entities[eidx].iy ) * 8;
                    entities[0].cooldown = 0.30;
                    rl::playSound(snd_attack);
                    if (0 == entities[i].health) {
                        entities[i].sprite = 39;
                        entities[i].block_movement = false;
                        note.txt = "Beast fell!";
                        note.color = rl::LIGHTGRAY;
                        note.timer = 5.00;
                    }
                }
                ix = entities[eidx].ix;
                iy = entities[eidx].iy;
                break;
            }
        }
        entities[eidx].ix = ix;
        entities[eidx].iy = iy;
        if (0 == eidx) {
            if (iy * MAP_WIDTH + ix == win_idx) {
                screen_shake = true;
                rl::playSound(snd_cast);
            }
        }
    }
    else {
        if (0 == eidx && 0.10 > note.timer) {
            add_note("Blocked!", rl::BROWN, 3.00);
        }
    }
}

fn void entity_spawn_monster(int x, int y, int lvl) {
    int mx = lvl * 23 / 5;
    if (mx < 4) {
        mx = 4;
    }
    if (mx > 23) {
        mx = 23;
    }
    int sprite = 16 + util_rand_range(0, mx);
    entity_new(x, y, sprite, (int)(1 + (float)( 1.0 + rnd() ) * (float)lvl), lvl, (int)(math::ceil((double)(( 0.20 + rnd() * 0.50 ) * lvl))), (int)(math::ceil((double)(( 0.20 + rnd() * 0.50 ) * lvl))), true);
}

fn void entity_update(int eidx, double t_delta) {
    
	float fps = (float)(1.0 / t_delta);
    if (fps < 10) {
        entities[eidx].px = entities[eidx].ix;
        entities[eidx].py = entities[eidx].iy;
        key_delay = 0;
    }
	
    float dx = entities[eidx].ix - entities[eidx].px;
    if (math::abs(dx) > 0.10) {
        entities[eidx].px = entities[eidx].px + dx * 0.50;
    }
    else {
        entities[eidx].px = entities[eidx].ix;
    }
	
    float dy = entities[eidx].iy - entities[eidx].py;
    if (math::abs(dy) > 0.10) {
        entities[eidx].py = entities[eidx].py + dy * 0.50;
    }
    else {
        entities[eidx].py = entities[eidx].iy;
    }
	
    entities[eidx].cooldown = (float)((double)entities[eidx].cooldown - t_delta);
}

fn void entity_update_all() {
    
	if (intro_hold) {
        return ;
    }
	
    double t_delta = 1.0 / 60.0;
    entity_update(0, t_delta);
    if (screen_shake) {
        return ;
    }
	
    if (0 < entities[0].health && entities[0].health < entities[0].max_health * 0.31 && !screen_shake && !game_win) {
        blip_timer = blip_timer - (float)t_delta;
        if (0 > blip_timer) {
            blip_timer = 1.00;
            rl::playSound(snd_blip);
        }
    }
	
    if (magic_ball.active) {
        magic_ball.px = magic_ball.px + magic_ball.vx * (float)t_delta;
        magic_ball.py = magic_ball.py + magic_ball.vy * (float)t_delta;
        int px = (int)(magic_ball.px + 0.50);
        int py = (int)(magic_ball.py + 0.50);
        int idx = py * MAP_WIDTH + px;
        if (- 1 != board[idx]) {
            magic_ball.active = false;
        }
    }
	
    if (!game_win && !screen_shake) {
        ambient_timer = ambient_timer - (float)t_delta;
        if (0 > ambient_timer) {
            ambient_timer = 4 + 4 * (float)rnd();
            int snd = util_rand_range(0, 3);
            if (0 == snd) {
                rl::playSound(snd_ambient_1);
            }
            else if (1 == snd) {
                rl::playSound(snd_ambient_2);
            }
            else if (2 == snd) {
                rl::playSound(snd_ambient_3);
            }
        }
    }
	
    for (int i = 1; i < num_entities; i++) {
        if (0 < entities[i].health && magic_ball.active) {
            float dx = entities[i].px - magic_ball.px;
            float dy = entities[i].py - magic_ball.py;
            if ((float)math::sqrt((double)(dx * dx + dy * dy)) < 0.50) {
                int dmg = 2 * entities[0].level;
                entities[i].health = max(0, entities[i].health - dmg);
                note.txt = string::tformat("Hit Beast for %d dmg!", dmg);
                note.color = rl::GRAY;
                note.timer = 5.00;
                entities[0].cooldown = 0.30;
                rl::playSound(snd_attack);
                if (0 == entities[i].health) {
                    entities[i].sprite = 39;
                    entities[i].block_movement = false;
                    note.txt = "Beast fell!";
                    note.color = rl::LIGHTGRAY;
                    note.timer = 5.00;
                }
            }
        }
        if (0 < entities[i].health && 0 > entities[i].skip_update && 0 > entities[i].cooldown) {
            if (amort == i % 4) {
                float dx = entities[0].px - entities[i].px;
                float dy = entities[0].py - entities[i].py;
                float dist = (float)math::sqrt((double)(dx * dx + dy * dy));
				
                if (WANDER == entities[i].state && dist < 5.00) {
                    entities[i].state = CHASE;
                }
                else if (CHASE == entities[i].state && dist > 7) {
                    entities[i].state = WANDER;
                }
				
                if (dist < 1.20 && rnd() < 0.50 && 0 < entities[0].health) {
                    note.txt = "Beast hit for 1 dmg!";
                    note.color = rl::RED;
                    note.timer = 5.00;
                    entities[i].cooldown = 0.70;
                    entities[i].ix = (int)entities[i].px;
                    entities[i].iy = (int)entities[i].py;
                    entities[i].kx = (int)dx * 8;
                    entities[i].ky = (int)dy * 8;
                    entities[0].health = max(0, entities[0].health - 1);
                    rl::playSound(snd_hurt);
                    if (0 == entities[0].health) {
                        rl::playSound(snd_dead);
                    }
                }
				
                if (WANDER == entities[i].state && rnd() < 0.10) {
                    int j = util_rand_range(0, 4);
                    if (0 == j) {
                        entity_move(i, MOVE_UP);
                    }
                    else if (1 == j) {
                        entity_move(i, MOVE_DOWN);
                    }
                    else if (2 == j) {
                        entity_move(i, MOVE_LEFT);
                    }
                    else if (3 == j) {
                        entity_move(i, MOVE_RIGHT);
                    }
                }
                else if (CHASE == entities[i].state && rnd() < 0.10) {
                    if (math::abs(dx) > math::abs(dy)) {
                        if (entities[i].px < entities[0].px) {
                            entity_move(i, MOVE_RIGHT);
                        }
                        else {
                            entity_move(i, MOVE_LEFT);
                        }
                    }
                    else {
                        if (entities[i].py < entities[0].py) {
                            entity_move(i, MOVE_DOWN);
                        }
                        else {
                            entity_move(i, MOVE_UP);
                        }
                    }
                }
            }
        }
        entity_update(i, t_delta);
    }
}

fn bool gen_rooms() {
    io::printfn("Generating Rooms");
	
	for (int i = 0; i < MAP_SZ; i++) {
		board[i] = -1;
		board2[i] = -1;
		board3[i] = -1;
		dist[i] = -1;
		dist2[i] = -1;
		seen[i] = false;
		known[i] = false;
	}
    
	num_rooms = 0;
	
	keep_going = false;
    int w3 = MAP_WIDTH / 3;
    int h2 = MAP_HEIGHT / 2;
    for (int j = 0; j < 6; j++) {
        int xx;
        int yy;
        if (1 == j) {
            yy = 1;
        }
        else if (2 == j) {
            xx = 1;
            yy = 1;
        }
        else if (3 == j) {
            xx = 1;
            yy = 0;
        }
        else if (4 == j) {
            xx = 2;
            yy = 0;
        }
        else if (5 == j) {
            xx = 2;
            yy = 1;
        }
        for (int k = 0; k < 200; k++) {
            int w = util_rand_range(4, 8);
            int h = util_rand_range(4, 6);
            int x = util_rand_range(( xx * w3 ), ( ( xx + 1 ) * w3 ) - w + 1);
            int y = util_rand_range(( yy * h2 ), ( ( yy + 1 ) * h2 ) - h + 1);
            if (check_room_plot(x, y, w, h)) {
                gen_room_plot(x, y, w, h);
            }
        }
    }
	
	bool[MAP_SZ] taken;
	for (int i = 0; i < MAP_SZ; i++) {
		taken[i] = false;
	}
	
    int w = 6;
    int h = 6;
    int y = MAP_HEIGHT - 7;
    int x = 54 + util_rand_range(0, 15);
    phoenix_loc = ( y + 2 ) * MAP_WIDTH + x + 2;
    gen_room_plot(x, y, w, h);
    for (int yy = 0; yy < h; yy++) {
        for (int xx = 0; xx < w; xx++) {
            int idx = ( y + yy ) * MAP_WIDTH + x + xx;
            taken[idx] = true;
        }
    }
	
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            if (- 1 == board[idx]) {
                board[idx] = 6;
            }
        }
    }
	
    for (int i = 0; i < num_rooms - 1; i++) {
        gen_hallway(i, i + 1);
    }
	
    for (int i = 0; i < MAP_SZ; i++) {
        board2[i] = board[i];
    }
	
    for (int i = 0; i < MAP_SZ; i++) {
        board[i] = board2[i];
        if (4 == board2[i]) {
            board[i] = - 1;
        }
        else if (- 1 == board2[i]) {
            board[i] = 3;
        }
        board2[i] = board[i];
    }
	
    for (int xi = 0; xi < MAP_WIDTH; xi++) {
        int idx = 18 * MAP_WIDTH + xi;
        if (- 1 == board[idx]) {
            board2[idx] = 1;
        }
    }
	
    for (int yi = 0; yi < MAP_HEIGHT - 1; yi++) {
        for (int xi = 0; xi < MAP_WIDTH - 1; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            if (6 != board[idx]) {
                continue;
            }
            if (6 == board[idx + 1] && 6 == board[idx + MAP_WIDTH] && 6 == board[idx + MAP_WIDTH + 1]) {
                board3[idx] = 13;
            }
        }
    }
	
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            if (6 != board[idx]) {
                continue;
            }
            bool up;
            bool down;
            bool left;
            bool right;
            if (xi > 0) {
                if (6 == board[idx - 1]) {
                    left = true;
                }
            }
            if (yi > 0) {
                if (6 == board[idx - MAP_WIDTH]) {
                    up = true;
                }
            }
            if (xi < MAP_WIDTH - 1) {
                if (6 == board[idx + 1]) {
                    right = true;
                }
            }
            if (yi < MAP_HEIGHT - 1) {
                if (6 == board[idx + MAP_WIDTH]) {
                    down = true;
                }
            }
            int yy = 8;
            int xx = 0;
            if (left) {
                xx = xx + 4;
            }
            if (right) {
                yy = yy + 1;
            }
            if (up) {
                xx = xx + 1;
            }
            if (down) {
                xx = xx + 2;
            }
            board2[idx] = yy * 8 + xx;
        }
    }
	
    for (int i = 0; i < MAP_SZ; i++) {
        board[i] = board2[i];
    }
	
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            if (xi < MAP_WIDTH - 1 && xi > 0) {
                if (77 == board[idx - 1] && 77 == board[idx] && 77 == board[idx + 1] && rnd() < 0.80) {
                    board[idx] = 76;
                }
                if (78 == board[idx - 1] && 78 == board[idx] && 78 == board[idx + 1] && rnd() < 0.80) {
                    board[idx] = 76;
                }
            }
            if (yi < MAP_HEIGHT - 1 && yi > 0) {
                if (71 == board[idx - MAP_WIDTH] && 71 == board[idx] && 71 == board[idx + MAP_WIDTH] && rnd() < 0.80) {
                    board[idx] = 67;
                }
                if (75 == board[idx - MAP_WIDTH] && 75 == board[idx] && 75 == board[idx + MAP_WIDTH] && rnd() < 0.80) {
                    board[idx] = 67;
                }
            }
        }
    }
	
    for (int i = 0; i < MAP_SZ; i++) {
        if (1 == board[i]) {
            dist[i] = 0;
        }
        else if (- 1 != board[i]) {
            dist[i] = - 2;
        }
    }
	
    float mindist = 9999999;
    for (int yi = 0; yi < 13; yi++) {
        for (int xi = 0; xi < 13; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            if (- 1 != board[idx]) {
                continue;
            }
            float d = (float)math::sqrt((double)(xi * xi + yi * yi));
            if (d < mindist) {
                mindist = d;
                start_idx = idx;
            }
        }
    }
	
    win_idx = phoenix_loc + 1 + 2 * MAP_WIDTH;
    dist[start_idx] = 1;
    dist2 = dist;
    int cc;
    while (true) {
        keep_going = false;
		for (int i = 0; i < MAP_SZ; i++) {
			update_dist(i);
		}
        
		dist = dist2;
        if (!keep_going) {
            break;
        }
		
        cc = cc + 1;
        if (cc > 1000) {
            return false;
        }
    }
	
    x = phoenix_loc % MAP_WIDTH;
    y = ( phoenix_loc - x ) / MAP_WIDTH;
    for (int yy = 0; yy < 3; yy++) {
        for (int xx = 0; xx < 3; xx++) {
            if (1 == xx && 2 == yy) {
                continue;
            }
            int idx = ( y + yy ) * MAP_WIDTH + x + xx;
            board[idx] = 4;
        }
    }
	
    int key0;
    int key1;
    int key2;
    int maxdist = - 1;
    for (int yi = 0; yi < 18; yi++) {
        for (int xi = 0; xi < 25; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            int d = dist[idx];
            if (d > maxdist) {
                maxdist = d;
                key0 = idx;
                taken[idx] = true;
            }
        }
    }
	
    x = key0 % MAP_WIDTH;
    y = ( key0 - x ) / MAP_WIDTH;
    item_new(x, y, 6 * 8 + 7, rl::GOLD, false, "Key", KEY);
    maxdist = - 1;
    for (int yi = 0; yi < 18; yi++) {
        for (int xi = 0; xi < 50; xi++) {
            int idx = ( 18 + yi ) * MAP_WIDTH + xi;
            int d = dist[idx];
            if (d > maxdist) {
                maxdist = d;
                key1 = idx;
                taken[idx] = true;
            }
        }
    }
	
    x = key1 % MAP_WIDTH;
    y = ( key1 - x ) / MAP_WIDTH;
    item_new(x, y, 6 * 8 + 7, rl::GOLD, false, "Key", KEY);
    maxdist = - 1;
    for (int yi = 0; yi < 18; yi++) {
        for (int xi = 0; xi < 50; xi++) {
            int idx = yi * MAP_WIDTH + xi + 25;
            int d = dist[idx];
            if (d > maxdist) {
                maxdist = d;
                key2 = idx;
                taken[idx] = true;
            }
        }
    }
	
    x = key2 % MAP_WIDTH;
    y = ( key2 - x ) / MAP_WIDTH;
    item_new(x, y, 6 * 8 + 7, rl::GOLD, false, "Key", KEY);
    maxdist = - 1;
    for (int i = 0; i < MAP_SZ; i++) {
        int d = dist[i];
        if (d > maxdist) {
            maxdist = d;
        }
    }
	
    int arm0;
    int arm1;
    int arm2;
    int leg0;
    int leg1;
    int leg2;
    int rod0;
    int heart0;
    int heart1;
    int heart2;
    int[6] potions;
    int[2] mana;
    Vec2i v;
	
    for (int yy = 0; yy < 2; yy++) {
        for (int xx = 0; xx < 3; xx++) {
            int mx = 1;
            if (0 < xx) {
                mx = mx + 1;
                if (0 == yy) {
                    mx = mx + 1;
                }
            }
            if (1 < xx) {
                mx = mx + 1;
            }
            for (int k = 0; k < mx; k++) {
                int c = 0;
                while (true) {
                    c = c + 1;
                    if (1000 == c) {
                        break;
                    }
                    v.x = util_rand_range(1, 25) + xx * 25;
                    v.y = util_rand_range(1, 18) + yy * 18;
                    int idx = v.y * MAP_WIDTH + v.x;
                    if (- 1 == board[idx] && !taken[idx]) {
                        bool pass = true;
                        for (int yi = 0; yi < 3; yi++) {
                            for (int xi = 0; xi < 3; xi++) {
                                int idx0 = idx + ( yi - 1 ) * MAP_WIDTH + xi - 1;
                                if (- 1 != board[idx0] || taken[idx0]) {
                                    pass = false;
                                    break;
                                }
                            }
                            if (!pass) {
                                break;
                            }
                        }
                        if (pass) {
                            taken[idx] = true;
							torches[num_torches] = v;
							num_torches += 1;
                            break;
                        }
                    }
                }
            }
        }
    }
	
    while (true) {
        x = util_rand_range(0, 25);
        y = util_rand_range(0, 18);
        if (0 == heart0) {
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                heart0 = idx;
                item_new(x, y, 6 * 8 + 1, rl::RED, false, "Heart Container", HEART);
                taken[idx] = true;
            }
        }
        else if (0 == heart1) {
            x = x + 25;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                heart1 = idx;
                item_new(x, y, 6 * 8 + 1, rl::RED, false, "Heart Container", HEART);
                taken[idx] = true;
            }
        }
        else if (0 == heart2) {
            x = x + 50;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                heart2 = idx;
                item_new(x, y, 6 * 8 + 1, rl::RED, false, "Heart Container", HEART);
                taken[idx] = true;
            }
        }
        else if (0 == arm0) {
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                arm0 = idx;
                item_new(x, y, 5 * 8 + 0, rl::VIOLET, false, "Shield", ARM_SHIELD);
                taken[idx] = true;
            }
        }
        else if (0 == arm1) {
            x = x + 25;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                arm1 = idx;
                item_new(x, y, 5 * 8 + 1, rl::VIOLET, false, "Helmet", ARM_HELMET);
                taken[idx] = true;
            }
        }
        else if (0 == arm2) {
            x = x + 50;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                arm2 = idx;
                item_new(x, y, 5 * 8 + 2, rl::VIOLET, false, "Mail", ARM_MAIL);
                taken[idx] = true;
            }
        }
        else if (0 == rod0) {
            x = x + 25;
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                rod0 = idx;
                item_new(x, y, 6 * 8 + 2, rl::GREEN, false, "Rod", ROD);
                taken[idx] = true;
            }
        }
        else if (0 == leg0) {
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                leg0 = idx;
                item_new(x, y, 5 * 8 + 3, rl::BROWN, false, "Food", TURKEY_LEG);
                taken[idx] = true;
            }
        }
        else if (0 == leg1) {
            x = x + 25;
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                leg1 = idx;
                item_new(x, y, 5 * 8 + 3, rl::BROWN, false, "Food", TURKEY_LEG);
                taken[idx] = true;
            }
        }
        else if (0 == leg2) {
            x = x + 50;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                leg2 = idx;
                item_new(x, y, 5 * 8 + 3, rl::BROWN, false, "Food", TURKEY_LEG);
                taken[idx] = true;
            }
        }
        else if (1 > potions[0]) {
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[0] = potions[0] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (2 > potions[1]) {
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[1] = potions[1] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (2 > potions[2]) {
            x = x + 25;
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[2] = potions[2] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (2 > potions[3]) {
            x = x + 25;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[3] = potions[3] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (2 > potions[4]) {
            x = x + 50;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[4] = potions[4] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (1 > potions[5]) {
            x = x + 50;
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                potions[5] = potions[5] + 1;
                item_new(x, y, 6 * 8 + 3, rl::RED, false, "Health Potion", POTION_HEALTH);
                taken[idx] = true;
            }
        }
        else if (2 > mana[0]) {
            y = y + 18;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                mana[0] = mana[0] + 1;
                item_new(x, y, 6 * 8 + 4, rl::GREEN, false, "Mana Potion", POTION_MANA);
                taken[idx] = true;
            }
        }
        else if (2 > mana[1]) {
            x = x + 25;
            int idx = y * MAP_WIDTH + x;
            if (- 1 == board[idx] && !taken[idx]) {
                mana[1] = mana[1] + 1;
                item_new(x, y, 6 * 8 + 4, rl::GREEN, false, "Mana Potion", POTION_MANA);
                taken[idx] = true;
            }
        }
        else {
            break;
        }
    }
	
    int px = start_idx % MAP_WIDTH;
    int py = ( start_idx - px ) / MAP_WIDTH;
    entity_new(px, py, 0, 10, 1, 1, 1, false);
    entities[0].mana = 5;
    entities[0].max_mana = entities[0].mana;
	
    for (int i = 0; i < 75; i++) {
        int c = 0;
        while (true) {
            c = c + 1;
            if (1000 == c) {
                break;
            }
            x = util_rand_range(0, MAP_WIDTH);
            y = util_rand_range(0, MAP_HEIGHT);
            int dx = x - px;
            int dy = y - py;
            float dist = (float)math::sqrt((double)(dx * dx + dy * dy));
            if (dist < 8) {
                continue;
            }
            if (dist < 15 && rnd() < 0.50) {
                continue;
            }
            if (x < 25 && rnd() < 0.30) {
                continue;
            }
            if (x < 50 && rnd() < 0.30) {
                continue;
            }
            int idx = y * MAP_WIDTH + x;
            if (- 1 != board[idx] || taken[idx]) {
                continue;
            }
            taken[idx] = true;
            int lvl = (int)( dist / (float)MAP_WIDTH ) * 4 + util_rand_range(0, 3);
            entity_spawn_monster(x, y, lvl);
            break;
        }
    }
	
    rl::beginTextureMode(ground_tex);
    rl::clearBackground(rl::BLACK);
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            int t = board[idx];
            if (0 > t) {
                continue;
            }
            int tx = t % 8;
            int ty = ( t - tx ) / 8;
            int r = 96;
            int g = 96;
            int b = 96;
            if (3 == t) {
                r = 64;
                g = 48;
                b = 32;
            }
            else if (1 == t) {
                r = 192;
                g = 127;
                b = 32;
            }
            if (xi < 26 && yi < 19) {
                r = 0;
            }
            if (xi > 49) {
                r = (int)((double)r * 1.20);
                g = (int)((double)g * 1.20);
                b = (int)((double)b * 1.20);
                if (yi > 18) {
                    r = 230;
					g = 230;
					b = 230;
                }
            }
            myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)xi * 8, (float)yi * 8, 8, 8, 0, 0, 0, r / 3, g / 3, b / 3, 255);
        }
    }
    rl::endTextureMode();
	
    rl::beginTextureMode(ceiling_tex);
    rl::clearBackground(rl::BLANK);
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int idx = yi * MAP_WIDTH + xi;
            int t = board3[idx];
            if (0 > t) {
                continue;
            }
            int tx = t % 8;
            int ty = ( t - tx ) / 8;
            int r = 96 / 3;
            int g = 64 / 3;
            int b = 127 / 3;
            if (xi < 26 && yi < 19) {
                g = 127 / 3;
                b = 96 / 3;
                r = 64 / 3;
                tx = 6 + ( xi + yi ) % 2;
                ty = ( xi + yi ) % 2;
            }
            if (xi > 49) {
                r = (int)((float)r * 0.30);
            }
            myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)xi * 8 + 4, (float)yi * 8 + 2, 8, 8, 0, 0, 0, r, g, b, 255);
        }
    }
    rl::endTextureMode();
	
    rl::beginTextureMode(pre_game_tex);
    rl::clearBackground(rl::BLANK);
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            int r = (int)(255.0 * ( (double)yi / (double)MAP_HEIGHT ) * 0.10);
            int b = (int)(255.0 * ( 1 - (double)yi / (double)MAP_HEIGHT ) * 0.30);
            int g = (int)((float)b * 0.70);
            myDrawTextureProRGBA(icons, 5 * 8, 8, 8, 8, (float)xi * 8, (float)yi * 8, 8, 8, 0, 0, 0, r, g, b, 255);
        }
    }
    rl::endTextureMode();
	
    return true;
}

fn void update_dist(int idx) {
    if (- 1 != dist[idx]) {
        return ;
    }
    int x = idx % MAP_WIDTH;
    int y = ( idx - x ) / MAP_WIDTH;
    if (x < 1 || y < 1 || x > MAP_WIDTH - 2 || y > MAP_HEIGHT - 2) {
        return ;
    }
    int up = dist[idx - MAP_WIDTH];
    int down = dist[idx + MAP_WIDTH];
    int left = dist[idx - 1];
    int right = dist[idx + 1];
    int d = max(max(max(up, down), left), right);
    if (d > - 1) {
        dist2[idx] = d + 1;
    }
    keep_going = true;
}

fn bool check_room_plot(int x, int y, int w, int h) {
    if (0 > x || 0 > y) {
        return false;
    }
    if (MAP_WIDTH - 1 < x + w || MAP_HEIGHT - 1 < y + h) {
        return false;
    }
    for (int yy = 0; yy < h; yy++) {
        for (int xx = 0; xx < w; xx++) {
            int i = ( yy + y ) * MAP_WIDTH + xx + x;
            if (- 1 != board[i]) {
                return false;
            }
        }
    }
    return true;
}

fn void gen_room_plot(int x, int y, int w, int h) {
    for (int yy = 0; yy < h; yy++) {
        for (int xx = 0; xx < w; xx++) {
            int i = ( yy + y ) * MAP_WIDTH + xx + x;
            if (0 == yy || 0 == xx) {
                board[i] = 6;
            }
            else {
                board[i] = 4;
            }
        }
    }
    Room_s room;
    room.x = x;
    room.y = y;
    room.w = w;
    room.h = h;
    room.cx = (int)(math::ceil((double)(x + w / 2)));
    room.cy = (int)(math::ceil((double)(y + h / 2)));
	rooms[num_rooms] = room;
	num_rooms += 1;
}

fn void gen_hallway(int r0_in, int r1_in) {
    int r0 = r0_in;
    int r1 = r1_in;
    if (rooms[r1].cy < rooms[r0].cy) {
        int temp = r0;
        r0 = r1;
        r1 = temp;
    }
    int y0 = rooms[r0].cy;
    int y1 = rooms[r1].cy;
    if (rooms[r0].cx < rooms[r1].x) {
        int x0 = rooms[r0].cx;
        int x1 = rooms[r1].cx;
        if (rnd() < 0.50) {
            for (int x = x0; x < x1 + 1; x++) {
                int idx = y0 * MAP_WIDTH + x;
                board[idx] = 4;
            }
            for (int y = y0; y < y1 + 1; y++) {
                int idx = y * MAP_WIDTH + x1;
                board[idx] = 4;
            }
        }
        else {
            for (int y = y0; y < y1 + 1; y++) {
                int idx = y * MAP_WIDTH + x0;
                board[idx] = 4;
            }
            for (int x = x0; x < x1 + 1; x++) {
                int idx = y1 * MAP_WIDTH + x;
                board[idx] = 4;
            }
        }
    }
    else {
        int x0 = rooms[r1].cx;
        int x1 = rooms[r0].cx;
        if (rnd() < 0.50) {
            for (int x = x0; x < x1 + 1; x++) {
                int idx = y0 * MAP_WIDTH + x;
                board[idx] = 4;
            }
            for (int y = y0; y < y1 + 1; y++) {
                int idx = y * MAP_WIDTH + x0;
                board[idx] = 4;
            }
        }
        else {
            for (int y = y0; y < y1 + 1; y++) {
                int idx = y * MAP_WIDTH + x1;
                board[idx] = 4;
            }
            for (int x = x0; x < x1 + 1; x++) {
                int idx = y1 * MAP_WIDTH + x;
                board[idx] = 4;
            }
        }
    }
}

fn void draw_map() {
    myDrawTexturePro(ground_tex_tex, 0, 0, MAP_WIDTH * 8, - MAP_HEIGHT * 8, (float)shake_x, (float)shake_y, MAP_WIDTH * SCALE_8, MAP_HEIGHT * SCALE_8, 0, 0, 0, rl::WHITE);
	
    int x = phoenix_loc % MAP_WIDTH;
    int y = ( phoenix_loc - x ) / MAP_WIDTH;
    int frame = (int)phoenix_frame;
    if (frame > 6) {
        frame = 6;
    }
    int tx = (int)frame % 4;
    int ty = ( (int)frame - tx ) / 4;
    myDrawTexturePro(reveal, (float)tx * 24, (float)ty * 24, 24, 24, (float)(x * SCALE_8), (float)(y * SCALE_8), (float)SCALE * 24, (float)SCALE * 24, 0, 0, 0, rl::WHITE);
	
    int ix = entities[0].ix;
    int iy = entities[0].iy;
	
    int idx;
    int dx;
    int dy;
    int xx;
    int yy;
    for (int yi = 0; yi < 15; yi++) {
        for (int xi = 0; xi < 15; xi++) {
            dx = xi - 6;
            dy = yi - 6;
            if (dx * dx + dy * dy > 36) {
                continue;
            }
            xx = ix + dx;
            yy = iy + dy;
            if (xx >= 0 && xx < MAP_WIDTH && yy >= 0 && yy < MAP_HEIGHT) {
                idx = yy * MAP_WIDTH + xx;
                if (dx * dx + dy * dy < 9) {
                    known[idx] = true;
                }
                if (!seen[idx]) {
                    continue;
                }
                float mag = (float)math::sqrt((double)(dx * dx + dy * dy)) / 6;
                if (mag > 1) {
                    mag = 1;
                }
                mag = 1 - mag;
				
                int t0 = board[idx];
                if (4 == t0) {
                    continue;
                }
                if (0 < t0) {
                    tx = t0 % 8;
                    ty = ( t0 - tx ) / 8;
                    int r = 96;
                    int g = 96;
                    int b = 96;
                    if (3 == t0) {
                        r = 64;
                        g = 48;
                        b = 32;
                    }
                    else if (1 == t0) {
                        r = 192;
                        g = 127;
                        b = 32;
                    }
                    r = min(255, 64 + r);
                    g = min(255, 32 + g);
                    if (xx < 26 && yy < 19) {
                        r = 0;
                    }
                    if (xx > 49) {
                        r = (int)((float)r * 1.20);
                        g = (int)((float)g * 1.20);
                        b = (int)((float)b * 1.20);
                        if (yy > 18) {
                            r = 242;
							g = 242;
							b = 242;
                        }
                    }
                    float rr = 0.33 + 0.66 * mag;
                    r = (int)((float)r * rr);
                    g = (int)((float)g * rr);
                    b = (int)((float)b * rr);
                    myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(xx * SCALE_8) + (float)shake_x, (float)(yy * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, r, g, b, 255);
                }
            }
        }
    }
	
    for (int i = 0; i < num_torches; i++) {
        ix = torches[i].x;
        iy = torches[i].y;
        int ofs = (int)(( t_flames * 12 + i )) % 6;
		
        for (int yi = 0; yi < 7; yi++) {
            for (int xi = 0; xi < 7; xi++) {
                dx = xi - 3;
                dy = yi - 3;
                int delta = dx * dx + dy * dy;
                xx = ix + dx;
                yy = iy + dy;
                if (xx > - 1 && yy > - 1 && xx < MAP_WIDTH && yy < MAP_HEIGHT) {
                    idx = yy * MAP_WIDTH + xx;
                    if (!seen[idx]) {
                        continue;
                    }
                    int t = board[idx];
                    if (0 > t || 4 == t) {
                        continue;
                    }
                    tx = t % 8;
                    ty = ( t - tx ) / 8;
                    float ratio = 1 - (float)math::sqrt((double)(delta)) / 3;
                    if (ratio > 1) {
                        ratio = 1;
                    }
                    if (ratio < 0) {
                        ratio = 0;
                    }
                    int r = 255;
                    int g = (int)( 128.0 + rnd() * 127.0 );
                    myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(xx * SCALE_8) + (float)shake_x, (float)(yy * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, r, g, 0, (int)(ratio * 255.0));
                }
            }
        }
    }
	
    myDrawTexturePro(ceiling_tex_tex, 0, 0, (float)(MAP_WIDTH * 8), (float)(-MAP_HEIGHT * 8), (float)shake_x, (float)shake_y, (float)(MAP_WIDTH * SCALE_8), (float)(MAP_HEIGHT * SCALE_8), 0, 0, 0, rl::WHITE);
	
    idx = 0;
    dx = 0;
    dy = 0;
    xx = 0;
    yy = 0;
    for (int yi = 0; yi < 15; yi++) {
        for (int xi = 0; xi < 15; xi++) {
            dx = xi - 6;
            dy = yi - 6;
            if (dx * dx + dy * dy > 36) {
                continue;
            }
            xx = ix + dx;
            yy = iy + dy;
            if (xx >= 0 && xx < MAP_WIDTH && yy >= 0 && yy < MAP_HEIGHT) {
			
                idx = yy * MAP_WIDTH + xx;
                if (!seen[idx]) {
                    continue;
                }
				
                float mag = (float)math::sqrt((double)(dx * dx + dy * dy)) / 6;
                if (mag > 1) {
                    mag = 1;
                }
                mag = 1 - mag;
				
                int t3 = board3[idx];
                if (0 < t3) {
                    tx = t3 % 8;
                    ty = ( t3 - tx ) / 8;
                    int r = 127;
                    int g = 64;
                    int b = 96;
                    if (xx < 26 && yy < 19) {
                        g = 127;
                        b = 96;
                        r = 64;
                        tx = 6 + ( xx + yy ) % 2;
                        ty = ( xx + yy ) % 2;
                    }
                    if (xx > 49) {
                        r = (int)((float)r * 0.30);
                    }
                    float rr = 0.33 + 0.66 * mag;
                    r = (int)((float)r * rr);
                    g = (int)((float)g * rr);
                    b = (int)((float)b * rr);
                    myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(xx * SCALE_8 + 4 * SCALE) + (float)shake_x, (float)(yy * SCALE_8 + 2 * SCALE) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, r, g, b, 255);
                }
            }
        }
    }
	
    for (int yi = 0; yi < MAP_HEIGHT; yi++) {
        for (int xi = 0; xi < MAP_WIDTH; xi++) {
            idx = yi * MAP_WIDTH + xi;
            if (!seen[idx]) {
                tx = 5;
                ty = 1;
                int r = 127;
                int g = 64;
                int b = 96;
                if (xi < 26 && yi < 19) {
                    g = 127;
                    b = 96;
                    r = 64;
                    tx = 6 + ( xi + yi ) % 2;
                    ty = ( xi + yi ) % 2;
                }
                if (xi > 49) {
                    r = (int)((float)r * 0.40 * 1.50);
                    b = (int)((float)b * 1.30 * 1.20);
                }
                if (!known[idx]) {
                    r = 96;
                    g = 96;
                    b = 96;
                    tx = 3;
                    ty = 0;
                }
                myDrawTextureProRGBA(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(xi * SCALE_8 + 4 * SCALE) + (float)shake_x, (float)(yi * SCALE_8 + 2 * SCALE) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, r / 3, g / 3, b / 3, 255);
            }
        }
    }
	
    if (intro_hold) {
        myDrawTexturePro(pre_game_tex_tex, 0, 0, (float)(MAP_WIDTH * 8), (float)(-MAP_HEIGHT * 8), (float)shake_x, (float)shake_y, MAP_WIDTH * SCALE_8, MAP_HEIGHT * SCALE_8, 0, 0, 0, rl::WHITE);
    }
}

fn void map_update_visibility() {

    float px = (float)entities[0].ix;
    float py = (float)entities[0].iy;
    float rx;
    float ry;
    float w = 0.30;
	
    for (int i = 0; i < 45; i++) {
        float an = (float)i * 8.0 * 3.14159326 / 180.0;
        float dx = math::cos(an);
        float dy = math::sin(an);
		
        for (int jj = 0; jj < 20; jj++) {
            float j = 0.50 + 0.35 * (float)jj;
            rx = px + dx * j;
            ry = py + dy * j;
            int x0 = (int)(rx - w);
            int y0 = (int)(ry - w);
            int x1 = (int)(rx - w);
            int y1 = (int)(ry + w);
            int x2 = (int)(rx + w);
            int y2 = (int)(ry + w);
            int x3 = (int)(rx + w);
            int y3 = (int)(ry - w);
            int c = 0;
			
            if (x0 > - 1 && y0 > - 1 && x0 < MAP_WIDTH && y0 < MAP_HEIGHT) {
                int idx = y0 * MAP_WIDTH + x0;
                if (- 1 == board[idx]) {
                    c = c + 1;
                }
            }
            if (x1 > - 1 && y1 > - 1 && x1 < MAP_WIDTH && y1 < MAP_HEIGHT) {
                int idx = y1 * MAP_WIDTH + x1;
                if (- 1 == board[idx]) {
                    c = c + 1;
                }
            }
            if (x2 > - 1 && y2 > - 1 && x2 < MAP_WIDTH && y2 < MAP_HEIGHT) {
                int idx = y2 * MAP_WIDTH + x2;
                if (- 1 == board[idx]) {
                    c = c + 1;
                }
            }
            if (x3 > - 1 && y3 > - 1 && x3 < MAP_WIDTH && y3 < MAP_HEIGHT) {
                int idx = y3 * MAP_WIDTH + x3;
                if (- 1 == board[idx]) {
                    c = c + 1;
                }
            }
            int ix = (int)rx;
            int iy = (int)ry;
            int idx = iy * MAP_WIDTH + ix;
            seen[idx] = true;
            if (0 == c) {
                break;
            }
        }
    }
}

fn void item_new(int x, int y, int sprite, rl::Color color, bool block_movement, String name, Enums kind) {
    Item_s i;
    i.ix = x;
    i.iy = y;
    i.sprite = sprite;
    i.color = color;
    i.block_movement = block_movement;
    i.name = name;
    i.found = false;
    i.kind = kind;
    i.skip_update = - 1;
	loot[num_loot] = i;
	num_loot += 1;
}

fn void item_draw_all() {

    for (int i = 0; i < num_loot; i++) {
        if (loot[i].found) {
            continue;
        }
		
        int sprite = loot[i].sprite;
        int tx = sprite % 8;
        int ty = ( sprite - tx ) / 8;
        int x = loot[i].ix;
        int y = loot[i].iy;
        if (!seen[y * MAP_WIDTH + x]) {
            continue;
        }
		
        float dx = entities[0].px - x;
        float dy = entities[0].py - y;
        float dist = (float)math::sqrt((double)(dx * dx + dy * dy));
		
        if (dist < 7.00) {
            if (dist < 5.00) {
                myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(x * SCALE_8) + (float)shake_x, (float)(y * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, loot[i].color);
            }
            else {
                myDrawTexturePro(icons, (float)tx * 8, (float)ty * 8, 8, 8, (float)(x * SCALE_8) + (float)shake_x, (float)(y * SCALE_8) + (float)shake_y, (float)SCALE_8, (float)SCALE_8, 0, 0, 0, DARKDARKGRAY);
            }
        }
		
        if (x == entities[0].ix && y == entities[0].iy) {
            String found_text = string::tformat("Found %s!", loot[i].name);
            if (POTION_HEALTH == loot[i].kind) {
                if (9 == inventory[0]) {
                    continue;
                }
                inventory[0] = inventory[0] + 1;
                add_note(found_text, rl::RED, 5.00);
            }
            else if (POTION_MANA == loot[i].kind) {
                if (9 == inventory[0]) {
                    continue;
                }
                inventory[1] = inventory[1] + 1;
                add_note(found_text, rl::GREEN, 5.00);
            }
            else if (TURKEY_LEG == loot[i].kind) {
                entities[0].power = entities[0].power + 1;
                add_note(found_text, rl::ORANGE, 5.00);
            }
            else if (ARM_SHIELD == loot[i].kind) {
                entities[0].defense = entities[0].defense + 1;
                found_shield = true;
                add_note(found_text, rl::VIOLET, 5.00);
            }
            else if (ARM_MAIL == loot[i].kind) {
                entities[0].defense = entities[0].defense + 1;
                found_mail = true;
                add_note(found_text, rl::VIOLET, 5.00);
            }
            else if (ARM_HELMET == loot[i].kind) {
                entities[0].defense = entities[0].defense + 1;
                found_helmet = true;
                add_note(found_text, rl::VIOLET, 5.00);
            }
            else if (KEY == loot[i].kind) {
                found_key = true;
                add_note(found_text, rl::GOLD, 5.00);
            }
            if (ROD == loot[i].kind) {
                found_rod = true;
                add_note(found_text, rl::GREEN, 5.00);
                rl::playSound(snd_cast);
            }
            else if (HEART == loot[i].kind) {
                note.txt = "LEVEL UP!";
                note.color = rl::PURPLE;
                note.timer = 5.00;
                entities[0].level = entities[0].level + 1;
                entities[0].max_health = (int)((float)entities[0].max_health * ( 1.30 + 0.30 * (float)rnd() ));
                entities[0].max_mana = entities[0].max_mana + 1;
                entities[0].health = entities[0].max_health;
                entities[0].mana = entities[0].max_mana;
                rl::playSound(snd_levelup);
            }
            else {
                rl::playSound(snd_pickup);
            }
            loot[i].found = true;
        }
    }
}

fn void get_player_input() {
    Enums move_dir = INVALID;
	
    if (rl::isKeyDown(rl::KEY_ESCAPE)) {
        quit_game = true;
    }
	
    if (0 >= entities[0].health) {
        add_note("YOU DIED!", rl::RED, 5.00);
        entities[0].block_movement = false;
        entities[0].sprite = 47;
        return ;
    }
	
    int idx = entities[0].iy * MAP_WIDTH + entities[0].ix;
	
	key_delay = key_delay - 1;
	
    if (0 > key_delay && intro_hold) {
        if (rl::isKeyPressed(rl::KEY_SPACE)) {
            key_delay = 5;
            if (INTRO == menu) {
                menu = CONTROLS;
            }
            else if (CONTROLS == menu) {
                menu = GAME;
                intro_hold = false;
                rl::stopSound(snd_melody);
            }
            rl::playSound(snd_hurt);
        }
        return ;
    }
	
    if (0 > key_delay && game_win && WIN == menu) {
        if (rl::isKeyPressed(rl::KEY_SPACE)) {
            quit_game = true;
        }
        return ;
    }
	
    if (!game_win && !screen_shake) {
        if (rl::isKeyDown(rl::KEY_UP)) {
            move_dir = MOVE_UP;
        }
        if (rl::isKeyDown(rl::KEY_DOWN)) {
            move_dir = MOVE_DOWN;
        }
        if (rl::isKeyDown(rl::KEY_LEFT)) {
            move_dir = MOVE_LEFT;
        }
        if (rl::isKeyDown(rl::KEY_RIGHT)) {
            move_dir = MOVE_RIGHT;
        }
		
        if (0 > key_delay && found_rod && rl::isKeyDown(rl::KEY_C) && 0 < entities[0].mana && 0 > entities[0].cooldown) {
            float px = entities[0].px;
            float py = entities[0].py;
            float vx;
            float vy;
            float speed = 8;
            if (MOVE_UP == last_move) {
                vy = - 1;
            }
            else if (MOVE_DOWN == last_move) {
                vy = 1;
            }
            else if (MOVE_LEFT == last_move) {
                vx = - 1;
            }
            else if (MOVE_RIGHT == last_move) {
                vx = 1;
            }
            vx = vx * speed;
            vy = vy * speed;
            key_delay = 5;
            entities[0].cooldown = 1.00;
            magic_ball.px = px;
            magic_ball.py = py;
            magic_ball.vx = vx;
            magic_ball.vy = vy;
            magic_ball.active = true;
            entities[0].mana = entities[0].mana - 1;
            rl::playSound(snd_cast);
        }
		
        if (0 > key_delay && 0 < inventory[0] && entities[0].health < entities[0].max_health && rl::isKeyDown(rl::KEY_H)) {
            inventory[0] = inventory[0] - 1;
            entities[0].health = entities[0].max_health;
            key_delay = 5;
            rl::playSound(snd_potion);
        }
		
        if (0 > key_delay && 0 < inventory[1] && entities[0].mana < entities[0].max_mana && rl::isKeyDown(rl::KEY_M)) {
            inventory[1] = inventory[1] - 1;
            entities[0].mana = entities[0].max_mana;
            key_delay = 5;
            rl::playSound(snd_potion);
        }
    }
	
    if (0 > key_delay) {
        if (INVALID != move_dir) {
            last_move = move_dir;
            entity_move(0, move_dir);
            key_delay = 4;
            map_update_visibility();
        }
    }
	
    int kx = entities[0].kx;
    int ky = entities[0].ky;
    if (kx < 0) {
        entities[0].kx = kx + 1;
    }
    if (kx > 0) {
        entities[0].kx = kx - 1;
    }
    if (ky < 0) {
        entities[0].ky = ky + 1;
    }
    if (ky > 0) {
        entities[0].ky = ky - 1;
    }
}


//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------

const String VERSION = "v1.0.0";
const int SCALE = 3;
const int XRES = 600;
const int XRES_HALF = XRES / 2;
const int YRES = 320;
const int YRES_HALF = YRES / 2;
const int SCALE_8 = SCALE * 8;
const int DIR_UP = 0;
const int DIR_DOWN = 1;
const int DIR_LEFT = 2;
const int DIR_RIGHT = 3;
const int MAP_WIDTH = 75;
const int MAP_HEIGHT = 36;
const int MAP_SZ = 3000;

const rl::Color SHARKGRAY = { 34, 32, 39, 255 };
const rl::Color DARKDARKGRAY = { 20, 20, 20, 255 };
const rl::Color DARKRED = { 128, 20, 25, 255 };
const rl::Color BITTERSWEET = { 254, 111, 94, 255 };
const rl::Color CYAN = { 0, 224, 224, 255 };

bool quit_game;
bool game_win;
int amort;
Enums last_move = MOVE_UP;

// textures
rl::Texture icons;
rl::Texture reveal;
rl::Texture gradient;
rl::Font fnt;
rl::Font fnt_sm;

rl::RenderTexture2D ceiling_tex;
rl::Texture ceiling_tex_tex;
rl::RenderTexture2D ground_tex;
rl::Texture ground_tex_tex;
rl::RenderTexture2D pre_game_tex;
rl::Texture pre_game_tex_tex;


// notifications
Notification note;

// sounds
rl::Sound snd_blip;
rl::Sound snd_hurt;
rl::Sound snd_attack;
rl::Sound snd_pickup;
rl::Sound snd_potion;
rl::Sound snd_ambient_1;
rl::Sound snd_ambient_2;
rl::Sound snd_ambient_3;
rl::Sound snd_cast;
rl::Sound snd_dead;
rl::Sound snd_door;
rl::Sound snd_levelup;
rl::Sound snd_shake;
rl::Sound snd_melody;


float blip_timer;
float ambient_timer;
bool screen_shake;
bool shake_sound_played;
double t_shake_move;
double t_shake_timer = 5;
float shake_x;
float shake_y;
double phoenix_frame;
double t_clock;
double t_game;
bool intro_hold = true;
Enums menu = INTRO;
double t_win;

Entity_s[100] entities;
int num_entities = 0;

rl::Color[6] flame = { rl::YELLOW, rl::ORANGE, rl::WHITE, rl::RED, rl::ORANGE, rl::WHITE };
rl::Color[5] magic = { rl::GREEN, rl::DARKGREEN, rl::YELLOW, rl::GREEN, rl::DARKGREEN };

Vec2i[25] torches;
int num_torches = 0;
double t_flames;

Projectile_s magic_ball;

// map data
int[MAP_SZ] board;
int[MAP_SZ] board2;
int[MAP_SZ] board3;
int[MAP_SZ] dist;
int[MAP_SZ] dist2;
bool[MAP_SZ] seen;
bool[MAP_SZ] known;

// rooms
Room_s[100] rooms;
int num_rooms = 0;

bool keep_going;
int start_idx;
int win_idx;

// inventory and loot
Item_s[100] loot;
int num_loot = 0;

int[2] inventory = { 1, 1 };
bool found_helmet;
bool found_mail;
bool found_shield;
bool found_key;
bool found_rod;
bool found_tears;

int phoenix_loc;
int key_delay;


//-----------------------------------------------------------------------------
// Entry Point
//-----------------------------------------------------------------------------

fn void main() {
    rl::initWindow(XRES * SCALE, YRES * SCALE, string::tformat_zstr("Dungeon of the Phoenix %s - by Syn9", VERSION));
    rl::setExitKey(rl::KEY_NULL);
    rl::initAudioDevice();
    rl::setTargetFPS(60);
    rl::beginDrawing();
    rl::clearBackground(SHARKGRAY);
    rl::endDrawing();
	
	icons = rl::loadTexture("assets/icons.png");
    reveal = rl::loadTexture("assets/reveal.png");
    gradient = rl::loadTexture("assets/gradient.png");
    fnt = rl::loadFont("assets/alagard.fnt");
    fnt_sm = rl::loadFont("assets/font.png");
    
	snd_blip = rl::loadSound("assets/sounds/blip.ogg");
    snd_hurt = rl::loadSound("assets/sounds/hurt.ogg");
    snd_attack = rl::loadSound("assets/sounds/attack.ogg");
    snd_pickup = rl::loadSound("assets/sounds/pickup.ogg");
    snd_potion = rl::loadSound("assets/sounds/potion.ogg");
    snd_ambient_1 = rl::loadSound("assets/sounds/ambient-1.ogg");
    snd_ambient_2 = rl::loadSound("assets/sounds/ambient-2.ogg");
    snd_ambient_3 = rl::loadSound("assets/sounds/ambient-3.ogg");
    snd_cast = rl::loadSound("assets/sounds/cast.ogg");
    snd_dead = rl::loadSound("assets/sounds/dead.ogg");
    snd_door = rl::loadSound("assets/sounds/door.ogg");
    snd_levelup = rl::loadSound("assets/sounds/levelup.ogg");
    snd_shake = rl::loadSound("assets/sounds/shake.ogg");
    snd_melody = rl::loadSound("assets/sounds/melody.ogg");
	
	ceiling_tex = rl::loadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8);
    ceiling_tex_tex = ceiling_tex.texture;
    ground_tex = rl::loadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8);
    ground_tex_tex = ground_tex.texture;
    pre_game_tex = rl::loadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8);
    pre_game_tex_tex = pre_game_tex.texture;
	
	while (true) {
        if (gen_rooms()) {
            break;
        }
    }
	
	
    map_update_visibility();
    rl::playSound(snd_melody);
	t_clock = rl::getTime();
	
    while (true) {
        rl::beginDrawing();
        rl::clearBackground(rl::BLACK);
        draw_map();
        if (!intro_hold) {
            item_draw_all();
            entity_draw_all();
        }
        ui_draw();
        rl::endDrawing();
		
        amort = ( amort + 1 ) % 4;
        get_player_input();
        entity_update_all();
		
        if (rl::windowShouldClose() || quit_game) {
            break;
        }
    }
    
	unload_sounds();
    rl::closeAudioDevice();
    rl::closeWindow();
}

