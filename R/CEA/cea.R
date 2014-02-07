### Function definitions ###

# generate input for the SMAA package
getSMAA <- function(scales, alternatives, criteria, iterations,measurements){
  
  SMAAInput <- array(data=(0:0),dim=c(iterations,alternatives,criteria))
  
  for ( j in 1 : alternatives){
    for ( i in 1 : criteria ){
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

# Generate weight for current lambda
weightCon <- function(lambda,scales) {
  w.1 <- lambda*(scales[2,1]-scales[1,1])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  w.2 <- (scales[2,2] - scales[1,2])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  c(w.1,w.2)
}

# Test doc for CEA implementation
# R 3.0.2

# Use DirichletReg package for pulling random numbers from multi beta distribution
library(DirichletReg)

# Use JSON to get data from input
library(RJSONIO)

# Use smaa package to determine confidence
library(smaa)

# Use abind to bind matrix to arrays
library(abind)

# Should come from JSON file
input <- fromJSON(file('simple.json'))
  
########## Inputs from website / JSON ##########

# Amount of states
numberOfStates <- length(input$states)

# Number of alternatives
alternatives <- length(input$alternatives)

iterations <- 2 #input$iterations
cycles <- 2 #input$cycles

# For now we only test two criteria
criteria <- 2

# All the beta values for transition states
transitionInput <- array(, dim=c(numberOfStates,numberOfStates,alternatives) )

for (i in 1:length(input$alternatives)){
  blaat <- matrix(unlist(input$alternatives[[i]]$transition), ncol=numberOfStates, byrow=TRUE)
  transitionInput[,,i] <- blaat
}

# Costs, alternativeCosts is startup costs
alternativeCosts <- matrix(, nrow = 1, ncol = alternatives, )

for (i in 1:length(input$alternatives)){
  blaat <- input$alternatives[[i]]$interventioncost
  alternativeCosts[,i] <- blaat
}

# and costs assosciated with each state
stateCosts <-  matrix(, nrow=1, ncol=numberOfStates, byrow=T)

for (i in 1:numberOfStates){
  blaat <- input$states[[i]]$statecost
  stateCosts[,i] <- blaat
}

# and costs assosciated with each state
startStates <-  matrix(, nrow=numberOfStates, ncol=1, byrow=T)

for (i in 1:numberOfStates){
  blaat <- input$states[[i]]$startingPatients
  startStates[i,] <- blaat
}

discountCosts <- input$discountcosts
discountBenefits <- input$discountbenefits

#measured effect
measuredEffect <- matrix(, nrow=1, ncol=numberOfStates, byrow=T)

for (i in 1:numberOfStates){
  blaat <- input$states[[i]]$measuredeffect
  measuredEffect[,i] <- blaat
}

########## End of inputs from website ##########

# Criteria measurements. An N*m*n array, where meas[i,,] is a matrix where N is amount of iterations,
# the m alternatives are the rows and the n criteria the columns.
measurements <- array(data=(0:0),dim=c(iterations,alternatives,criteria))

# Simulation function
for (iteration in 1:iterations){
  
  # Start with empty transition matrix
  P <- array(,dim=c(alternatives, numberOfStates, 0))
  
  # Fill transition matrix for this iteration
  P <- distribution.dirichlet(numberOfStates,transitionInput,alternatives,P)
  
  # Within this iteration, we calculate each alternative
  for (alternative in 1:alternatives){
    
    transitionMatrix <- t(P[,,alternative])
    
    # Before we start, assign costs related to each alternative
    measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + alternativeCosts[,alternative]
    print(measurements)
    
    for (cycle in 1:cycles){
      
      # Determine how many patients end up in which state
      if (cycle == 1){
        patientsInStates <- startStates
      } else {
        patientsInStates <- patientsInStatesAfterCalc
      }
      patientsInStatesAfterCalc <- transitionMatrix %*% patientsInStates
      
      # Determine the effects from each state
      effects <- apply(measuredEffect, 1, function(x) x / (1 + discountBenefits) ^ cycle )        
      measurements[iteration, alternative, 1] <- measurements[iteration, alternative, 1] + ( sum(patientsInStatesAfterCalc * effects) / sum(startStates) )
      
      # Determine the costs from each state
      costs <- apply(stateCosts, 1, function(x) x / ( 1 + discountCosts ) ^ cycle )    
      measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + ( sum(patientsInStatesAfterCalc * costs) / sum(startStates) )
      
    }
  }
}

print(measurements)

# To construct a graph we first rescale all values between 0 and 1, this is the input for the SMAA function
scales <- scaleRange(measurements,alternatives,criteria)

# From the simulation, generate input for the SMAA package
SMAAInput <- getSMAA(scales, alternatives, criteria, iterations,measurements)

# define misc values to get a ra table
lambda <- 0
index <- 1

# worst possible outcome, max costs
wtp.max <- max(alternativeCosts) + max(stateCosts) * cycles 
wtp.step <- wtp.max / 10
steps <- wtp.max/wtp.step + 1
lambda.vec <- rep(0,steps)
cost.effect.accep <- c()

while (lambda<=wtp.max) {
  # Calculate the current weights, according to ( SMAA-2 : Stochastic Multicriteria Acceptability Analysis for Group Decision Making ANALYSIS FOR GROUP DECISION MAKING, 2011 )
  # the current weights are returned in a N * n matrix, to be used in smaa.value see smaa package
  cur.weight <- weightCon(lambda,scales)
  
  # Get rank acceptability per criteria.
  # rank acceptability = the amount of time that the alternative is the best / amount of times the simulation is ran, which is equal to amount of patients
  values <- smaa.values(SMAAInput, cur.weight)
  ranks <- smaa.ranks(values) 
  ra <- smaa.ra(ranks)
  
  # because smaa.ra outputs an m*m matrix where rows AND collumns are equal to the amount of alternatives
  # and we only need to know which alternative has what acceptability rate
  # we only extract the first row from smaa.ra
  rank.accept <-  ra[1,]
  
  # and bind it to the corresponding row
  cost.effect.accep <- rbind(cost.effect.accep,rank.accept)
  
  # we also save a mapping to the lamba for which we calculated the rank acceptabilities 
  lambda.vec[index] <- lambda
  index <- index + 1
  lambda <- lambda + wtp.step
}

# create proper list
ceac <- list()
for (i in 1:alternatives){
  ceac.data <- cbind(lambda.vec,cost.effect.accep[,i])
  colnames(ceac.data) <- c("x","y")
  ceac[[i]] <- ceac.data
  names(ceac)[[i]] <- c(i)
}

print(ceac)