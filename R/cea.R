# Require: smaa, DirichletReg, abind, RJSONIO
require ('DirichletReg')
require ('abind')

test <- function(params){
  ceacData <- cea(params)
  ceacData
}

cea <-function(input){
 
 ########## Inputs from website / JSON ##########
 
 numberOfStates <- length(input$states)
 amountOfAlternatives <- length(input$alternatives)

 transitionInput <- array(, dim=c(numberOfStates,numberOfStates,amountOfAlternatives) )
   for (i in 1:length(input$alternatives)){
     blaat <- matrix(unlist(input$alternatives[[i]]$transition), ncol=numberOfStates, byrow=TRUE)
     transitionInput[,,i] <- blaat
   }
 
 alternativeCosts <- matrix(, nrow = 1, ncol = amountOfAlternatives, )
   for (i in 1:length(input$alternatives)){
     blaat <- input$alternatives[[i]]$interventioncost
     alternativeCosts[,i] <- blaat
   }
 
 stateCosts <- matrix(, nrow=numberOfStates, ncol=amountOfAlternatives, byrow=T)
   for (i in 1:amountOfAlternatives){
     blaat <- input$alternatives[[i]]$stateCosts
     stateCosts[,i] <- blaat
   }
 
 measuredEffect <- matrix(, nrow=1, ncol=numberOfStates, byrow=T)
   for (i in 1:numberOfStates){
     blaat <- input$states[[i]]$measuredEffect
     measuredEffect[,i] <- blaat
   }
 
 startStates <-  matrix(, nrow=numberOfStates, ncol=1, byrow=T)
   for (i in 1:numberOfStates){
     blaat <- input$states[[i]]$startingPatients
     startStates[i,] <- blaat
   }
 
 iterations <- input$iterations
 cycles <- input$cycles
 criteria <- 2
 discountBenefits <- input$discountBenefits
 discountCosts <- input$discountCosts
 minWillingnessToPay <- input$minWillingnessToPay
 maxWillingnessToPay <- input$maxWillingnessToPay
 simulationApproach <- input$simulationApproach
 
 ########## End of inputs from website ##########
 
 # Criteria measurements. An N*m*n array, where meas[i,,] is a matrix where N is amount of iterations,
 # the m alternatives are the rows and the n criteria the columns.
 measurements <- array(data=(0:0),dim=c(iterations,amountOfAlternatives,criteria))
 
 # Simulation function, 4 approaches (deterministic, with or without relative effect & probabilistic with or without relative effect)

switch(simulationApproach, 
        Deterministic={
          # TODO
        },
        DeterministicRelativeEffect={
          # TODO
        },
        Probabilistic={
          
          for (iteration in 1:iterations){
            
            # Start with empty transition matrix
            P <- array(,dim=c(numberOfStates, numberOfStates, 0))
            # Fill transition matrix for this iteration
            P <- sampleDirichlet(numberOfStates,transitionInput,amountOfAlternatives,P)
            
            # For this given transition matrix, we calculate each alternative
            for (alternative in 1:amountOfAlternatives){
              
              transitionMatrix <- t(P[,,alternative])
              
              # Before we start, assign costs related to each alternative
              measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + ( alternativeCosts[,alternative] * sum(startStates) )
              
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
                measurements[iteration, alternative, 1] <- measurements[iteration, alternative, 1] + sum(patientsInStatesAfterCalc * effects)
                
                # Determine the costs from each state
                costs <- apply(stateCosts, 1, function(x) x / ( 1 + discountCosts ) ^ cycle )    
                measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + sum(patientsInStatesAfterCalc * costs[alternative,])
                
              }
            }
          }
        },
        ProbabilisticRelativeEffect={
          
          for (iteration in 1:iterations){
            
            # Start with empty transition matrix
            P <- array(,dim=c(numberOfStates, numberOfStates, 0))
            
            # Fill baseline transition matrix for this iteration
            P <- sampleDirichlet(numberOfStates,transitionInput,1,P)
            
            # Once we know the baseline, we apply the relative effect to obtain the transition rates for other alternatives
            P <- calculateRelativeEffect(numberOfStates,transitionInput,amountOfAlternatives,P)
            
            # For this given transition matrix, we calculate each alternative
            for (alternative in 1:amountOfAlternatives){
              
              transitionMatrix <- t(P[,,alternative])
              
              # Before we start, assign costs related to each alternative
              measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + ( alternativeCosts[,alternative] * sum(startStates) )
              
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
                measurements[iteration, alternative, 1] <- measurements[iteration, alternative, 1] + sum(patientsInStatesAfterCalc * effects)
                
                # Determine the costs from each state
                costs <- apply(stateCosts, 1, function(x) x / ( 1 + discountCosts ) ^ cycle )    
                measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + sum(patientsInStatesAfterCalc * costs[alternative,])
                
              }
            }
          }
        }
       )

 # To construct a graph we first rescale all values between 0 and 1, this is the input for the SMAA function
 scales <- scaleRange(measurements,amountOfAlternatives,criteria)
 
 # From the simulation, generate input for the SMAA package
 SMAAInput <- getSMAA(scales, amountOfAlternatives, criteria, iterations,measurements)
 
 # define misc values to get rank acceptabilities
 lambda <- 0
 index <- 1
 wtp.step <- maxWillingnessToPay / 100
 steps <- maxWillingnessToPay/wtp.step + 1
 lambda.vec <- rep(0,steps)
 cost.effect.accep <- c()
 lambda <- minWillingnessToPay
 
 while (lambda<=maxWillingnessToPay) {
   # Calculate the current weights, according to (Postmus et al, 2013)
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
 for (i in 1:amountOfAlternatives){
   ceac.data <- cbind(lambda.vec,cost.effect.accep[,i])
   colnames(ceac.data) <- c("x","y")
   ceac[[i]] <- ceac.data
   names(ceac)[[i]] <- input$alternatives[[i]]$title
 }
 ceac
}

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
sampleDirichlet <- function(numberOfStates,transitionArray,alternatives,P){
 
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

# generate transition probabilities based on a relative effect found on the baseline
calculateRelativeEffect <- function(numberOfStates,transitionArray,alternatives,P){
  
  # we know the first alternative, so we are intrested in the others which have a relative effect
  for ( alternative in 2 : alternatives ){
    X <- matrix(, ncol=numberOfStates, nrow = numberOfStates, )
    
    for (fromState in 1:numberOfStates){
      
      sumOfTransitionsFromThisState <- 0
      
      for (toState in 1:numberOfStates){
        
        if (fromState != toState){
          # We calculate the adjusted risk based on Postmus et al 2011 ( DOI: 10.1002/sim.5434 )
          # First take the transition from the baseline, which is now reported on a discrete scale (yearly cycles) and adjust to coninuous cycle 
          continuousTransition <- -log(1 - P[fromState, toState , 1 ])
          
          # Adjust the ratio on a continuous scale with the reported hazard ratio
          adjustedContinuousTransition <- continuousTransition * transitionArray[fromState, toState , alternative ]
          
          # Rescale the transition reported on a continuous to a discrete scale
          X[fromState, toState] <- 1 - exp(-adjustedContinuousTransition)
          
          # Keep track of the sum of adjusted transition rates for this alternative, the reflexive transition is based on 1 - the sum
          sumOfTransitionsFromThisState <- sumOfTransitionsFromThisState + X[fromState, toState]
        }
      }
      
      # We make the assumption that the reflexive transition is always 1 minus all other depart rates
      X[fromState,fromState] <- 1 - sumOfTransitionsFromThisState
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