function build(c::Connection, om::ComponentModifier, oe::OliveExtension{:creatorbase})
    if "searchbar" in om
        return
    end
    # search
    search = Components.textdiv("searchbar")
    style!(search, "display" => "inline-block", "background-color" => "white", "font-size" => 18pt, "color" => "#1e1e1e", "border" => "1px solid #1e1e1e", 
        "border-bottom-left-radius" => 3pt, "border-top-left-radius" => 3pt, "border-radius" => 0pt, "padding" => .5percent, "min-width" => 250px)
    searchicon = topbar_icon("searchbutt", "search")
    style!(searchicon, "background-color" => "#36454F", "color" => "white", "border-top-right-radius" => 3pt, "border-bottom-right-radius" => 3pt, 
        "font-size" => 18pt, "padding" => .5percent, "display" => "inline-block")
    search_box = div("searbox", align = "left", children = [search, searchicon])
    style!(search_box, "display" => "inline-flex", "overflow" => "hidden", "padding" => 0px, "border-radius" => 0px)
    if getname(c) == "guest"
        insert!(om, "rightmenu", 1, search_box)
        return
    end
    # memory progress
    progress_bar::Component{:progress} = Components.progress("memoryusage", value = 0, min = 0, max = 100)
    style!(progress_bar, "display" => "inline-block", "width" => 80px, "margin-right" => 3px)
    progress_label1::Component{:a} = a("memlabel", text = "0")
    progress_label2::Component{:a} = a("memlimitlabel", text = "/ 2 GB")
    a_styles = ("font-weight" => "bold", "font-size" => 13pt, "color" => "white")
    style!(progress_label1, a_styles ...)
    style!(progress_label2, a_styles ...)
    memory_box::Component{:div} = div("memcontainer", children = [progress_bar, progress_label1, progress_label2])
    style!(memory_box, "display" => "inline-block", "margin-top" => .1percent) #<- important
    # user indicator
    name = getname(c)
    user_data = OliveCreator.USERS_CACHE[name]
    usr_img = img("usrimg", src = user_data.profile_img, width = 30px)
    usr_indicator = div("usrind", children = [usr_img], align = "center")
    style!(usr_indicator, "background-color" => "white", "border" => "1px solid #1e1e1e", 
        "display" => "inline-flex", "border-radius" => 7pt, "margin-right" => 5px, "margin-left" => 10px,
        "cursor" => "pointer", "padding" => 0px, "width" => 30px, "height" => 30px, "overflow" => "visible")
    style!(usr_img, "border-radius" => 10pt)
    on(c, usr_indicator, "click") do cm::ComponentModifier
        alert!(cm, "hello")
    end
    container = div("-", children = [memory_box, search_box, usr_indicator])
    style!(container, "padding" => 0px, "border-radius" => 0px)
    insert!(om, "rightmenu", 1, container)
end

sumsizeof(mod::Module) = begin
    total = 0
    for name in names(mod, all = true)
       val = getfield(mod, name)
       total += sizeof(val)
    end
    total
end

on_code_evaluate(c::Connection, cm::ComponentModifier, oe::OliveExtension{:memorylimiter}, 
    cell::Cell{:code}, proj::Project{<:Any}) = begin
    user = Olive.CORE.users[getname(c)]
    total_data::Int64 = sum([sumsizeof(project[:mod]) for project in user.environment.projects])
    data_available::Int64 = 2147483648
    in_gb = total_data / 1000000000
    percentage = Int64(round(total_data / data_available * 100))
    if total_data > data_available
        projs = user.environment.projects
        pos = findfirst(pro -> pro.id == proj.id,
        projs)
        Olive.empty_module!(c, proj)
        new_project = Project{:readonly}(proj.name, proj.data)
        new_project.id = proj.id
        projtab = Olive.build_tab(c, new_project)
        pane = proj.data[:pane]
        deleteat!(projs, pos)
        push!(projs, new_project)
        remove!(cm, "tab$(proj.id)")
        append!(cm, "pane_$(pane)_tabs", projtab)
        set_children!(cm, proj.id, 
        [build(c, cm, cell, new_project) for cell in new_project.data[:cells]])
        Olive.olive_notify!(cm, "you ran out of memory -- your current project is now read only", color = "red")
        cm["memoryusage"] = "value" => string(percentage)
        style!(cm, "memlabel", "color" => "red")
        on(c, cm, 2000) do cm2::ComponentModifier
            total_data = sum([sumsizeof(project[:mod]) for project in Olive.CORE.users[getname(c)].projects])
            data_available = 2147483648
            in_gb = total_data / 1000000000
            percentage = Int64(round(total_data / data_available * 100))
            cm2["memoryusage"] = "value" => string(percentage)
            set_text!(cm2, "memlabel", string(in_gb))
            style!(cm2, "memlabel", "color" => "white")
        end
    end
    cm["memoryusage"] = "value" => string(percentage)
    set_text!(cm, "memlabel", string(in_gb))
end

function cell_bind!(c::Connection, cell::Cell{<:Any}, proj::Project{:readonly}, 
    km::ToolipsSession.KeyMap = ToolipsSession.KeyMap())
    keybindings = c[:OliveCore].users[getname(c)]["keybindings"]
    ToolipsSession.bind(km, keybindings["save"], prevent_default = true) do cm::ComponentModifier
        save_project(c, cm, proj)
    end
    ToolipsSession.bind(km, keybindings["saveas"], prevent_default = true) do cm::ComponentModifier
        style!(cm, "projectexplorer", "width" => "500px")
        style!(cm, "olivemain", "margin-left" => "500px")
        style!(cm, "explorerico", "color" => "lightblue")
        set_text!(cm, "explorerico", "folder_open")
        cm["olivemain"] = "ex" => "1"
        save_project_as(c, cm, proj)
    end
    ToolipsSession.bind(km, keybindings["focusup"]) do cm::ComponentModifier
        focus_up!(c, cm, cell, proj)
    end
    ToolipsSession.bind(km, keybindings["up"]) do cm2::ComponentModifier
        olive_notify!(cm2, "this project is in read-only mode", color = "darkred")
    end
    ToolipsSession.bind(km, keybindings["down"]) do cm2::ComponentModifier
        olive_notify!(cm2, "this project is in read-only mode", color = "darkred")
    end
    ToolipsSession.bind(km, keybindings["delete"]) do cm2::ComponentModifier
        olive_notify!(cm2, "this project is in read-only mode", color = "darkred")
    end
    ToolipsSession.bind(km, keybindings["evaluate"]) do cm2::ComponentModifier
        olive_notify!(cm2, "this project is in read-only mode")
    end
    ToolipsSession.bind(km, keybindings["new"]) do cm2::ComponentModifier
        olive_notify!(cm2, "this project is in read-only mode")
    end
    ToolipsSession.bind(km, keybindings["focusdown"]) do cm::ComponentModifier
        focus_down!(c, cm, cell, proj)
    end
    km::ToolipsSession.KeyMap
end