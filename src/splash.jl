function build_splash()
    creator = img("creator-heart", src = "assets/creator_holding_heart.png")
    style!(creator, "position" => "absolute", "transition"  => 500ms, "transform" => "translateX(550%) translateY(30%)", 
    "z-index" => -13)
    hearts = [begin 
                particle = img("heart-particle$count", src = "assets/heart.png")
                rotation = rand(1:160) * deg
                trans_x = 540percent
                z = string(rand(-15:-10))
                scale = rand(7:9)
                trans_y = rand(10:70) * percent
                style!(particle, "position" => "absolute", "transform-origin" => "50% 50%", "transition" => 500ms,
                    "transform" => "translateY($(trans_y)) translateX($(trans_x)) scale(.0$scale)", 
                    "z-index" => z)
                particle
    end for count in 1:30]
    splash_div = div("splash", children = [creator, hearts ...])
    style!(splash_div, "pointer-events" => "none", "position" => "relative", "width" => 100percent, "height" => 100percent)
    main = body("main", children = [splash_div])
    style!(main, "width" => 100percent, "height" => 100percent, "background-color" => "#171717")
    main
end

SPLASH = build_splash()