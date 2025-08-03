module OliveCreator
using Olive
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession
using Olive.OliveHighlighters
using ToolipsORM
import Olive: build, evalin, Cell, Project, ComponentModifier, getname, build_base_cell, olive_notify!, OliveExtension
import Olive: on_code_evaluate, cell_bind!, get_session_key, cell_highlight!
import Base: getindex, delete!, append!
import Toolips: route!, router_name
using ZipFile

# globals
DB_INFO = ("":8000, "name", "pwd", "key")
ORM_EXTENSION = ToolipsORM.ORM(ToolipsORM.ChiDBDriver, DB_INFO[1], DB_INFO[2:end] ...)
USER_DIR = "users"
KEY_CACHE = Dict{String, String}()
ORM_COLUMN_ORDER = String[]
ALPHA_KEYS = Bool[]
ZIP_DIR::String = "zips"
GUESTN::UInt32 = UInt32(0)

include("users.jl")
include("oliveposts.jl")
function set_orm_order!(orm::ToolipsORM.ORM{<:Any})
    vals = query(Vector{String}, orm, "columns", "users")
    OliveCreator.ORM_COLUMN_ORDER = [replace(val, "\n" => "") for val in vals]
end

# routing and auth

abstract type CreatorCentralRoute <: Toolips.AbstractHTTPRoute end

router_name(T::Type{<:CreatorCentralRoute}) = "olive creator custom router"

mutable struct CreatorRoute <: CreatorCentralRoute
    path::String
    routes::Vector{AbstractRoute}
    CreatorRoute(routes::Vector) = new("/", routes)
end

route!(c::AbstractConnection, routes::Vector{<:CreatorCentralRoute}) = begin
    targeted_path::String = get_route(c)
    if targeted_path != "/" && targeted_path in routes[1].routes
        route!(c, routes[1].routes)
        return
    end
    served_splash = creator_auth(c, targeted_path)
    if served_splash
        return
    end
    user = Olive.CORE.users[getname(c)]
    is_a_guest = isguest(user)
    if targeted_path == "/"
        perform_envcheck(user, is_a_guest)
        Olive.make_session(c, key = false, sheet = custom_sheet, settings_enabled = false)
        return
    end
    n = length(targeted_path)
    if n > 3
        if targeted_path[1:2] == "/@"
            generate_profile(c, targeted_path[3:end])
            # load_profile_project(user, targeted_path[3:end])
        end
    end
    if contains(targeted_path, "/user-content/") && targeted_path[1:14] == "/user-content/"
        serve_user_content(user, replace(targeted_path, "/user-content/" => ""))
    end
    perform_envcheck(user, is_a_guest)
    Olive.make_session(c, key = false, sheet = custom_sheet, settings_enabled = false)
end

function perform_envcheck(user::Olive.OliveUser, is_a_guest::Bool)
    nodirs = length(user.environment.directories) == 0
    if environment_empty(user)
        if is_a_guest
            load_guest_environment!(user)
        else
            load_feed_environment!(user)
        end
    elseif nodirs
        if is_a_guest
            load_guest_directories!(user)
        else
            load_user_directories!(user)
        end
    end
end

function add_as_guest(c::AbstractConnection)
    session_key = Olive.get_session_key(c)
    new_data = Olive.TOML.parse(read("olive/default_settings.toml", String))
    new_data["group"] = "guest"
    newuser = Olive.OliveUser{:olive}("guest$(OliveCreator.GUESTN)", session_key, Olive.Environment("olive"), new_data)
    Olive.init_user(newuser)
    OliveCreator.GUESTN += 1
    push!(Olive.CORE.users, newuser)
end

environment_empty(user::Olive.OliveUser) = length(user.environment.projects) == 0 && length(user.environment.directories) == 0

function load_guest_environment!(user::Olive.OliveUser)

end

function load_guest_directories!(user::Olive.OliveUser)

end

function load_user_directories!(user::Olive.OliveUser)
    creator_dir = Olive.Directory("users/$(user.name)/wd", dirtype = "creatorcloud")
    push!(user.environment.directories, creator_dir)
end

function load_feed_environment!(user::Olive.OliveUser)
    feedproj = Olive.Project{:feed}("feed")
    feedproj.data[:cells] = [Cell{:newpost}(), Cell{:feed}()]
    push!(user.environment.projects, feedproj)
    load_user_directories!(user)
    nothing::Nothing
end

