function build_login_box(c::AbstractConnection, cm::ComponentModifier)
    unamelbl = a(text = "username/email: ", class = "loginpres")
    unameinput = textdiv("userinp", text = "", class = "stdinp")
    ToolipsSession.bind(c, cm, unameinput, "Enter", prevent_default = true) do cm
        focus!(cm, "pwdinp")
    end
    uname_section = div("-", children = [unamelbl, unameinput])
    pwdlbl = a(text = "password: ", class = "loginpres")
    pwdinput = textdiv("pwdinp", text = "", class = "stdinp")
    complete_login = cm -> begin
        provided_pwd = cm["pwdinp"]["text"]
        provided_name = cm["userinp"]["text"]
        success = login_user(c, OliveCreator.ORM_EXTENSION, provided_name, provided_pwd)
        if typeof(success) <: AbstractString
            if "errmsg" in cm
                set_text!(cm, "errmsg", success)
            else
                error_a = div("errmsg", text = success)
                append!(cm, "confsect", error_a)
            end
            return
        end
        session_key = get_session_key(c)
        load_client!(Olive.CORE, provided_name, session_key)
        redirect!(cm, "/")
    end
    ToolipsSession.bind(complete_login, c, cm, pwdinput, "Enter", prevent_default = true)
    style!(pwdinput, "font-family" => "password")
    pwd_section = div("-", children = [pwdlbl, pwdinput])
    confirm_button = button("loginconf", text = "confirm")
    on(complete_login, c, confirm_button, "click")
    confirm_section = div("confsect", children = [confirm_button], align = "right")
    style!(confirm_section, "margin-top" => .5percent)
    main_box = div("logheader", children = [uname_section, pwd_section, confirm_section], align = "left")
    main_box
end

function build_setup_account_box(c::AbstractConnection, cm::ComponentModifier, key::String, key_tablei::Int64)
    unameinput = textdiv("userinp", text = "", class = "stdinp")
    emailinp = textdiv("emailinp", text = "", class = "stdinp")
    pwdinput1 = textdiv("passwordinp", text = "", class = "stdinp")
    pwdinput2 = textdiv("confpwd", text = "", class = "stdinp")
    style!(pwdinput1, "font-family" => "password")
    style!(pwdinput2, "font-family" => "password")
    unamelbl = a(text = "username", class = "loginpres")
    emaillbl = a(text = "email", class = "loginpres")
    pwdlbl = a(text = "new password", class = "loginpres")
    conflbl = a(text = "confirm password", class = "loginpres")
    confirm_info = cm::ComponentModifier -> begin
        new_username = cm["userinp"]["text"]
        new_email = cm["emailinp"]["text"]
        pwd_1 = cm["passwordinp"]["text"]
        pwd_2 = cm["confpwd"]["text"]
        @info new_email
        @info new_username
        err = nothing
        orm = OliveCreator.ORM_EXTENSION
        user_tablei = query(Int64, orm, "index", "users/name", new_username)
        maili = query(Int64, orm, "index", "users/mail", new_email)
        keep_out_of_name = ("|", "\$", "!", "@", "#", "%", "^", "&", "*", "(", ")", "\\", 
            "/", "]", "[", ".", "\"", ";", ":", "'", "`", "?")
        found = findfirst(x -> contains(new_username, x), keep_out_of_name)
        if contains(new_username, " ")
            new_username = replace(new_username, " " => "_")
        elseif contains(pwd_1, "!;")
            err = "password cannot contain `!;`"
        elseif length(pwd_1) < 6
            err = "password must be at least 6 characters"
        elseif user_tablei != 0
            err = "username taken"
        elseif ~(isnothing(found))
            err = "username contains invalid symbols"
        elseif pwd_1 != pwd_2
            err = "passwords do not match"
        elseif maili != 0
            err = "email taken"
        elseif ~(contains(new_email, "@"))
            err = "invalid email"
        end
        if ~(isnothing(err))
            if "errmsg" in cm
                set_text!(cm, "errmsg", err)
            else
                error_a = div("errmsg", text = err)
                append!(cm, "confsect", error_a)
            end
            return
        end
        create_new_user(c, orm, new_username, new_email, pwd_1)
        query(String, orm, "set", "creatorkeys/used", key_tablei, true)
        load_client!(Olive.CORE, new_username, get_session_key(c))
        redirect!(cm, "/")
    end
    confirm_button = button("loginconf", text = "confirm")
    on(confirm_info, c, confirm_button, "click")
    confirm_section = div("confsect", children = [confirm_button], align = "right", 
        style = "margin-top:.75%;")
    main_box = div("logheader", children = [unamelbl, unameinput, 
        emaillbl, emailinp, pwdlbl, pwdinput1, conflbl, pwdinput2, confirm_section], align = "left")
    main_box
end

