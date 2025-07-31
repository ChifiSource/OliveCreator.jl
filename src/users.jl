function decompress_user_data(name::String)
    user_directory = OliveCreator.USER_DIR * "/$name"
    if isdir(user_directory)
        true
    else
        mkdir(user_directory)
    end
    zip_uri = OliveCreator.ZIP_DIR * "/$name.zip"
    zip_reader = ZipFile.Reader(zip_uri)
    for file in zip_reader.files
        fname = file.name
        dirs = split(replace(fname, OliveCreator.USER_DIR => ""), "/")
        if length(dirs) > 2
            current_dir = user_directory
            for dir in dirs[2:end - 1]
                current_dir = current_dir * "/$dir"
                if ~(isdir(current_dir))
                 mkdir(current_dir)
                 @info current_dir
                end
            end
        end
        f_uri = OliveCreator.USER_DIR * "/" * file.name
        touch(f_uri)
        open(f_uri, "w") do o
            write(o, read(file, String))
        end
    end
    close(zip_reader)
    true
end

function recompress_user_data(name::String; remove::Bool = true)
    user_directory = OliveCreator.USER_DIR * "/$name"
    if ~(isdir(user_directory))
        return(true)
    end
    zip_uri = OliveCreator.ZIP_DIR * "/$name.zip"
    if ~(isfile(zip_uri))
        touch(zip_uri)
    end
    zip_writer = ZipFile.Writer(zip_uri)
    for uri in Toolips.route_from_dir(user_directory)
        zip_uri = replace(uri, "users/" => "")
        file = ZipFile.addfile(zip_writer, zip_uri)
        write(file, read(uri, String))
        close(file)
    end
    close(zip_writer)
    if remove
        rm("users/$name", recursive = true)
    end
    return(true)
end

function create_userdir(name::String)

end

mutable struct CreatorUser
    name::String
    level::Float64
    profile_img::String
    fi::Int64
    memlimit::Float64
    spclimit::Float64
    projlimit::Int64
end

mutable struct UserManager
    cached::Vector{CreatorUser}
    UserManager() = new(Vector{CreatorUser}())
end

getindex(um::UserManager, name::String) = begin
    found = findfirst(user::CreatorUser -> (user.name == name), um.cached)
    if ~(isnothing(found))
        return(um.cached[found])::CreatorUser
    end
    if ~(isdir(OliveCreator.USER_DIR * "/$name"))
        success = decompress_user_data(name)
        if ~(success)
            return(success)
        end
    end
    user_data = Olive.TOML.parse(read(OliveCreator.USER_DIR * "/$name/creator/settings.toml", String))
    loaded_user = CreatorUser(name, 0.0, user_data["img"], 
        0, 0.0, 0.0, 1)
    
    orm = OliveCreator.ORM_EXTENSION
    user_tablei = query(Int64, orm, "index", "users/name", name)
    usrinfo = query(Vector{String}, orm, "getrow", "users", user_tablei)
    colorder = OliveCreator.ORM_COLUMN_ORDER
    fipos = findfirst(x -> x == "fi", colorder)
    levelpos = findfirst(x -> x == "level", colorder)
    loaded_user.fi = parse(Int64, usrinfo[fipos])
    loaded_user.level = parse(Float64, usrinfo[levelpos])
    # TODO orm load creator data (memlimit, spclimit, projlimit) from creator table.
    user_data = nothing
    push!(um.cached, loaded_user)
    loaded_user::CreatorUser
end

USERS_CACHE = UserManager()

struct Achievement
    fi::Int64
    name::String
    img::String
    desc::String
end

function read_achievements()
    raw::String = read("olive/achievements.txt", String)
    [begin
        splits = split(achievement_str, "|")
        Achievement(parse(Int64, splits[1]), string(splits[2]), string(splits[3]), splits[4])
    end for achievement_str in split(raw, "\n")]::Vector{Achievement}
end

ACHIEVEMENTS = read_achievements()
