#------------------------------------------------------------------------------#
# component of sandwich estimator for AIPW estimator of value of a fixed regime
#
# REQUIRES
#   value_AIPW()
#
# ASSUMPTIONS
#   tx is binary coded as {0,1}
#   moOR is a linear model
#   moPS is a logistic model
#
# INPUTS:
#    moOR : modeling object for outcome regression
#           *** must be a linear model ***
#    moPS : modeling object for propensity score regression
#           *** must be a logistic model ***
#    data : data.frame containing baseline covariates and tx
#           *** tx must be coded 0/1 ***
#       y : outcome of interest
#  txName : tx column in data (tx must be coded as 0/1)
#  regime : 0/1 vector containing recommended tx
#
# OUTPUTS:
#  value : list returned by value_AIPW()
#     MM : M M^T matrix
#   dMdB : matrix of derivatives of M wrt beta
#   dMdG : matrix of derivatives of M wrt gamma
#------------------------------------------------------------------------------#
value_AIPW_swv <- function(moOR, moPS, data, y, txName, regime) {

  # estimated value
  value <- value_AIPW(moOR = moOR, 
                      moPS = moPS, 
                      data = data,
                      y = y, 
                      regime = regime,
                      txName = txName)
  
  # pi(x;gammaHat)
  p1 <- modelObj::predict(object = value$fitPS, newdata = data)
  if( is.matrix(x = p1) ) p1 <- p1[,ncol(x = p1), drop=TRUE]
  
  # propensity to have received consistent tx
  pid <- p1*regime + {1.0-p1}*{1.0-regime}
      
  # model.matrix for propensity model
  piMM <- stats::model.matrix(object = modelObj::model(object = moPS), 
                              data = data)
      
  A <- data[,txName]
      
  # Q(H,A=d;betaHat)
  data[,txName] <- regime 
  Qd <- drop(modelObj::predict(object = value$fitOR, newdata = data))
      
  # dQ(H,A=d;betaHat)
  # derivative of a linear model is the model.matrix
  dQd <- stats::model.matrix(object = modelObj::model(object = moOR), 
                             data = data)
      
  Cd <- regime == A

  # value component of M-equation
  mValuei <- Cd * y / pid - {Cd - pid} / pid * Qd - value$valueHat
  mmValue <- mean(x = mValuei^2)

  # derivative of value component w.r.t. beta
  dMdB <- colMeans(x = -{Cd - pid} / pid*dQd)
      
  # derivative of value component w.r.t. gamma
  dMdG <- Cd*{y - Qd}/pid^2*{-1}^{regime}
  dMdG <- colMeans(x = dMdG*p1*{1.0-p1}*piMM) 
  
  return( list("value" = value, "MM" = mmValue, "dMdB" = dMdB, "dMdG" = dMdG) )
      
}
