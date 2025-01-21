mutable struct UserManager
    names::Vector{String}
    profile_img::Vector{String}
    achievements::Vector{Vector{Int64}}
    fi::Vector{Int64}
    UserManager() = new(Vector{String}(), Vector{String}(), Vector{Int64}(), Vector{Int64}())
end

getindex(um::UserManager, n::Int64) = begin
    return(um.names[n], um.profile_img[n], um.fi[n], um.achievements[n])::Tuple{String, String, Int64, Vector{Int64}}
end

getindex(um::UserManager, name::String) = begin
    position = findfirst(n::String -> n == name, um.names)
    if isnothing(position)
        throw(KeyError(name))
    end
    um[position]::Tuple{String, String, Int64, Vector{Int64}}
end

function append!(um::UserManager, name::String, profile_img::String, fi::Int64, achievements::Int64 ...)
    push!(um.names, name)
    push!(um.profile_img, profile_img)
    push!(um.fi, fi)
    push!(um.achievements, [achievements ...])
end

USERS = UserManager()
append!(USERS, "emmac", "https://avatars.githubusercontent.com/u/52672675?v=4", 1200, 1, 2)

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
