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
global score is 0.

global minx is 0.
global miny is 1.
global maxx is terminal:width - 1.
global maxy is terminal:height - 2.

on ag8 {
    if ydir <> 1 {
        set xdir to 0.
        set ydir to -1.
    }
    preserve.
}
on ag6 {
    if xdir <> -1 {
        set xdir to 1.
        set ydir to 0.
    }
    preserve.
}
on ag5 {
    if ydir <> -1 {
        set xdir to 0.
        set ydir to 1.
    }
    preserve.
}
on ag4 {
    if xdir <> 1 {
        set xdir to -1.
        set ydir to 0.
    }
    preserve.
}

on ag10 { set exit to true. }
on ag1 { set start to true. preserve. }

function draw_start_screen {
    clearscreen.
    print "           SNAKE".
    print "=============================".
    print "1 - start".
    print "0 - exit".
    print "=============================".
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
    set score to 0.
    
    // Add start position.
    local yy is round((maxy + miny) / 2).
    local xx is minx + 1.
    local i is 0.
    until i = 4 {
        snake:add(list(xx, yy)).
        set snake_head to list(xx, yy).
        set xx to xx + 1.
        set i to i + 1.
    }
    set xdir to 1.
    set ydir to 0.

    // generate first apple.
    renew_apple().
}

function update_game {
    // move snake
    local new_snake is list(snake_head[0] + xdir, snake_head[1] + ydir).
    
    if new_snake[0] = applex and new_snake[1] = appley {
        renew_apple().
        print "A" at (applex, appley).
        
        set score to score + 1.
        print score at (7, 0).
    } else {
        // remove tail.
        print "_" at (snake[0][0], snake[0][1]).
        snake:remove(0).
    } 
    
    if new_snake[0] < minx or new_snake[0] > maxx or new_snake[1] < miny or new_snake[1] > maxy {
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
    print "S" at (new_snake[0], new_snake[1]).
    set snake_head to new_snake.
}

function draw_field {

    clearscreen.
    print "SCORE: 0" at (0, 0).
    local empty_line is "".
    local xx is minx.
    until xx > maxx {
        set empty_line to empty_line + "_".
        set xx to xx + 1.
    }

    local yy is miny.
    until yy > maxy {
        print empty_line at(0, yy).
        set yy to yy + 1.
    }
    
    print "A" at (applex, appley).
    for s in snake {
        print "S" at (s[0], s[1]).
    }
}

function draw_game_over {
    clearscreen.
    print "GAME OVER" at(round(terminal:width / 2) - 5, round(terminal:height / 2)).
}

until exit {
    draw_start_screen().
    wait until start.
    initialize().
    draw_field().
    until exit or not start {
        wait 0.2.
        update_game().
    }
    draw_game_over().
    wait 5.
}