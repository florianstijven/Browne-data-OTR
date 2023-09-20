#------------------------------------------------------------------------------#
# value and standard error for the AIPW estimator of the value of a fixed
# regime using the sandwich estimator of variance
#
# REQUIRES
#   swv_ML(), swv_OLS(), and value_AIPW_swv()
#
# ASSUMPTIONS
#   tx is binary coded as {0,1}
#   moOR is a linear model
#   moPS is a logistic model
#
# INPUTS
#    moPS : modeling object specifying propensity score regression
#           *** must be a logistic model ***
#    moOR : modeling object specifying outcome regression
#           *** must be a linear model ***
#    data : data.frame containing covariates and tx
#           *** tx must be coded 0/1 ***
#       y : vector of outcome of interest
#  txName : treatment column in data (treatment must be coded as 0/1)
#  regime : 0/1 vector containing recommended tx
#
# RETURNS
#  a list containing
#     fitOR : value object returned by outcome regression
#     fitPS : value object returned by propensity score regression
#        EY : sample average outcome for each received tx grp
#  valueHat : estimated value
#  sigmaHat : estimated standard error
#------------------------------------------------------------------------------#
value_AIPW_se <- function(moPS, moOR, data, y, txName, regime) {

  #### ML components
  ML <- swv_ML(mo = moPS, data = data, y = data[,txName]) 

  #### OLS components
  OLS <- swv_OLS(mo = moOR, data = data, y = y) 

  #### estimator components
  AIPW <- value_AIPW_swv(moOR = moOR, 
                         moPS = moPS, 
                         data = data, 
                         y = y, 
                         regime = regime,
                         txName = txName)
      
  #### 1,1 Component of Sandwich Estimator

  ## ML contribution
  temp <- AIPW$dMdG %*% ML$invdM
  sig11ML <- temp %*% ML$MM %*% t(x = temp)

  ## OLS contribution
  temp <- AIPW$dMdB %*% OLS$invdM
  sig11OLS <- temp %*% OLS$MM %*% t(x = temp)

  sig11 <- drop(x = AIPW$MM + sig11ML + sig11OLS)

  return( c(AIPW$value, "sigmaHat" = sqrt(x = sig11 / nrow(x = data)))  )
      
}