function build_redeem_box(c::AbstractConnection, cm::Toolips.Components.AbstractComponentModifier, keytxt::String = "")
    akey_lbl = h3(text = "enter alpha key:")
    keybox = textdiv("keyinp", text = keytxt, class = "stdinp")
    style!(keybox, "font-family" => "password")
    process_key = cm::ComponentModifier -> begin
        provided_key = cm["keyinp"]["text"]
        if provided_key == ""
            return
        end
        orm = OliveCreator.ORM_EXTENSION
        user_tablei = query(Int64, orm, "index", "creatorkeys/keys", provided_key)
        if user_tablei == 0
            # TODO invalid key error message
            return
        end
        used_key = query(Bool, orm, "get", "creatorkeys/used", user_tablei)
        @info used_key
        if used_key
            # TODO used key error message
            return
        end
        login_box = build_setup_account_box(c, cm, provided_key, user_tablei)
        remove!(cm, "logheader")
        set_children!(cm, "mainbox", [login_box])
    end
    ToolipsSession.bind(process_key, c, cm, keybox, "Enter", prevent_default = true)
    confirm_button = button("loginconf", text = "use alpha key")
    style!(confirm_button, "animation-name" => "banim", "animation-duration" => 5seconds, "animation-iteration-count" => "infinite")
    on(process_key, c, confirm_button, "click")
    confirm_section = div("confsect", children = [confirm_button], align = "right")
    main_box = div("logheader", children = [akey_lbl, keybox, confirm_section], align = "left")
end

function build_getkey_box(c::AbstractConnection)
    header = h5(text = "get your alpha key", align = "left")
    n_keys = length(findall(x -> ~(x), OliveCreator.ALPHA_KEYS))
    confirm_button = button("loginconf", text = "claim your key")
    remaining_keys = if n_keys == 0
        confirm_button[:disabled] = true
        style!(confirm_button, "background-color" => "gray", "cursor" => "not-allowed")
        h3(text = "sorry, all available keys have been claimed. More will be available soon.", align = "center")
    else
        style!(confirm_button, "animation-name" => "banim", "animation-duration" => 5seconds, "animation-iteration-count" => "infinite")
        h3(text = "$n_keys keys remaining", align = "center")
    end
    style!(remaining_keys, "color" => "white")
    on(c, confirm_button, "click") do cm::ComponentModifier
        nexti = findfirst(x -> ~(x), OliveCreator.ALPHA_KEYS)
        if isnothing(nexti)
            cm["loginconf"] = "disabled" => "true"
        end
        this_key = query(String, OliveCreator.ORM_EXTENSION, "get", "creatorkeys/keys", nexti)
        @warn this_key
        redeem_box = build_redeem_box(c, cm, this_key)
        remove!(cm, "logheader")
        insert!(cm, "mainbox", 1, redeem_box)
    end
    confirm_section = div("confsect", children = [confirm_button], align = "center")
    style!(confirm_section, "margin-bottom" => 1.5percent)
    main_box = div("logheader", children = [header, remaining_keys, confirm_section], align = "left")
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
        login_box = build_login_box(c, cm)
        insert!(cm, "mainbox", 1, login_box)
    end
    get_key_button = button("getkeyb", text = "get your alpha key")
    on(c, get_key_button, "click") do cm::ComponentModifier
        remove!(cm, "logheader")
        keybox = build_getkey_box(c)
        insert!(cm, "mainbox", 1, keybox)
    end
    key_button = button("redeem", text = "redeem alpha key")
    on(c, key_button, "click") do cm::ComponentModifier
        remove!(cm, "logheader")
        login_box = build_redeem_box(c, cm)
        insert!(cm, "mainbox", 1, login_box)
    end
    guest_button = button("guestb", text = "enter as guest")
    on(c, guest_button, "click") do cm::ComponentModifier
        
    end
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
    end for count in 1:500]
    splash_div = div("splash", children = [creator, hearts ...])
    style!(splash_div, "pointer-events" => "none", "position" => "absolute", "width" => 100percent, "height" => 100percent, 
    "top" => 0percent, "left" => 0percent, "padding" => 0percent, "overflow" => "visible")
    scr = on(700) do cl::ClientModifier
        style!(cl, "creator", "opacity" => 100percent, "transform" => "rotate(10deg)", "left" => 50percent)
        next_cl = ClientModifier()
        [begin
            trans_y = rand(-5:100)
            trans_x = rand(-5:100)
            scale = rand(1:4)
            rotation = rand(-20:20) * deg
            offset = rand(-240:240)
            style!(cl, "heart-particle$count", "opacity" => 100percent,
                "transform" => "scale(.0$scale) rotate($rotation)", "top" => trans_y * percent, "left" => trans_x * percent)
            style!(next_cl, "heart-particle$count", "transition" => 3000s, "transform" => "rotate($(offset)deg) scale(0.0$(scale + 1))", 
                "left" => (trans_x + offset) * percent, "top" => (trans_y + offset) * percent)
        end for count in 1:500]
        next!(cl, creator) do cl::ClientModifier
            push!(cl.changes, next_cl.changes ...)
            style!(cl, "mainbox", "transform" => "scale(1, 1)")
        end
    end
    main = body("main", children = [OliveCreator.custom_sheet, splash_div, scr], align = "center")
    style!(main, "width" => 90percent, "height" => 100percent, "background-color" => "#171717", 
    "overflow" => "hidden")
    main
end

SPLASH = nothing