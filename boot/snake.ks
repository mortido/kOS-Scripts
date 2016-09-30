core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

clearscreen.

global xdir is 1.
global ydir is 0.
global exit is false.
global start is false.
global snake is list().
global snake_head is list().
global applex is 0.
global appley is 0.

global minx is 0.
global miny is 1.
global maxx is terminal:width - 1.
global maxy is terminal:height - 1.

on ag8 { set xdir to 0. set ydir tp -1. preserve. }
on ag6 { set xdir to 1. set ydir tp 0. preserve. }
on ag2 { set xdir to 0. set ydir tp 1. preserve. }
on ag4 { set xdir to -1. set ydir tp 0. preserve. }

on ag10 { set exit to true. }
on ag1 { set start to true. preserve. }

function draw_start_screen {
    // TODO: menu.
}

function renew_apple {
    local done is false.
    until done {
        set applex to minx + round(random() * (maxy - miny)).
        set appley to miny + round(random() * (maxy - miny)).
        
        set done to true.
        for s in snake {
            if s[0] = applex and s[1] = appley {
                set done to false.
                break.
            }
        }
    }
}

function initialize {
    snake:clear().
    
    // Add start position.
    local yy is round((maxy + miny) / 2).
    local xy is minx + 1.
    local i is 0.
    until i < 4 {
        snake:add(list(xx, yy)).
        set xx to xx + 1.
        set i to i + 1.
    }
    
    // generate first apple.
    renew_apple().
}

function update_game {
    // move snake
    local new_snake is list(snake_head[0] + xdir, snake_head[1] + ydir).
    
    if new_snake[0] = applex and new_snake[1] = appley {
        renew_apple().
    } else {
        // remove tail.
        snake:remove(0).
    }
    
    else if new_snake[0] < xmin or new_snake[0] > xmax or new_snake[1] < ymin or new_snake[1] > ymax {
        // if snake moved out of bound or into itself - game over.
        set start to false.
    }
    
    for s in snake {
        if s[0] = new_snake[0] and s[1] = new_snake[1] {
            set start to false.
            break.
        }
    }
    
    snake:add(new_snake).
}

function draw_game {
    clearscreen.
    // print score.
    local score is 0.
    for s in snake { set score to score + 1. }
    
    // print snake and apple.
    
}

function draw_game_over {
    // TODO: draw game over.
}

until exit {
    draw_start_screen().
    wait until start.
    initialize().
    until exit or not start {
        wait 1.
        update_game().
        draw_game().
    }
    draw_game_over().
    wait 10.
}