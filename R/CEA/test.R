# Require: smaa, DirichletReg, abind, RJSONIO
require ('DirichletReg')
require ('abind')

test <- function(params){
  
  ceacData <- cea(params)
  ceacData
  
}

cea <-function(input){
 
 ########## Inputs from website / JSON ##########
 
 # Amount of states
 numberOfStates <- length(input$states)
 
 # Number of alternatives
 alternatives <- length(input$alternatives)
 
 iterations <- input$iterations
 cycles <- input$cycles
 
 #doCEA(input)
 
 # For now we only test two criteria
 criteria <- 2
 
 # All the beta values for transition states
 transitionInput <- array(c(17,0,0,2,15,0,1,5,20,8,0,0,6,10,0,6,10,20,4,0,0,6,5,0,10,14,20), dim=c(numberOfStates,numberOfStates,alternatives) )
 
 # Costs, alternativeCosts is startup costs
 alternativeCosts <- matrix(c(2000,250,0), nrow = 1, ncol = alternatives, )
 
 # and costs assosciated with each state
 stateCosts <- array(c(50,50,50,75,75,75,5,5,5), dim=c(numberOfStates,numberOfStates,alternatives))
 
 #measured effect
 measuredEffect <- array(c(input$measuredeffect), dim=c(numberOfStates,numberOfStates,alternatives))
 
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
     
     # Start at cycle 1
     state <- 1
     
     # Before we start we assume there are startup costs
     measurements[iteration, alternative, 2] <-  measurements[iteration, alternative, 2] + alternativeCosts[1,alternative]
     
     for (cycle in 1:cycles){
       
       # add effects ( Matrix algebra )
       measurements[iteration, alternative, 1] <- measurements[iteration, alternative, 1] + sum(P[state, , alternative]*measuredEffect[, state, alternative ]) / ( ( 1 + input$discountbenefits ) ^ cycle )
       
       # add costs ( Matrix algebra )
       measurements[iteration, alternative, 2] <- measurements[iteration, alternative, 2] + sum(P[state, , alternative]*stateCosts[, state, alternative ]) / ( ( 1 + input$discountcosts ) ^ cycle ) 
       
       # determine which state we transition to
       state <- sample(1:numberOfStates,size=1,prob=P[state, , alternative   ])
       
     }
     
   }
   
 }
 
 
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
 x <- list()
 for (i in 1:alternatives){
   
   ceac.data <- cbind(lambda.vec,cost.effect.accep[,i])
   colnames(ceac.data) <- c("x","y")
   x[[i]] <- ceac.data
   names(x)[[i]] <- c(i)
   
 }
 
 x
 
 # finally map the rows to the lambda against which we plot
#  ceac.data <- cbind(lambda.vec,cost.effect.accep[,1])
#  colnames(ceac.data) <- c("x","Y")
#  ceac.data
 
 #cost.effect.accep
 
}

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