abstract type PostType{T} end

function build_post(c::Connection, cm::ComponentModifier, post_type::Type{PostType{:short}})

end

available_post_types = [m.sig.parameters[4].parameters[1] for m in methods(build_post, [Connection, ComponentModifier, Type{PostType}])]

function build(c::Connection, cm::ComponentModifier, cell::Cell{:newpost},
    proj::Project{:feed})
    cellid = cell.id
    newcell = build_base_cell(c, cm, cell, proj, highlight = true, sidebox = false)
    interior = newcell[:children]["cellinterior$(cell.id)"]
    style!(interior, "padding" => 0px)
    maincell = interior[:children][1]
    Components.style!(maincell, "border-bottom-right-radius" => 0px, "border-bottom-left-radius" => 0px, 
    "border-top-left-radius" => 5px)
    bottom_box = div("postbottom", text = "postbottom")
    style!(bottom_box, "margin" => 0px, "border-top-left-radius" => 0px, "border-top-right-radius" => 0px, 
        "width" => 91percent)
    style!(bottom_box, "background-color" => "#1e1e1e")
    insert!(newcell[:children], 2, bottom_box)
    newcell
end

function cell_highlight!(c::Connection, cm::ComponentModifier, cell::Cell{:newpost},
    proj::Project{<:Any})
    active_cell = cm["cell$(cell.id)"]
    curr = active_cell["text"]
    if active_cell["contenteditable"] == "false"
        return
    end
    cell.source = replace(curr, "<br>" => "\n", "<div>" => "")
    tm::Highlighter = CORE.users[getname(c)]["highlighters"]["markdown"]
    tm.raw = cell.source
    OliveHighlighters.mark_markdown!(tm)
    set_text!(cm, "cellhighlight$(cell.id)", string(tm))
    OliveHighlighters.clear!(tm)
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:feed},
    proj::Project{:feed})
    div("sample", text = "feed")
end