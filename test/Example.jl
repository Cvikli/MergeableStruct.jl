
using RelevanceStacktrace
using Revise
using MergeableStruct

#  an exmpla struct that will be working out of the box with minor extension of the core interface
mutable struct BasicExample <: AbstractMergeableStruct
	config::String
	fr::Int
	to::Int
	data::Vector{Float32}
end
BasicExample()=BasicExample("test",20,30,Float32[])

MergeableStruct.isempty(obj::BasicExample)      = isempty(obj.data)
MergeableStruct.glob_pattern(obj::BasicExample) = "BasicExample_$(obj.config)_*_*"*".jld2"
MergeableStruct.get_data(obj::BasicExample)     = begin
	obj.data=randn(Float32,obj.to-obj.fr)
	obj
end
MergeableStruct.get_data(T::Type{BasicExample}, fr, to, conf) = T(conf,fr,to,randn(Float32,to-fr))
MergeableStruct.append(cache::BasicExample,  after::BasicExample) = BasicExample(cache.config, cache.fr, after.to, vcat(cache.data,after.data)) 
MergeableStruct.prepend(before::BasicExample,cache::BasicExample) = BasicExample(cache.config, before.fr, cache.to, vcat(before.data,cache.data)) 
MergeableStruct.is_same(o1::BasicExample, o2::BasicExample) = return o1.config == o2.config && o1.fr == o2.fr && o1.to == o2.to


dd = merge_load(BasicExample("test",3,53,Float32[]))

# @mergeable_load BasicExample("test",30,40,Float32[])
#%%
dd.fr,
dd.to,
size(dd.data)
