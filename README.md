# MergeableStruct.jl
Persisting extendable structure for storing data. So we only load the NEW data and we persist the loaded new data. 


So...
If you are storing queries... so you request the data from TimeStamp to Timestamp. And on new interval you don't just redownload the whole datasize. You just download the "new" data and *merge* into the existing data that is persisted on the disk. 

Key: You shouldn't request the same frames multiple time. 

This pkg is to provide an interface that help to build a dataset to work this way.


So you extend some functions and you dataset will be *extendable* 

Example:
#  an exmpla struct that will be working out of the box with minor extension of the core interface
```julia
using MergeableStruct

mutable struct BasicExample <: AbstractMergeableStruct
	config::String
	fr::Int
	to::Int
	data::Vector{Float32}
end
BasicExample()=BasicExample("test",20,30,Float32[])

MergeableStruct.glob_pattern(obj::BasicExample) = "BasicExample_$(obj.config)_*_*"*".jld2"
MergeableStruct.get_data(obj::BasicExample)     = begin
	obj.data=randn(Float32,obj.to-obj.fr)
	obj
end
MergeableStruct.get_data(T::Type{BasicExample}, fr, to, conf) = T(conf,fr,to,randn(Float32,to-fr))
MergeableStruct.append(cache::BasicExample,  after::BasicExample) = BasicExample(cache.config, cache.fr, after.to, vcat(cache.data,after.data)) 
MergeableStruct.prepend(before::BasicExample,cache::BasicExample) = BasicExample(cache.config, before.fr, cache.to, vcat(before.data,cache.data)) 
MergeableStruct.is_same(o1::BasicExample, o2::BasicExample) = return o1.config == o2.config && o1.fr == o2.fr && o1.to == o2.to


merge_load(BasicExample("test",3,53,Float32[]))
```

# Note
It is really adviced to use this package with https://github.com/Cvikli/MemoizeTyped.jl 
So you can use the `load` function you want but it won't load the data multiple times just reuse from cache. 

I am still trying to figure out what is the best pattern to do this that match for everyone usecase. It is not 100% trivial. So maybe there should be multiple way to do it later on. 

Contributions and tips are welcomed! 


Maybe more accurate name could have been: `ExtendableStruct`, `ExtendableData`, these maybe better picks... later we can rename. 