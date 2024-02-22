module MergeableStruct

using JLD2
using Glob

export AbstractMergeableStruct
export merge_load

# Extendable struct
abstract type AbstractMergeableStruct end

# Core functions
merge_load(obj::T) where T <: AbstractMergeableStruct = load_it(obj)  # this could redefined to use a cache layer @memoize_typed...


load_it(TYPE, args...; kw_args...) = begin
	obj = TYPE()
	set_config(obj, args...; kw_args...)
	load_it(obj)
end
load_it(obj) = if 0<length((files=find_files(obj);))
	c=JLD2.load("$(find_largest(files))", "cached")
	is_same(c,obj) && return c
	big_obj = need_more_data(obj,c) ? save(merge(data_before(obj,c),c,data_after(c, obj))) : c
	return cut_requested!(obj, big_obj) 
else
	return save(get_data(obj), false)
end
save(obj::T, needclean=true)              where T <: AbstractMergeableStruct = (needclean && clean_files(files_excluded_best(obj)); JLD2.save(persistent_filename(obj), "cached",obj); obj)
merge(before::T,cached::T,after::T)       where T <: AbstractMergeableStruct = concatenate(before,cached,after)
merge(before::Nothing,cached::T,after::T) where T <: AbstractMergeableStruct = append(cached,after)
merge(before::T,cached::T,after::Nothing) where T <: AbstractMergeableStruct = prepend(before,cached)

# utils
strip_jld2(fname::String)          = fname[1:end-5]
clean_files(files::Vector{String}) = rm_if_exist.(files)
rm_if_exist(fname::String)         = isfile(fname) && rm(fname)


# Interfaces
# Optionalble redefineable 
# If you want 1 preallocation and merge all the three there at once
concatenate(before,cache,after) = prepend(before,append(cache,after))
need_more_data(obj,c) = need_data_before(obj,c) || need_data_after(obj,c)
prepend(before::Nothing,cache::T) where T <: AbstractMergeableStruct = cache
prepend(before::T,cache::T)       where T <: AbstractMergeableStruct = append(cache, before)
append(cache::T,after::Nothing)   where T <: AbstractMergeableStruct = cache 


# Recommended to be overloaded
append(cache::T,  after::T) where T <: AbstractMergeableStruct = @assert false "Implement the merging process, how do you concat two $T"

uniquekey(obj::T)           where T <: AbstractMergeableStruct = obj.fr, obj.to, obj.conf 

is_same(o1::T, o2::T)       where T = (throw("Unimplemented is_same(...)"); return o1.config == o2.config && o1.fr == o2.fr && o1.to == o2.to) 

parse_fname(fname::String)          = begin
	tipe, config, fr, to = split(fname,"_")
	return String(tipe), String(config), parse(Int,fr), parse(Int,to)
end
unique_fname(obj)                   = "$(obj.config)_$(obj.fr)_$(obj.to)"
persistent_filename(obj::T) where T = "$(T)_$(unique_fname(obj)).jld2" 
glob_pattern(obj::T)        where T = ("$(T)_$(obj.config)_*_*"*".jld2"; throw("Unimplemented glob_pattern(...)"))
folder(obj)                         = "./"
find_files(obj)                     = glob(glob_pattern(obj), folder(obj))
files_excluded_best(obj)            = (top_idx = TOP1_idx((files=find_files(obj);)); [files[i] for i in 1:length(files) if i !==top_idx])
score(data)                         = begin tipe, config, fr, to = data; return to - fr; end
find_largest(files)                 = files[TOP1_idx((files))]
TOP1_idx(files)                     = argmax(score.(parse_fname.(strip_jld2.(files))))

cut_requested!(obj, big_obj)        = obj.data = big_obj.data[1+obj.fr-big_obj.fr:end-(big_obj.to-obj.to)]


need_data_before(obj,c) = obj.fr < c.fr
need_data_after(obj,c)  = c.to < obj.to
data_before(obj::T, c::T)  where T = need_data_before(obj,c) ? get_data(T, obj.fr, c.fr, obj.config) : nothing
data_after(c::T,  obj::T)  where T = need_data_after(obj,c)  ? get_data(T, c.to, obj.to, obj.config) : nothing

get_data(obj::T)                   where T <: AbstractMergeableStruct = throw("Unimplemented get_data(...), obj.fr, obj.to, obj.conf")
get_data(t::Type{T}, fr, to, conf) where T <: AbstractMergeableStruct = throw("Unimplemented get_data(...), fr, to, conf")




# ADVICE:
# You can do caching on it... So it worth to redefine the "merge_load" too for your type if you can save the configuration somewhere... so no unnecessary recomputation happens
# using MemoizeTyped
# 
# load(obj::T) where T <: AbstractMergeableStruct = @memoize_typed T obj.keyyyss load_it(obj)

end # module MergeableStruct
