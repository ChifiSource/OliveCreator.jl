
function build(c::Connection, cm::ComponentModifier, cell::Cell{:profileheader},
    proj::Project{<:Any})
    uname::String = proj[:uname]
    user_data = OliveCreator.USERS_CACHE[proj[:uname]]
    main_cell = div("cellcontainer$(cell.id)")
    style!(main_cell, "display" => "inline-flex", "padding" => 5percent)
    info_box = div("userinfo")
    lvl_acc = user_data.level
    filabel = a(text = string(user_data.fi))
    ficirc = span("ficirc")
    fibox = div("fibox", children = [ficirc, filabel])
    lvlprog, lvl_acc = modf(lvl_acc)
    level_label = h3("lvllabel", text = string(lvl_acc))
    figress = Components.progress("figress", value = string(lvlprog), min="0", max="1")
    lvlbox = div("lvlbox", children = [level_label, figress])
    style!(lvlbox, "padding" => 0px, "margin-top" => 0px)
    namelabel = h2("nameheader", text = uname)
    style!(figress, "display" => "inline-block", "margin-left" => 5px)
    style!(namelabel, "font-size" => 30pt, "margin-bottom" => 5px, "display" => "inline-block")
    style!(level_label, "font-size" => 20pt, "color" => "#D36CB6", "display" => "inline-block")
    style!(info_box, "padding" => 10px)
    top_box = div("tbox")
    control_box = div("controls", style = "display:inline-block;")
    style!(top_box, "display" => "inline-block")
    push!(top_box, namelabel, control_box)
    push!(info_box, top_box, fibox, lvlbox)
    if getname(c) == uname
        editbutton = Olive.topbar_icon("edit-pb", "edit_document")
        style!(editbutton, "font-size" => 13pt, "color" => "darkgray")
        on(c, editbutton, "click") do cm::ComponentModifier
            save_button = Olive.topbar_icon("save-pb", "save")
            style!(save_button, "font-size" => 13pt, "color" => "darkgray")
            on(c, save_button, "click") do cm2::ComponentModifier
                set_children!(cm2, "controls", [editbutton])
                [make_uneditable!(c, cm2, lcell, proj) for lcell in proj.data[:cells][2:end]]
                Olive.IPyCells.save(proj.data[:cells][2:end], "users/$(Olive.getname(c))/profile/profile.jl")
                Olive.olive_notify!(cm2, "profile successfully saved")
            end
            set_children!(cm, "controls", [save_button])
            if length(proj.data[:cells]) == 1
                new_cell = Cell{:creator}()
                push!(proj.data[:cells], new_cell)
                append!(cm, proj.id, build(c, cm, new_cell,
                  proj))
                return
            end
            for lcell in proj.data[:cells][2:end]
                make_editable!(c, cm, lcell, proj)
            end
        end
        push!(control_box, editbutton)
    end
    profile_img = img(width = 150, height = 150, src = user_data.profile_img)
    img_wrapper = div("img_wrapper")
    push!(img_wrapper, profile_img)
    style!(img_wrapper, "border-radius" => 10px, "border" => "1px solid whitesmoke", "padding" => 0px, 
    "width" => 150px, "height" => 150px, "overflow" => "hidden")
    push!(main_cell, img_wrapper, info_box)
    main_cell::Component{:div}
end

function make_uneditable!(c::Connection, cm::ComponentModifier, cell::Cell{:blurb}, 
    proj::Project{:profile})
    cellid = cell.id
    cell.source = cm["cell$cellid"]["text"]
    cm["cell$cellid"] = "contenteditable" => "false"
    style!(cm, "cell$cellid", "border" => "none")
    remove!(cm, "$(cellid)upper")
    remove!(cm, "$(cellid)controls")
    remove!(cm, "$(cellid)lower")
end

function make_editable!(c::Connection, cm::ComponentModifier, cell::Cell{:blurb}, 
    proj::Project{:profile})
    controls = make_control_boxes(c, cm, cell, proj)
    cellid = cell.id
    cm["cell$cellid"] = "contenteditable" => "true"
    style!(cm, "cell$cellid", "border" => "2px solid #DDD6DD")
    insert!(cm, "cellcontainer$cellid", 1, controls[1])
    insert!(cm, "cellcontainer$cellid", 2, controls[3])
    append!(cm, "cellcontainer$cellid", controls[2])
end

function make_uneditable!(c::Connection, cm::ComponentModifier, cell::Cell{<:Any}, 
    proj::Project{:profile})
    remove!(cm, "$(cell.id)upper")
    remove!(cm, "$(cell.id)controls")
    remove!(cm, "$(cell.id)lower")
end

function make_editable!(c::Connection, cm::ComponentModifier, cell::Cell{<:Any}, 
    proj::Project{:profile})
    controls = make_control_boxes(c, cm, cell, proj)
    insert!(cm, "cellcontainer$(cell.id)", 1, controls[1])
    insert!(cm, "cellcontainer$(cell.id)", 2, controls[3])
    append!(cm, "cellcontainer$(cell.id)", controls[2])
end

