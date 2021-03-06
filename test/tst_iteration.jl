
using StochasticOptimization.Iteration

@testset "Data Iteration" begin
    n = 4
    X = rand(2,n)
    y = rand(n)

    # nobs/getobs of arrays
    @test nobs(X) == n
    @test nobs(y) == n
    @test getobs(X, 1) == X[:,1]
    @test getobs(y, 1) == y[1]
    @test getobs(X, 1:2) == X[:, 1:2]
    @test getobs(y, 1:2) == y[1:2]

    # -----------------------------------------------
    # ObsIterator

    # construction
    itr = each_obs(X, y)
    @test typeof(itr) <: EachObs{Tuple{Matrix{Float64},Vector{Float64}}}
    @test length(itr) == n
    # @test itr.indices == 1:n
    @test itr.source == (X,y)
    @test nobs(itr) == n

    # iterating... sort of
    o1, o2, o3, o4 = itr
    @test o2 == (X[:,2], y[2])

    # random obs
    (x1,x2),yi = rand(itr)
    @test x1 in X
    @test x2 in X
    @test yi in y

    # random arrays
    xs,ys = rand(itr, 2)
    @test size(xs) == (2,2)
    @test size(ys) == (2,)

    # getindex
    for i=1:n
        @test itr[i] == (X[:,i], y[i])
    end

    # iteration
    for (i,(x,yi)) in enumerate(itr)
        @test x == X[:,i]
        @test yi == y[i]
    end

    # extraction
    rng = 2:3
    itr2 = subset_obs((X, y), rng)
    S,T,I = typeof(itr2).parameters
    @test S <: Tuple
    @test S.parameters[1] <: Matrix
    @test S.parameters[2] <: Vector
    @test T <: Tuple
    @test T.parameters[1] <: SubArray
    @test T.parameters[2] == Float64
    @test T == typeof(getobs((X,y), 1))
    @test I == typeof(rng)

    cx, cy = collect(itr2)
    @test typeof(cx) <: Matrix
    @test cx == X[:,rng]
    @test typeof(cy) <: Vector
    @test cy == y[rng]
    for (i,obs) in enumerate(itr2)
        @test obs == getobs((X,y), rng[i])
    end

    # shuffling
    ss = shuffled_obs(X,y)
    @test length(ss.indices) == n

    # filtering
    fitr = filtered_obs(i -> i%2==0, X, y)
    @test typeof(fitr) <: SubsetObs
    newx,newy = collect(fitr)
    @test newx == X[:,2:2:n]
    @test newy == y[2:2:n]

    # infinite nothing
    itr3 = infinite_obs(nothing)
    S,T = typeof(itr3).parameters
    @test S == Void
    @test T == Void
    for (i,v) in enumerate(itr3)
        @test v == nothing
        i > 3 && break
    end


    # -----------------------------------------------
    # BatchIterator

    # test/train split
    train, test = split_obs(X,y,at=0.5)
    @test typeof(train) <: SubsetObs
    @test typeof(test) <: SubsetObs
    rng = 1:2
    @test train.indices == rng
    @test get(train) == (view(X,:,rng), view(y,rng))
    @test nobs(train) == 2
    @test nobs(test) == 2

    # train/validate/test split
    X = rand(2,10)
    y = rand(10)
    bs = split_obs(X,y,at=(0.5,0.2))
    @test typeof(bs) <: Batches
    train, validate, test = bs
    @test nobs(train) == 5
    @test nobs(validate) == 2
    @test nobs(test) == 3
    @test train.indices == 1:5
    @test validate.indices == 6:7
    @test test.indices == 8:10

    # minibatch split
    bs = each_batch(X,y,size=2)
    @test typeof(bs) <: EachBatch
    @test length(bs) == 5
    for b in bs
        # @show x yi
        @test typeof(b) <: SubsetObs
        x, yi = get(b)
        @test typeof(x) <: SubArray
        @test typeof(yi) <: SubArray
        @test size(x) == (2,2)
        @test length(yi) == 2
        for (xj,yj) in each_obs(x,yi)
            # just to make sure there's no errors in nesting...
        end
    end

    # infinite_batches
    ibs = infinite_batches(X,y,size=2)
    for (i,batch) in enumerate(ibs)
        @test typeof(batch) <: SubsetObs
        @test length(batch) == 2
        i > 4 && break
    end


    # # -----------------------------------------------
    # # BatchesIterator
    #
    # # kfolds
    # kf = kfolds(X, y)
    # @test typeof(kf) <: KFolds
    # @test kf.k == 5
    # @test StochasticOptimization.start_index(kf, 2) == 3
    # @test StochasticOptimization.end_index(kf, 2) == 4
    # i = 0
    # for (train, test) in kf
    #     i += 1
    #     # @show typeof(train) typeof(test)
    #     @test typeof(train) <: Tuple
    #     @test typeof(test) <: Tuple
    #     @test train == getobs((X,y), setdiff(1:10, 2i-1:2i))
    #     @test test == getobs((X,y), 2i-1:2i)
    #     @test nobs(train) == 8
    #     @test nobs(test) == 2
    # end
    # @test i == kf.k
    #
    # loo = leave_one_out(y)
    # @test typeof(loo) <: KFolds
    # @test loo.k == nobs(X)
    # for (train,test) in loo
    #     @test nobs(train) == 9
    #     @test nobs(test) == 1
    # end


end
