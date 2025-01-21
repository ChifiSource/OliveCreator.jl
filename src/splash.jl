function build_splash()
    creator_font = style("@font-face", "font-family" => "Condiment", "src" => "url(\"assets/Condiment.ttf\")")
    creator = img("creator", src = "assets/creator_holding_heart.png")
    creator_header = h2("creator-label", text = "creator")
    style!(creator_header, "font-family" => "\"Condiment\", serif", "font-weight" => 400, "position" => "absolute", 
    "top" => 20percent, "left" => 10percent, "font-size" => 100pt, "color" => "white", "opacity" => 0percent, "transition" => 2s)
    style!(creator, "position" => "absolute", "transition"  => 850ms, "transform" => "translateX(550%) translateY(30%)", 
    "z-index" => -9, "opacity" => 0percent)
    hearts = [begin 
                particle = img("heart-particle$count", src = "assets/heart.png")
                trans_x = 540percent
                z = string(rand(-15:-10))
                scale = rand(7:9)
                transition = rand(400:840) * ms
                trans_y = rand(10:70) * percent
                style!(particle, "position" => "absolute", "transform-origin" => "50% 50%", "transition" => transition,
                    "transform" => "translateY($(trans_y)) translateX($(trans_x)) scale(.0$scale)", 
                    "z-index" => z, "opacity" => 0percent)
                particle
    end for count in 1:30]
    splash_div = div("splash", children = [creator_header, creator, hearts ...])
    style!(splash_div, "pointer-events" => "none", "position" => "relative", "width" => 100percent, "height" => 100percent)
    scr = on(700) do cl::ClientModifier
        style!(cl, "creator", "opacity" => 100percent, "transform" => "translateX(480%) translateY(29%)")
        [begin
            trans_y = rand(-10:120) * percent
            trans_x = rand(330:490) * percent
            scale = rand(1:4)
            rotation = rand(-20:20) * deg
            style!(cl, "heart-particle$count", "opacity" => 100percent,
            "transform" => "translateY($(trans_y)) translateX($(trans_x)) scale(.0$scale) rotate($rotation)")
        end for count in 1:30]
        style!(cl, "creator-label", "opacity" => 100percent, "left" => 30percent)
        next!(cl, creator) do cl2::ClientModifier
            style!(cl2, "creator", "transform" => "translateX(480%) translateY(29%) rotate(2deg)")
        end
    end
    main = body("main", children = [creator_font, splash_div, scr])
    style!(main, "width" => 100percent, "height" => 100percent, "background-color" => "#171717")
    main
end

SPLASH = build_splash()