function build(c::Connection, om::ComponentModifier, oe::OliveExtension{:memorylimiter})
    if getname(c) == "guest"
        return
    end
    progress_bar::Component{:progress} = Components.progress("memoryusage", value = 0, min = 0, max = 100)
    style!(progress_bar, "display" => "inline-block")
    progress_label1::Component{:a} = a("memlabel", text = "0")
    progress_label2::Component{:a} = a("memlimitlabel", text = "/ 2 GB")
    a_styles = ("font-weight" => "bold", "font-size" => 13pt, "color" => "white")
    style!(progress_label1, a_styles ...)
    style!(progress_label2, a_styles ...)
    memory_box::Component{:div} = div("memcontainer", children = [progress_bar, progress_label1, progress_label2])
    style!(memory_box, "display" => "inline-block") #<- important
    insert!(om, "rightmenu", 1, memory_box)
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
    total_data::Int64 = sum([sumsizeof(project[:mod]) for project in c[:OliveCore].open[getname(c)].projects])
    data_available::Int64 = 2147483648
    in_gb = total_data / 1000000000
    percentage = Int64(round(total_data / data_available * 100))
    if total_data > data_available
        projs = c[:OliveCore].open[getname(c)].projects
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
            total_data = sum([sumsizeof(project[:mod]) for project in c[:OliveCore].open[getname(c)].projects])
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
    keybindings = c[:OliveCore].client_data[getname(c)]["keybindings"]
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