module OliveCreator
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
using ToolipsORM
import Olive: build, evalin, Cell, Project, ComponentModifier, getname, build_base_cell, olive_notify!, OliveExtension
import Olive: on_code_evaluate, cell_bind!
import Base: getindex, delete!, append!
import Toolips: route!, router_name
include("users.jl")
include("profiles.jl")
include("splash.jl")
include("limiter.jl")

ZIP_DIR::String = ""

GUESTN::UInt32 = UInt32(0)
# Base users
DB_INFO = ("":8000, "name", "pwd", "key")

USRCACHE = Dict{String, String}()

abstract type CreatorCentralRoute <: Toolips.AbstractHTTPRoute end

router_name(T::Type{<:CreatorCentralRoute}) = "olive creator custom router"

mutable struct CreatorRoute <: CreatorCentralRoute
    path::String
    routes::Vector{AbstractRoute}
    CreatorRoute(routes::Vector) = new("/", routes)
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
    CORE = Olive.CORE
    args = get_args(c)
    session_key = Olive.get_session_key(c)
    user_index = findfirst(usr -> usr.key == session_key, CORE.users)
    in_users = ~(isnothing(user_index))
    if in_users
        return(true)
    elseif haskey(USRCACHE, session_key)
       load_client!(olive.CORE, USRCACHE[session_key], session_key)
       return(true)
    elseif get_route(c) == "/"
        write!(c, SPLASH)
        return(false)
    else
        session_key = Olive.get_session_key(c)
        new_data = Dict{String, Any}("group" => "guest")
        newuser = Olive.OliveUser{:guest}("guest$(OliveCreator.GUESTN)", session_key, Olive.Environment("guest"), new_data)
        Olive.init_user(newuser)
        OliveCreator.GUESTN += 1
        push!(Olive.CORE.users, newuser)
        return(true)
    end
end

function login_user(c::AbstractConnection, orm::ToolipsORM.ORM, session_key::String, 
        name::String, pwd::String)
    user_tablei = query(Int64, orm, "index", "users/name", name)
    if user_tablei == 0
        return("username $name does not exist")
    end
    correct_pwd = query(Bool, orm, "compare", "users/password", user_tablei, pwd)
    if ~(correct_pwd)
        return("incorrect password")
    end
    session_key = get_session_key(c)
    load_client!(Olive.CORE, name, session_key)
    nothing::Nothing
end

function decompress_user_data(name::String)
    if isdir("users/$name")
        return
    end
end

function recompress_user_data(name::String)
    if ~(isdir("users/$name"))
        return
    end
end

function load_client!(core::Olive.OliveCore, client_name::String, key::String)
    found = findfirst(user -> user.name == client_name, core.users)
    if ~(isnothing(found))
        user = core.users[found]
        user.key = key
        return
    end
    decompress_user_data(name)
    push!(USRCACHE, session_key => name)
end

function unload_client!(core::Olive.OliveCore, client_name::String)
    
end

custom_sheet = begin 
    custom_sheet = Olive.olivesheet()
    stys = custom_sheet[:children]
    delete!(stys, "div.topbar")
    stys[".material-icons"]["color"] = "#171717"
    new_topbars = style("div.topbar", 
    "border-radius" => "5px", "background-color" => "#f197b0", "transition" => 500ms)
    stys["body"]["background-color"] = "#171717"
    progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
    stys["a.tablabel"]["color"] = "#171717"
    stys["div.tabopen"]["background-color"] = "#e77254"
    style!(stys["div.projectwindow"], "background-color" => "#2e2e2e")
    push!(custom_sheet, new_topbars)
    custom_sheet
end

creator_heart = begin
    heart_path = Component{:path}("creatorload", fill = "pink", class = "heart",
    d = "M200 251.67l-2.053-1.67c-44.96-36.62-57.136-49.51-57.136-70.45 0-17.213 14.01-31.22 31.224-31.22 14.386 0 22.518 8.17 27.97 14.315 5.448-6.146 13.58-14.315 27.968-14.315 17.215 0 31.22 14.007 31.22 31.22 0 20.94-12.175 33.83-57.134 70.45L200 251.67z")
    heart_sty = style(".heart", "stroke" => "#444", "stroke-width" => 7px, "animation" => "pulse 800ms linear infinite")
    push!(custom_sheet, progress_sty, heart_sty)
    creator_heart = svg("olive-loader", width = 500, height = 500, children = [heart_path])
end

main = route("/") do c::Toolips.AbstractConnection
    making_session = creator_auth(c)
    if ~(making_session)
        return
    end
    Olive.make_session(c, key = false, sheet = custom_sheet, icon = creator_heart)
end

isguest(name::String) = length(name) > 4 && name[1:5] == "guest"

build(c::Connection, cm::ComponentModifier, oe::Olive.OliveExtension{:creator}) = begin
 #   progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
  #  remove!(cm, "::-webkit-progress-value")
  #  append!(cm, "olivestyle", progress_sty)
  olive_notify!(cm, "hi")
end

function start(ip::IP4 = "127.0.0.1":8000)
    creator_route = CreatorRoute(copy(Olive.olive_routes))
    creator_route.routes["/"] = main
    Olive.olive_routes = [creator_route]
    push!(creator_route.routes, Olive.key_route)
    assets = mount("/assets" => "creator_assets")
    creator_route.routes = vcat(creator_route.routes, assets)
    Olive.SES.invert_active = true
    Olive.SES.active_routes = vcat(["/MaterialIcons.otf", "/favicon.ico"], [r.path for r in assets])
    Olive.start(ip, path = ".")
end

export evalin
end # module OliveCreator
