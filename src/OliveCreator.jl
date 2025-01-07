module OliveCreator
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
import Olive: build, evalin, Cell, Project, OliveModifier, getname, build_base_cell, olive_notify!
import Base: getindex, delete!, append!
include("profiles.jl")

main = route("/") do c::Toolips.AbstractConnection
    custom_sheet = Olive.olivesheet()
    delete!(custom_sheet[:children], "div.topbar")
    new_topbars = style("div.topbar", 
    "border-radius" => "5px", "background-color" => "#444", "transition" => 500ms)
    custom_sheet[:children]["body"]["background-color"] = "#171717"
    progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
    push!(custom_sheet, new_topbars)
    heart_path = Component{:path}("creatorload", fill = "pink", class = "heart",
    d = "M200 251.67l-2.053-1.67c-44.96-36.62-57.136-49.51-57.136-70.45 0-17.213 14.01-31.22 31.224-31.22 14.386 0 22.518 8.17 27.97 14.315 5.448-6.146 13.58-14.315 27.968-14.315 17.215 0 31.22 14.007 31.22 31.22 0 20.94-12.175 33.83-57.134 70.45L200 251.67z")
    heart_sty = style(".heart", "stroke" => "#444", "stroke-width" => 7px, "animation" => "pulse 800ms linear infinite")
    push!(custom_sheet, progress_sty, heart_sty)
    creator_heart = svg("load", width = 500, height = 500, children = [heart_path])
    creator_auth(c)
    Olive.make_session(c, key = false, sheet = custom_sheet, icon = creator_heart)
end

build(c::Connection, cm::OliveModifier, oe::Olive.OliveExtension{:creator}) = begin
 #   progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
  #  remove!(cm, "::-webkit-progress-value")
  #  append!(cm, "olivestyle", progress_sty)
  olive_notify!(cm, "hi")
end

function start()
    Olive.start("127.0.0.1":8000, path = ".")
    Olive.routes["/"] = main
    [begin
        profile_route = route("/@$user") do c::AbstractConnection
            creator_auth(c)
            name = Olive.getname(c)
            newenv = Olive.Environment("creator", name)
            newenv.pwd = c[:OliveCore].data["home"]
            read_in_cells = Olive.IPyCells.read_jl("olive/home/users/$user/profile/profile.jl")
            project_data = Dict{Symbol, Any}(:cells => Vector{Olive.Cell}([
                    Olive.Cell{:profileheader}(""), read_in_cells ...
                ]), :pane => "one", :wd => newenv.pwd, :uname => user)
            push!(newenv.projects, Olive.Project{:profile}("@$user", project_data))
            pwd_direc::Olive.Directory{:pwd} = Olive.Directory(newenv.pwd, dirtype = "pwd")
            push!(newenv.directories, pwd_direc)
            f = findfirst(env -> env.name == name, c[:OliveCore].open)
            if ~(isnothing(f))
                deleteat!(c[:OliveCore].open, f)
            end
            length(c[:OliveCore].open)
            push!(c[:OliveCore].open, newenv)
            length(c[:OliveCore].open)
            Olive.make_session(c, key = false)
        end
        push!(Olive.SES.active_routes, profile_route.path)
        push!(Olive.routes, profile_route)
    end for user in USERS.names]
end

export evalin
end # module OliveCreator
