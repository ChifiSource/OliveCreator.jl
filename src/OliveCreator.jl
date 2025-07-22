module OliveCreator
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
import Olive: build, evalin, Cell, Project, ComponentModifier, getname, build_base_cell, olive_notify!, OliveExtension
import Olive: on_code_evaluate, cell_bind!
import Base: getindex, delete!, append!
import Toolips: route!, router_name
include("users.jl")
include("profiles.jl")
include("splash.jl")
include("limiter.jl")

# Base users
DB_INFO = ("", "", "")

USRCACHE = Dict{String, String}()

abstract type CreatorCentralRoute <: Toolips.AbstractHTTPRoute end

router_name(T::Type{<:CreatorCentralRoute}) = "olive creator custom router"

mutable struct CreatorRoute <: CreatorCentralRoute
    path::String
    routes::Vector{AbstractRoute}
    CreatorRoute(routes::Vector) = new("/", routes)
end

function confirm_user_pwd()

end

function get_user(name::String)

end

route!(c::AbstractConnection, routes::Vector{<:CreatorCentralRoute}) = begin
    targeted_path::String = get_route(c)
    if length(targeted_path) > 1
        if targeted_path[1:2] == "/@"
            session_key = Olive.get_session_key(c)
            new_data = Dict{String, Any}("group" => "guest")
            newuser = Olive.OliveUser{:guest}("guest", session_key, Olive.Environment("guest"), new_data)
            Olive.init_user(newuser)
            push!(Olive.CORE.users, newuser)
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
    @warn "performed creator auth"
    in_users = ~(isnothing(findfirst(usr -> usr.key == session_key, CORE.users)))
    @info in_users
    @warn session_key
    if in_users
        return(true)
    elseif haskey(USRCACHE, session_key)
       
    else
        write!(c, SPLASH)
        return(false)
    end
    return
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
    read_in_cells = Olive.IPyCells.read_jl("users/$user/profile/profile.jl")
    project_data = Dict{Symbol, Any}(:cells => Vector{Olive.Cell}([
            Olive.Cell{:profileheader}(""), read_in_cells ...
        ]), :pane => "one", :wd => "nothing", :uname => user)
    Olive.CORE.users[name].environment.projects = Vector{Olive.Project}([Olive.Project{:profile}("@$user", project_data)])
    Olive.make_session(c, key = false)
end

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