function make_control_boxes(c::Connection, cm::ComponentModifier, cell::Cell{<:Any}, 
    proj::Project{:profile})
    add_top = Olive.topbar_icon("addtop$(cell.id)", "add")
    on(c, add_top, "click") do cm2::ComponentModifier
        cells = proj.data[:cells]
        cellpos = findfirst(lcell -> lcell.id == cell.id, cells)
        Olive.cell_new!(c, cm2, cells[cellpos - 1], proj)
    end
    add_bottom = Olive.topbar_icon("addbottom$(cell.id)", "add")
    on(c, add_bottom, "click") do cm2::ComponentModifier
        Olive.cell_new!(c, cm2, cell, proj)
    end
    icon_styles = ("color" => "darkgray", "font-size" => 7pt, "background-color" => "white", "padding" => 3px, "border-radius" => 3px, 
    "border" => "2px solid black")
    style!(add_top, icon_styles ...)
    style!(add_bottom, icon_styles ...)
    upper_box = div("$(cell.id)upper", children = [add_top])
    style!(upper_box, "height" => 1.75percent, "background-color" => "gray", "border-bottom-right-radius" => 0px, 
    "border-bottom-left-radius" => 0px, "overflow" => "hidden")
    lower_box = div("$(cell.id)lower", children = [add_bottom])
    style!(lower_box, "height" => 1.5percent, "background-color" => "gray", "border-top-left-radius" => 0px, 
    "border-top-right-radius" => 0px, "overflow" => "hidden")
    controller_box = div("$(cell.id)controls", align = "right")
    delete_butt = Olive.topbar_icon("addbottom$(cell.id)", "delete")
    on(c, delete_butt, "click") do cm2::ComponentModifier
        Olive.cell_delete!(c, cm2, cell, proj[:cells])
    end
    push!(controller_box, delete_butt)
    return(upper_box, lower_box, controller_box)
end

function build_base_profile_cell(c::Connection, cm::ComponentModifier, cell::Cell{<:Any}, 
    proj::Project{:profile}, editable::Bool)
    outer_box = div("cellcontainer$(cell.id)", align = "center")
    style!(outer_box, "border" => "none", "padding" => 4percent)
    upper_box, lower_box, controller = make_control_boxes(c, cm, cell, proj)
    mid_box = div("cell$(cell.id)")
    style!(mid_box, "border-radius" => 0px)
    if editable
        push!(outer_box, upper_box, controller, mid_box, lower_box)
    else
        push!(outer_box, mid_box)
    end
    outer_box::Component{:div}
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:achievements},
    proj::Project{:profile}; editable::Bool = false)
    achieves = Olive.CORE.users[getname(c)].data["achievements"]
    achievebox = build_base_profile_cell(c, cm, cell, proj, editable)
    main_box = achievebox[:children]["cell$(cell.id)"]
    main_box[:children] = Vector{AbstractComponent}([begin
        achieve = ACHIEVEMENTS[n]
        achieve_div = div("achieve-div$n")
        style!(achieve_div, "display" => "inline-block", 
        "overflow-y" => "hidden", "overflow-x" => "scroll", "border" => "3px solid #DDDDDD", "border-radius" => 4px)
        img_header = img("achieve$n", src = achieve.img, width = 75, height = 75)
        achieve_label = p("achievelabel", text = achieve.name)
        style!(achieve_label, "color" => "#DDDDDD", "font-weight" => "bold", "font-size" => 16pt)
        push!(achieve_div, img_header, achieve_label)
        achieve_div
    end for n in achieves])
    achievebox::Component{:div}
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:blurb},
    proj::Project{:profile}; editable::Bool = false)
    main_cell = build_base_profile_cell(c, cm, cell, proj, editable)
    main_box = main_box = main_cell[:children]["cell$(cell.id)"]
    main_box.name = "textframe$(cell.id)"
    main_box[:align] = "left"
    newdiv = Components.textdiv("cell$(cell.id)", text = "enter your post here")
    style!(newdiv, "color" => "darkgray", "font-weight" => "bold", "border" => "2px solid #DDD6DD", 
    "font-size" => 18pt)
    if cell.source != ""
        newdiv[:text] = cell.source
    end
    if ~(editable)
        newdiv[:contenteditable] = false
        style!(newdiv, "border" => "none")
    end
    push!(main_box, newdiv)
    on(c, newdiv, "focus") do cm::ComponentModifier
        if contains(cm[newdiv]["text"], "enter your post here")
            set_text!(cm, newdiv, "")
        end
    end
    main_cell::Component{:div}
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:creator},
    proj::Project{:profile})
    cells = proj[:cells]
    windowname::String = proj.id
    creatorkeys = c[:OliveCore].users[getname(c)].data["creatorkeys"]
    signatures = [:blurb, :achievements, :progression, :recents, :projects, :linkbox, :codeoutput]
    nameput = Components.textdiv("cell$(cell.id)")
    buttonbox = div("cellcontainer$(cell.id)")
    push!(buttonbox, h3("spawn$(cell.id)", text = "new cell"), nameput)
     for sig in signatures
         b = button("$(sig)butt", text = string(sig))
         on(c, b, "click") do cm2::ComponentModifier
            pos = findfirst(lcell -> lcell.id == cell.id, cells)
            remove!(cm2, buttonbox)
            new_cell = Cell{sig}("", false)
            deleteat!(cells, pos)
            insert!(cells, pos, new_cell)
            insert!(cm2, windowname, pos, build(c, cm2, new_cell,
              proj, editable = true))
         end
         push!(buttonbox, b)
     end
     buttonbox
end

function generate_profile(c::Toolips.AbstractConnection, user::AbstractString)
    creator_auth(c)
    name = Olive.getname(c)
    read_in_cells = Olive.IPyCells.read_jl("users/$user/profile/profile.jl")
    project_data = Dict{Symbol, Any}(:cells => Vector{Olive.Cell}([
            Olive.Cell{:profileheader}(""), read_in_cells ...
        ]), :pane => "one", :wd => "nothing", :uname => user)
    Olive.CORE.users[name].environment.projects = Vector{Olive.Project}([Olive.Project{:profile}("@$user", project_data)])
    if name == "guest"
        Olive.make_session(c, key = false, themes_enabled = false, sheet = custom_sheet,
            settings_enabled = false)
    else
        Olive.make_session(c, key = false, sheet = custom_sheet,
            settings_enabled = false)
    end
end
