# main body
sojourntime <- function(data) {
  results <- simulation.results(data)
  ceac <- ceac(data, results)
  ceac
}

# return a 2 * n matrix where the first collumn holds the id of the state and the second collumn the assosciated transition rate
transition.rate <- function(state, covariateCounts, alternative) {
  for (i in 1:length(state$departureRates)) {
    rates <- matrix(, nrow=0, ncol=2, byrow=T)
    thisRate <- 0
    if (state$departureRates[[i]]$lastState == FALSE) {
      departureDistribution <- state$departureRates[[i]]$distribution
      switch(departureDistribution, 
             Logistic={
               alpha <- state$departureRates[[i]]$values$alpha
               covariates <- covariates(state$departureRates[[i]]$values$covariates, covariateCounts, state$departureRates[[i]]$values$treatments, alternative)
               thisRate <- thisRate + logistic(alpha, covariates)
               rates <- rbind(rates, c(state$departureRates[[i]]$to, thisRate))
             }
      ) 
    } else {
      lastState <- state$departureRates[[i]]$to
    }
  }
  rates <- rbind(rates, c(lastState,1))
  rates
}

# returns which state a patient travels to after sojourn time has been determined
next.state <- function(state, covariateCounts, alternative, data) {
  uniform <- runif(1)
  rates <- transition.rate(state, covariateCounts, alternative)
  rowIndex <- which(uniform < rates[,2])[1]
  currentStateId <- rates[rowIndex,1] + 1
  state <- data$state[[currentStateId]]
}

# return results based on the time a patient spent in a state (sojourn time)
result <- function(alternative, iteration, results, state, sojournTime, data) {
  results[iteration, alternative, 1] <- results[iteration, alternative, 1] + sojournTime
  results[iteration, alternative, 2] <- results[iteration, alternative, 2] + ( unname(data$alternatives[[alternative]]$costs[[state$id+1]]) * sojournTime )
  results
}

# return the time a patient has spent in a state (sojourn time)
sojourn.time <- function(covariateCounts, state, timeSpent, alternative, timeHorizon) {
  switch(state$sojournTimeRate$distribution, 
         Weibull={
           covariates <- covariates(state$sojournTimeRate$values$covariates, covariateCounts, state$sojournTimeRate$values$treatments, alternative)
           sojournTime <- weibull(covariates, state)
         },
         LogLogistic={
           covariates <- covariates(state$sojournTimeRate$values$covariates, covariateCounts, state$sojournTimeRate$values$treatments, alternative)
           sojournTime <- log.logistic(state, covariates)
         }
  )
  
  # adhere to time horizon
  if ( ( sojournTime + timeSpent ) > timeHorizon ) {
    sojournTime <- timeHorizon - timeSpent
  }
  
  sojournTime
}

# get all the characteristics for the current state
state <- function(data, stateId) {
  state <- data$state[[stateId + 1]]
}

# return sojourn time when a Weibull distribution is used
weibull <- function(covariates, state) {
  uniform <- runif(1)
  rho <- state$sojournTimeRate$values$scale
  lambda <- state$sojournTimeRate$values$shape
  lambda <- exp(lambda + covariates)
  val <- (-1/lambda * (log(1 - uniform)))^(1/rho)
}

# return sojourn time when a Log Logistic distribution is used
log.logistic <- function(state, covariates) {
  uniform <- runif(1)
  beta <- state$sojournTimeRate$values$scale
  lambda <- state$sojournTimeRate$values$shape
  lambda <- exp(lambda + covariates)
  alpha <- (1/lambda)^(1/beta) # Median of the log-logistic distribution
  val <- alpha*(uniform/(1-uniform)^(1/beta))
}

# return a rate which depicts the probability a patient travels to this state
logistic <- function(alpha, covariates) {
  alpha <- exp(alpha + covariates)
  val <- alpha / ( 1 + alpha )
}  

# retrieve all patient characteristics that are based on a function
covariate.counts <- function(data) {

  covariateCounts <- matrix(, nrow=0, ncol=1, byrow=T)
  
  for (i in 1:length(data$patient$covariates)){
    covariateCounts <- rbind(covariateCounts, data$patient$covariates[[i]]$value)
    rownames(covariateCounts)[i] <- data$patient$covariates[[i]]$name
  }
  
  for (i in 1:length(data$patient$covariateExpr)){
    thiscovar <- (data$patient$covariateExpr[[i]]$input)
    lhsvalue <- thiscovar[['lhs']]
    lhs <- unname(covariateCounts[lhsvalue,])
    rhsvalue <- thiscovar[['rhs']]
    rhs <- unname(covariateCounts[rhsvalue,])
    operator <- thiscovar[['operator']]
    covlength <- length(covariateCounts) + 1
    
    switch(operator, 
           log={
             covariateCounts <- rbind(covariateCounts, log(lhs))
           },
           minus={
             covariateCounts <- rbind(covariateCounts, lhs-rhs)
           }
    )
    rownames(covariateCounts)[covlength] <- data$patient$covariateExpr[[i]]$name
  }
  covariateCounts
}

