function build_splash()
    creator_font = style("@font-face", "font-family" => "Condiment", "src" => "url(\"assets/Condiment.ttf\")")
    creator = img("creator", src = "assets/creator_holding_heart.png", width = 5percent)
    creator_header = h2("creator-label", text = "creator")
    style!(creator_header, "font-weight" => 400, "position" => "absolute", 
    "top" => 20percent, "left" => 45percent, "width" => 10percent, "font-size" => 100pt, "color" => "white", "opacity" => 0percent, "transition" => 2s)
    style!(creator, "position" => "absolute", "transition"  => 850ms, 
    "z-index" => -9, "opacity" => 0percent, "top" => 10percent, "left" => 55percent)
    hearts = [begin 
                particle = img("heart-particle$count", src = "assets/heart.png")
                trans_x = 54percent
                z = string(rand(-15:-10))
                scale = rand(1:9)
                transition = rand(400:840) * ms
                trans_y = rand(10:70) * percent
                style!(particle, "position" => "absolute", "transform-origin" => "50% 50%", "transition" => transition,
                    "transform" => "scale(.00$scale)", "left" => trans_x, "top" => trans_y,
                    "z-index" => z, "opacity" => 0percent)
                particle
    end for count in 1:100]
    splash_div = div("splash", children = [creator, hearts ...])
    style!(splash_div, "pointer-events" => "none", "position" => "absolute", "width" => 100percent, "height" => 100percent)
    scr = on(700) do cl::ClientModifier
        style!(cl, "creator", "opacity" => 100percent, "transform" => "rotate(10deg)", "left" => 50percent)
        [begin
            trans_y = rand(5:80) * percent
            trans_x = rand(5:95) * percent
            scale = rand(1:4)
            rotation = rand(-20:20) * deg
            style!(cl, "heart-particle$count", "opacity" => 100percent,
            "transform" => "scale(.0$scale) rotate($rotation)", "top" => trans_y, "left" => trans_x)
        end for count in 1:100]
        next!(cl, creator) do cl2::ClientModifier
  #          style!(cl2, "creator-label", "opacity" => 100percent)
        end
    end
    main = body("main", children = [creator_font, splash_div, scr], align = "center")
    style!(main, "width" => 90percent, "height" => 100percent, "background-color" => "#171717", 
    "overflow" => "hidden")
    main
end

SPLASH = build_splash()