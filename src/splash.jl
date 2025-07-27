function generate_loginbox()

end

function build_splash()
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
                trans_y = rand(0:70) * percent
                style!(particle, "position" => "absolute", "transform-origin" => "50% 50%", "transition" => transition,
                    "transform" => "scale(.01$scale)", "left" => trans_x, "top" => trans_y,
                    "z-index" => z, "opacity" => 0percent)
                particle
    end for count in 1:1000]
    splash_div = div("splash", children = [creator, hearts ...])
    style!(splash_div, "pointer-events" => "none", "position" => "absolute", "width" => 100percent, "height" => 100percent)
    login_box = begin
        open_alphal = tmd("logheader", """##### welcome to our open alpha
            Due to hardware limitations, olive creator is starting small with a **closed** alpha. This project plans to eventually open its doors to the broader public.
            Thank you for understanding financial constraints during this period.
            Within the alpha period, it is still possible to browse the site as a guest *or* claim a key to access the closed alpha.""")
        login_button = button("loginb", text = "login")
        on(Olive.SES, "clicklogin") do cm::ComponentModifier
            remove!(cm, "logheader")
            login_box = generate_loginbox()

        end
        on(Olive.SES, "confirmlogin") do cm::ComponentModifier

        end
        get_key_button = button("getkeyb", text = "get your alpha key")
        on(Olive.SES, "getkeypress") do cm::ComponentModifier

        end
        key_button = button("redeem", text = "redeem alpha key")
        on(Olive.SES, "redeemkeypress") do cm::ComponentModifier

        end
        guest_button = button("guestb", text = "enter as guest")
        on(Olive.SES, "guestpress") do cm::ComponentModifier

        end
        box = div("loginbox", children = [open_alphal, login_button, key_button, get_key_button, guest_button])
        style!(box, "position" => "absolute", "padding" => 3percent, "width" => 40percent, "top" => 35percent, "left" => 27percent, 
            "z-index" => 5, "transform" => "scale(1, 0)", "background-color" => "#cb416b", "border" => "11px solid #1e1e1e", "transition" => 850ms)
        box
    end
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
        next!(cl, creator) do cl::ClientModifier
            style!(cl, "loginbox", "transform" => "scale(1, 1)")
        end
    end
    main = body("main", children = [OliveCreator.custom_sheet, splash_div, scr, login_box], align = "center")
    style!(main, "width" => 90percent, "height" => 100percent, "background-color" => "#171717", 
    "overflow" => "hidden")
    main
end

SPLASH = build_splash()