function creator_auth(c::Toolips.AbstractConnection, targeted_path::String = "/")::Bool
    CORE = Olive.CORE
    session_key = Olive.get_session_key(c)
    user_index = findfirst(usr -> usr.key == session_key, CORE.users)
    in_users = ~(isnothing(user_index))
    if in_users
        return(false)
    elseif haskey(KEY_CACHE, session_key)
       load_client!(olive.CORE, KEY_CACHE[session_key], session_key)
       return(false)
    elseif targeted_path == "/"
        splash_cop = copy(SPLASH)
        push!(splash_cop, build_main_box(c))
        write!(c, splash_cop)
        return(true)
    else
        add_as_guest(c)
        return(false)
    end
end

function login_user(c::AbstractConnection, orm::ToolipsORM.ORM, 
        name::String, pwd::String)
    user_tablei = query(Int64, orm, "index", "users/name", name)
    if user_tablei == 0
        return("username $name does not exist")
    end
    correct_pwd = query(Bool, orm, "compare", "users/password", user_tablei, pwd)
    if ~(correct_pwd)
        return("incorrect password")
    end
    nothing::Nothing
end

function create_new_user(c::AbstractConnection, orm::ToolipsORM.ORM, 
    name::String, email::String, pwd::String)
    data = Dict("name" => name, "mail" => email, "fi" => 0, "level" => 0, 
        "password" => pwd, "confirmed" => false)
    args = [data[key] for key in ORM_COLUMN_ORDER]
    query(String, orm, "store", "users", args)
    create_default_userdata(c, name)
    recompress_user_data(name, remove = false)
end

function create_default_userdata(c::AbstractConnection, name::String)
    base_userdir = OliveCreator.USER_DIR * "/$name"
    mkdir(base_userdir)
    mkdir(base_userdir * "/profile")
    mkdir(base_userdir * "/wd")
    mkdir(base_userdir * "/creator")
    cp("olive/default_settings.toml", base_userdir * "/creator/settings.toml")
    profdir = base_userdir * "/profile/profile.jl"
    touch(profdir)
    open(profdir, "w") do o::IO
        write(o, 
        """welcome to my new profile!
#==output[blurb]
false


==#
#==|||==#""")
    end
end

function load_client!(core::Olive.OliveCore, client_name::String, key::String)
    found = findfirst(user -> user.name == client_name, core.users)
    found_value = ~(isnothing(found))
    found_dir = client_name in readdir(OliveCreator.USER_DIR)
    if found_value && found_dir
        user = core.users[found]
        if ~(haskey(user.data, "achievements"))
            data = Olive.TOML.parse(read(OliveCreator.USER_DIR * "/$client_name/creator/settings.toml", String))
            core.users[found] = Olive.OliveUser{:olive}(client_name, key, Olive.Environment("olive"), data)
            user = core.users[found]
            Olive.init_user(user)
            user.environment.pwd = USER_DIR * "/$client_name/wd"
        end
        if ~(haskey(OliveCreator.KEY_CACHE, key))
            push!(OliveCreator.KEY_CACHE, key => client_name)
        else
            OliveCreator.KEY_CACHE[key] = client_name
        end
        user.key = key
        return
    end
    decompress_user_data(client_name)
    if found_value
        return
    end
    data = Olive.TOML.parse(read("users/$client_name/creator/settings.toml", String))
    new_user = Olive.OliveUser{:olive}(client_name, key, Olive.Environment("olive"), data)
    new_user.environment.pwd = "users/$client_name/wd"
    push!(core.users, new_user)
    Olive.init_user(new_user)
    push!(KEY_CACHE, key => client_name)
    nothing::Nothing
end

function unload_client!(core::Olive.OliveCore, client_name::String)
    if isdir("users/$client_name")
        client_settings = deepcopy(CORE.users[name].data)
        [onsave(client_settings, OliveExtension{m.sig.parameters[3].parameters[1]}()) for m in methods(onsave, [AbstractDict, OliveExtension{<:Any}])]
        open("users/$client_name/settings.toml", "w") do io
            TOML.print(io, client_settings)
        end
        recompress_user_data(client_name)
    end
    found_position = findfirst(user -> user.name == client_name, core.users)
    if isnothing(found_position)
        return
    end
    deleteat!(CORE.users, found_position)
end

