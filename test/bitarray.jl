# Testing range indexing
B = BitArray(150)
for rstart=1:66, rstop=rstart:130
    fill!(B, false)
    B[rstart:rstop] = true
    @test all(B[1:rstart-1]   .== false)
    @test all(B[rstart:rstop] .== true)
    @test all(B[rstop+1:end]  .== false)
    
    fill!(B, true)
    B[rstart:rstop] = false
    @test all(B[1:rstart-1]   .== true)
    @test all(B[rstart:rstop] .== false)
    @test all(B[rstop+1:end]  .== true)
    
    fill!(B, false)
    B[rstart:rstop] = false
    @test all(B[1:rstart-1]   .== false)
    @test all(B[rstart:rstop] .== false)
    @test all(B[rstop+1:end]  .== false)
    
    fill!(B, true)
    B[rstart:rstop] = true
    @test all(B[1:rstart-1]   .== true)
    @test all(B[rstart:rstop] .== true)
    @test all(B[rstop+1:end]  .== true)
end
