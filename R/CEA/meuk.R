# Require: smaa, DirichletReg, abind, RJSONIO
require ('DirichletReg')

input <- fromJSON(file('simple.json'))

# Amount of states
numberOfStates <- length(input$states)

print(numberOfStates)


# and costs assosciated with each state
stateCosts <-  matrix(, nrow=1, ncol=numberOfStates, byrow=T)

for (i in 1:numberOfStates){
  blaat <- input$states[[i]]$statecost
  stateCosts[,i] <- blaat
}


#measured effect
measuredEffect <- matrix(, nrow=1, ncol=numberOfStates, byrow=T)

for (i in 1:numberOfStates){
  blaat <- input$states[[i]]$measuredeffect
  measuredEffect[,i] <- blaat
}

print(measuredEffect)

# Number of alternatives
alternatives <- length(input$alternatives)

input <- fromJSON(file('simple2.json'))

# All the beta values for transition states
transitionInput <- array(, dim=c(numberOfStates,numberOfStates,alternatives) )

for (i in 1:length(input$alternatives)){
  blaat <- matrix(unlist(input$alternatives[[i]]$transition), ncol=numberOfStates, byrow=TRUE)
  transitionInput[,,i] <- blaat
}

# Start with empty transition matrix
P <- array(,dim=c(alternatives, numberOfStates, 0))
# Fill transition matrix for this iteration
print("calling Dirichlet")
P <- distribution.dirichlet(numberOfStates,transitionInput,alternatives,P)
print(P)
print("done calling Dirichlet")

p1 <- t(P[,,1])
print(p1)


print(bla)

for (i in 1:3){
  if (i == 1){
    bla <- matrix(c(500,0,0),nrow=alternatives, ncol=1, byrow=TRUE)
  } else {
    bla <- joehoe
  }
  joehoe <- p1 %*% bla
  
  measuredEffect <- matrix(c(1,0.5,0),nrow=alternatives, ncol=1, byrow=TRUE)
  
  # Determine the effects from each state
  effects <- apply(measuredEffect,1,function(x) x / ( ( 1.06 ) ^ i) )
  
  print("effects")
  print(effects)
  
  calc <- effects * joehoe
  
  print("calc")
  print(calc)
  
  print("joehoe")
  print(joehoe)
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
      dirichlet <- rdirichlet(1, dirichletInput)
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