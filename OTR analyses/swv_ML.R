#------------------------------------------------------------------------------#
# components of the sandwich estimator for a maximum likelihood estimation of 
#   a logistic regression model
#
# ASSUMPTIONS
#   mo is a logistic model with parameters to be estimated using ML
#
# INPUTS
#    mo : a modeling object specifying a regression step
#         *** must be a logistic model ***
#  data : a data.frame containing covariates and tx
#     y : a vector containing the binary outcome of interest
#
#
# RETURNS
# a list containing
#     MM : M^T M component from ML
#  invdM : inverse of the matrix of derivatives of M wrt gamma
#------------------------------------------------------------------------------#
swv_ML <- function(mo, data, y) {

  # regression step
  fit <- modelObj::fit(object = mo, data = data, response = y)

  # yHat
  p1 <- modelObj::predict(object = fit, newdata = data) 
  if (is.matrix(x = p1)) p1 <- p1[,ncol(x = p1), drop = TRUE]

  # model.matrix for model
  piMM <- stats::model.matrix(object = modelObj::model(object = mo), 
                              data = data)

  n <- nrow(x = piMM)
  p <- ncol(x = piMM)

  # ML M-estimator component
  mMLi <- {y - p1} * piMM

  # ML component of M MT
  mmML <- sapply(X = 1L:n, 
                 FUN = function(i){ mMLi[i,] %o% mMLi[i,] }, 
                 simplify = "array")

  # derivative of ML component
  dFun <- function(i){ 
            - piMM[i,] %o% piMM[i,] * p1[i] * {1.0 - p1[i]}
           } 
  dmML <- sapply(X = 1L:n, FUN = dFun, simplify = "array")

  if( p == 1L ) {
    mmML <- mean(x = mmML)
    dmML <- mean(x = dmML)
  } else {
    mmML <- rowMeans(x = mmML, dim = 2L)
    dmML <- rowMeans(x = dmML, dim = 2L)
  }

  # invert derivative ML component
  invD <- solve(a = dmML) 

  return( list("MM" = mmML, "invdM" = invD) )

}