custom_sheet = begin 
    custom_sheet = Olive.olivesheet()
    stys = custom_sheet[:children]
    push!(stys, Style("a.loginpres", "color" => "#ffefdb", "font-size" => 16pt, 
    "margin-top" => .5percent))
    push!(stys, Style("@font-face", "font-family" => "'password'", "src" => "url('/assets/password.ttf') format('truetype')", 
    "font-weight" => "normal", "font-style" => "normal"))
    delete!(stys, "div.topbar")
    stys["h5"]["color"] = "#1e1e1e"
    style!(stys["h5"], "font-size" => 20pt)
    buttons = stys["button"]
    buttons["border-radius"] = 4px
    buttons["border"] = "2px solid #3D3D3D"
    stys[".material-icons"]["color"] = "#171717"
    push!(stys, buttons[:extras] ...)
    delete!(buttons.properties, :extras)
    banim = keyframes("banim")
     keyframes!(banim, 0percent, "color" => "#7bd63e", "background-color" => "707eb8")
    keyframes!(banim, 20percent, "color" => "#4f73c9", "background-color" => "#80ffa2")
    keyframes!(banim, 40percent, "color" => "#d6943e", "background-color" => "#bc6ec2")
    keyframes!(banim, 60percent, "color" => "#d6553e", "background-color" => "#cfd63e")
    keyframes!(banim, 80percent, "color" => "#833ed6", "background-color" => "#3ed6b0")
    keyframes!(banim, 100percent, "color" => "#7bd63e", "background-color" => "#707eb8")
    push!(stys, banim)
    new_topbars = style("div.topbar", 
        "border-radius" => "5px", "background-color" => "#f197b0", "transition" => 500ms)
    stys["body"]["background-color"] = "#171717"
    style!(stys["button"], "margin-right" => 2px, "font-size" => 15pt, "cursor" => "pointer", 
        "padding" => 1.25percent, "color" => "#562d57", "font-weight" => "bold")
    progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6", "cursor" => "pointer")
    stys["p"]["color"] = "#ffebcd"
    push!(stys, style("body", "color" => "white"))
    inp_cell = stys["div.input_cell"]
    style!(inp_cell, "color" => "#3d3d3d", "background-color" => "#3d3d3d")
    standard_inp = style("div.stdinp", "background-color" => "#1e1e1e", "border-radius" => 4px, "padding" => 1.25percent, 
        "color" => "white", "font-size" => 15pt)
    push!(stys, standard_inp)
    stys["a.tablabel"]["color"] = "#171717"
    stys["div.tabopen"]["background-color"] = "#e77254"
    style!(stys["div.projectwindow"], "background-color" => "#2e2e2e", "border-radius" => 0px)
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

isguest(user::Olive.OliveUser) = user["group"] == "guest"
isguest(name::String) = Olive.CORE.users[name]["group"] == "guest"

build(c::Connection, cm::ComponentModifier, oe::Olive.OliveExtension{:creator}) = begin
 #   progress_sty = style("::-webkit-progress-value", "background" => "#D36CB6")
  #  remove!(cm, "::-webkit-progress-value")
  #  append!(cm, "olivestyle", progress_sty)
  olive_notify!(cm, "hi")
end

include("profiles.jl")
include("splash.jl")
include("limiter.jl")

function start(ip::IP4 = "127.0.0.1":8000, threads::Int64 = 1)
    OliveCreator.SPLASH = build_splash()
    OliveCreator.ORM_EXTENSION = ToolipsORM.ORM(ToolipsORM.ChiDBDriver, DB_INFO[1], DB_INFO[2:end] ...)
    orm = OliveCreator.ORM_EXTENSION
    try
        connect!(orm)
    catch
        throw("""failed to connect to database server, make sure it is running, firewall is not in the way, and 
            OliveCreator.DB_INFO is set to the proper DB_INFO.""")
    end
    set_orm_order!(orm)
    OliveCreator.ALPHA_KEYS = query(Vector{Bool}, OliveCreator.ORM_EXTENSION, "get", "creatorkeys/used")
    creator_route = CreatorRoute(Olive.olive_routes)
    delete!(creator_route.routes, "/")
    Olive.olive_routes = [creator_route]
    push!(creator_route.routes, Olive.key_route)
    assets = mount("/assets" => "creator_assets")
    creator_route.routes = vcat(creator_route.routes, assets)
    Olive.SES.invert_active = true
    Olive.SES.active_routes = vcat(["/MaterialIcons.otf", "/favicon.ico"], [r.path for r in assets])
    EVENTS = copy(Olive.SES.events)
    Olive.start(ip, path = ".", user_threads = 1, threads = threads)
    SES.events = EVENTS
    nothing
end



export evalin
end # module OliveCreator
