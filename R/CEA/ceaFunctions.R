### Function definitions ###

# generate input for the SMAA package
getSMAA <- function(scales, alternatives, criteria, iterations,measurements){
  
  SMAAInput <- array(data=(0:0),dim=c(iterations,alternatives,criteria))
  
  for ( j in 1 : alternatives){
    for ( i in 1 : criteria ){
      
      # For measured effect highest is best, for cost lowest is best
      if( i == 1){
        SMAAInput [ , j, i] <- smaa.pvf(measurements[ , j, i],
                                        cutoffs=c(scales[1,i], scales[2,i]),
                                        values=c(0, 1),
                                        outOfBounds="interpolate")
      } else {
        
        SMAAInput [ , j, i] <- smaa.pvf(measurements[ , j, i],
                                        cutoffs=c(scales[2,i], scales[1,i]),
                                        values=c(0, 1),
                                        outOfBounds="interpolate")
      }
    }
  }
  
  SMAAInput
  
}

# generate transition matrix based on dirichlet distribution

distribution.dirichlet <- function(numberOfStates,transitionArray,alternatives,P){

for ( a in 1 : alternatives ){
  X <- matrix(, ncol=numberOfStates, nrow = 0, )
  
  # we draw random input variables using the transitionArray, for each row
  for ( row in 1 : numberOfStates ){
  
    # Matrix which represents transition probabilities for one row
    nextRow <- matrix(, nrow=1, ncol=numberOfStates,)
    
    # add all numbers into a temporary matrix
    dirichletInput <- matrix(, nrow = 1, ncol = 0, )
    
    # iterator is needed to push values of zero into the transition table
    iterator <- 1
    
    for( column in 1 : numberOfStates ) {
      
      # By default Dirichlet does not accept values of zero
      if(transitionArray[row, column, a]==0){
        
        nextRow[1,column] <- transitionArray[row, column, a]
        
      }else{
        
        input <- matrix(transitionArray[row, column, a],nrow=1,ncol=1,)
        dirichletInput <- cbind(dirichletInput,input)
        iterator <- iterator + 1
        
      }
    }
  
    # With all the non zero values, determine a Dirichlet distribution
    dirichlet <- rdirichlet(1, dirichletInput)
    
    # Fill the row that is to be added to the transition matrix
    rowToAdd <- matrix( , nrow = 1, ncol = numberOfStates, )
    iterator2 <- 1
    for( i in 1 : numberOfStates ){
      if( is.na(nextRow[1,i]) ){
        rowToAdd[1,i] <- dirichlet[1,iterator2]
        iterator2 <- iterator2 + 1
      } else{
        rowToAdd[1,i] <- 0 
      }
    }
  
    X<- rbind(X, rowToAdd)

    }
  
  # Fill the transition matrix P
  P <- abind( P, X, along=3 )
  
  }

P

}

# criteria = measured effect and cost
scaleRange <- function(SMAAInput,alternatives,criteria) {
  low <- rep(Inf,criteria)
  high <- rep(-Inf,criteria)
  for (i in 1:alternatives) {
    for (j in 1:criteria) {
      low[j] <- min(low[j],min(SMAAInput[,,j]))
      high[j] <- max(high[j],max(SMAAInput[,,j]))
    }
  }
  rbind(low,high)
}

# Gerneate weight for current lambda
weightCon <- function(lambda,scales) {
  w.1 <- lambda*(scales[2,1]-scales[1,1])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  w.2 <- (scales[2,2] - scales[1,2])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  c(w.1,w.2)
} 