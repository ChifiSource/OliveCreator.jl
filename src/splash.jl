function build_login_box(c::AbstractConnection)
    unamelbl = a(text = "username/email: ")
    unameinput = textdiv("userinp", text = "")
    style!(unameinput, "background-color" => "#1e1e1e", "color" => "white", 
    "font-size" => 13pt, "font-weight" => "bold")
    uname_section = section(children = [unamelbl, unameinput])
    pwdlbl = a(text = "password: ")
    pwdinput = textdiv("pwdinp", text = "")
    style!(pwdinput, "background-color" => "#1e1e1e", "color" => "#1e1e1e")
    pwd_section = section(children = [pwdlbl, pwdinput])
    
    confirm_button = button("loginconf", text = "confirm")
    on(c, confirm_button, "click") do cm::ComponentModifier
        provided_pwd = cm["pwdinp"]["text"]
        provided_name = cm["userinp"]["text"]
        login_user(c, OliveCreator.ORM_EXTENSION, provided_name, provided_pwd)
    end
    confirm_section = div("confsect", children = [confirm_button], align = "right")
    main_box = div("logheader", children = [uname_section, pwd_section, confirm_section], align = "left")
    main_box
end

function build_main_box(c::AbstractConnection)
    open_alphal = tmd("logheader", """##### welcome to creator closed alpha
        Due to hardware limitations, olive creator is starting small with a **closed** alpha. This project plans to eventually open its doors to the broader public.
        Thank you for understanding financial and physical constraints during this period, and thank you for your interest in this project. 
        Within the alpha period, it is still possible to browse the site as a guest *or* claim a key to access the closed alpha.""")
    login_button = button("loginb", text = "login")
    on(c, login_button, "click") do cm::ComponentModifier
        remove!(cm, "logheader")
        login_box = build_login_box(c)
        insert!(cm, "mainbox", 1, login_box)
    end
    get_key_button = button("getkeyb", text = "get your alpha key")
    on(c, get_key_button, "click") do cm::ComponentModifier

    end
    key_button = button("redeem", text = "redeem alpha key")
    guest_button = button("guestb", text = "enter as guest")
    box = div("mainbox", children = [open_alphal, login_button, key_button, get_key_button, guest_button])
    style!(box, "position" => "absolute", "padding" => 3percent, "width" => 40percent, "top" => 35percent, "left" => 27percent, 
        "z-index" => 5, "transform" => "scale(1, 0)", "background-color" => "#cb416b", "border" => "11px solid #1e1e1e", "transition" => 850ms)
    box
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
    style!(splash_div, "pointer-events" => "none", "position" => "absolute", "width" => 100percent, "height" => 100percent, 
    "top" => 0percent, "left" => 0percent, "padding" => 0percent, "overflow" => "visible")
    scr = on(700) do cl::ClientModifier
        style!(cl, "creator", "opacity" => 100percent, "transform" => "rotate(10deg)", "left" => 50percent)
        [begin
            trans_y = rand(-5:100) * percent
            trans_x = rand(-5:100) * percent
            scale = rand(1:4)
            rotation = rand(-20:20) * deg
            style!(cl, "heart-particle$count", "opacity" => 100percent,
            "transform" => "scale(.0$scale) rotate($rotation)", "top" => trans_y, "left" => trans_x)
        end for count in 1:500]
        next!(cl, creator) do cl::ClientModifier
            style!(cl, "mainbox", "transform" => "scale(1, 1)")
        end
    end
    main = body("main", children = [OliveCreator.custom_sheet, splash_div, scr], align = "center")
    style!(main, "width" => 90percent, "height" => 100percent, "background-color" => "#171717", 
    "overflow" => "hidden")
    main
end

SPLASH = nothing