# get all patient characteristics and treatments effects needed to assess sojourn time / departure rate
covariates <- function(covariates, covariateCounts, treatments, alternative) {
  cov <- matrix(, nrow=length(covariates), ncol=1, byrow=T)

  
  cov1 <- matrix(, nrow=0, ncol=1, byrow=T)
  
  #new
  for (i in 1:length(covariates)){
    cov1 <- rbind(cov1, covariates[[i]]$value)
    rownames(cov1)[i] <- covariates[[i]]$name
  }
  
  print(cov1)
  print(rownames(cov1)[5])
  
  #patient charcteristics
  for (i in 1:length(covariates)){
    if (rownames(cov1)[i] %in% rownames(covariateCounts)) {
      name <- rownames(cov1)[i]
      covcount <- (covariateCounts)[name,1]
      cov[i,] <- (cov1[[i]] * covcount)
    } 
  }
  
  #treatment effects
  if ( is.null(treatments) == FALSE ) {
    output <- as.matrix((treatments), ncol=1, byrow=T)
    if ( is.null(unlist(output[alternative,])) == FALSE) {
      cov <- rbind(cov, log(unlist(output[alternative,])))
    }
  } 
  sum(cov)
}

# simulate based on json file, return a i*a*2 array which holds the outcomes per iteration (rows) per alternative (collumns) per criterium (2 dimensions)
simulation.results <- function(data) {
  covariateCounts <- covariate.counts(data)
  results <- array(data=(0:0),dim=c(data$iterations, length(data$alternatives), 2))
  
  for (iteration in 1:data$iterations) {
    
    # random numbers should be the same for each patient
    set.seed(iteration)
    
    for (alternative in 1:length(data$alternatives)) {
      
      state <- state(data, data$patient$startingState)
      timeSpent <- 0
      
      while (state$absorbingState == FALSE && timeSpent < data$timeHorizon){
        sojournTime <- sojourn.time(covariateCounts, state, timeSpent, alternative, data$timeHorizon)
        timeSpent <- timeSpent + sojournTime
        results <- result(alternative, iteration, results, state, sojournTime, data)
        state <- next.state(state, covariateCounts, alternative, data)
      }  
    }
  }
  results
}

# To construct a graph we first rescale all values between 0 and 1, this is the input for the SMAA function
scale.range <- function(SMAAInput,alternatives,criteria) {
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


# generate input for the SMAA package
smaa.input <- function(scales, alternatives, criteria, iterations,results){
  
  SMAAInput <- array(data=(0:0),dim=c(iterations,alternatives,criteria))
  
  for ( j in 1 : alternatives){
    for ( i in 1 : criteria ){
      if( i == 1){
        SMAAInput [ , j, i] <- smaa.pvf(results[ , j, i],
                                        cutoffs=c(scales[1,i], scales[2,i]),
                                        values=c(0, 1),
                                        outOfBounds="interpolate")
      } else {
        
        SMAAInput [ , j, i] <- smaa.pvf(results[ , j, i],
                                        cutoffs=c(scales[2,i], scales[1,i]),
                                        values=c(0, 1),
                                        outOfBounds="interpolate")
      }
    }
  }
  SMAAInput
}

# Generate weight for current lambda
weightCon <- function(lambda,scales) {
  w.1 <- lambda*(scales[2,1]-scales[1,1])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  w.2 <- (scales[2,2] - scales[1,2])/(lambda*(scales[2,1]-scales[1,1]) + scales[2,2] - scales[1,2])
  c(w.1,w.2)
}

# returns the cost-effectiveness acceptability curve based on the results
ceac <- function(data, results) {
  scales <- scale.range(results,length(data$alternatives),2)
  SMAAInput <- smaa.input(scales, length(data$alternatives), 2, data$iterations, results)
  
  # define misc values to get rank acceptabilities
  index <- 1
  wtp.step <- data$maxWillingnessToPay / 10
  steps <- ( data$maxWillingnessToPay - data$minWillingnessToPay ) / wtp.step
  lambda.vec <- rep(0,steps)
  cost.effect.accep <- c()
  lambda <- data$minWillingnessToPay
  
  # generate rank acceptabilities
  while (lambda<=data$maxWillingnessToPay) {
    cur.weight <- weightCon(lambda,scales)
    values <- smaa.values(SMAAInput, cur.weight)
    ranks <- smaa.ranks(values) 
    ra <- smaa.ra(ranks)
    rank.accept <-  ra[1,]
    cost.effect.accep <- rbind(cost.effect.accep,rank.accept)
    lambda.vec[index] <- lambda
    index <- index + 1
    lambda <- lambda + wtp.step
  }
  
  # create proper list
  ceac <- list()
  for (i in 1:length(data$alternatives)){
    ceac.data <- cbind(lambda.vec,cost.effect.accep[,i])
    colnames(ceac.data) <- c("x","y")
    ceac[[i]] <- ceac.data
    names(ceac)[[i]] <- data$alternatives[[i]]$title
  }
  ceac
}