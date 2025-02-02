module OliveCreator
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
import Olive: build, evalin, Cell, Project, OliveModifier, getname, build_base_cell, olive_notify!, OliveExtension
import Olive: on_code_evaluate, cell_bind!
import Base: getindex, delete!, append!
import Toolips: route!, router_name
include("users.jl")
include("profiles.jl")
include("splash.jl")
include("limiter.jl")

abstract type CreatorCentralRoute <: Toolips.AbstractRoute end

router_name(T::Type{<:CreatorCentralRoute}) = "olive creator custom router"

mutable struct CreatorRoute <: CreatorCentralRoute
    path::String
    routes::Vector{AbstractRoute}
    CreatorRoute(routes::Vector) = new("creator", routes)
end

route!(c::AbstractConnection, routes::Vector{<:CreatorCentralRoute}) = begin
    targeted_path::String = get_route(c)
    if length(targeted_path) > 1
        if targeted_path[1:2] == "/@"
            generate_profile(c, targeted_path[3:end])
            return
        end
    end
    if targeted_path in routes[1].routes
        route!(c, routes[1].routes)
        return
    end
end

function creator_auth(c::Toolips.AbstractConnection)::Bool
    args = get_args(c)
    if :key in keys(args)
        if ~(args[:key] in keys(c[:OliveCore].client_keys))
            write!(c, "bad key.")
            return
        end
        uname = c[:OliveCore].client_keys[args[:key]]
        if ~(get_ip(c) in keys(c[:OliveCore].names))
            push!(c[:OliveCore].names, get_ip(c) => uname)
        end
        return(true)
    end
    # if no key we write the splash
    write!(c, SPLASH)
    return(false)
    # --- currently deactivated
    if ~(get_ip(c) in keys(c[:OliveCore].names))
        identifier = Olive.Toolips.gen_ref(4)
        push!(c[:OliveCore].names, get_ip(c) => identifier)
        push!(c[:OliveCore].client_data, identifier => Dict{String, Vector{String}}(
            "group" => ["all"]))
        return(true)
    end 
end

main = route("/") do c::Toolips.AbstractConnection
    custom_sheet = Olive.olivesheet()
    delete!(custom_sheet[:children], "div.topbar")
    custom_sheet[:children][".material-icons"]["color"] = "white"
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
    making_session = creator_auth(c)
    if ~(making_session)
        return
    end
    Olive.make_session(c, key = false, sheet = custom_sheet, icon = creator_heart)
end

function generate_profile(c::Toolips.AbstractConnection, user::AbstractString)
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

build(c::Connection, cm::OliveModifier, oe::Olive.OliveExtension{:creator}) = begin
 #   progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
  #  remove!(cm, "::-webkit-progress-value")
  #  append!(cm, "olivestyle", progress_sty)
  olive_notify!(cm, "hi")
end

function start(ip::IP4 = "127.0.0.1":8000)
    creator_route = CreatorRoute(copy(Olive.olive_routes))
    Olive.olive_routes = [creator_route]
    creator_route.routes["/"] = main
    assets = mount("/assets" => "creator_assets")
    creator_route.routes = vcat(creator_route.routes, assets)
    Olive.SES.invert_active = true
    Olive.SES.active_routes = vcat(["/MaterialIcons.otf", "/favicon.ico"], [r.path for r in assets])
    Olive.start(ip, path = ".")
end

export evalin
end # module OliveCreator
