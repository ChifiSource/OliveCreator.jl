function decompress_user_data(name::String)
    if isdir(OliveCreator.USER_DIR * "/$name")
        return
    end
    true
end

function recompress_user_data(name::String; remove::Bool = true)
    if ~(OliveCreator.USER_DIR * "/$name")
        return
    end
end

function create_userdir(name::String)

end

mutable struct CreatorUser
    name::String
    level::Float64
    profile_img::String
    fi::Int64
    achievements::Vector{Int64}
    missions::Dict{Int64, Bool}
    messages::Vector{Pair{String, String}}
end

mutable struct UserManager
    cached::Vector{CreatorUser}
    UserManager() = new(Vector{CreatorUser}())
end

getindex(um::UserManager, name::String) = begin
    found = findfirst(user::CreatorUser -> (user.name == name), um.cached)
    if ~(isnothing(found))
        return(um.cached[name])::CreatorUser
    end
    if ~(isdir(OliveCreator.USER_DIR * "/$name"))
        success = decompress_user_data(name)
        if ~(success)
            return(success)
        end
    end
    user_data = Olive.TOML.parse(read(OliveCreator.USER_DIR * "/$name/creator/info.toml", String))
    x = user_data["messages"]
    n = length(x)
    messages = [x[e] => x[e + 1] for e in range(1, n, step = 2)]
    loaded_user = CreatorUser(name, user_data["level"], user_data["img"], 
        user_data["fi"], user_data["achievements"], user_data["missions"], 
        messages)
    user_data = nothing
    push!(um.cached, loaded_user)
    loaded_user::CreatorUser
end


USERS_CACHE = UserManager()

@warn USERS_CACHE["emmac"]

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
