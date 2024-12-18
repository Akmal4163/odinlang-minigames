package minigames

import "core:fmt"
import "core:strings"
import rl"vendor:raylib"

WINDOW_SIZE :: 600
GRID_WIDTH :: 30
CELL_SIZE  :: 26
GRID_SIZE  :: GRID_WIDTH * CELL_SIZE
TICK_RATE  :: 0.17

Snake :: struct {
    body: [GRID_WIDTH * GRID_WIDTH]rl.Vector2,
    len: i32,
    move_direction: rl.Vector2
}

game_text :: struct {
    text: string,
    size: i32,
    target: rl.Vector2,
    width: f32,
}

timer: f32 = TICK_RATE
snake: Snake
food_position: rl.Vector2
game_over: bool
score: i32
high_score: i32

max :: proc (a, b: i32) -> i32 {
    if a > b {
        return a
    } else {
        return b
    }
}

restart_game :: proc () {
    head_position: rl.Vector2 = { GRID_WIDTH/2, GRID_WIDTH/2 }
    score = 0
    
    snake.body[0] = head_position
    snake.body[1] = head_position - {0, 1}
    snake.body[2] = head_position - {0, 2}
    snake.len = 3
    snake.move_direction = {0, 1}

    game_over = false
    place_food()
}

place_food :: proc () {
    food_grid: [GRID_WIDTH * GRID_WIDTH]u8

    for i in 0..<snake.len {
        food_grid[i32(snake.body[i].y * GRID_WIDTH + snake.body[i].x)] = 1
    }

    food_placement := make([dynamic]rl.Vector2); defer delete(food_placement)

    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_WIDTH {
            if food_grid[y * GRID_WIDTH + x] != 1 {
                append(&food_placement, rl.Vector2 {f32(x), f32(y)})
            } 
        }
    }

    if len(food_placement) > 0 {
        random_index := rl.GetRandomValue(0, i32(len(food_placement) - 1))
        food_position = food_placement[random_index]
    }

}


main :: proc () {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake"); defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    game_over_text := game_text {
        "Game Over!!!",
        90,
        {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2)},
        f32(rl.MeasureText("Game Over!!!", 90)),
    }

    press_restart_text := game_text {
        "Press Space to Restart",
        45,
        {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2) + 80},
        f32(rl.MeasureText("Press Space to Restart", 45)),
    }

    restart_game()

    mainloop: for !rl.WindowShouldClose() {
        if rl.IsKeyDown(.UP) {
            snake.move_direction = {0, -1}
        }

        if rl.IsKeyDown(.DOWN) {
            snake.move_direction = {0, 1}
        }

        if rl.IsKeyDown(.LEFT) {
            snake.move_direction = {-1, 0}
        }

        if rl.IsKeyDown(.RIGHT) {
            snake.move_direction = {1, 0}
        }

        if game_over {
            high_score = max(high_score, score)
            if rl.IsKeyPressed(.SPACE) {
                restart_game()
            }
        } else {
            timer -= rl.GetFrameTime()
        }

        
        if timer <= 0 {
            next_part_position := snake.body[0]
            snake.body[0] += snake.move_direction
            current_head_position := snake.body[0]

            if current_head_position.x < 0 || current_head_position.x >= GRID_WIDTH || 
            current_head_position.y < 0 || current_head_position.y >= GRID_WIDTH {
                game_over = true
            }

            for i in 1..<snake.len {
                current_position := snake.body[i]
                snake.body[i] = next_part_position
                next_part_position = current_position

                if current_head_position == snake.body[i] {
                    game_over = true
                }
            }

            if current_head_position == next_part_position {
                game_over = true
            }

            if current_head_position == food_position {
                snake.len += 1
                snake.body[snake.len - 1] = next_part_position
                score += 1
                place_food()
            }
            timer = TICK_RATE + timer
        }

        rl.BeginDrawing()
        rl.ClearBackground({20, 76, 45, 2})

        camera := rl.Camera2D {
            zoom = f32(WINDOW_SIZE) / GRID_SIZE
        }

        rl.BeginMode2D(camera)

        food_rect := rl.Rectangle {
            food_position.x*CELL_SIZE,
            food_position.y*CELL_SIZE,
            CELL_SIZE,
            CELL_SIZE,
        }

        rl.DrawRectangleRec(food_rect, rl.RED)

        for i in 0..<snake.len {
            snake_rect := rl.Rectangle {
                snake.body[i].x*CELL_SIZE,
                snake.body[i].y*CELL_SIZE,
                CELL_SIZE,
                CELL_SIZE,
            }

            rl.DrawRectangleRec(snake_rect, rl.WHITE)
        }

        score_text := game_text {
            fmt.tprintf("score: %v", score),
            50,
            {0, 0},
            f32(rl.MeasureText("score: %v", 50))
        }
    
        high_score_text := game_text {
            fmt.tprintf("high score: %v", high_score),
            36,
            {f32(rl.GetScreenWidth()/2), f32(rl.GetScreenHeight()/2) + (80 * 2)},
            f32(rl.MeasureText("high score: %v", 36))
        }

        rl.DrawText(strings.clone_to_cstring(score_text.text),
                i32(score_text.target.x),
                i32(score_text.target.y),
                score_text.size,
                rl.WHITE)

        if game_over {
            
            rl.DrawText(strings.clone_to_cstring(game_over_text.text), 
                i32((game_over_text.target.x - (game_over_text.width/2))), 
                i32(game_over_text.target.y), 
                game_over_text.size, 
                rl.BLACK)
            rl.DrawText(strings.clone_to_cstring(press_restart_text.text), 
                i32((press_restart_text.target.x - (press_restart_text.width/2))), 
                i32(press_restart_text.target.y), 
                press_restart_text.size, 
                rl.BLACK)
            rl.DrawText(strings.clone_to_cstring(high_score_text.text),
                i32(high_score_text.target.x),
                i32(high_score_text.target.y),
                high_score_text.size,
                rl.YELLOW)
        }

        rl.EndMode2D()
        rl.EndDrawing()
    }

}
