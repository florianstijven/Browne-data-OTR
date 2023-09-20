#------------------------------------------------------------------------------#
# components of the sandwich estimator for an ordinary least squares estimation
#   of a linear regression model
#
# ASSUMPTIONS
#   mo is a linear model with parameters to be estimated using OLS
#
# INPUTS
#    mo : a modeling object specifying a regression step
#         *** must be a linear model ***
#  data : a data.frame containing covariates and tx
#     y : a vector containing the outcome of interest
#
#
# RETURNS
# a list containing
#     MM : M^T M component from OLS
#  invdM : inverse of the matrix of derivatives of M wrt beta
#------------------------------------------------------------------------------#
swv_OLS <- function(mo, data, y) {

  n <- nrow(x = data)

  fit <- modelObj::fit(object = mo, data = data, response = y)

  # Q(X,A;betaHat)
  Qa <- drop(x = modelObj::predict(object = fit, newdata = data))

  # derivative of Q(X,A;betaHat)
  dQa <- stats::model.matrix(object = modelObj::model(object = mo), 
                             data = data)

  # number of parameters in model
  p <- ncol(x = dQa)

  # OLS component of M
  mOLSi <- {y - Qa}*dQa

  # OLS component of M MT
  mmOLS <- sapply(X = 1L:n, 
                  FUN = function(i){ mOLSi[i,] %o% mOLSi[i,] }, 
                  simplify = "array")

  # derivative OLS component
  dmOLS <- - sapply(X = 1L:n, 
                    FUN = function(i){ dQa[i,] %o% dQa[i,] }, 
                    simplify = "array")

  # sum over individuals
  if (p == 1L) {
    mmOLS <- mean(x = mmOLS)
    dmOLS <- mean(x = dmOLS)
  } else {
    mmOLS <- rowMeans(x = mmOLS, dim = 2L)
    dmOLS <- rowMeans(x = dmOLS, dim = 2L)
  }

  # invert derivative OLS component
  invD <- solve(a = dmOLS) 

  return( list("MM" = mmOLS, "invdM" = invD) )

}
