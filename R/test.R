test <- function(params){
	allowed <- c('test')
  if(params$method %in% allowed) {
  	hoi <- 5
    do.call(paste(hoi))
  } else {
    stop("method not allowed")
}